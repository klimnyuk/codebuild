data "aws_caller_identity" "current" {}

resource "null_resource" "docker" {
  provisioner "local-exec" {
    command     = "build.sh"
    interpreter = ["bash"]
    working_dir = var.working_dir
    environment = {
      image_url = local.image_url
      id        = data.aws_caller_identity.current.account_id
      AWS_REGION = var.region
      tag       = var.tag
    }
  }
}

resource "aws_ecr_repository" "demo_repository" {
  name = format("%s-%s", var.app_name, var.env)
}

locals {
  image_url = format("%s.%s.%s.%s/%s-%s", data.aws_caller_identity.current.account_id, "dkr.ecr", var.region, "amazonaws.com", var.app_name, var.env)
}