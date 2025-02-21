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

echo "=== Configuring EBS Volume ==="

# Format the EBS volume only if not already formatted
if ! lsblk | grep -q "xvdf"; then
    echo "Formatting EBS volume..."
    sudo mkfs -t ext4 /dev/xvdf
fi

# Create the mount point directory
echo "Creating mount point for EBS volume..."
sudo mkdir -p /opt/devsecops-blog/data

# Mount the volume
echo "Mounting EBS volume..."
sudo mount /dev/xvdf /opt/devsecops-blog/data

# Ensure the volume mounts on reboot
echo "Updating /etc/fstab for EBS volume..."
echo '/dev/xvdf /opt/devsecops-blog/data ext4 defaults,nofail 0 2' | sudo tee -a /etc/fstab

# Set appropriate permissions
echo "Setting permissions for mounted volume..."
sudo chown -R ubuntu:ubuntu /opt/devsecops-blog/data
sudo chmod -R 755 /opt/devsecops-blog/data

# Pull and run the Docker container with persistent storage
echo "Pulling latest Docker image..."
sudo docker login -u "${DOCKER_USERNAME}" -p "${DOCKER_PASSWORD}"
sudo docker pull itjobforme/devsecops-lab:latest

echo "Running Docker container with persistent storage..."
sudo docker stop devsecops-blog || true
sudo docker rm devsecops-blog || true
sudo docker run -d -p 80:80 --restart unless-stopped --name devsecops-blog \
  -v /opt/devsecops-blog/data:/app/instance \
  -e FLASK_SECRET_KEY="${FLASK_SECRET_KEY}" \
  itjobforme/devsecops-lab:latest

echo "=== User Data Script Completed Successfully ==="
