data "aws_caller_identity" "me" {}

locals {
  services = ["frontend-web", "api-reservas", "consumer-pagos", "servicio-notificaciones"]
  cluster  = "hba-ecs-cluster"
}

# ---------------- ECR ----------------
resource "aws_ecr_repository" "svc" {
  for_each             = toset(local.services)
  name                 = "hba/${each.key}"
  image_tag_mutability = "IMMUTABLE"
  force_delete         = true # laboratorio: permite destruir aunque tenga imágenes

  image_scanning_configuration {
    scan_on_push = true
  }
}

# ---------------- CloudWatch Logs ----------------
resource "aws_cloudwatch_log_group" "svc" {
  for_each          = toset(local.services)
  name              = "/hba/${each.key}"
  retention_in_days = 14
}

# ---------------- ECS: clúster, nodos y capacidad ----------------
resource "aws_ecs_cluster" "main" {
  name = local.cluster
}

data "aws_ssm_parameter" "ecs_ami" {
  name = "/aws/service/ecs/optimized-ami/amazon-linux-2023/recommended/image_id"
}

resource "aws_launch_template" "ecs" {
  name_prefix   = "hba-lt-ecs-"
  image_id      = data.aws_ssm_parameter.ecs_ami.value
  instance_type = var.instance_type

  iam_instance_profile {
    name = "LabInstanceProfile" # AWS Academy no permite crear roles propios
  }

  vpc_security_group_ids = [var.sg_app_id]

  user_data = base64encode(<<-EOT
    #!/bin/bash
    echo "ECS_CLUSTER=${local.cluster}" >> /etc/ecs/ecs.config
  EOT
  )

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_size           = 30
      volume_type           = "gp3"
      encrypted             = true
      delete_on_termination = true
    }
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required" # IMDSv2
    http_put_response_hop_limit = 2
  }

  tag_specifications {
    resource_type = "instance"
    tags          = { Name = "hba-ecs-node" }
  }
}

resource "aws_autoscaling_group" "ecs" {
  name                  = "hba-asg-ecs"
  min_size              = var.asg_min
  desired_capacity      = var.asg_desired
  max_size              = var.asg_max
  vpc_zone_identifier   = var.app_subnet_ids
  health_check_type     = "EC2"
  protect_from_scale_in = false

  launch_template {
    id      = aws_launch_template.ecs.id
    version = "$Latest"
  }

  tag {
    key                 = "AmazonECSManaged"
    value               = "true"
    propagate_at_launch = true
  }

  tag {
    key                 = "Name"
    value               = "hba-ecs-node"
    propagate_at_launch = true
  }

  lifecycle {
    ignore_changes = [desired_capacity]
  }
}

resource "aws_ecs_capacity_provider" "ec2" {
  name = "hba-cp-ec2"

  auto_scaling_group_provider {
    auto_scaling_group_arn         = aws_autoscaling_group.ecs.arn
    managed_termination_protection = "DISABLED"

    managed_scaling {
      status                    = "ENABLED"
      target_capacity           = 100
      minimum_scaling_step_size = 1
      maximum_scaling_step_size = 2
    }
  }
}

resource "aws_ecs_cluster_capacity_providers" "main" {
  cluster_name       = aws_ecs_cluster.main.name
  capacity_providers = [aws_ecs_capacity_provider.ec2.name]

  default_capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.ec2.name
    weight            = 1
  }
}

# ---------------- Certificado autofirmado importado en ACM ----------------
resource "tls_private_key" "alb" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_self_signed_cert" "alb" {
  private_key_pem       = tls_private_key.alb.private_key_pem
  validity_period_hours = 8760
  allowed_uses          = ["key_encipherment", "digital_signature", "server_auth"]

  subject {
    common_name  = "hotel-bello-amanecer.local"
    organization = "Hotel Bello Amanecer (laboratorio)"
  }
}

resource "aws_acm_certificate" "alb" {
  private_key      = tls_private_key.alb.private_key_pem
  certificate_body = tls_self_signed_cert.alb.cert_pem
  tags             = { Name = "hba-cert-laboratorio" }
}

# ---------------- ALB ----------------
resource "aws_lb" "main" {
  name                       = "hba-alb"
  load_balancer_type         = "application"
  internal                   = false
  subnets                    = var.public_subnet_ids
  security_groups            = [var.sg_alb_id]
  drop_invalid_header_fields = true
}

resource "aws_lb_target_group" "frontend" {
  name                 = "hba-tg-frontend"
  port                 = 80 # los puertos reales son dinámicos (los registra ECS)
  protocol             = "HTTP"
  vpc_id               = var.vpc_id
  target_type          = "instance"
  deregistration_delay = 30

  health_check {
    path                = "/healthz"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }
}

resource "aws_lb_target_group" "api" {
  name                 = "hba-tg-api"
  port                 = 80
  protocol             = "HTTP"
  vpc_id               = var.vpc_id
  target_type          = "instance"
  deregistration_delay = 30

  health_check {
    path                = "/actuator/health"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }
}

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.main.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = aws_acm_certificate.alb.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontend.arn
  }
}

resource "aws_lb_listener_rule" "api" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 10

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.api.arn
  }

  condition {
    path_pattern {
      values = ["/api/*"]
    }
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

data "aws_iam_role" "lab" {
  name = "LabRole"
}
