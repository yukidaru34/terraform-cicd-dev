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
resource "aws_iam_policy" "ssm_policy" {
  name        = "ssm-policy"
  description = "Allows CodeBuild to access SSM parameters"
  policy      = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Action": "ssm:GetParameters",
        "Resource": "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ssm_policy_attachment" {
  policy_arn = aws_iam_policy.ssm_policy.arn
  role       = aws_iam_role.codebuild_role.name
}
#policyのアタッチ
resource "aws_iam_role_policy_attachment" "codebuild_policy" {
  role       = aws_iam_role.codebuild_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSCodeBuildAdminAccess"

}
resource "aws_iam_role_policy" "codebuild_cloudwatch_policy" {
  name = "codebuild_cloudwatch_policy"
  role = aws_iam_role.codebuild_role.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "*"
    }
  ]
}
EOF
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
    # # TODO
    # auth {
    #   type     = "OAUTH"
    #   resource =  "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"
    #   # // replace thiss with your GitHub personal access token
    # }
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