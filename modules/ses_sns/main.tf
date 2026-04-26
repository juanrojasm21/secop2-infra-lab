# Configura el servicio de notificaciones para SECOP II.
# SES envía correos a entidades y proveedores.
# SNS actúa como bus de eventos para los hitos del proceso.
# Desactivado en dev con enable_ses_sns = false.

# ── SNS Topic para notificaciones ─────────────────────────────────────────
# Canal de mensajería donde los microservicios publican eventos.
# Por ejemplo: "oferta recibida", "contrato adjudicado".
resource "aws_sns_topic" "notifications" {
  name = "${var.project}-${var.env}-notifications"

  tags = {
    Name        = "${var.project}-${var.env}-notifications"
    Environment = var.env
    Project     = var.project
  }
}

# ── SES — Identidad de correo ──────────────────────────────────────────────
# Registra el dominio desde el que se envían los correos.
# En prod se verificaría el dominio real de Colombia Compra Eficiente.
resource "aws_ses_email_identity" "main" {
  email = var.notification_email
}

# ── Suscripción de correo al topic SNS ────────────────────────────────────
# Conecta SNS con SES para que los eventos disparen correos.
resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.notifications.arn
  protocol  = "email"
  endpoint  = var.notification_email
}