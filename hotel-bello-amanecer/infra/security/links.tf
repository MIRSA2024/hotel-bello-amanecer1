# Entrega los IDs de los Security Groups a los módulos data y compute (ver network/links.tf).

resource "local_file" "to_data" {
  filename = "${path.module}/../data/security.auto.tfvars.json"
  content  = jsonencode({ sg_db_id = aws_security_group.db.id })
}

resource "local_file" "to_compute" {
  filename = "${path.module}/../compute/security.auto.tfvars.json"
  content = jsonencode({
    sg_alb_id = aws_security_group.alb.id
    sg_app_id = aws_security_group.app.id
  })
}
