output "lambda_function_name" {
  description = "Nombre de la función Lambda"
  value       = aws_lambda_function.integrations.function_name
}

output "lambda_function_arn" {
  description = "ARN de la función Lambda"
  value       = aws_lambda_function.integrations.arn
}

output "lambda_role_arn" {
  description = "ARN del rol IAM de Lambda"
  value       = aws_iam_role.lambda.arn
}