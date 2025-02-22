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

resource "aws_lb" "devsecops_alb" {
  name               = "devsecops-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [aws_subnet.public_subnet_1.id, aws_subnet.public_subnet_2.id]


  enable_deletion_protection = false

  depends_on = [aws_acm_certificate_validation.blog_cert_validation]


  tags = {
    Name = "DevSecOps-ALB"
  }
}


resource "aws_route53_record" "blog_dns" {
  zone_id = "Z01497793G9Q2YQQ3ARC8"
  name    = "blog.securingthecloud.org"
  type    = "A"

  alias {
    name                   = aws_lb.devsecops_alb.dns_name
    zone_id                = aws_lb.devsecops_alb.zone_id
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

### Create Public Subnet 1
resource "aws_subnet" "public_subnet_1" {
  vpc_id                  = aws_vpc.devsecops_vpc.id
  cidr_block              = "10.0.3.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "DevSecOps-Public-Subnet-1"
  }
}

### Create Public Subnet 2
resource "aws_subnet" "public_subnet_2" {
  vpc_id                  = aws_vpc.devsecops_vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true

  tags = {
    Name = "DevSecOps-Public-Subnet-2"
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

### Associate Route Table with Public Subnet 1
resource "aws_route_table_association" "public_assoc_1" {
  subnet_id      = aws_subnet.public_subnet_1.id
  route_table_id = aws_route_table.public_route_table.id
}

### Associate Route Table with Public Subnet 2
resource "aws_route_table_association" "public_assoc_2" {
  subnet_id      = aws_subnet.public_subnet_2.id
  route_table_id = aws_route_table.public_route_table.id
}


# Load Balancer Listener for HTTP to HTTPS Redirect
resource "aws_lb_listener" "http_redirect" {
  load_balancer_arn = aws_lb.devsecops_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"
    redirect {
      protocol    = "HTTPS"
      port        = "443"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_lb_listener" "https_listener" {
  load_balancer_arn = aws_lb.devsecops_alb.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = aws_acm_certificate.blog_cert.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.devsecops_tg.arn
  }
}

resource "aws_lb_target_group" "devsecops_tg" {
  name     = "devsecops-tg"
  port     = 5000
  protocol = "HTTP"
  vpc_id   = aws_vpc.devsecops_vpc.id

  health_check {
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = {
    Name = "DevSecOps-TG"
  }
}

resource "aws_lb_target_group_attachment" "devsecops_tg_attachment" {
  target_group_arn = aws_lb_target_group.devsecops_tg.arn
  target_id        = aws_instance.devsecops_blog.id
  port             = 5000
}

# Security Group for ALB
resource "aws_security_group" "alb_sg" {
  name        = "alb-security-group"
  description = "Security group for ALB"
  vpc_id      = aws_vpc.devsecops_vpc.id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ALB-SG"
  }
}

# Security Group for EC2 Instance
resource "aws_security_group" "devsecops_sg" {
  vpc_id = aws_vpc.devsecops_vpc.id

  ingress {
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    security_groups = [aws_security_group.alb_sg.id] # Allow only from ALB
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

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

# EC2 Instance Configuration
resource "aws_instance" "devsecops_blog" {
  ami                         = "ami-09e67e426f25ce0d7"
  instance_type               = "t2.micro"
  key_name                    = "devsecops-key-new"
  subnet_id                   = aws_subnet.public_subnet_1.id
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.ec2_ssm_profile.name
  vpc_security_group_ids      = [aws_security_group.devsecops_sg.id]

  metadata_options {
    http_tokens   = "required"
    http_endpoint = "enabled"
  }

  user_data = file("user-data.sh")

  tags = {
    Name = "DevSecOps-Blog"
  }
}


### Create an EBS Volume in the Same Availability Zone as the EC2 Instance
resource "aws_ebs_volume" "devsecops_blog_data" {
  availability_zone = "us-east-1a" # Make sure this matches your EC2 instance AZ
  size              = 10 # Size in GB
  tags = {
    Name = "DevSecOps-Blog-Data"
  }
}

### Attach the EBS Volume to the EC2 Instance
resource "aws_volume_attachment" "devsecops_blog_data_attachment" {
  device_name = "/dev/sdf" # Linux will mount this as /dev/xvdf
  volume_id   = aws_ebs_volume.devsecops_blog_data.id
  instance_id = aws_instance.devsecops_blog.id
  force_detach = true

  # Ensure the EBS volume is attached only after the instance is created
  depends_on = [
    aws_instance.devsecops_blog
  ]
}

