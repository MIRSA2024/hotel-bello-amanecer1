resource "aws_security_group" "alb" {
  name        = "hba-sg-alb"
  description = "ALB publico: solo HTTP/HTTPS"
  vpc_id      = var.vpc_id
  tags        = { Name = "hba-sg-alb" }
}

resource "aws_security_group" "app" {
  name        = "hba-sg-app"
  description = "Nodos ECS: solo desde el ALB"
  vpc_id      = var.vpc_id
  tags        = { Name = "hba-sg-app" }
}

resource "aws_security_group" "db" {
  name        = "hba-sg-db"
  description = "RDS: solo desde la capa de aplicacion"
  vpc_id      = var.vpc_id
  tags        = { Name = "hba-sg-db" }
}

# ---- sg-alb ----
resource "aws_vpc_security_group_ingress_rule" "alb_https" {
  security_group_id = aws_security_group.alb.id
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = "0.0.0.0/0"
  description       = "Trafico HTTPS publico"
}

resource "aws_vpc_security_group_ingress_rule" "alb_http" {
  security_group_id = aws_security_group.alb.id
  ip_protocol       = "tcp"
  from_port         = 80
  to_port           = 80
  cidr_ipv4         = "0.0.0.0/0"
  description       = "Solo para redirigir (301) a HTTPS"
}

resource "aws_vpc_security_group_egress_rule" "alb_to_app" {
  security_group_id            = aws_security_group.alb.id
  referenced_security_group_id = aws_security_group.app.id
  ip_protocol                  = "tcp"
  from_port                    = 32768
  to_port                      = 65535
  description                  = "Reenvio a las tareas ECS (puertos dinamicos)"
}

# ---- sg-app ----
resource "aws_vpc_security_group_ingress_rule" "app_from_alb" {
  security_group_id            = aws_security_group.app.id
  referenced_security_group_id = aws_security_group.alb.id
  ip_protocol                  = "tcp"
  from_port                    = 32768 # rango de puertos dinámicos de ECS
  to_port                      = 65535
  description                  = "Solo desde el balanceador"
}

resource "aws_vpc_security_group_egress_rule" "app_to_db" {
  security_group_id            = aws_security_group.app.id
  referenced_security_group_id = aws_security_group.db.id
  ip_protocol                  = "tcp"
  from_port                    = 5432
  to_port                      = 5432
  description                  = "Acceso a PostgreSQL"
}

resource "aws_vpc_security_group_egress_rule" "app_https_out" {
  security_group_id = aws_security_group.app.id
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = "0.0.0.0/0" # ECR, SQS, Secrets, SendGrid
  description       = "ECR, SQS, Secrets Manager, CloudWatch y SendGrid (via NAT)"
}

# ---- sg-db ----
resource "aws_vpc_security_group_ingress_rule" "db_from_app" {
  security_group_id            = aws_security_group.db.id
  referenced_security_group_id = aws_security_group.app.id
  ip_protocol                  = "tcp"
  from_port                    = 5432
  to_port                      = 5432
  description                  = "Solo desde la capa de aplicacion"
}

# ---- NACL de la capa de datos (segunda barrera) ----
resource "aws_network_acl" "db" {
  vpc_id     = var.vpc_id
  subnet_ids = var.db_subnet_ids
  tags       = { Name = "hba-nacl-db" }

  ingress {
    rule_no    = 100
    protocol   = "tcp"
    action     = "allow"
    cidr_block = var.app_cidrs[0]
    from_port  = 5432
    to_port    = 5432
  }

  ingress {
    rule_no    = 110
    protocol   = "tcp"
    action     = "allow"
    cidr_block = var.app_cidrs[1]
    from_port  = 5432
    to_port    = 5432
  }

  egress {
    rule_no    = 100
    protocol   = "tcp"
    action     = "allow"
    cidr_block = var.app_cidrs[0]
    from_port  = 1024
    to_port    = 65535
  }

  egress {
    rule_no    = 110
    protocol   = "tcp"
    action     = "allow"
    cidr_block = var.app_cidrs[1]
    from_port  = 1024
    to_port    = 65535
  }
}
