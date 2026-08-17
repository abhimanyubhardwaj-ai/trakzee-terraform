variable "region" {
  description = "AWS region"
  type        = string
  default     = "ap-south-1"
}

variable "account_id" {
  description = "AWS account ID (used to build ECR image URIs)"
  type        = string
}

variable "cluster_name" {
  description = "ECS cluster name, e.g. Trakzee4-Cluster"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where everything is deployed"
  type        = string
}

variable "subnet_ids" {
  description = "Subnet IDs for the ASGs / EC2 instances (private subnets)"
  type        = list(string)
}

variable "alb_subnet_ids" {
  description = "Subnet IDs for the ALB (usually the same as subnet_ids, or public subnets)"
  type        = list(string)
}

variable "instance_security_group_id" {
  description = "Security group ID for EC2 instances. MUST allow inbound TCP 32768-65535 from the ALB security group (see alb_security_group_id) - this was the root cause of the Trakzee2 incident documented separately."
  type        = string
}

variable "alb_security_group_id" {
  description = "Security group ID for the ALB itself"
  type        = string
}

variable "key_name" {
  description = "EC2 key pair name for SSH access to instances"
  type        = string
}

variable "ecs_ami_id" {
  description = "ECS-optimized AMI ID for the launch templates"
  type        = string
}

variable "iam_instance_profile_name" {
  description = "IAM instance profile name granting ECS agent permissions"
  type        = string
}

variable "common_tags" {
  description = "Tags applied to every resource this module creates, e.g. { Project = \"Trakzee4asg\", Environment = \"Production\" }"
  type        = map(string)
  default     = {}
}

# ============================================================
# THE MAIN THING YOU EDIT: one entry per microservice.
# Copy an existing block, change the values, and a full
# primary+secondary pair (launch templates, ASGs, capacity
# providers, task definitions, ECS services, target group,
# listener rule, and secondary autoscaling policy) gets created
# automatically - no other file needs to change.
# ============================================================
variable "services" {
  description = "Map of microservices to deploy. Key = service name (lowercase, used in resource names)."
  type = map(object({
    ecr_repo           = string # e.g. "vts-prod" - must already exist in ECR
    container_name     = string # e.g. "VTSApp" - must match what the app expects inside the container
    container_port     = number # e.g. 8080
    health_check_path  = string # e.g. "/jsp/login.jsp"
    health_check_matcher = string # e.g. "200" or "200-499"
    path_pattern       = list(string) # ALB listener rule routing, e.g. ["/jsp/*"]
    listener_priority  = number # must be unique across all services

    primary = object({
      cpu           = number # task-level vCPU units (1024 = 1 vCPU)
      memory        = number # task-level memory in MiB
      instance_type = string # EC2 instance type for this ASG
      desired_count = number # normally 1 - primaries are fixed capacity, not autoscaled
    })

    secondary = object({
      cpu                 = number
      memory              = number
      instance_type       = string
      min_capacity        = number # normally 0
      max_capacity         = number # normally 2
      cpu_target_value    = number # e.g. 70 - the % CPU that triggers scale-out
      scale_out_cooldown  = number # seconds, e.g. 60
      scale_in_cooldown   = number # seconds, e.g. 300
    })
  }))
}
