# Estos outputs son los que usan el resto de módulos.
# Por ejemplo: el módulo EKS recibe private_app_subnet_ids
# para saber en qué subredes desplegar los nodos.

output "vpc_id" {
  description = "ID de la VPC"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "IDs de las subredes públicas"
  value       = aws_subnet.public[*].id
}

output "private_app_subnet_ids" {
  description = "IDs de las subredes privadas de aplicación (EKS)"
  value       = aws_subnet.private_app[*].id
}

output "private_data_subnet_ids" {
  description = "IDs de las subredes privadas de datos (RDS)"
  value       = aws_subnet.private_data[*].id
}

output "private_route_table_id" {
  description = "ID de la tabla de rutas privada — la usa el módulo nat/"
  value       = aws_route_table.private.id
}

output "internet_gateway_id" {
  description = "ID del Internet Gateway — lo necesita el módulo nat/"
  value       = aws_internet_gateway.main.id
}