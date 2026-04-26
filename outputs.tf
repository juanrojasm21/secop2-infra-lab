output "alb_url" {
  description = "URL del Load Balancer — punto de entrada a la plataforma"
  value       = module.alb.alb_dns_name
}

output "eks_cluster_name" {
  description = "Nombre del clúster EKS"
  value       = module.eks.cluster_name
}

output "eks_cluster_endpoint" {
  description = "Endpoint del clúster EKS para conectar kubectl"
  value       = module.eks.cluster_endpoint
}

output "rds_endpoint" {
  description = "Endpoint de conexión a la base de datos"
  value       = module.rds.db_endpoint
  sensitive   = true
}

output "s3_bucket_name" {
  description = "Nombre del bucket S3 para documentos contractuales"
  value       = module.s3.bucket_name
}

output "vpc_id" {
  description = "ID de la VPC creada"
  value       = module.vpc.vpc_id
}