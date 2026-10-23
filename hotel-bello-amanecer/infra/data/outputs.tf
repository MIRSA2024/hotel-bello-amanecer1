output "db_endpoint" {
  description = "Nombre DNS de la base de datos (sin puerto)"
  value       = aws_db_instance.main.address
}

output "db_secret_arn" {
  description = "Secreto con usuario y clave de la BD"
  value       = var.use_managed_master_password ? aws_db_instance.main.master_user_secret[0].secret_arn : aws_secretsmanager_secret.db[0].arn
}

output "media_bucket" {
  value = aws_s3_bucket.media.bucket
}

output "queue_urls" {
  value = { for k, q in aws_sqs_queue.main : k => q.url }
}

output "mail_secret_arn" {
  value = aws_secretsmanager_secret.mail.arn
}
