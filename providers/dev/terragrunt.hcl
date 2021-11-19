locals {
    app_name = "my-app"
    env = "dev"
    region = "eu-central-1"
    tag = "v0.0"
    profile = "default"
    zones_count = "2"
}

inputs = {
    app_name = local.app_name
    env = local.env
    region = local.region
    tag = local.tag
    profile = local.profile
    zones_count = local.zones_count
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
