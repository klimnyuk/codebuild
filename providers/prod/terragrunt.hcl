locals {
    app_name = "my-app"
    env = "prod"
    region = "eu-west-3"
    tag = "v0.0"
    profile = "default"
    zones_count = "3"
    repository = "https://github.com/klimnyuk/codebuild"
    ami_id = "ami-0bce8e5f8fd912af2"
}

inputs = {
    app_name = local.app_name
    env = local.env
    region = local.region
    tag = local.tag
    profile = local.profile
    zones_count = local.zones_count
    repository = local.repository
    ami_id = local.ami_id
}

remote_state {
  backend = "s3"

  config = {
    encrypt        = true
    bucket         = format("%s-%s-%s", local.app_name, local.env, local.region)
    key            = format("%s/terraform.tfstate", path_relative_to_include())
    region         = local.region
    dynamodb_table = format("tflock-%s-%s-%s", local.env, local.app_name, local.region)
    profile        = local.profile
  }
}
