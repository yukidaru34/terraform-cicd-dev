provider "aws" {
  version = "3.6.0"
  region  = "ap-northeast-1"
}

provider "github" {
  token = var.github_pat
}