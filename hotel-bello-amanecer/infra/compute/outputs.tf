output "alb_dns_name" {
  value = aws_lb.main.dns_name
}

output "ecr_registry" {
  value = "${data.aws_caller_identity.me.account_id}.dkr.ecr.${var.region}.amazonaws.com"
}

output "cluster_name" {
  value = aws_ecs_cluster.main.name
}

output "capacity_provider" {
  value = aws_ecs_capacity_provider.ec2.name
}

output "tg_frontend_arn" {
  value = aws_lb_target_group.frontend.arn
}

output "tg_api_arn" {
  value = aws_lb_target_group.api.arn
}

output "lab_role_arn" {
  value = data.aws_iam_role.lab.arn
}
