output "alb_dns_name" {
  description = "Public DNS name of the ALB - browse to this + a service's path_pattern to reach it"
  value       = aws_lb.this.dns_name
}

output "cluster_name" {
  value = aws_ecs_cluster.this.name
}

output "target_group_arns" {
  description = "Target group ARN per service"
  value       = { for k, v in aws_lb_target_group.this : k => v.arn }
}

output "ecs_service_names" {
  description = "Every ECS service created (one per service+role)"
  value       = { for k, v in aws_ecs_service.this : k => v.name }
}

output "capacity_provider_names" {
  value = { for k, v in aws_ecs_capacity_provider.this : k => v.name }
}
