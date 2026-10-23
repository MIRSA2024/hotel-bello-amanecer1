# Escribe los IDs que necesitan los módulos siguientes (security, data y compute) en archivos
# *.auto.tfvars.json, que Terraform carga solos. Así no hay que copiar IDs a mano.
# Estos archivos NO se versionan (ver .gitignore).

resource "local_file" "to_security" {
  filename = "${path.module}/../security/network.auto.tfvars.json"
  content = jsonencode({
    vpc_id        = aws_vpc.main.id
    db_subnet_ids = [aws_subnet.this["private-db-a"].id, aws_subnet.this["private-db-b"].id]
  })
}

resource "local_file" "to_data" {
  filename = "${path.module}/../data/network.auto.tfvars.json"
  content = jsonencode({
    db_subnet_ids = [aws_subnet.this["private-db-a"].id, aws_subnet.this["private-db-b"].id]
  })
}

resource "local_file" "to_compute" {
  filename = "${path.module}/../compute/network.auto.tfvars.json"
  content = jsonencode({
    vpc_id            = aws_vpc.main.id
    public_subnet_ids = [aws_subnet.this["public-a"].id, aws_subnet.this["public-b"].id]
    app_subnet_ids    = [aws_subnet.this["private-app-a"].id, aws_subnet.this["private-app-b"].id]
  })
}
