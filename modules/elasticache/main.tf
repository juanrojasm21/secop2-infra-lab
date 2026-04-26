# Crea el clúster de Redis para caché de sesiones y consultas frecuentes.
# Desactivado en dev con enable_elasticache = false.
# En prod reduce la carga sobre RDS cachando consultas repetidas.

# ── Subnet Group ──────────────────────────────────────────────────────────
# Define en qué subredes puede vivir ElastiCache.
resource "aws_elasticache_subnet_group" "main" {
  name       = "${var.project}-${var.env}-cache-subnet-group"
  subnet_ids = var.subnet_ids

  tags = {
    Name        = "${var.project}-${var.env}-cache-subnet-group"
    Environment = var.env
    Project     = var.project
  }
}

# ── Clúster Redis ─────────────────────────────────────────────────────────
resource "aws_elasticache_cluster" "main" {
  cluster_id           = "${var.project}-${var.env}-redis"
  engine               = "redis"
  node_type            = "cache.t3.micro"  # Mínimo disponible
  num_cache_nodes      = 1
  parameter_group_name = "default.redis7"
  port                 = 6379
  subnet_group_name    = aws_elasticache_subnet_group.main.name
  security_group_ids   = [var.cache_sg_id]

  tags = {
    Name        = "${var.project}-${var.env}-redis"
    Environment = var.env
    Project     = var.project
  }
}