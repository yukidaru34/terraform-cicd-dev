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
  vpc_id = aws_vpc.vpc.id
  tags = {
    name = "handson"
  }
}

resource "aws_route_table" "main" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
}

resource "aws_security_group" "alb" {
  name = "alb-security-group"
  description = "alb-security-group"
  vpc_id = aws_vpc.vpc.id

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
  name = "handson1"

  security_groups = [ "${aws_security_group.alb.id}" ]
  subnets = [ "${aws_subnet.subnet_a.id}","${aws_subnet.subnet_b.id}","${aws_subnet.subnet_c.id}" ]
  
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

