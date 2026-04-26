# Crea los grupos de logs y alarmas básicas para monitorear
# el comportamiento de los servicios desplegados.
# En el laboratorio lo mantenemos mínimo — solo lo necesario
# para evidenciar que el monitoreo está configurado.

# ── Grupo de logs del clúster EKS ─────────────────────────────────────────
resource "aws_cloudwatch_log_group" "eks" {
  name              = "/aws/eks/${var.project}-${var.env}-cluster/cluster"
  retention_in_days = 7

  tags = {
    Name        = "${var.project}-${var.env}-eks-logs"
    Environment = var.env
    Project     = var.project
  }
}

# ── Grupo de logs de Lambda ───────────────────────────────────────────────
resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${var.project}-${var.env}-integrations"
  retention_in_days = 7

  tags = {
    Name        = "${var.project}-${var.env}-lambda-logs"
    Environment = var.env
    Project     = var.project
  }
}

# ── Grupo de logs del ALB ─────────────────────────────────────────────────
resource "aws_cloudwatch_log_group" "alb" {
  name              = "/aws/alb/${var.project}-${var.env}"
  retention_in_days = 7

  tags = {
    Name        = "${var.project}-${var.env}-alb-logs"
    Environment = var.env
    Project     = var.project
  }
}

# ── Alarma de CPU en nodos EKS ────────────────────────────────────────────
# Alerta cuando el uso de CPU supera el 80%.
# No tiene acción configurada en el laboratorio — solo registra la alarma.
resource "aws_cloudwatch_metric_alarm" "eks_cpu" {
  alarm_name          = "${var.project}-${var.env}-eks-cpu-high"
  alarm_description   = "CPU de nodos EKS supera el 80%"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 120
  statistic           = "Average"
  threshold           = 80

  # Sin dimensiones específicas — monitorea todos los nodos de la cuenta
  tags = {
    Name        = "${var.project}-${var.env}-eks-cpu-alarm"
    Environment = var.env
    Project     = var.project
  }
}

# ── Alarma de errores en el ALB ───────────────────────────────────────────
# El ARN del ALB en CloudWatch usa solo la parte relativa:
# arn:aws:...:loadbalancer/app/nombre/id → app/nombre/id
resource "aws_cloudwatch_metric_alarm" "alb_errors" {
  alarm_name          = "${var.project}-${var.env}-alb-errors"
  alarm_description   = "Errores 5xx en el Load Balancer superan el umbral"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "HTTPCode_ELB_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = 300
  statistic           = "Sum"
  threshold           = 10

  dimensions = {
    LoadBalancer = replace(var.alb_arn, "/^.*:loadbalancer\\//", "")
  }

  tags = {
    Name        = "${var.project}-${var.env}-alb-errors-alarm"
    Environment = var.env
    Project     = var.project
  }
}
