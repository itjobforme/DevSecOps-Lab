provider "aws" {
  region = "us-east-1"
}

terraform {
  backend "s3" {
    bucket = "devsecops-blog-0a1a509edae085e7"
    key    = "k8s-app/terraform.tfstate"
    region = "us-east-1"
  }
}

resource "aws_iam_role" "ec2_ssm_role" {
  name = "DevSecOpsEC2SSMRole-k8s-app"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_policy_attachment" "ssm_policy_attachment" {
  name       = "ssm-policy-attachment-k8s-app"
  roles      = [aws_iam_role.ec2_ssm_role.name]
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_policy" "ecr_policy" {
  name   = "DevSecOpsEC2ECRPolicy-k8s-app"
  path   = "/"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage"
        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecr_policy_attachment" {
  role       = aws_iam_role.ec2_ssm_role.name
  policy_arn = aws_iam_policy.ecr_policy.arn
}

resource "aws_iam_instance_profile" "ec2_ssm_profile" {
  name = "DevSecOpsEC2SSMProfile-k8s-app"
  role = aws_iam_role.ec2_ssm_role.name
}

resource "aws_instance" "k8s_app_ec2" {
  ami           = "ami-09e67e426f25ce0d7" # Ubuntu Server 20.04 LTS
  instance_type = "t3.small"
  iam_instance_profile = aws_iam_instance_profile.ec2_ssm_profile.name
  key_name = "devsecops-key-new"

  security_groups = ["k8s-app-sg"]

  user_data = <<-EOF
    #!/bin/bash
    exec > /var/log/user-data.log 2>&1
    set -x

    # Ensure no other apt processes are running
    while sudo fuser /var/lib/dpkg/lock >/dev/null 2>&1; do
       echo "Waiting for other apt processes to finish..."
       sleep 5
    done

    sudo apt-get update -y
    sleep 5

    # Retry package installation with sleep intervals
    RETRIES=5
    until sudo apt-get install -y docker.io unzip awscli; do
      if [ $RETRIES -le 0 ]; then
        echo "Failed to install packages after multiple attempts, exiting."
        exit 1
      fi
      echo "Retrying package installation..."
      sleep 10
      RETRIES=$((RETRIES-1))
    done

    # Start Docker and add the ubuntu user to the docker group
    sudo systemctl enable docker
    sudo systemctl start docker
    sudo usermod -aG docker ubuntu
    sleep 5

    # Login to ECR
    aws ecr get-login-password --region us-east-1 | sudo docker login --username AWS --password-stdin 580034872400.dkr.ecr.us-east-1.amazonaws.com
    sleep 5

    # Install k3s
    curl -sfL https://get.k3s.io | sh -
    sleep 30

    # Wait for K3s API server to be ready
    echo "Waiting for K3s API server to be ready..."
    RETRIES=30
    until sudo k3s kubectl get nodes &>/dev/null; do
      echo "K3s server not yet ready, waiting..."
      sleep 10
      RETRIES=$((RETRIES-1))
      if [ $RETRIES -le 0 ]; then
        echo "K3s server failed to start, exiting."
        exit 1
      fi
    done
    echo "K3s API server is ready!"

    # Check Node Status
    sudo k3s kubectl get nodes
    sudo k3s kubectl get pods -A

    # Apply Kubernetes configurations
    sudo k3s kubectl apply -f /home/ubuntu/k8s-app-deployment.yml --validate=false
    sudo k3s kubectl apply -f /home/ubuntu/k8s-app-service.yml --validate=false
    sleep 5

    echo "User data script completed."
  EOF

  tags = {
    Name = "k8s-app-ec2"
  }
}

resource "aws_security_group" "k8s_app_sg" {
  name        = "k8s-app-sg"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 30000
    to_port     = 30000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

output "ec2_public_ip" {
  value = aws_instance.k8s_app_ec2.public_ip
  description = "Public IP address of the Kubernetes EC2 instance"
}
