provider "aws" {
  region = "us-east-1"
}


data "aws_availability_zones" "available" {}

resource "aws_vpc" "devsecops_eks_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "devsecops-eks-vpc"
  }
}

resource "aws_subnet" "eks_subnets" {
  count = 2
  vpc_id            = aws_vpc.devsecops_eks_vpc.id
  cidr_block        = cidrsubnet(aws_vpc.devsecops_eks_vpc.cidr_block, 4, count.index)
  availability_zone = element(data.aws_availability_zones.available.names, count.index)
  map_public_ip_on_launch = true


  tags = {
    Name = "devsecops-eks-subnet-${count.index}"
  }
}

resource "aws_internet_gateway" "devsecops_eks_igw" {
  vpc_id = aws_vpc.devsecops_eks_vpc.id
  tags = {
    Name = "devsecops-eks-igw"
  }
}

resource "aws_route_table" "devsecops_eks_route_table" {
  vpc_id = aws_vpc.devsecops_eks_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.devsecops_eks_igw.id
  }

  tags = {
    Name = "devsecops-eks-route-table"
  }
}

resource "aws_route_table_association" "eks_route_table_association" {
  count          = 2
  subnet_id      = aws_subnet.eks_subnets[count.index].id
  route_table_id = aws_route_table.devsecops_eks_route_table.id
}

resource "aws_ecr_repository" "devsecops_k8s_app" {
  name = "devsecops-k8s-app"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = "devsecops-k8s-app"
  }
}

resource "aws_iam_role" "eks_cluster_role" {
  name = "devsecops-eks-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "eks.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  role       = aws_iam_role.eks_cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_eks_cluster" "devsecops_eks" {
  name     = "devsecops-eks-cluster"
  role_arn = aws_iam_role.eks_cluster_role.arn
  version  = "1.32" 

  vpc_config {
    subnet_ids       = aws_subnet.eks_subnets[*].id
    security_group_ids = [aws_security_group.eks_node_sg.id]
  }

  depends_on = [aws_iam_role_policy_attachment.eks_cluster_policy]
}


# ACM Certificate
resource "aws_acm_certificate" "devsecops_cert" {
  domain_name       = "k8s.securingthecloud.org"
  validation_method = "DNS"
}

resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.devsecops_cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      type   = dvo.resource_record_type
      record = dvo.resource_record_value
    }
  }
  zone_id = "Z01497793G9Q2YQQ3ARC8"
  name    = each.value.name
  type    = each.value.type
  records = [each.value.record]
  ttl     = 60
}

resource "aws_acm_certificate_validation" "devsecops_cert_validation" {
  certificate_arn         = aws_acm_certificate.devsecops_cert.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
}

resource "aws_lb" "devsecops_eks_lb" {
  name               = "devsecops-eks-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = aws_subnet.eks_subnets[*].id

  depends_on = [aws_acm_certificate_validation.devsecops_cert_validation]
}



resource "aws_lb_target_group" "eks_target_group" {
  name       = "devsecops-eks-tg"
  port       = 443
  protocol   = "HTTPS"
  vpc_id     = aws_vpc.devsecops_eks_vpc.id
  target_type = "ip"
}

resource "aws_lb_listener" "https_listener" {
  load_balancer_arn = aws_lb.devsecops_eks_lb.arn
  port               = "443"
  protocol           = "HTTPS"
  ssl_policy         = "ELBSecurityPolicy-2016-08"
  certificate_arn    = aws_acm_certificate.devsecops_cert.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.eks_target_group.arn
  }
}

resource "aws_route53_record" "dns_record" {
  zone_id = "Z01497793G9Q2YQQ3ARC8"
  name    = "k8s.securingthecloud.org"
  type    = "A"
  alias {
    name                   = aws_lb.devsecops_eks_lb.dns_name
    zone_id                = aws_lb.devsecops_eks_lb.zone_id
    evaluate_target_health = true
  }
}
