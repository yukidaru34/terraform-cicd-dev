resource "aws_ecs_cluster" "main" {
  name = "main-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

resource "aws_ecs_service" "api" {
    name = "main-service-api"
    cluster = aws_ecs_cluster.main.id
}

resource "aws_ecs_service" "fornt" {
    name = "main-service-front"
    cluster = aws_ecs_cluster.main.id
}

//フロントエンド用のタスク定義
resource "aws_ecs_task_definition" "api" {
  family = "api"
  container_definitions = 
}

//サーバサイド用のタスク定義
resource "aws_ecs_task_definition" "front" {
  family = "front"
  container_definitions = 
}