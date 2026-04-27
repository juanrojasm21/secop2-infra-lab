# Crea el clúster EKS y el grupo de nodos donde corren
# los microservicios de SECOP II como contenedores.
#
# El plano de control (control plane) lo gestiona AWS.
# Los nodos son instancias EC2 t3.medium que se unen al clúster.

# ── Clúster EKS ───────────────────────────────────────────────────────────
resource "aws_eks_cluster" "main" {
  name     = "${var.project}-${var.env}-cluster"
  role_arn = var.eks_cluster_role_arn
  version  = "1.32"  # Versión estable de Kubernetes en AWS

  vpc_config {
    subnet_ids              = var.private_subnet_ids
    security_group_ids      = [var.eks_sg_id]
    endpoint_private_access = true   # Los nodos se comunican internamente
    endpoint_public_access  = true   # Permite conectar kubectl desde local
  }

  tags = {
    Name        = "${var.project}-${var.env}-cluster"
    Environment = var.env
    Project     = var.project
  }

}

# ── Grupo de nodos ────────────────────────────────────────────────────────
# Los nodos son las instancias EC2 donde corren los contenedores.
# El Cluster Autoscaler los escala entre min y max según la demanda.
resource "aws_eks_node_group" "main" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "${var.project}-${var.env}-nodes"
  node_role_arn   = var.eks_node_role_arn
  subnet_ids      = var.private_subnet_ids  # Nodos en subredes privadas

  # Tipo y cantidad de instancias
  instance_types = [var.eks_node_type]

  scaling_config {
    desired_size = var.eks_node_count  # Nodos al arrancar
    min_size     = var.eks_node_min    # Mínimo con poca carga
    max_size     = var.eks_node_max    # Máximo en picos
  }

  # Actualización gradual — reemplaza un nodo a la vez
  update_config {
    max_unavailable = 1
  }

  tags = {
    Name        = "${var.project}-${var.env}-nodes"
    Environment = var.env
    Project     = var.project
  }
}