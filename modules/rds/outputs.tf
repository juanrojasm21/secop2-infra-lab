output "db_endpoint" {
  description = "Endpoint de conexión a la base de datos"
  value       = aws_db_instance.main.endpoint
  sensitive   = true
}

output "db_name" {
  description = "Nombre de la base de datos"
  value       = aws_db_instance.main.db_name
}

output "db_port" {
  description = "Puerto de conexión"
  value       = aws_db_instance.main.port
}