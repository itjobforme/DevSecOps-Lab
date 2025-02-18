terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  required_version = ">= 1.3.0"

  backend "s3" {
    bucket         = "devsecops-blog-b3f1dd72d334a052"
    key            = "terraform/state"
    region         = "us-east-1"
    encrypt        = true
  }
}

provider "aws" {
  region = "us-east-1"
}

resource "aws_acm_certificate" "blog_cert" {
  domain_name       = "blog.securingthecloud.org"
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "BlogSSL"
  }
}

resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.blog_cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  zone_id = "Z01497793G9Q2YQQ3ARC8" # Your Hosted Zone ID
  name    = each.value.name
  type    = each.value.type
  records = [each.value.record]
  ttl     = 60
}

resource "aws_acm_certificate_validation" "blog_cert_validation" {
  certificate_arn         = aws_acm_certificate.blog_cert.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
}

resource "aws_cloudfront_distribution" "blog_distribution" {
  origin {
    domain_name = aws_instance.devsecops_blog.public_dns
    origin_id   = aws_instance.devsecops_blog.id

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  enabled             = true
  default_root_object = "index.html"

  default_cache_behavior {
    target_origin_id       = aws_instance.devsecops_blog.id
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    forwarded_values {
      query_string = true
      cookies {
        forward = "all"
      }
    }
  }

  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate.blog_cert.arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  tags = {
    Name = "DevSecOpsBlogCloudFront"
  }

  depends_on = [aws_acm_certificate_validation.blog_cert_validation] # Ensure the certificate is validated before CloudFront deploys
}


resource "aws_route53_record" "blog_dns" {
  zone_id = "Z01497793G9Q2YQQ3ARC8"
  name    = "blog.securingthecloud.org"
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.blog_distribution.domain_name
    zone_id                = aws_cloudfront_distribution.blog_distribution.hosted_zone_id
    evaluate_target_health = false
  }
}


### Create an IAM Role for EC2 with SSM Access
resource "aws_iam_role" "ec2_ssm_role" {
  name = "DevSecOpsEC2SSMRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_policy_attachment" "ssm_policy_attachment" {
  name       = "ssm-policy-attachment"
  roles      = [aws_iam_role.ec2_ssm_role.name]
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ec2_ssm_profile" {
  name = "DevSecOpsEC2SSMProfile"
  role = aws_iam_role.ec2_ssm_role.name
}

### Create a Secure VPC
resource "aws_vpc" "devsecops_vpc" {
  cidr_block = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "DevSecOps-VPC"
  }
}

### Create an Internet Gateway 
resource "aws_internet_gateway" "devsecops_igw" {
  vpc_id = aws_vpc.devsecops_vpc.id

  tags = {
    Name = "DevSecOps-IGW"
  }
}

### Create a Public Subnet
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.devsecops_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "DevSecOps-Public-Subnet"
  }
}

### Create a Route Table for Public Subnet
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.devsecops_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.devsecops_igw.id
  }

  tags = {
    Name = "DevSecOps-Public-Route-Table"
  }
}

### Associate Route Table with Public Subnet
resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_route_table.id
}

### Create a Security Group for EC2
resource "aws_security_group" "devsecops_sg" {
  vpc_id = aws_vpc.devsecops_vpc.id

  # Allow SSH only from your IP
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["173.216.28.115/32"]
  }

  # Allow traffic from CloudFront using AWS-managed Prefix List
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    prefix_list_ids = ["pl-3b927c52"]
  }
  
  # Allow SSM Agent Traffic (Keep this open for AWS Systems Manager access)
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Required for SSM
  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "DevSecOps-SG"
  }
}

### Deploy an EC2 Instance in the Public Subnet
resource "aws_instance" "devsecops_blog" {
  ami                         = "ami-09e67e426f25ce0d7" # Ubuntu AMI
  instance_type               = "t2.micro"
  key_name                    = "devsecops-key-new"
  subnet_id                   = aws_subnet.public_subnet.id
  vpc_security_group_ids      = [aws_security_group.devsecops_sg.id]
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.ec2_ssm_profile.name

  metadata_options {
    http_tokens   = "required" # Enforce IMDSv2
    http_endpoint = "enabled"
  }

  user_data = <<-EOF
    #!/bin/bash
    set -e  # Exit on error

    # Update and install required packages
    sudo apt update -y
    sudo apt upgrade -y
    sudo apt install -y docker.io python3 python3-pip

    # Enable and start Docker
    sudo systemctl enable docker
    sudo systemctl start docker
    sudo usermod -aG docker ubuntu

    # Install AWS SSM Agent (if not using pre-installed Snap package)
    if ! command -v snap &> /dev/null; then
      sudo apt install -y amazon-ssm-agent
    else
      sudo snap install amazon-ssm-agent --classic
    fi

    sudo systemctl enable amazon-ssm-agent
    sudo systemctl start amazon-ssm-agent

    # Pull and run the updated Dockerized web app
    sudo docker pull itjobforme/devsecops-lab:latest
    sudo docker run -d -p 80:5000 --name devsecops-blog itjobforme/devsecops-lab:latest
  EOF

  tags = {
    Name = "DevSecOps-Blog"
  }
}
