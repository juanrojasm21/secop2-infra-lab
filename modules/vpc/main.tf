# Crea la red principal del proyecto.
# Todo lo que se despliega en AWS vive dentro de esta VPC.
# Las subredes públicas tienen salida directa a internet.
# Las subredes privadas solo salen a través del NAT Gateway.

# ── VPC principal ─────────────────────────────────────────────────────────
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true  # Requerido para que EKS resuelva nombres internos
  enable_dns_support   = true

  tags = {
    Name        = "${var.project}-${var.env}-vpc"
    Environment = var.env
    Project     = var.project
  }
}

# ── Zonas de disponibilidad ───────────────────────────────────────────────
# Obtiene las zonas disponibles en la región automáticamente.
# En us-east-1 hay 6 zonas — usamos las primeras 2 para el laboratorio.
data "aws_availability_zones" "available" {
  state = "available"
}

# ── Subredes públicas (ALB, NAT Gateway) ──────────────────────────────────
resource "aws_subnet" "public" {
  count             = 2
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index + 1)
  availability_zone = data.aws_availability_zones.available.names[count.index]

  # Los recursos en subred pública reciben IP pública automáticamente
  map_public_ip_on_launch = true

  tags = {
    Name                     = "${var.project}-${var.env}-public-${count.index + 1}"
    Environment              = var.env
    Project                  = var.project
    # EKS necesita esta etiqueta para descubrir subredes públicas
    "kubernetes.io/role/elb" = "1"
  }
}

# ── Subredes privadas de aplicación (EKS) ─────────────────────────────────
resource "aws_subnet" "private_app" {
  count             = 2
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index + 10)
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name                              = "${var.project}-${var.env}-private-app-${count.index + 1}"
    Environment                       = var.env
    Project                           = var.project
    # EKS necesita esta etiqueta para descubrir subredes privadas
    "kubernetes.io/role/internal-elb" = "1"
  }
}

# ── Subredes privadas de datos (RDS, ElastiCache) ─────────────────────────
resource "aws_subnet" "private_data" {
  count             = 2
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index + 20)
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name        = "${var.project}-${var.env}-private-data-${count.index + 1}"
    Environment = var.env
    Project     = var.project
  }
}

# ── Internet Gateway ───────────────────────────────────────────────────────
# Conecta la VPC con internet.
# Sin este componente nada en la VPC puede salir ni entrar de internet.
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name        = "${var.project}-${var.env}-igw"
    Environment = var.env
    Project     = var.project
  }
}

# ── Tabla de rutas pública ─────────────────────────────────────────────────
# Dirige todo el tráfico saliente de subredes públicas al Internet Gateway.
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name        = "${var.project}-${var.env}-rt-public"
    Environment = var.env
    Project     = var.project
  }
}

# Asocia la tabla de rutas pública a cada subred pública
resource "aws_route_table_association" "public" {
  count          = 2
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# ── Tabla de rutas privada ─────────────────────────────────────────────────
# Las subredes privadas necesitan su propia tabla de rutas.
# El tráfico saliente va al NAT Gateway (creado en el módulo nat/).
# Si NAT está desactivado, las subredes privadas no tienen salida a internet.
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name        = "${var.project}-${var.env}-rt-private"
    Environment = var.env
    Project     = var.project
  }
}

# Asocia la tabla de rutas privada a cada subred de aplicación
resource "aws_route_table_association" "private_app" {
  count          = 2
  subnet_id      = aws_subnet.private_app[count.index].id
  route_table_id = aws_route_table.private.id
}

# Asocia la tabla de rutas privada a cada subred de datos
resource "aws_route_table_association" "private_data" {
  count          = 2
  subnet_id      = aws_subnet.private_data[count.index].id
  route_table_id = aws_route_table.private.id
}