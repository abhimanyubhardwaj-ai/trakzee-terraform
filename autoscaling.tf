# Autoscaling applies to secondary services only - primaries run
# at a fixed desired_count and are never touched by this.
resource "aws_appautoscaling_target" "secondary" {
  for_each = var.services

  max_capacity       = each.value.secondary.max_capacity
  min_capacity       = each.value.secondary.min_capacity
  resource_id        = "service/${aws_ecs_cluster.this.name}/${aws_ecs_service.this["${each.key}-secondary"].name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "secondary_cpu" {
  for_each = var.services

  name               = "${lower(var.cluster_name)}-${each.key}-secondary-scaling-policy"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.secondary[each.key].resource_id
  scalable_dimension = aws_appautoscaling_target.secondary[each.key].scalable_dimension
  service_namespace  = aws_appautoscaling_target.secondary[each.key].service_namespace

  target_tracking_scaling_policy_configuration {
    target_value       = each.value.secondary.cpu_target_value
    scale_out_cooldown = each.value.secondary.scale_out_cooldown
    scale_in_cooldown  = each.value.secondary.scale_in_cooldown

    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
  }
}
