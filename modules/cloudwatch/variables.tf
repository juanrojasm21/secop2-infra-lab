variable "project" {
  description = "Nombre del proyecto"
  type        = string
}

variable "env" {
  description = "Ambiente de despliegue"
  type        = string
}

variable "eks_cluster" {
  description = "Nombre del clúster EKS para las métricas"
  type        = string
}

variable "alb_arn" {
  description = "ARN del ALB para las métricas"
  type        = string
}