#######ロードバランサ関連#######
# ALB用セキュリティグループ
resource "aws_security_group" "alb" {
  name        = "alb-security-group"
  description = "alb-security-group"
  vpc_id      = data.aws_vpc.vpc.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    name = "alb-security-group"
  }
}

# ALB用セキュリティグループルール
resource "aws_security_group_rule" "alb" {
  security_group_id = aws_security_group.alb.id
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"

  cidr_blocks = ["0.0.0.0/0"]
}

# ALB
resource "aws_lb" "main" {

  load_balancer_type = "application"
  name               = "alb-dev-I231-sample"

  security_groups = [aws_security_group.alb.id]
  subnets         = [data.aws_subnet.subnet_a.id, data.aws_subnet.subnet_b.id, data.aws_subnet.subnet_c.id]

}

# ALBリスナー
resource "aws_lb_listener" "main" {
  port     = "80"
  protocol = "HTTP"

  load_balancer_arn = aws_lb.main.arn

  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      status_code  = "200"
      message_body = "ok"
    }
  }
}

# ALBターゲットグループ
resource "aws_lb_target_group" "main" {
  name = "tg-dev-I231-sample-app"

  vpc_id = data.aws_vpc.vpc.id

  port        = 80
  protocol    = "HTTP"
  target_type = "ip"

  health_check {
    port = 80
    path = "/"
  }
}

# ALBリスナールール
resource "aws_lb_listener_rule" "main" {

  listener_arn = aws_lb_listener.main.arn

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main.arn
  }

  condition {
    path_pattern {
      values = ["*"]
    }
  }
}
