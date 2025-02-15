resource "aws_lb" "main" {
  name               = "main"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.lb_sg.id]
  subnets            = [for subnet in aws_subnet.public : subnet.id]

  enable_deletion_protection = true

  access_logs {
    bucket  = aws_s3_bucket.lb_logs.id
    prefix  = "test-lb"
    enabled = true
  }

  tags = {
    Environment = "production"
  }
}

# resource "aws_security_group" "api" {
  
# }

# resource "aws_security_group" "api" {
  
# }

resource "aws_lb_target_group" "api" {
  name     = "main-lb-tg-api"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
}

resource "aws_lb_listener" "main" {
  load_balancer_arn = aws_lb.main.arn
  port              = "443"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.front
  }
}


resource "aws_lb_target_group" "front" {
  name     = "tf-main-lb-tg-front"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
}

resource "aws_lb_listener_rule" "api" {
  listener_arn = aws_lb_listener.main.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.api
  }

  condition {
    path_pattern {
      values = ["/api/*"]
    }
  }
}

resource "aws_lb_listener_rule" "front" {
  listener_arn = aws_lb_listener.main.arn
  priority     = 200

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.front
    }

  condition {
    path_pattern {
      values = ["/front/*"]
    }
  }
}

resource "aws_lb_target_group" "service_stop" {
  name     = "tf-main-lb-tg-service_stop"
  port     = 9080
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
}

resource "aws_lb_listener_rule" "service_stop" {
  listener_arn = aws_lb_listener.main.arn
  priority     = 300

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.service_stop.arn
  }

  condition {
    path_pattern {
      values = ["/*"]
    }
  }
}





