locals {
  # Flattens { vts = { primary = {...}, secondary = {...} }, ... }
  # into { "vts-primary" = {...}, "vts-secondary" = {...}, ... }
  # so every launch template / ASG / capacity provider / task
  # definition / ECS service can be created with a single
  # for_each, regardless of how many services are defined above.
  service_role_pairs = merge([
    for svc_name, svc in var.services : {
      for role in ["primary", "secondary"] :
      "${svc_name}-${role}" => {
        service_name       = svc_name
        role               = role
        ecr_repo           = svc.ecr_repo
        container_name     = svc.container_name
        container_port     = svc.container_port
        cpu                = svc[role].cpu
        memory             = svc[role].memory
        instance_type      = svc[role].instance_type
        desired_count      = role == "primary" ? svc.primary.desired_count : 0
        is_secondary       = role == "secondary"
      }
    }
  ]...)

  # Server_group tag convention matching the manual Trakzee2/3 setup
  server_group_tag = "${var.cluster_name}-asg"
}