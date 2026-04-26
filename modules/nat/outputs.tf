output "nat_gateway_id" {
  description = "ID del NAT Gateway"
  value       = var.enable_nat_gateway ? aws_nat_gateway.main[0].id : null
}

output "nat_eip" {
  description = "IP pública asignada al NAT Gateway"
  value       = var.enable_nat_gateway ? aws_eip.nat[0].public_ip : null
}