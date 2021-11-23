terraform {
  source = "../../../modules//cluster"
}

include {
  path = find_in_parent_folders()
}

dependency "init" {
    config_path = "../init"
    mock_outputs = {
      ecr_repository_url = "000000000000.dkr.ecr.eu-central-1.amazonaws.com/my-app"
  }
}

inputs = {
    ecr_repository_url = dependency.init.outputs.ecr_repository_url
  }