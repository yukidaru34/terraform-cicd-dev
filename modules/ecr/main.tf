locals {
  name = "${var.env}-${var.name}"
}

resource "aws_ecr_repository" "ecr" {
  name = local.name

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Terraform   = true
    Environment = var.env
    Name        = local.name
  }
}

## ref: https://docs.aws.amazon.com/AmazonECR/latest/userguide/LifecyclePolicies.html
resource "aws_ecr_lifecycle_policy" "lifecycle_policy" {
  repository = aws_ecr_repository.ecr.name

  policy = jsonencode(
    {
      rules = [
        {
          rulePriority = 1
          description  = "keep last 30 prd images"
          selection = {
            tagStatus     = "tagged"
            tagPrefixList = ["prd-"]
            countType     = "imageCountMoreThan"
            countNumber   = 30
          }
          action = {
            type = "expire"
          }
        },
        {
          rulePriority = 5
          description  = "keep last 10 dev images"
          selection = {
            tagStatus     = "tagged"
            tagPrefixList = ["dev-"]
            countType     = "imageCountMoreThan"
            countNumber   = 10
          }
          action = {
            type = "expire"
          }
        },
        {
          rulePriority = 10
          description  = "keep last 10 untagged images"
          selection = {
            tagStatus   = "untagged"
            countType   = "imageCountMoreThan"
            countNumber = 10
          }
          action = {
            type = "expire"
          }
        },
        {
          rulePriority = 15
          description  = "keep last 10 unknown-tagged images"
          selection = {
            tagStatus   = "any"
            countType   = "imageCountMoreThan"
            countNumber = 10
          }
          action = {
            type = "expire"
          }
        },
      ]
    }
  )
}
resource "aws_vpc" "vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "AWS_IC_DEV Common-VPC"
  }
}

resource "aws_subnet" "subnet_a" {
  vpc_id     = aws_vpc.vpc.id
  cidr_block = "10.0.0.0/18"
  availability_zone = "ap-northeast-1a"

  tags = {
    Name = "Common-SN-Priv01-1a"
  }
}

resource "aws_subnet" "subnet_b" {
  vpc_id     = aws_vpc.vpc.id
  cidr_block = "10.0.64.0/18"
  availability_zone = "ap-northeast-1c"

  tags = {
    Name = "Common-SN-Priv01-1b"
  }
}

resource "aws_subnet" "subnet_c" {
  vpc_id     = aws_vpc.vpc.id
  cidr_block = "10.0.128.0/18"
  availability_zone = "ap-northeast-1d"
  tags = {
    Name = "Common-SN-Priv01-1c"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = "${aws_vpc.vpc.id}"
  tags = {
    name = "handson"
  }
}

resource "aws_route_table" "main" {
  vpc_id = "${aws_vpc.vpc.id}"

   tags = {
    Name = "handson-public"
  }
}

resource "aws_route" "main" {
  destination_cidr_block = "0.0.0.0/0"
  route_table_id         = "${aws_route_table.main.id}"
  gateway_id             = "${aws_internet_gateway.main.id}"

}

resource "aws_route_table_association" "public_1a" {
  subnet_id      = "${aws_subnet.subnet_a.id}"
  route_table_id = "${aws_route_table.main.id}"
}

resource "aws_route_table_association" "public_1c" {
  subnet_id      = "${aws_subnet.subnet_b.id}"
  route_table_id ="${aws_route_table.main.id}"
}

resource "aws_route_table_association" "public_1d" {
  subnet_id      = "${aws_subnet.subnet_c.id}"
  route_table_id = "${aws_route_table.main.id}"
}

resource "aws_security_group" "alb" {
  name = "alb-security-group"
  description = "alb-security-group"
  vpc_id = "${aws_vpc.vpc.id}"

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

resource "aws_security_group_rule" "alb" {
  security_group_id = "${aws_security_group.alb.id}"
  type = "ingress"
  from_port = 80
  to_port = 80
  protocol = "tcp"

  cidr_blocks = ["0.0.0.0/0"]  
}

resource "aws_lb" "main" {

  load_balancer_type = "application"
  name = "handson"

  security_groups = [ "${aws_security_group.alb.id}" ]
  subnets = [ "${aws_subnet.subnet_a.id}","${aws_subnet.subnet_b.id}","${aws_subnet.subnet_c.id}" ]
  
}

resource "aws_lb_listener" "main"{
  port = "80"
  protocol = "HTTP"

  load_balancer_arn = "${aws_lb.main.arn}"

  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      status_code = "200"
      message_body = "ok"
    }
  }
}

resource "aws_ecs_task_definition" "main"{
  family = "handson"
  requires_compatibilities = [ "FARGATE" ]

  cpu = "256"
  memory = "512"

  network_mode = "awsvpc"

  container_definitions = <<EOL
  [
    {
      "name": "nginx",
      "image": "nginx:1.14",
      "portMappings": [
        {
        "containerPort": 80,
        "hostPort": 80
        }
      ]
    }
  ]
  EOL
}

//cluster
resource "aws_ecs_cluster" "main"{
  name = "handson"
}

resource "aws_lb_target_group" "main"{
  name = "handson"

  vpc_id = "${aws_vpc.vpc.id}"

  port = 80
  protocol = "HTTP"
  target_type = "ip"

  health_check {
    port = 80
    path = "/"
  }
}

resource "aws_lb_listener_rule" "main" {

  listener_arn = "${aws_lb_listener.main.arn}"

  action {
    type = "forward"
    target_group_arn = "${aws_lb_target_group.main.arn}"
  }

  condition {
    path_pattern{
      values = ["*"]    
    }
  }
}

resource "aws_security_group" "ecs" {
  name = "handson-ecs"
  description = "handson ecs"

  vpc_id = "${aws_vpc.vpc.id}"

   egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "handson-ecs"
  }
}

resource "aws_security_group_rule" "ecs" {
  security_group_id = "${aws_security_group.ecs.id}"

  # インターネットからセキュリティグループ内のリソースへのアクセス許可設定
  type = "ingress"

  # TCPでの80ポートへのアクセスを許可する
  from_port = 80
  to_port   = 80
  protocol  = "tcp"

  # 同一VPC内からのアクセスのみ許可
  cidr_blocks = ["10.0.0.0/16"]
}
resource "aws_ecs_service" "main" {
  name = "handson"

  # 依存関係の記述。
  # "aws_lb_listener_rule.main" リソースの作成が完了するのを待ってから当該リソースの作成を開始する。
  # "depends_on" は "aws_ecs_service" リソース専用のプロパティではなく、Terraformのシンタックスのため他の"resource"でも使用可能
  depends_on = ["aws_lb_listener_rule.main"]

  # 当該ECSサービスを配置するECSクラスターの指定
  cluster = "${aws_ecs_cluster.main.name}"

  # データプレーンとしてFargateを使用する
  launch_type = "FARGATE"

  # ECSタスクの起動数を定義
  desired_count = "1"

  # 起動するECSタスクのタスク定義
  task_definition = "${aws_ecs_task_definition.main.arn}"

  network_configuration {
    subnets         = ["${aws_subnet.subnet_a.id}", "${aws_subnet.subnet_b.id}", "${aws_subnet.subnet_c.id}"]
    # タスクに紐付けるセキュリティグループ
    security_groups = ["${aws_security_group.ecs.id}"]
  }
  load_balancer {
    target_group_arn = "${aws_lb_target_group.main.arn}"
    container_name = "nginx"
    container_port = "80"
  }
}
