resource "aws_cloudwatch_log_group" "this" {
  for_each = var.services

  name              = "/ecs/${var.cluster_name}-${each.key}"
  retention_in_days = 14
  tags              = var.common_tags
}

resource "aws_ecs_task_definition" "this" {
  for_each = local.service_role_pairs

  family                   = "${lower(var.cluster_name)}-${each.key}"
  requires_compatibilities = ["EC2"]
  network_mode             = "bridge" # matches the observed dynamic host-port pattern (hostPort 0 -> random 32768-65535)
  cpu                      = each.value.cpu
  memory                   = each.value.memory

  container_definitions = jsonencode([
    {
      name      = each.value.container_name
      image     = "${var.account_id}.dkr.ecr.${var.region}.amazonaws.com/${each.value.ecr_repo}:latest"
      cpu       = each.value.cpu
      memory    = each.value.memory
      essential = true

      portMappings = [
        {
          containerPort = each.value.container_port
          hostPort      = 0 # dynamic port - this is what the ALB dynamic-port-range SG rule must allow
          protocol      = "tcp"
        }
      ]

      environment = [
        { name = "SERVER_NAME", value = var.cluster_name },
        { name = "SERVER_ROLE", value = each.value.role },
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.this[each.value.service_name].name
          "awslogs-region"        = var.region
          "awslogs-stream-prefix" = "ecs"
          "awslogs-create-group"  = "true"
        }
      }
    }
  ])

  tags = merge(var.common_tags, {
    Name = "${lower(var.cluster_name)}-${each.key}"
  })
}
