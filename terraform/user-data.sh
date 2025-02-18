#!/bin/bash
set -euxo pipefail  # Enable strict error handling and debugging

# Redirect all output to a log file
exec > >(tee /var/log/user-data.log | logger -t user-data) 2>&1

echo "=== Starting User Data Script ==="

# Update and install required packages
echo "Updating packages..."
sudo apt update -y
sudo apt upgrade -y

echo "Installing required packages..."
sudo apt install -y docker.io python3 python3-pip

# Enable and start Docker
echo "Starting Docker service..."
sudo systemctl enable docker
sudo systemctl start docker
sudo usermod -aG docker ubuntu

# Wait to ensure Docker is up
sleep 10

# Check if the SSM Agent is already installed via Snap
if snap list | grep -q amazon-ssm-agent; then
    echo "SSM Agent is already installed via Snap."
else
    echo "Installing AWS SSM Agent..."
    sudo snap install amazon-ssm-agent --classic
fi

# Ensure SSM Agent is started
echo "Starting AWS SSM Agent..."
sudo systemctl restart snap.amazon-ssm-agent.amazon-ssm-agent.service || true

# Wait to ensure SSM is up
sleep 10

# Pull and run the Docker container
echo "Pulling latest Docker image..."
sudo docker pull itjobforme/devsecops-lab:latest

echo "Running Docker container..."
sudo docker run -d -p 80:80 --restart unless-stopped --name devsecops-blog itjobforme/devsecops-lab:latest

echo "=== User Data Script Completed Successfully ==="
