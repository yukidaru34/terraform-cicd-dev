resource "aws_ssm_parameter" "github_pat" {
  name  = "PAT"
  type  = "SecureString"
  value = "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"
}