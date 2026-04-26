# Estos IDs los usan los demás módulos para referenciar
# cada Security Group sin duplicar su definición.

output "alb_sg_id" {
  description = "ID del Security Group del ALB"
  value       = aws_security_group.alb.id
}

output "eks_sg_id" {
  description = "ID del Security Group de EKS"
  value       = aws_security_group.eks.id
}

output "rds_sg_id" {
  description = "ID del Security Group de RDS"
  value       = aws_security_group.rds.id
}

output "cache_sg_id" {
  description = "ID del Security Group de ElastiCache"
  value       = aws_security_group.cache.id
}
