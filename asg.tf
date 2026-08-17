resource "aws_autoscaling_group" "this" {
  for_each = local.service_role_pairs

  name                = "${lower(var.cluster_name)}-${each.key}-asg"
  vpc_zone_identifier = var.subnet_ids

  # Primary ASGs run exactly 1 instance (fixed capacity).
  # Secondary ASGs start at 0 and let ECS Managed Scaling grow
  # them (up to max_capacity) only when a task actually needs
  # placement - matching the manual Trakzee2/3 pattern.
  min_size         = each.value.is_secondary ? 0 : 1
  max_size         = each.value.is_secondary ? 2 : 1
  desired_capacity = each.value.is_secondary ? 0 : 1

  launch_template {
    id      = aws_launch_template.this[each.key].id
    version = "$Latest"
  }

  protect_from_scale_in = true # required for ECS Managed Scaling

  tag {
    key                 = "Name"
    value               = "${lower(var.cluster_name)}-${each.key}-lt-node"
    propagate_at_launch = true
  }

  tag {
    key                 = "Server_group"
    value               = local.server_group_tag
    propagate_at_launch = true
  }

  dynamic "tag" {
    for_each = var.common_tags
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }

  lifecycle {
    ignore_changes = [desired_capacity] # let ECS Managed Scaling / manual scaling own this after creation
  }
}

resource "aws_ecs_capacity_provider" "this" {
  for_each = local.service_role_pairs

  name = "${lower(var.cluster_name)}-${each.key}-cp"

  auto_scaling_group_provider {
    auto_scaling_group_arn         = aws_autoscaling_group.this[each.key].arn
    managed_termination_protection = "ENABLED"

    managed_scaling {
      status                    = "ENABLED"
      target_capacity           = 100
      minimum_scaling_step_size = 1
      maximum_scaling_step_size = 2
    }
  }

  tags = var.common_tags
}
