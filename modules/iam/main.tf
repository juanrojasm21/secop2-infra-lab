# Solo los dos roles obligatorios para que EKS funcione.
# Sin estos dos roles el clúster no puede arrancar.

# ── Rol del clúster EKS ───────────────────────────────────────────────────
# Permite al plano de control de EKS gestionar recursos
# de AWS en nombre del clúster (nodos, balanceadores, etc.)
resource "aws_iam_role" "eks_cluster" {
  name = "${var.project}-${var.env}-eks-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "eks.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = {
    Name        = "${var.project}-${var.env}-eks-cluster-role"
    Environment = var.env
    Project     = var.project
  }
}

# Política administrada por AWS requerida para el clúster
resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  role       = aws_iam_role.eks_cluster.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

# ── Rol de los nodos EKS ──────────────────────────────────────────────────
# Permite a las instancias EC2 (nodos) unirse al clúster
# y descargar imágenes de contenedores desde ECR.
resource "aws_iam_role" "eks_node" {
  name = "${var.project}-${var.env}-eks-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = {
    Name        = "${var.project}-${var.env}-eks-node-role"
    Environment = var.env
    Project     = var.project
  }
}

# Las tres políticas mínimas que necesitan los nodos
resource "aws_iam_role_policy_attachment" "eks_worker_node_policy" {
  role       = aws_iam_role.eks_node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "eks_cni_policy" {
  role       = aws_iam_role.eks_node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "eks_ecr_policy" {
  role       = aws_iam_role.eks_node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}