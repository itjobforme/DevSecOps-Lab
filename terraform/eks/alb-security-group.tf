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

  # Allow NodePort Range for EKS Nodes
  ingress {
    from_port                = 30000
    to_port                  = 32767
    protocol                 = "tcp"
    security_groups          = [aws_security_group.eks_node_sg.id]
    description              = "Allow traffic from EKS nodes on NodePort range"
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
