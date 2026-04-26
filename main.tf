# Orquesta todos los módulos en orden.
# Cada módulo recibe los outputs de los módulos que necesita.
# Por ejemplo: EKS necesita los IDs de las subredes que creó VPC.

module "vpc" {
  source             = "./modules/vpc"
  project            = var.project
  env                = var.env
  vpc_cidr           = var.vpc_cidr
  enable_nat_gateway = var.enable_nat_gateway
}

module "nat" {
  source                 = "./modules/nat"
  project                = var.project
  env                    = var.env
  enable_nat_gateway     = var.enable_nat_gateway
  public_subnet_ids      = module.vpc.public_subnet_ids
  private_route_table_id = module.vpc.private_route_table_id
  internet_gateway_id    = module.vpc.internet_gateway_id
}

module "security" {
  source  = "./modules/security"
  project = var.project
  env     = var.env
  vpc_id  = module.vpc.vpc_id
}

module "iam" {
  source        = "./modules/iam"
  project       = var.project
  env           = var.env
}

module "s3" {
  source  = "./modules/s3"
  project = var.project
  env     = var.env
}

module "alb" {
  source            = "./modules/alb"
  project           = var.project
  env               = var.env
  vpc_id            = module.vpc.vpc_id
  public_subnet_ids = module.vpc.public_subnet_ids
  alb_sg_id         = module.security.alb_sg_id
}

module "eks" {
  source               = "./modules/eks"
  project              = var.project
  env                  = var.env
  vpc_id               = module.vpc.vpc_id
  private_subnet_ids   = module.vpc.private_app_subnet_ids
  eks_node_type        = var.eks_node_type
  eks_node_count       = var.eks_node_count
  eks_node_min         = var.eks_node_min
  eks_node_max         = var.eks_node_max
  eks_node_role_arn    = module.iam.eks_node_role_arn
  eks_cluster_role_arn = module.iam.eks_cluster_role_arn
  eks_sg_id            = module.security.eks_sg_id
}

module "rds" {
  source            = "./modules/rds"
  project           = var.project
  env               = var.env
  db_instance_class = var.db_instance_class
  multi_az          = var.multi_az
  db_name           = var.db_name
  db_username       = var.db_username
  db_password       = var.db_password
  db_sg_id          = module.security.rds_sg_id
  subnet_ids        = module.vpc.private_data_subnet_ids
}

module "lambda" {
  source         = "./modules/lambda"
  project        = var.project
  env            = var.env
  s3_bucket_name = module.s3.bucket_name
}

module "apigateway" {
  source      = "./modules/apigateway"
  project     = var.project
  env         = var.env
  # Estos dos valores vienen de los outputs que agregamos
  # al módulo Lambda en el Paso 2. Terraform los obtiene
  # automáticamente sin que tengas que escribir el ARN a mano.
  lambda_arn  = module.lambda.lambda_arn
  lambda_name = module.lambda.lambda_name
}


module "cloudwatch" {
  source      = "./modules/cloudwatch"
  project     = var.project
  env         = var.env
  eks_cluster = module.eks.cluster_name
  alb_arn     = module.alb.alb_arn
}

module "elasticache" {
  count          = var.enable_elasticache ? 1 : 0
  source         = "./modules/elasticache"
  project        = var.project
  env            = var.env
  cache_sg_id    = module.security.cache_sg_id
  subnet_ids     = module.vpc.private_app_subnet_ids
}

module "ses_sns" {
  count   = var.enable_ses_sns ? 1 : 0
  source  = "./modules/ses_sns"
  project = var.project
  env     = var.env
}

output "api_url" {
  description = "URL base de la API de SECOP II — úsala para probar los endpoints"
  value       = module.apigateway.api_url
}