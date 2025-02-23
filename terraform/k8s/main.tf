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

resource "aws_iam_instance_profile" "ec2_ssm_profile" {
  name = "DevSecOpsEC2SSMProfile-k8s-app"
  role = aws_iam_role.ec2_ssm_role.name
}

resource "aws_instance" "k8s_app_ec2" {
  ami           = "ami-09e67e426f25ce0d7" # Ubuntu Server 20.04 LTS
  instance_type = "t2.micro"
  iam_instance_profile = aws_iam_instance_profile.ec2_ssm_profile.name

  security_groups = ["k8s-app-sg"]

  user_data = <<-EOF
    #!/bin/bash
    # Ensure no other apt processes are running
    while sudo fuser /var/lib/dpkg/lock >/dev/null 2>&1; do
       echo "Waiting for other apt processes to finish..."
       sleep 5
    done

    sudo apt-get update -y
    sudo apt-get install -y docker.io unzip

    # Start Docker and add the ubuntu user to the docker group
    sudo systemctl enable docker
    sudo systemctl start docker
    sudo usermod -aG docker ubuntu

    # Install AWS CLI
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip awscliv2.zip
    sudo ./aws/install

    # Login to ECR
    aws ecr get-login-password --region us-east-1 | sudo docker login --username AWS --password-stdin 580034872400.dkr.ecr.us-east-1.amazonaws.com

    # Install k3s (Lightweight Kubernetes)
    curl -sfL https://get.k3s.io | sh -

    # Create Kubernetes deployment
    cat <<EOL > /home/ubuntu/k8s-app-deployment.yaml
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: k8s-app
    spec:
      replicas: 1
      selector:
        matchLabels:
          app: k8s-app
      template:
        metadata:
          labels:
            app: k8s-app
        spec:
          containers:
          - name: k8s-app
            image: 580034872400.dkr.ecr.us-east-1.amazonaws.com/devsecops-k8s-app
            imagePullPolicy: Always
            ports:
            - containerPort: 80
    EOL

    # Create Kubernetes service
    cat <<EOL > /home/ubuntu/k8s-app-service.yaml
    apiVersion: v1
    kind: Service
    metadata:
      name: k8s-app-service
    spec:
      type: NodePort
      selector:
        app: k8s-app
      ports:
      - protocol: TCP
        port: 80
        targetPort: 80
        nodePort: 30000
    EOL

    # Apply Kubernetes configurations
    sudo k3s kubectl apply -f /home/ubuntu/k8s-app-deployment.yaml
    sudo k3s kubectl apply -f /home/ubuntu/k8s-app-service.yaml
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
