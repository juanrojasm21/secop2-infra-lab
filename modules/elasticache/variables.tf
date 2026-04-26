variable "project" {
  description = "Nombre del proyecto"
  type        = string
}

variable "env" {
  description = "Ambiente de despliegue"
  type        = string
}

variable "cache_sg_id" {
  description = "ID del Security Group de ElastiCache"
  type        = string
}

variable "subnet_ids" {
  description = "IDs de las subredes privadas de aplicación"
  type        = list(string)
}