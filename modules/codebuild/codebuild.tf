data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

resource "null_resource" "import_source_credentials" {
    provisioner "local-exec" {
    command = "aws --region ${data.aws_region.current.name} codebuild import-source-credentials --token ${var.github_oauth_token} --server-type GITHUB --auth-type PERSONAL_ACCESS_TOKEN"
  }
}

resource "aws_codebuild_project" "example" {
  name          = "${var.app_name}-${var.env}"
  description   = "test_codebuild_project"
  build_timeout = "5"
  service_role  = aws_iam_role.example.arn

  artifacts {
    type = "NO_ARTIFACTS"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:5.0"
    type                        = "LINUX_CONTAINER"
    privileged_mode = true


    environment_variable {
      name  = "app_name"
      value = "${var.app_name}"
    }
    environment_variable {
      name  = "env"
      value = "${var.env}"
    }
    environment_variable {
      name  = "Account_ID"
      value = "${data.aws_caller_identity.current.account_id}"
    }
  }

  source {
    type                = "GITHUB"
    location            = var.repository
    git_clone_depth     = 1
    buildspec           = var.build_spec_file
    report_build_status = "true"

    git_submodules_config {
      fetch_submodules = true
    }
  }

  source_version = "master"

  /*vpc_config {
    vpc_id = aws_vpc.example.id

    subnets = [
      aws_subnet.example1.id,
      aws_subnet.example2.id,
    ]

    security_group_ids = [
      aws_security_group.example1.id,
      aws_security_group.example2.id,
    ]
  }

  tags = {
    Environment = "Test"
  }*/
}

resource "aws_codebuild_webhook" "example" {
  project_name = aws_codebuild_project.example.name
  build_type   = "BUILD"
}