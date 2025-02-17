terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
  required_version = ">= 1.3.0"
}

provider "aws" {
  region = "us-east-1"
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

### Enable VPC Flow Logs for Security
resource "aws_flow_log" "devsecops_vpc_flow_log" {
  log_destination = aws_s3_bucket.devsecops_vpc_logs.arn
  traffic_type    = "ALL"
  vpc_id          = aws_vpc.devsecops_vpc.id

  tags = {
    Name = "DevSecOps-VPC-Flow-Logs"
  }
}

### Create an S3 Bucket for VPC Flow Logs
resource "aws_s3_bucket" "devsecops_vpc_logs" {
  bucket        = "devsecops-vpc-logs-${random_id.bucket_id.hex}"
  force_destroy = true

  tags = {
    Name = "DevSecOps-VPC-Logs"
  }
}

resource "aws_s3_bucket_versioning" "vpc_logs_versioning" {
  bucket = aws_s3_bucket.devsecops_vpc_logs.id
  versioning_configuration {
    status = "Enabled"
  }
}

###  Create an Internet Gateway
resource "aws_internet_gateway" "devsecops_igw" {
  vpc_id = aws_vpc.devsecops_vpc.id

  tags = {
    Name = "DevSecOps-IGW"
  }
}

###  Create a Public Subnet
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.devsecops_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true # Ensures instances get a public IP

  tags = {
    Name = "DevSecOps-Public-Subnet"
  }
}

###  Create a Route Table for Public Subnet
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

###  Associate Route Table with Public Subnet
resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_route_table.id
}

###  Create a Security Group for EC2
resource "aws_security_group" "devsecops_sg" {
  vpc_id = aws_vpc.devsecops_vpc.id

  # Allow SSH only from a specific IP
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["173.216.28.115/32"]
  }

  # Allow HTTP access from anywhere (required for website)
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
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

  metadata_options {
    http_tokens   = "required" # Enforce IMDSv2 for security
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

    # Pull and run the Dockerized web app
    sudo docker run -d -p 80:5000 --name devsecops-blog itjobforme/devsecops-blog:latest
  EOF

  tags = {
    Name = "DevSecOps-Blog"
  }
}

### Generate a Unique S3 Bucket Name
resource "random_id" "bucket_id" {
  byte_length = 8
}

### Create an S3 Bucket for the Web App
resource "aws_s3_bucket" "devsecops_blog_bucket" {
  bucket        = "devsecops-blog-${random_id.bucket_id.hex}"
  acl           = "private"
  force_destroy = true

  tags = {
    Name = "DevSecOps-Blog-Bucket"
  }
}

### Enable Versioning for S3 Bucket
resource "aws_s3_bucket_versioning" "blog_bucket_versioning" {
  bucket = aws_s3_bucket.devsecops_blog_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}
