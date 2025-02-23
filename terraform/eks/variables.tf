variable "cluster_name" {
  description = "EKS cluster name"
  default     = "devsecops-eks-cluster"
}

variable "region" {
  description = "AWS region"
  default     = "us-east-1"
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  default     = "10.0.0.0/16"
}

variable "private_subnets" {
  description = "Private subnets"
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "public_subnets" {
  description = "Public subnets"
  default     = ["10.0.101.0/24", "10.0.102.0/24"]
}

variable "certificate_arn" {
  description = "ACM certificate ARN for k8s.securingthecloud.org"
}

