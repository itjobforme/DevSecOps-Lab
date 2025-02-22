#!/bin/bash
set -euxo pipefail

# Redirect all output to a log file
exec > >(tee /var/log/user-data.log | logger -t user-data) 2>&1

echo "=== Starting User Data Script ==="

# Load environment variables if available
if [ -f /etc/environment ]; then
    source /etc/environment
fi

# Update required packages including AWS CLI
sudo apt update -y
sudo apt upgrade -y
sudo apt install -y docker.io python3 python3-pip awscli

# Enable and start Docker
echo "=== Starting Docker Service ==="
sudo systemctl enable docker
sudo systemctl start docker
sudo usermod -aG docker ubuntu
newgrp docker
sudo systemctl status docker

# Install and start SSM agent
echo "=== Installing and Starting SSM Agent ==="
if ! snap list | grep -q amazon-ssm-agent; then
    sudo snap install amazon-ssm-agent --classic
fi
sudo systemctl enable snap.amazon-ssm-agent.amazon-ssm-agent.service
sudo systemctl start snap.amazon-ssm-agent.amazon-ssm-agent.service
sudo systemctl status snap.amazon-ssm-agent.amazon-ssm-agent.service

echo "=== Fetching Secrets from SSM Parameter Store ==="

# Set the AWS Region
export AWS_REGION="us-east-1"

# Fetch secrets from SSM Parameter Store
DOCKER_USERNAME=$(aws ssm get-parameter --name DOCKER_USERNAME --with-decryption --query Parameter.Value --output text --region "$AWS_REGION")
DOCKER_PASSWORD=$(aws ssm get-parameter --name DOCKER_PASSWORD --with-decryption --query Parameter.Value --output text --region "$AWS_REGION")
FLASK_SECRET_KEY=$(aws ssm get-parameter --name FLASK_SECRET_KEY --with-decryption --query Parameter.Value --output text --region "$AWS_REGION")

echo "=== Docker login and pulling the new image ==="

# Docker login and pull the new image
echo "$DOCKER_PASSWORD" | sudo docker login -u "$DOCKER_USERNAME" --password-stdin
sudo docker pull itjobforme/devsecops-lab:latest

echo "=== Stopping and removing any existing container ==="

# Stop and remove any existing container
sudo docker stop devsecops-lab || true
sudo docker rm devsecops-lab || true

echo "=== Running the new container ==="

# Run the new container 
sudo docker run -d -p 80:80 --restart unless-stopped --name devsecops-lab \
  -e FLASK_SECRET_KEY="${FLASK_SECRET_KEY}" \
  itjobforme/devsecops-lab:latest

# Check if the container is running
sudo docker ps

echo "=== User Data Script Completed Successfully ==="
