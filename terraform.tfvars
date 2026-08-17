region     = "ap-south-1"
account_id = "389758363574"

cluster_name = "Trakzee-Test-Cluster"

vpc_id         = "vpc-a01bbfc8"
subnet_ids     = ["subnet-66dac72b", "subnet-816bc9e9"]
alb_subnet_ids = ["subnet-66dac72b", "subnet-816bc9e9"]

instance_security_group_id = "sg-d69860bd"
alb_security_group_id      = "sg-09d0f3a15bc885344"

key_name                  = "allserver"
ecs_ami_id                = "ami-01f662fe6044dfacb"
iam_instance_profile_name = "ecsInstanceRole"

common_tags = {
  Project     = "TrakzeeTest"
  Environment = "Testing"
}

services = {
  vts = {
    ecr_repo             = "vts-prod"
    container_name       = "VTSApp"
    container_port       = 8080
    health_check_path    = "/jsp/login.jsp"
    health_check_matcher = "200"
    path_pattern         = ["/jsp/*"]
    listener_priority    = 10

    primary = {
      cpu           = 1536
      memory        = 3072
      instance_type = "c5a.large"
      desired_count = 1
    }

    secondary = {
      cpu                = 1536
      memory             = 3072
      instance_type      = "c5a.large"
      min_capacity       = 0
      max_capacity       = 1
      cpu_target_value   = 70
      scale_out_cooldown = 60
      scale_in_cooldown  = 300
    }
  }

  livetracking = {
    ecr_repo             = "livetracking-prod"
    container_name       = "LiveTrackingApp"
    container_port       = 8080
    health_check_path    = "/LiveTrackingDashBoardMicroService/"
    health_check_matcher = "200-499"
    path_pattern         = ["/LiveTrackingDashBoardMicroService/*"]
    listener_priority    = 20

    primary = {
      cpu           = 1536
      memory        = 3072
      instance_type = "c5a.large"
      desired_count = 1
    }

    secondary = {
      cpu                = 1536
      memory             = 3072
      instance_type      = "c5a.large"
      min_capacity       = 0
      max_capacity       = 1
      cpu_target_value   = 70
      scale_out_cooldown = 60
      scale_in_cooldown  = 300
    }
  }

  report = {
    ecr_repo             = "report-prod"
    container_name       = "ReportApp"
    container_port       = 8080
    health_check_path    = "/ReportServices/"
    health_check_matcher = "200-499"
    path_pattern         = ["/ReportServices/*"]
    listener_priority    = 30

    primary = {
      cpu           = 1536
      memory        = 3072
      instance_type = "c5a.large"
      desired_count = 1
    }

    secondary = {
      cpu                = 1536
      memory             = 3072
      instance_type      = "c5a.large"
      min_capacity       = 0
      max_capacity       = 1
      cpu_target_value   = 70
      scale_out_cooldown = 60
      scale_in_cooldown  = 300
    }
  }
}