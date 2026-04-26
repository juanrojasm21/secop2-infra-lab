# Crea la base de datos PostgreSQL para SECOP II.
# En dev despliega una instancia db.t3.micro en una sola zona.
# En prod se reemplaza por Aurora PostgreSQL Multi-AZ.

# ── Subnet Group ──────────────────────────────────────────────────────────
# Define en qué subredes puede vivir la base de datos.
# RDS siempre necesita al menos dos subredes en zonas distintas
# aunque en dev solo use una.
resource "aws_db_subnet_group" "main" {
  name       = "${var.project}-${var.env}-db-subnet-group"
  subnet_ids = var.subnet_ids

  tags = {
    Name        = "${var.project}-${var.env}-db-subnet-group"
    Environment = var.env
    Project     = var.project
  }
}

# ── Base de datos RDS PostgreSQL ──────────────────────────────────────────
resource "aws_db_instance" "main" {
  identifier     = "${var.project}-${var.env}-db"
  engine         = "postgres"
  engine_version = "15.12"

  instance_class        = var.db_instance_class  # db.t3.micro en dev
  allocated_storage     = 20                      # GB mínimos en Free Tier
  max_allocated_storage = 100                     # Autoescala hasta 100 GB

  db_name  = var.db_name
  username = var.db_username
  password = var.db_password

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [var.db_sg_id]

  multi_az            = var.multi_az      # false en dev, true en prod
  publicly_accessible = false             # Nunca accesible desde internet
  skip_final_snapshot = true              # En dev no necesitamos snapshot al destruir

  # Backups automáticos — mínimo para el laboratorio
  backup_retention_period = 1
  backup_window           = "03:00-04:00"

  # Cifrado en reposo
  storage_encrypted = true

  tags = {
    Name        = "${var.project}-${var.env}-db"
    Environment = var.env
    Project     = var.project
  }
}