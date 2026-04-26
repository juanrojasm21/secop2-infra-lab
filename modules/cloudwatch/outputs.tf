output "eks_log_group" {
  description = "Nombre del grupo de logs de EKS"
  value       = aws_cloudwatch_log_group.eks.name
}

output "lambda_log_group" {
  description = "Nombre del grupo de logs de Lambda"
  value       = aws_cloudwatch_log_group.lambda.name
}

output "alb_log_group" {
  description = "Nombre del grupo de logs del ALB"
  value       = aws_cloudwatch_log_group.alb.name
}