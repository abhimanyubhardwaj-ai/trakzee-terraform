resource "aws_launch_template" "this" {
  for_each = local.service_role_pairs

  name          = "${lower(var.cluster_name)}-${each.key}-lt"
  image_id      = var.ecs_ami_id
  instance_type = each.value.instance_type
  key_name      = var.key_name

  iam_instance_profile {
    name = var.iam_instance_profile_name
  }

  vpc_security_group_ids = [var.instance_security_group_id]

  user_data = base64encode(<<-EOF
    #!/bin/bash
    echo ECS_CLUSTER=${var.cluster_name} >> /etc/ecs/ecs.config
  EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags = merge(var.common_tags, {
      Name         = "${lower(var.cluster_name)}-${each.key}-lt-node"
      Server_group = local.server_group_tag
    })
  }

  tags = merge(var.common_tags, {
    Name = "${lower(var.cluster_name)}-${each.key}-lt"
  })
}
