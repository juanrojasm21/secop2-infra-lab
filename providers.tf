# Define el proveedor AWS y la versión mínima de Terraform.
# Las credenciales se leen automáticamente desde las variables
# de entorno AWS_ACCESS_KEY_ID y AWS_SECRET_ACCESS_KEY.

terraform {
  required_version = ">= 1.7.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region
}