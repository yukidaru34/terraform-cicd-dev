#Codebuild用IAMロール
resource "aws_iam_role" "codebuild_role" {
  name = "codebuild-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "codebuild.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

#policyのアタッチ
resource "aws_iam_role_policy_attachment" "codebuild_policy" {
  role       = aws_iam_role.codebuild_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSCodeBuildAdminAccess"
}

#codebuild
resource "aws_codebuild_project" "codebuild_project" {
  name          = "codebuild-project"
  description   = "CodeBuild project created by Terraform"
  service_role  = aws_iam_role.codebuild_role.arn
  build_timeout = "5"
  queued_timeout = "5"

  source {
    type            = "GITHUB"
    location        = "https://github.com/yuuking0304/sample-app.git"
    git_clone_depth = 1
    buildspec       = "buildspec.yml"
  }

  artifacts {
    type = "NO_ARTIFACTS"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:4.0"
    type                        = "LINUX_CONTAINER"
    privileged_mode             = true
  }
}