output "alb_arn" {
  description = "ARN del Load Balancer"
  value       = aws_lb.main.arn
}

output "alb_dns_name" {
  description = "URL del Load Balancer para acceder a la plataforma"
  value       = aws_lb.main.dns_name
}

output "target_group_arn" {
  description = "ARN del Target Group — lo usa EKS para registrar los pods"
  value       = aws_lb_target_group.main.arn
}