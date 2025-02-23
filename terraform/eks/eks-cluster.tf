module "eks_cluster" {
  source          = "terraform-aws-modules/eks/aws"
  cluster_name    = var.cluster_name
  cluster_version = "1.26"
  subnets         = module.eks_vpc.private_subnets
  vpc_id          = module.eks_vpc.vpc_id

  node_groups = {
    eks_nodes = {
      desired_capacity = 2
      max_capacity     = 3
      min_capacity     = 1

      instance_type = "t2.micro"

      key_name = "my-ec2-key-pair"
    }
  }

  tags = {
    Name = "devsecops-eks-cluster"
  }
}
