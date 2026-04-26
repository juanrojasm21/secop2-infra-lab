variable "project" {
  description = "Nombre del proyecto"
  type        = string
}

variable "env" {
  description = "Ambiente de despliegue"
  type        = string
}

variable "lambda_arn" {
  description = "ARN de la Lambda que API Gateway debe invocar"
  type        = string
}

variable "lambda_name" {
  description = "Nombre de la función Lambda"
  type        = string
}