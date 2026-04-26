variable "project" {
  description = "Nombre del proyecto"
  type        = string
}

variable "env" {
  description = "Ambiente de despliegue"
  type        = string
}

variable "s3_bucket_name" {
  description = "Nombre del bucket S3 de documentos"
  type        = string
}
