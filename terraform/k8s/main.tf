name: Deploy Terraform to EC2 Kubernetes

on:
  push:
    branches:
      - main
    paths:
      - 'k8s-app/**'
      - 'terraform/k8s/**'

jobs:
  deploy:
    runs-on: ubuntu-latest

    permissions:
      id-token: write
      contents: read

    steps:
    - name: Checkout Code
      uses: actions/checkout@v3

    - name: Configure AWS Credentials
      uses: aws-actions/configure-aws-credentials@v2
      with:
        role-to-assume: ${{ secrets.AWS_ROLE_TO_ASSUME }}
        aws-region: us-east-1

    - name: Install Terraform
      uses: hashicorp/setup-terraform@v2
      with:
        terraform_wrapper: false

    - name: Add SSH Key
      run: |
        mkdir -p ~/.ssh
        echo "${{ secrets.DEVSECOPS_SSH_KEY }}" > ~/.ssh/devsecops-key-new.pem
        chmod 600 ~/.ssh/devsecops-key-new.pem
        ssh-keyscan -H k8s-app-ec2 >> ~/.ssh/known_hosts

    - name: Generate Kubeconfig on EC2
      run: |
        INSTANCE_ID=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=k8s-app-ec2" --query "Reservations[*].Instances[*].InstanceId" --output text)
        aws ssm send-command \
          --instance-ids "$INSTANCE_ID" \
          --document-name "AWS-RunShellScript" \
          --parameters 'commands=["mkdir -p ~/.kube && sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config && sudo chown $(id -u):$(id -g) ~/.kube/config"]' \
          --comment "Setup kubeconfig on EC2 instance" \
          --region us-east-1

    - name: Retrieve Kubeconfig from EC2
      run: |
        INSTANCE_IP=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=k8s-app-ec2" --query "Reservations[*].Instances[*].PublicIpAddress" --output text)
        scp -o StrictHostKeyChecking=no -i ~/.ssh/devsecops-key-new.pem ubuntu@$INSTANCE_IP:~/.kube/config ~/.kube/config

    - name: Initialize and Apply Terraform
      run: |
        cd terraform/k8s
        export KUBECONFIG=~/.kube/config
        terraform init
        terraform apply -auto-approve
