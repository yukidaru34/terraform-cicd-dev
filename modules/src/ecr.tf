# ECRリポジトリ
resource "aws_ecr_repository" "main" {
  name                 = "ectr-dev-i231-sample"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}