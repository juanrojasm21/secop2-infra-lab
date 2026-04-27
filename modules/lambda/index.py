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
            return _response(400, {"error": "El parámetro de id del proceso es requerido por la URL"})
        
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