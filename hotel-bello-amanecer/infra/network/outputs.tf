output "vpc_id" {
  value = aws_vpc.main.id
}

output "public_subnet_ids" {
  value = [aws_subnet.this["public-a"].id, aws_subnet.this["public-b"].id]
}

output "app_subnet_ids" {
  value = [aws_subnet.this["private-app-a"].id, aws_subnet.this["private-app-b"].id]
}

output "db_subnet_ids" {
  value = [aws_subnet.this["private-db-a"].id, aws_subnet.this["private-db-b"].id]
}
