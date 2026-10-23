# Colas de mensajería (en el informe este archivo corresponde al hito APF3, pero los
# servicios ECS las necesitan para arrancar, por eso se aprovisionan junto con los datos).

locals {
  queues = toset(["q-reservas", "q-notificaciones"])
}

resource "aws_sqs_queue" "dlq" {
  for_each                  = local.queues
  name                      = "${each.key}-dlq"
  message_retention_seconds = 1209600 # 14 días
  sqs_managed_sse_enabled   = true
}

resource "aws_sqs_queue" "main" {
  for_each                   = local.queues
  name                       = each.key
  message_retention_seconds  = 345600 # 4 días
  visibility_timeout_seconds = 30
  receive_wait_time_seconds  = 10
  sqs_managed_sse_enabled    = true

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dlq[each.key].arn
    maxReceiveCount     = 5 # RF07: 5 intentos y luego a la DLQ
  })
}
