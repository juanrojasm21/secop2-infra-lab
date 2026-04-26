# Define los Security Groups de cada capa de la arquitectura.
# Un Security Group es un firewall virtual que controla
# qué tráfico puede entrar y salir de cada recurso.
#
# Regla general: todo lo que no está explícitamente permitido
# está denegado por defecto.

# ── Security Group del ALB ─────────────────────────────────────────────────
# El ALB es el único recurso que acepta tráfico desde internet.
# Solo permite HTTPS (443) entrante desde cualquier IP.
resource "aws_security_group" "alb" {
  name        = "${var.project}-${var.env}-sg-alb"
  description = "Trafico permitido hacia el Load Balancer"
  vpc_id      = var.vpc_id

  # Permite HTTPS desde internet
  ingress {
    description = "HTTPS desde internet"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Permite HTTP solo para redirigir a HTTPS
  ingress {
    description = "HTTP para redireccion a HTTPS"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Permite todo el tráfico saliente
  egress {
    description = "Todo el trafico saliente"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project}-${var.env}-sg-alb"
    Environment = var.env
    Project     = var.project
  }
}

# ── Security Group de EKS ──────────────────────────────────────────────────
# Los nodos de EKS solo aceptan tráfico del ALB.
# Nunca reciben conexiones directas desde internet.
resource "aws_security_group" "eks" {
  name        = "${var.project}-${var.env}-sg-eks"
  description = "Trafico permitido hacia los nodos de EKS"
  vpc_id      = var.vpc_id

  # Permite tráfico del ALB hacia los nodos en cualquier puerto
  ingress {
    description     = "Trafico del ALB hacia los nodos"
    from_port       = 0
    to_port         = 65535
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  # Permite comunicación entre nodos del mismo clúster
  ingress {
    description = "Comunicacion entre nodos del cluster"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
  }

  # Permite todo el tráfico saliente (para descargar imágenes, llamar APIs)
  egress {
    description = "Todo el trafico saliente"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project}-${var.env}-sg-eks"
    Environment = var.env
    Project     = var.project
  }
}

# ── Security Group de RDS ──────────────────────────────────────────────────
# RDS solo acepta conexiones desde los nodos de EKS.
# Nunca es accesible desde internet ni desde el ALB.
resource "aws_security_group" "rds" {
  name        = "${var.project}-${var.env}-sg-rds"
  description = "Trafico permitido hacia RDS"
  vpc_id      = var.vpc_id

  # Solo acepta PostgreSQL (5432) desde los nodos de EKS
  ingress {
    description     = "PostgreSQL desde nodos EKS"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.eks.id]
  }

  # Sin tráfico saliente — la BD no inicia conexiones
  egress {
    description = "Sin salida"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project}-${var.env}-sg-rds"
    Environment = var.env
    Project     = var.project
  }
}

# ── Security Group de ElastiCache ─────────────────────────────────────────
# Redis solo acepta conexiones desde los nodos de EKS.
resource "aws_security_group" "cache" {
  name        = "${var.project}-${var.env}-sg-cache"
  description = "Trafico permitido hacia ElastiCache Redis"
  vpc_id      = var.vpc_id

  # Solo acepta Redis (6379) desde los nodos de EKS
  ingress {
    description     = "Redis desde nodos EKS"
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [aws_security_group.eks.id]
  }

  egress {
    description = "Sin salida"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project}-${var.env}-sg-cache"
    Environment = var.env
    Project     = var.project
  }
}