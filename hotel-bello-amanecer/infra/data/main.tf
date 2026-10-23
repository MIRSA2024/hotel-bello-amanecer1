resource "aws_db_subnet_group" "db" {
  name       = "hba-db-subnets"
  subnet_ids = var.db_subnet_ids # private-db-a y private-db-b
}

resource "aws_db_parameter_group" "pg16" {
  name   = "hba-pg16"
  family = "postgres16"

  parameter {
    name  = "rds.force_ssl" # rechaza conexiones sin TLS
    value = "1"
  }
}

# Plan B de la nota del informe: si el laboratorio no permite el secreto administrado por RDS
resource "random_password" "db" {
  count   = var.use_managed_master_password ? 0 : 1
  length  = 24
  special = false
}

resource "aws_secretsmanager_secret" "db" {
  count                   = var.use_managed_master_password ? 0 : 1
  name                    = "hba/db-credentials"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "db" {
  count     = var.use_managed_master_password ? 0 : 1
  secret_id = aws_secretsmanager_secret.db[0].id
  secret_string = jsonencode({
    username = "hba_admin"
    password = random_password.db[0].result
  })
}

resource "aws_db_instance" "main" {
  identifier            = "hba-db-principal"
  engine                = "postgres"
  engine_version        = "16"
  instance_class        = var.db_instance_class
  allocated_storage     = 20
  max_allocated_storage = 50 # autoescalado de almacenamiento
  storage_type          = "gp3"
  storage_encrypted     = true # cifrado en reposo (KMS)

  db_name  = "reservas"
  username = "hba_admin"

  manage_master_user_password = var.use_managed_master_password ? true : null # clave en Secrets Manager
  password                    = var.use_managed_master_password ? null : random_password.db[0].result

  multi_az               = var.db_multi_az
  db_subnet_group_name   = aws_db_subnet_group.db.name
  vpc_security_group_ids = [var.sg_db_id]
  parameter_group_name   = aws_db_parameter_group.pg16.name
  publicly_accessible    = false

  backup_retention_period = 7 # habilita PITR
  backup_window           = "06:00-07:00"

  deletion_protection       = var.db_deletion_protection
  skip_final_snapshot       = var.db_skip_final_snapshot
  final_snapshot_identifier = var.db_skip_final_snapshot ? null : "hba-db-final"

  apply_immediately = true

  lifecycle {
    ignore_changes = [engine_version]
  }
}

# Clave de SendGrid (MAIL_API_KEY). Queda con un valor de relleno: en el laboratorio el
# servicio usa MAIL_PROVIDER=log y solo registra el correo. Para enviar correos reales,
# reemplazar el valor desde la consola de Secrets Manager y poner MAIL_PROVIDER=sendgrid.
resource "aws_secretsmanager_secret" "mail" {
  name                    = "hba/mail-api-key"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "mail" {
  secret_id     = aws_secretsmanager_secret.mail.id
  secret_string = "no-configurado"

  lifecycle {
    ignore_changes = [secret_string] # no pisar la clave real si se cambia a mano
  }
}
