# Declaración de todas las variables del proyecto.
# Los valores concretos van en dev.tfvars y prod.tfvars.

# ── Generales ─────────────────────────────────────────────────────────────

variable "project" {
  description = "Nombre del proyecto. Se usa como prefijo en todos los recursos"
  type        = string
  default     = "secop2"
}

variable "env" {
  description = "Ambiente de despliegue"
  type        = string
  validation {
    condition     = contains(["dev", "prod"], var.env)
    error_message = "El ambiente debe ser dev o prod."
  }
}

variable "region" {
  description = "Región AWS del despliegue"
  type        = string
  default     = "us-east-1"
}

# ── Red ───────────────────────────────────────────────────────────────────

variable "vpc_cidr" {
  description = "Bloque CIDR de la VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "enable_nat_gateway" {
  description = "Activa el NAT Gateway. Requerido para EKS"
  type        = bool
  default     = true
}

# ── EKS ───────────────────────────────────────────────────────────────────

variable "eks_node_type" {
  description = "Tipo de instancia para los nodos de EKS"
  type        = string
  default     = "t3.medium"
}

variable "eks_node_count" {
  description = "Número de nodos del clúster EKS"
  type        = number
  default     = 2
}

variable "eks_node_min" {
  description = "Número mínimo de nodos (autoescalado)"
  type        = number
  default     = 1
}

variable "eks_node_max" {
  description = "Número máximo de nodos (autoescalado)"
  type        = number
  default     = 4
}

# ── Base de datos ─────────────────────────────────────────────────────────

variable "db_instance_class" {
  description = "Tipo de instancia RDS"
  type        = string
  default     = "db.t3.micro"
}

variable "multi_az" {
  description = "Réplica en múltiples zonas de disponibilidad"
  type        = bool
  default     = false
}

variable "db_name" {
  description = "Nombre de la base de datos"
  type        = string
  default     = "secop2"
}

variable "db_username" {
  description = "Usuario administrador de la base de datos"
  type        = string
  default     = "secop2admin"
}

variable "db_password" {
  description = "Contraseña del administrador. Nunca va en el código"
  type        = string
  sensitive   = true
}

# ── Servicios opcionales ──────────────────────────────────────────────────

variable "enable_elasticache" {
  description = "Activa ElastiCache Redis"
  type        = bool
  default     = false
}

variable "enable_ses_sns" {
  description = "Activa SES y SNS para notificaciones"
  type        = bool
  default     = false
}