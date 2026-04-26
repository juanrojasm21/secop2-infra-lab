variable "project" {
  description = "Nombre del proyecto"
  type        = string
}

variable "env" {
  description = "Ambiente de despliegue"
  type        = string
}

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
}

variable "db_username" {
  description = "Usuario administrador"
  type        = string
}

variable "db_password" {
  description = "Contraseña del administrador"
  type        = string
  sensitive   = true
}

variable "db_sg_id" {
  description = "ID del Security Group de RDS"
  type        = string
}

variable "subnet_ids" {
  description = "IDs de las subredes privadas de datos"
  type        = list(string)
}