terraform {
  source = "../../../modules//codebuild"
}

include {
  path = find_in_parent_folders()
}

dependency "cluster" {
  config_path = "../cluster"
  skip_outputs = true
}

locals {
  secrets = read_terragrunt_config(find_in_parent_folders("secrets.hcl"))
}

inputs = merge (
  local.secrets.inputs,
  {
  build_spec_file = "proveiders/dev/buildspec.yml"
}
)