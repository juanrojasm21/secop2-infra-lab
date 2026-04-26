#!/bin/bash
# ─────────────────────────────────────────────────────────────────────────
# bootstrap.sh — Ejecutar UNA SOLA VEZ antes de terraform init
#
# Uso:
#   chmod +x scripts/bootstrap.sh
#   ./scripts/bootstrap.sh
# ─────────────────────────────────────────────────────────────────────────

set -e

PROJECT="secop2"
ENV="dev"
REGION="us-east-1"
BUCKET="${PROJECT}-${ENV}-tfstate"
TABLE="${PROJECT}-${ENV}-tfstate-lock"

echo "=== PASO 1: Creando bucket S3 para estado de Terraform ==="
aws s3api create-bucket \
  --bucket "$BUCKET" \
  --region "$REGION"

echo "=== PASO 2: Activando versionado en el bucket ==="
aws s3api put-bucket-versioning \
  --bucket "$BUCKET" \
  --versioning-configuration Status=Enabled

echo "=== PASO 3: Creando tabla DynamoDB para bloqueo de estado ==="
aws dynamodb create-table \
  --table-name "$TABLE" \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region "$REGION"

echo ""
echo "=== Bootstrap completado. Sigue estos pasos en orden ==="
echo ""
echo "─── 1. DESPLIEGUE ───────────────────────────────────────────────────"
echo "  terraform init"
echo "  terraform apply -var-file=dev.tfvars -var='db_password=TuPassword'"
echo ""
echo "─── 2. VERIFICAR EL CLÚSTER ─────────────────────────────────────────"
echo "  aws eks update-kubeconfig --region us-east-1 --name secop2-dev-cluster"
echo "  kubectl get nodes"
echo "  kubectl get pods -A"
echo ""
echo "─── 3. TOMAR EVIDENCIAS (screenshots) ───────────────────────────────"
echo "  Consola AWS → EKS → Clusters → secop2-dev-cluster"
echo "  Consola AWS → EC2 → Instances (nodos del clúster)"
echo "  Consola AWS → RDS → Databases → secop2-dev-db"
echo "  Consola AWS → S3 → secop2-dev-documents"
echo "  Consola AWS → VPC → Your VPCs → secop2-dev-vpc"
echo "  Consola AWS → EC2 → Load Balancers → secop2-dev-alb"
echo "  Terminal → kubectl get nodes"
echo "  Terminal → kubectl get pods -A"
echo "  Terminal → terraform output"
echo ""
echo "─── 4. DESTRUIR (solo después de tomar todas las evidencias) ────────"
echo "  terraform destroy -var-file=dev.tfvars -var='db_password=TuPassword'"
echo ""
echo "─── 5. LIMPIEZA TOTAL (opcional) ────────────────────────────────────"
echo "  aws s3 rm s3://$BUCKET --recursive"
echo "  aws s3api delete-bucket --bucket $BUCKET --region $REGION"
echo "  aws dynamodb delete-table --table-name $TABLE --region $REGION"