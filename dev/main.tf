variable "github_pat" {}

module "src_api" {
  source = "../modules/src"
  github_pat = var.github_pat
}
