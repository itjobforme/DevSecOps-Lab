output "eks_cluster_name" {
  value = module.eks_cluster.cluster_id
}

output "eks_cluster_endpoint" {
  value = module.eks_cluster.cluster_endpoint
}

output "eks_cluster_security_group_id" {
  value = module.eks_cluster.cluster_security_group_id
}

