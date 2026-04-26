# El NAT Gateway permite que los recursos en subredes privadas
# (como los nodos de EKS) salgan a internet para descargar
# imágenes de contenedores y comunicarse con APIs externas,
# sin que esos recursos sean accesibles desde internet.
#
# Se crea solo si enable_nat_gateway = true en las variables.
# En el laboratorio está activado porque EKS lo requiere.

# ── IP pública fija para el NAT Gateway ───────────────────────────────────
# El NAT Gateway necesita una IP pública estática (Elastic IP)
# para que el tráfico saliente siempre venga de la misma dirección.
resource "aws_eip" "nat" {
  count  = var.enable_nat_gateway ? 1 : 0
  domain = "vpc"

  tags = {
    Name        = "${var.project}-${var.env}-eip-nat"
    Environment = var.env
    Project     = var.project
  }
}

# ── NAT Gateway ───────────────────────────────────────────────────────────
# Se ubica en la subred PÚBLICA porque necesita acceso a internet,
# pero sirve de salida para las subredes PRIVADAS.
resource "aws_nat_gateway" "main" {
  count         = var.enable_nat_gateway ? 1 : 0
  allocation_id = aws_eip.nat[0].id
  subnet_id     = var.public_subnet_ids[0]  # Siempre en la primera subred pública

  tags = {
    Name        = "${var.project}-${var.env}-nat"
    Environment = var.env
    Project     = var.project
  }
}

# ── Ruta privada hacia el NAT Gateway ─────────────────────────────────────
# Agrega una ruta en la tabla de rutas privada para que
# todo el tráfico saliente de subredes privadas pase por el NAT.
resource "aws_route" "private_nat" {
  count                  = var.enable_nat_gateway ? 1 : 0
  route_table_id         = var.private_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.main[0].id
}