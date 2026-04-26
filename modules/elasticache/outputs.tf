output "cache_endpoint" {
  description = "Endpoint de conexión a Redis"
  value       = aws_elasticache_cluster.main.cache_nodes[0].address
}

output "cache_port" {
  description = "Puerto de Redis"
  value       = aws_elasticache_cluster.main.port
}