variable "project" {
  description = "Nombre del proyecto"
  type        = string
}

variable "env" {
  description = "Ambiente de despliegue"
  type        = string
}

variable "vpc_id" {
  description = "ID de la VPC"
  type        = string
}

variable "public_subnet_ids" {
  description = "IDs de las subredes públicas donde vive el ALB"
  type        = list(string)
}

variable "alb_sg_id" {
  description = "ID del Security Group del ALB"
  type        = string
}