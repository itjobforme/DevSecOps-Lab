# Security Group for EKS Nodes
resource "aws_security_group" "eks_node_sg" {
  name   = "devsecops-eks-node-sg"
  vpc_id = aws_vpc.devsecops_eks_vpc.id
  description = "Security group for EKS worker nodes"

  # Allow HTTPS traffic to nodes
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow HTTPS traffic to nodes"
  }

  # Allow SSH access from specific IP
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["173.216.28.115/32"]
    description = "Allow SSH access from admin IP"
  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = {
    Name = "devsecops-eks-node-sg"
  }
}

# Security Group for ALB
resource "aws_security_group" "alb_sg" {
  name   = "devsecops-alb-sg"
  vpc_id = aws_vpc.devsecops_eks_vpc.id
  description = "Allow inbound traffic to ALB"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow HTTP traffic from anywhere"
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow HTTPS traffic from anywhere"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = {
    Name = "devsecops-alb-sg"
  }
}

# Allow ALB to access EKS nodes on NodePort range
resource "aws_security_group_rule" "allow_alb_to_nodeport" {
  type                     = "ingress"
  from_port                = 30000
  to_port                  = 32767
  protocol                 = "tcp"
  security_group_id        = aws_security_group.eks_node_sg.id
  source_security_group_id = aws_security_group.alb_sg.id
  description              = "Allow ALB to access EKS nodes on NodePort range"
}

# Allow EKS nodes to send traffic to ALB by updating the ALB security group instead of using 'destination_security_group_id'
resource "aws_security_group_rule" "allow_node_to_alb" {
  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  security_group_id        = aws_security_group.alb_sg.id
  source_security_group_id = aws_security_group.eks_node_sg.id
  description              = "Allow EKS nodes to send traffic to ALB"
}
