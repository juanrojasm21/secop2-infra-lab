variable "project" {
  description = "Nombre del proyecto"
  type        = string
}

variable "env" {
  description = "Ambiente de despliegue"
  type        = string
}

variable "enable_nat_gateway" {
  description = "Activa el NAT Gateway"
  type        = bool
  default     = true
}

variable "public_subnet_ids" {
  description = "IDs de las subredes públicas — el NAT vive aquí"
  type        = list(string)
}

variable "private_route_table_id" {
  description = "ID de la tabla de rutas privada — aquí se agrega la ruta al NAT"
  type        = string
}

variable "internet_gateway_id" {
  description = "ID del Internet Gateway — el NAT depende de que exista"
  type        = string
}