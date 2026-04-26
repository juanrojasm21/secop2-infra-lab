# Crea las funciones Lambda para integraciones con sistemas
# externos del Estado. Se ejecutan solo cuando se invocan,
# sin servidor dedicado corriendo permanentemente.

# ── Archivo zip de la función ─────────────────────────────────────────────
data "archive_file" "lambda_placeholder" {
  type        = "zip"
  output_path = "${path.module}/lambda_placeholder.zip"

  source {
    content  = <<EOF
import json
import boto3
import os
import uuid
import logging
from datetime import datetime

# ── Configuración de logs estructurados ──────────────────────────────────
# En vez de print(), usamos logging para que CloudWatch pueda
# filtrar y buscar por nivel (INFO, ERROR, WARNING)
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Cliente S3 — se inicializa fuera del handler para reutilizarlo
# entre invocaciones y reducir el cold start
s3 = boto3.client("s3")

def handler(event, context):
    """
    Handler principal de la Lambda de SECOP II.
    
    Flujo:
    1. Recibe evento desde API Gateway o SQS
    2. Valida campos obligatorios del proceso de contratación
    3. Genera un ID único para el proceso (idempotencia)
    4. Guarda el documento en S3
    5. Retorna respuesta estructurada
    """

    logger.info("Evento recibido", extra={
        "request_id": context.aws_request_id,
        "function": context.function_name
    })

    http_method = event.get("requestContext", {}).get("http", {}).get("method", "POST")
    
    if http_method == "GET":
        # Extraer el proceso_id de la URL
        proceso_id = event.get("pathParameters", {}).get("proceso_id")
        
        if not proceso_id:
            return _response(400, {"error": "proceso_id es requerido en la URL"})
        
        # Buscar el documento en S3
        bucket = os.environ.get("S3_BUCKET", "")
        s3_key = f"contratos/{proceso_id}.json"
        
        try:
            resultado = s3.get_object(Bucket=bucket, Key=s3_key)
            documento = json.loads(resultado["Body"].read().decode("utf-8"))
            logger.info("Consulta exitosa", extra={"proceso_id": proceso_id})
            return _response(200, documento)
        except s3.exceptions.NoSuchKey:
            logger.warning("Proceso no encontrado", extra={"proceso_id": proceso_id})
            return _response(404, {
                "error": "Proceso no encontrado",
                "proceso_id": proceso_id
            })
        except Exception as e:
            logger.error("Error consultando S3", extra={"error": str(e)})
            raise
            
    # ── Paso 1: Parsear el cuerpo del evento ─────────────────────────────
    # API Gateway manda el body como string JSON, hay que parsearlo.
    # Si el evento ya es un dict (invocación directa o SQS), lo usamos tal cual.
    try:
        if isinstance(event.get("body"), str):
            body = json.loads(event["body"])
        elif "body" in event:
            body = event["body"]
        else:
            # Invocación directa o desde SQS
            body = event
    except json.JSONDecodeError as e:
        logger.error("Body inválido — no es JSON válido", extra={"error": str(e)})
        return _response(400, {"error": "El cuerpo de la solicitud no es JSON válido"})

    # ── Paso 2: Validar campos obligatorios ──────────────────────────────
    # Un proceso de contratación en SECOP II debe tener al minimum:
    # - entidad: quien publica el proceso
    # - modalidad: licitación, mínima cuantía, contratación directa, etc.
    # - objeto: qué se quiere contratar
    campos_requeridos = ["entidad", "modalidad", "objeto"]
    faltantes = [c for c in campos_requeridos if not body.get(c)]
    
    if faltantes:
        logger.warning("Validación fallida — campos faltantes", extra={
            "campos_faltantes": faltantes
        })
        return _response(400, {
            "error": "Campos obligatorios faltantes",
            "campos": faltantes
        })

    # ── Paso 3: Idempotencia ──────────────────────────────────────────────
    # Si el cliente ya envió un proceso_id, lo respetamos.
    # Así, si el mismo mensaje llega dos veces (SQS at-least-once),
    # no creamos dos registros distintos en S3.
    proceso_id = body.get("proceso_id") or str(uuid.uuid4())
    
    logger.info("Procesando contrato", extra={
        "proceso_id": proceso_id,
        "entidad": body["entidad"],
        "modalidad": body["modalidad"]
    })

    # ── Paso 4: Construir el documento a guardar ──────────────────────────
    documento = {
        "proceso_id":  proceso_id,
        "entidad":     body["entidad"],
        "modalidad":   body["modalidad"],
        "objeto":      body["objeto"],
        "valor":       body.get("valor", 0),
        "estado":      "RECIBIDO",
        "timestamp":   datetime.utcnow().isoformat() + "Z",
        "request_id":  context.aws_request_id
    }

    # ── Paso 5: Guardar en S3 ─────────────────────────────────────────────
    # Clave del objeto: contratos/{proceso_id}.json
    # Esto permite buscar cualquier contrato por su ID directamente.
    bucket = os.environ.get("S3_BUCKET", "")
    s3_key = f"contratos/{proceso_id}.json"

    try:
        s3.put_object(
            Bucket=bucket,
            Key=s3_key,
            Body=json.dumps(documento, ensure_ascii=False),
            ContentType="application/json",
            # Metadatos para búsqueda y auditoría
            Metadata={
                "proceso-id": proceso_id,
                "entidad":    body["entidad"][:50],  # S3 limita metadata a 2KB
                "modalidad":  body["modalidad"]
            }
        )
        logger.info("Documento guardado en S3", extra={
            "bucket": bucket,
            "key": s3_key,
            "proceso_id": proceso_id
        })
    except Exception as e:
        logger.error("Error guardando en S3 — SQS reintentará", extra={
            "error": str(e),
            "bucket": bucket,
            "key": s3_key
        })
        # Si esta Lambda fue invocada desde SQS, lanzar la excepción
        # le indica a SQS que el mensaje falló y debe reintentarse.
        # Si fue invocada desde API Gateway directamente, el error
        # igual se registra en CloudWatch para trazabilidad.
        raise

    # ── Paso 6: Respuesta exitosa ─────────────────────────────────────────
    return _response(201, {
        "mensaje":    "Proceso de contratación recibido correctamente",
        "proceso_id": proceso_id,
        "estado":     "RECIBIDO",
        "s3_key":     s3_key
    })


def _response(status_code, body):
    """Construye respuesta HTTP estándar para API Gateway."""
    return {
        "statusCode": status_code,
        "headers": {
            "Content-Type": "application/json",
            "X-Request-Source": "SECOP-II-Lambda"
        },
        "body": json.dumps(body, ensure_ascii=False)
    }
EOF
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