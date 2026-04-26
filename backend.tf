# El estado remoto guarda qué recursos existen en AWS.
# Sin este archivo cada ingeniero tendría su propio estado
# local y Terraform no sabría qué ya está creado.
#
# IMPORTANTE: el bucket S3 y la tabla DynamoDB deben crearse
# manualmente UNA SOLA VEZ antes de ejecutar terraform init.
# Ver scripts/bootstrap.sh para los comandos.

terraform {
  backend "s3" {
    bucket       = "secop2-dev-tfstate"
    key          = "dev/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
  }
}
