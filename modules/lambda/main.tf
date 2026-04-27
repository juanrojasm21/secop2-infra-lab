# Crea las funciones Lambda para integraciones con sistemas
# externos del Estado. Se ejecutan solo cuando se invocan,
# sin servidor dedicado corriendo permanentemente.

# ── Archivo zip de la función ─────────────────────────────────────────────
data "archive_file" "lambda_placeholder" {
  type        = "zip"
  output_path = "${path.module}/lambda_placeholder.zip"

  source {
    content  = file("${path.module}/index.py")
    filename = "index.py"
  }
}


# ── Función Lambda de integraciones ───────────────────────────────────────
# Maneja integraciones con sistemas externos del Estado:
# RUES, SIIF, SIGEP y procesamiento de firma electrónica.
resource "aws_lambda_function" "integrations" {
  function_name    = "${var.project}-${var.env}-integrations"
  role             = aws_iam_role.lambda.arn
  runtime          = "python3.11"
  handler          = "index.handler"
  filename         = data.archive_file.lambda_placeholder.output_path
  source_code_hash = data.archive_file.lambda_placeholder.output_base64sha256

  # Tiempo máximo de ejecución en segundos
  timeout     = 30
  memory_size = 128  # MB mínimos — suficiente para el laboratorio
  publish          = true

  # Variables de entorno que la función puede leer
  environment {
    variables = {
      PROJECT     = var.project
      ENV         = var.env
      S3_BUCKET   = var.s3_bucket_name
    }
  }

  tags = {
    Name        = "${var.project}-${var.env}-integrations"
    Environment = var.env
    Project     = var.project
  }
}

# ── Permisos para que Lambda escriba logs en CloudWatch ───────────────────
resource "aws_iam_role" "lambda" {
  name = "${var.project}-${var.env}-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = {
    Name        = "${var.project}-${var.env}-lambda-role"
    Environment = var.env
    Project     = var.project
  }
}

resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "lambda_s3" {
  name = "${var.project}-${var.env}-lambda-s3-policy"
  role = aws_iam_role.lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = [
        "s3:PutObject",
        "s3:GetObject"
      ]
      # Solo permite acceso a la carpeta "contratos/" del bucket,
      # no a todo el bucket — principio de mínimo privilegio
      Resource = "arn:aws:s3:::${var.project}-${var.env}-documents/contratos/*"
    }]
  })
}

# ── Cola SQS principal ────────────────────────────────────────────────────
# Esta cola recibe los procesos de contratación validados por la Lambda.
# Actúa como buffer ante los picos de demanda de fin de vigencia fiscal.
resource "aws_sqs_queue" "contratos_dlq" {
  # La DLQ se crea PRIMERO porque la cola principal la referencia.
  # Dead Letter Queue: aquí llegan los mensajes que fallaron
  # más de 3 veces. El equipo los revisa y reprocesa manualmente.
  name                      = "${var.project}-${var.env}-contratos-dlq"
  message_retention_seconds = 1209600  # 14 días — tiempo para investigar el fallo

  tags = {
    Name        = "${var.project}-${var.env}-contratos-dlq"
    Environment = var.env
    Project     = var.project
  }
}

resource "aws_sqs_queue" "contratos" {
  name                       = "${var.project}-${var.env}-contratos"
  
  # Tiempo que SQS "oculta" el mensaje mientras Lambda lo procesa.
  # Si Lambda no termina en 60s, SQS asume que falló y reintenta.
  # Debe ser mayor que el timeout de Lambda (que es 30s).
  visibility_timeout_seconds = 60

  # Cuánto tiempo vive un mensaje en la cola si nadie lo procesa
  message_retention_seconds  = 86400  # 1 día

  # Política de reintentos: después de 3 fallos, el mensaje
  # va a la DLQ en lugar de perderse
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.contratos_dlq.arn
    maxReceiveCount     = 3
  })

  tags = {
    Name        = "${var.project}-${var.env}-contratos"
    Environment = var.env
    Project     = var.project
  }
}

# ── Conectar SQS con Lambda ───────────────────────────────────────────────
# Este recurso le dice a AWS que cuando llegue un mensaje a la cola,
# dispare automáticamente la función Lambda.
# Es el "trigger" event-driven de la arquitectura.
resource "aws_lambda_event_source_mapping" "sqs_trigger" {
  event_source_arn = aws_sqs_queue.contratos.arn
  function_name    = aws_lambda_function.integrations.arn
  
  # Cuántos mensajes procesa Lambda de una vez.
  # Con 1 es más fácil depurar en el laboratorio.
  batch_size       = 1
  
  # Lambda solo se activa cuando hay mensajes en la cola
  enabled          = true
}

# ── Permiso para que Lambda lea de SQS ───────────────────────────────────
# Sin este permiso, el trigger de arriba fallaría con AccessDenied.
# Principio de mínimo privilegio: solo puede leer de ESTA cola específica,
# no de cualquier cola de la cuenta AWS.
resource "aws_iam_role_policy" "lambda_sqs" {
  name = "${var.project}-${var.env}-lambda-sqs-policy"
  role = aws_iam_role.lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "sqs:ReceiveMessage",
        "sqs:DeleteMessage",
        "sqs:GetQueueAttributes"
      ]
      # Solo acceso a esta cola específica, no a toda la cuenta
      Resource = aws_sqs_queue.contratos.arn
    }]
  })
}

resource "aws_lambda_alias" "live" {
  name             = "live"
  function_name    = aws_lambda_function.integrations.function_name
  function_version = aws_lambda_function.integrations.version

  lifecycle {
    ignore_changes = [routing_config]
  }
}

# ── Outputs útiles para el módulo de API Gateway ──────────────────────────
# El módulo de API Gateway va a necesitar saber el ARN y nombre
# de la Lambda para poder invocarla. Los outputs los exponen.
output "lambda_arn" {
  description = "ARN de la función Lambda de integraciones"
  value       = aws_lambda_function.integrations.arn
}

output "lambda_name" {
  description = "Nombre de la función Lambda"
  value       = aws_lambda_function.integrations.function_name
}

output "sqs_queue_url" {
  description = "URL de la cola SQS de contratos"
  value       = aws_sqs_queue.contratos.url
}

output "sqs_dlq_url" {
  description = "URL de la Dead Letter Queue"
  value       = aws_sqs_queue.contratos_dlq.url
}

output "lambda_alias_invoke_arn" {
  description = "ARN del alias live — usado por API Gateway"
  value       = aws_lambda_alias.live.invoke_arn
}