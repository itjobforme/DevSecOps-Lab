provider "aws" {
  region = "us-east-1"  # Change this if needed
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
  map_public_ip_on_launch = true  # Ensures instances get a public IP

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

  # Allow SSH from YOUR IP ONLY
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["173.216.28.115/32"]  # Replace with your actual IP
  }

  # Allow HTTP access from anywhere (for testing)
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
  ami             = "ami-09e67e426f25ce0d7"  # Ubuntu AMI
  instance_type   = "t2.micro"
  key_name        = "devsecops-key-new"

  subnet_id       = aws_subnet.public_subnet.id
  vpc_security_group_ids = [aws_security_group.devsecops_sg.id]

  associate_public_ip_address = true

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

