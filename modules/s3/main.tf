# Crea el bucket S3 para documentos contractuales de SECOP II.
#
# NOTA: El bucket del estado de Terraform (secop2-dev-tfstate)
# y la tabla DynamoDB se crean manualmente con scripts/bootstrap.sh
# ANTES de ejecutar terraform init. No se gestionan aquí.

# ── Bucket de documentos contractuales ────────────────────────────────────
resource "aws_s3_bucket" "documents" {
  bucket        = "${var.project}-${var.env}-documents"
  force_destroy = true

  tags = {
    Name        = "${var.project}-${var.env}-documents"
    Environment = var.env
    Project     = var.project
  }
}

# Bloquea todo acceso público
resource "aws_s3_bucket_public_access_block" "documents" {
  bucket = aws_s3_bucket.documents.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Cifrado en reposo
resource "aws_s3_bucket_server_side_encryption_configuration" "documents" {
  bucket = aws_s3_bucket.documents.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}
