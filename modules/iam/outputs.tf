output "eks_cluster_role_arn" {
  description = "ARN del rol del clúster EKS"
  value       = aws_iam_role.eks_cluster.arn
}

output "eks_node_role_arn" {
  description = "ARN del rol de los nodos EKS"
  value       = aws_iam_role.eks_node.arn
}