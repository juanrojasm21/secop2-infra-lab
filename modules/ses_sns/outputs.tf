output "sns_topic_arn" {
  description = "ARN del topic SNS de notificaciones"
  value       = aws_sns_topic.notifications.arn
}

output "ses_identity" {
  description = "Identidad de correo registrada en SES"
  value       = aws_ses_email_identity.main.email
}