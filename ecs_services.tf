resource "aws_ecs_service" "this" {
  for_each = local.service_role_pairs

  name            = "${lower(var.cluster_name)}-${each.key}"
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.this[each.key].arn
  desired_count   = each.value.desired_count

  capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.this[each.key].name
    weight             = 1
    base               = 0
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.this[each.value.service_name].arn
    container_name    = each.value.container_name
    container_port    = each.value.container_port
  }

  health_check_grace_period_seconds = 300

  deployment_minimum_healthy_percent = 100
  deployment_maximum_percent         = 200

  tags = merge(var.common_tags, {
    Name         = "${lower(var.cluster_name)}-${each.key}"
    Server_group = local.server_group_tag
  })

  depends_on = [
    aws_lb_listener_rule.this,
    aws_ecs_cluster_capacity_providers.this,
  ]
}
