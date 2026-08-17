resource "aws_lb" "this" {
  name               = "${lower(var.cluster_name)}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.alb_security_group_id]
  subnets            = var.alb_subnet_ids

  tags = merge(var.common_tags, {
    Name = "${lower(var.cluster_name)}-alb"
  })
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "No matching route"
      status_code  = "404"
    }
  }
}

# One target group per SERVICE (not per role) - primary and
# secondary share the same target group, exactly like the
# manual Trakzee2/3 setup, so the ALB spreads traffic across
# whichever tasks are actually healthy at any given time.
resource "aws_lb_target_group" "this" {
  for_each = var.services

  name        = substr("${lower(var.cluster_name)}-${each.key}-tg", 0, 32)
  port        = each.value.container_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "instance"

  health_check {
    path                = each.value.health_check_path
    matcher             = each.value.health_check_matcher
    interval            = 60
    timeout             = 30
    healthy_threshold   = 2
    unhealthy_threshold = 5
  }

  tags = merge(var.common_tags, {
    Name = "${lower(var.cluster_name)}-${each.key}-tg"
  })
}

resource "aws_lb_listener_rule" "this" {
  for_each = var.services

  listener_arn = aws_lb_listener.http.arn
  priority     = each.value.listener_priority

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this[each.key].arn
  }

  condition {
    path_pattern {
      values = each.value.path_pattern
    }
  }
}
