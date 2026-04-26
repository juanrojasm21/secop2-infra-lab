# Crea el Application Load Balancer que recibe todo el tráfico
# entrante desde internet y lo distribuye entre los pods de EKS.
# Es el único punto de entrada público a la plataforma.
#
# Nota: En el laboratorio usamos HTTP puro en puerto 80.
# En producción se agregaría un certificado ACM para HTTPS.

# ── Application Load Balancer ─────────────────────────────────────────────
resource "aws_lb" "main" {
  name               = "${var.project}-${var.env}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.alb_sg_id]
  subnets            = var.public_subnet_ids

  tags = {
    Name        = "${var.project}-${var.env}-alb"
    Environment = var.env
    Project     = var.project
  }
}

# ── Target Group ──────────────────────────────────────────────────────────
# Define hacia dónde envía el tráfico el ALB.
# Los pods de EKS se registran automáticamente aquí.
resource "aws_lb_target_group" "main" {
  name        = "${var.project}-${var.env}-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"  # Requerido para EKS con pods

  health_check {
    enabled             = true
    path                = "/health"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
  }

  tags = {
    Name        = "${var.project}-${var.env}-tg"
    Environment = var.env
    Project     = var.project
  }
}

# ── Listener HTTP ─────────────────────────────────────────────────────────
# En el laboratorio escucha en puerto 80 y reenvía al target group.
# En producción este listener redirigiría a HTTPS y se agregaría
# un listener 443 con certificado ACM.
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main.arn
  }
}
