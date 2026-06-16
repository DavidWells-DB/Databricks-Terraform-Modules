resource "aws_security_group" "nlb" {
  name        = "${var.name}-nlb-sg"
  description = "Security group for NLB to forward traffic to ${var.target_ip}:${var.target_port}"
  vpc_id      = var.vpc_id

  egress {
    description = "Allow all outbound traffic to target resource"
    from_port   = var.target_port
    to_port     = var.target_port
    protocol    = "tcp"
    cidr_blocks = ["${var.target_ip}/32"]
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.name}-nlb-sg"
    }
  )
}

resource "aws_lb" "this" {
  name               = var.name
  internal           = true
  load_balancer_type = "network"
  subnets            = var.subnet_ids

  enable_deletion_protection       = false
  enable_cross_zone_load_balancing = true

  tags = merge(
    var.tags,
    {
      Name = var.name
    }
  )
}

resource "aws_lb_target_group" "this" {
  name        = "${var.name}-tg"
  port        = var.target_port
  protocol    = "TCP"
  target_type = "ip"
  vpc_id      = var.vpc_id

  health_check {
    enabled             = true
    protocol            = "TCP"
    port                = "traffic-port"
    healthy_threshold   = 3
    unhealthy_threshold = 3
    interval            = 30
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.name}-tg"
    }
  )
}

resource "aws_lb_target_group_attachment" "this" {
  target_group_arn = aws_lb_target_group.this.arn
  target_id        = var.target_ip
  port             = var.target_port
}

resource "aws_lb_listener" "this" {
  load_balancer_arn = aws_lb.this.arn
  port              = local.effective_listener_port
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.arn
  }

  tags = var.tags
}

resource "aws_vpc_endpoint_service" "this" {
  acceptance_required        = false
  network_load_balancer_arns = [aws_lb.this.arn]

  tags = merge(
    var.tags,
    {
      Name = var.name
    }
  )
}

resource "aws_vpc_endpoint_service_allowed_principal" "databricks" {
  vpc_endpoint_service_id = aws_vpc_endpoint_service.this.id
  principal_arn           = local.databricks_principal_arn
}
