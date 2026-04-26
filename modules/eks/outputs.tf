output "cluster_name" {
  description = "Nombre del clúster EKS"
  value       = aws_eks_cluster.main.name
}

output "cluster_endpoint" {
  description = "Endpoint del clúster para conectar kubectl"
  value       = aws_eks_cluster.main.endpoint
}

output "cluster_ca" {
  description = "Certificado de autoridad del clúster"
  value       = aws_eks_cluster.main.certificate_authority[0].data
}