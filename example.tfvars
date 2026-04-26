project            = "secop2"
env                = "dev"
region             = "us-east-1"

# Red
vpc_cidr           = "10.0.0.0/16"
enable_nat_gateway = true

# EKS
eks_node_type      = "t3.medium"
eks_node_count     = 2
eks_node_min       = 1
eks_node_max       = 4

# Base de datos
db_instance_class  = "db.t3.micro"
multi_az           = false
db_name            = "secop2"
db_username        = "secop2admin"
# db_password se pasa por línea de comandos:
# -var="db_password=TuPassword"

# Servicios opcionales — desactivados en prueba
enable_elasticache = false
enable_ses_sns     = false
