# Trakzee ECS Cluster - Infrastructure as Code

This turns everything built manually for Trakzee2 (ECR, launch templates, ASGs,
capacity providers, task definitions, ECS services, ALB, target groups, and
secondary autoscaling) into a single Terraform module. Add a new microservice
by editing **one file** - `terraform.tfvars` - nothing else.

## What this creates, per entry in the `services` map

- 2x Launch Template (primary + secondary)
- 2x Auto Scaling Group (primary fixed at 1, secondary starts at 0)
- 2x ECS Capacity Provider (ECS Managed Scaling enabled)
- 2x ECS Task Definition
- 2x ECS Service (sharing one target group)
- 1x ALB Target Group + 1x Listener Rule (path-based routing)
- 1x Application Auto Scaling policy on the secondary only (target-tracking, CPU%)

Plus one shared ECS Cluster and one shared ALB for the whole environment.

## Prerequisites (not created by this code - must already exist)

- A VPC with subnets
- A security group for the EC2 instances that allows inbound TCP
  **32768-65535 from the ALB's security group**. This is not optional -
  it was the exact root cause of a real outage (ALB could not reach the
  ECS dynamic port range, every task showed `Target.FailedHealthChecks`).
  See `instance_security_group_id` in variables.tf.
- A security group for the ALB (inbound 80/443 from wherever your traffic comes from)
- An EC2 key pair
- An ECS-optimized AMI ID for your region
- An IAM instance profile with the standard `AmazonEC2ContainerServiceforEC2Role` policy
- ECR repositories already containing images tagged `:latest` for each service

## Usage

```bash
cp terraform.tfvars.example terraform.tfvars
# edit terraform.tfvars with your real VPC/subnet/SG/AMI/key values

terraform init
terraform plan    # review what will be created
terraform apply
```

## Adding a new microservice later

Open `terraform.tfvars`, copy one block inside the `services = { ... }` map
(there's a commented-out `billing` example at the bottom showing the exact
pattern), rename the key, adjust the values, then:

```bash
terraform plan
terraform apply
```

Terraform will create only the new service's resources - it won't touch
anything already running.

## Health check matcher note

VTS's health check path typically returns a clean `200`. LiveTracking and
Report return `403` on their health check paths by application design, so
their `health_check_matcher` is set to `"200-499"` rather than `"200"` -
this mirrors a real fix applied after an ALB health-check incident. If you
add a new service and its health check path returns something other than
a clean `200`, set `health_check_matcher` accordingly rather than treating
non-200 as broken.

## Known limitations / things to double-check before applying

- **Not yet validated with `terraform validate`** in this environment
  (network-restricted sandbox couldn't download the Terraform binary).
  Manually reviewed for correctness, but run `terraform validate` yourself
  before `apply` as a first step.
- The default capacity provider strategy on the cluster picks the first
  service+role pair alphabetically/by map order - harmless (it only
  affects tasks that don't specify their own strategy, and every service
  here does specify one), but worth knowing.
- ASG `desired_capacity` is set once at creation and then Terraform is told
  to ignore future drift (`lifecycle { ignore_changes = [desired_capacity] }`)
  so that manual scaling (or ECS Managed Scaling) doesn't get fought by
  `terraform apply` on every run.
- Autoscaling here only watches each **secondary's own** CPU - it does not
  trigger secondary scale-out based on primary's load. Extending this to a
  step-scaling policy watching primary's CloudWatch alarm is a reasonable
  future addition, but isn't built here.
- Cost allocation tags follow the `Project` / `Environment` / `Server_group`
  convention used in the manual build - adjust `common_tags` and
  `local.server_group_tag` if your team's convention differs.

## Files

| File | Purpose |
|---|---|
| `variables.tf` | All inputs, including the `services` map you edit |
| `locals.tf` | Flattens `services` into per-role resource maps |
| `provider.tf` | AWS provider + Terraform version constraint |
| `cluster.tf` | ECS cluster + capacity provider attachment |
| `launch_templates.tf` | One launch template per service+role |
| `asg.tf` | ASGs + ECS capacity providers |
| `task_definitions.tf` | Task definitions + CloudWatch log groups |
| `alb.tf` | ALB, listener, target groups, routing rules |
| `ecs_services.tf` | ECS services |
| `autoscaling.tf` | Secondary-only target tracking autoscaling |
| `outputs.tf` | ALB DNS name and other useful outputs |
| `terraform.tfvars.example` | Copy to `terraform.tfvars` and edit this |
# trakzee-terraform
