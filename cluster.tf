resource "aws_ecs_cluster" "this" {
  name = var.cluster_name

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = merge(var.common_tags, {
    Name = var.cluster_name
  })
}

# Attach every capacity provider (one per service+role) to the cluster,
# with the first one set as the default strategy - mirrors how the
# manual Trakzee2 build attached all 6 capacity providers with vts-primary
# as the default (weight 1, base 0).
resource "aws_ecs_cluster_capacity_providers" "this" {
  cluster_name = aws_ecs_cluster.this.name

  capacity_providers = [for k, v in local.service_role_pairs : aws_ecs_capacity_provider.this[k].name]

  default_capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.this[keys(local.service_role_pairs)[0]].name
    weight            = 1
    base              = 0
  }
}
