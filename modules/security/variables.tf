variable "project" {
  description = "Nombre del proyecto"
  type        = string
}

variable "env" {
  description = "Ambiente de despliegue"
  type        = string
}

variable "vpc_id" {
  description = "ID de la VPC donde se crean los Security Groups"
  type        = string
}