variable "project" {
  description = "Nombre del proyecto"
  type        = string
}

variable "env" {
  description = "Ambiente de despliegue"
  type        = string
}

variable "notification_email" {
  description = "Correo que recibe las notificaciones del sistema"
  type        = string
  default     = "notificaciones@colombiacompra.gov.co"
}