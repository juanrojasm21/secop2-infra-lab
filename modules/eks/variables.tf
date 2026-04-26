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

variable "private_subnet_ids" {
  description = "IDs de las subredes privadas donde viven los nodos"
  type        = list(string)
}

variable "eks_sg_id" {
  description = "ID del Security Group de EKS"
  type        = string
}

variable "eks_cluster_role_arn" {
  description = "ARN del rol IAM del clúster"
  type        = string
}

variable "eks_node_role_arn" {
  description = "ARN del rol IAM de los nodos"
  type        = string
}

variable "eks_node_type" {
  description = "Tipo de instancia EC2 para los nodos"
  type        = string
  default     = "t3.medium"
}

variable "eks_node_count" {
  description = "Número de nodos al arrancar"
  type        = number
  default     = 2
}

variable "eks_node_min" {
  description = "Número mínimo de nodos"
  type        = number
  default     = 1
}

variable "eks_node_max" {
  description = "Número máximo de nodos"
  type        = number
  default     = 4
}