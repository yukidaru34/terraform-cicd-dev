terraform {
  required_version = "1.7.4"

  backend "s3" {
    bucket = "sample-terraform-1"
    key    = "resources.shd.src.tfstate"
    region = "ap-northeast-1"
  }
}

