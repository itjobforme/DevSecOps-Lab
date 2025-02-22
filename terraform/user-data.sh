#!/bin/bash
set -euxo pipefail

# Redirect all output to a log file
exec > >(tee /var/log/user-data.log | logger -t user-data) 2>&1

echo "=== Starting User Data Script ==="

# Update and install required packages
sudo apt update -y
sudo apt upgrade -y
sudo apt install -y docker.io python3 python3-pip

# Enable and start Docker
sudo systemctl enable docker
sudo systemctl start docker
sudo usermod -aG docker ubuntu
sleep 10

# Install and start SSM agent
if ! snap list | grep -q amazon-ssm-agent; then
    sudo snap install amazon-ssm-agent --classic
fi
sudo systemctl restart snap.amazon-ssm-agent.amazon-ssm-agent.service
sleep 10

echo "=== Configuring EBS Volume ==="

# Format the EBS volume only if not already formatted
if ! sudo file -s /dev/xvdf | grep -q 'ext4'; then
    echo "Formatting EBS volume..."
    sudo mkfs.ext4 /dev/xvdf
fi

# Create the mount point directory
sudo mkdir -p /opt/devsecops-blog/data

# Mount the volume
sudo mount /dev/xvdf /opt/devsecops-blog/data

# Ensure the volume mounts on reboot
echo '/dev/xvdf /opt/devsecops-blog/data ext4 defaults,nofail 0 2' | sudo tee -a /etc/fstab

# Set appropriate permissions
sudo chown -R ubuntu:ubuntu /opt/devsecops-blog/data
sudo chmod -R 755 /opt/devsecops-blog/data

# Pull and run the Docker container with persistent storage
sudo docker login -u "${DOCKER_USERNAME}" -p "${DOCKER_PASSWORD}"
sudo docker pull itjobforme/devsecops-lab:latest

sudo docker stop devsecops-blog || true
sudo docker rm devsecops-blog || true

sudo docker run -d -p 80:80 --restart unless-stopped --name devsecops-blog \
  -v /opt/devsecops-blog/data:/app/instance \
  -v /opt/devsecops-blog/logs:/app/logs \
  -e FLASK_SECRET_KEY="${FLASK_SECRET_KEY}" \
  itjobforme/devsecops-lab:latest

echo "=== User Data Script Completed Successfully ==="
