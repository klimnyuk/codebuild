provider "aws" {
  region = "eu-central-1"
}
data "aws_region" "current" {}
data "aws_caller_identity" "current_identity" {}

resource "null_resource" "import_source_credentials" {
    provisioner "local-exec" {
    command = "aws --region ${data.aws_region.current.name} codebuild import-source-credentials --token ${var.github_oauth_token} --server-type GITHUB --auth-type PERSONAL_ACCESS_TOKEN"
  }
}

resource "aws_codebuild_project" "example" {
  name          = "test-project"
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
    //image_pull_credentials_type = "CODEBUILD"
    privileged_mode = true


   /* environment_variable {
      name  = "SOME_KEY1"
      value = "SOME_VALUE1"
    }*/
  }

  source {
    type            = "GITHUB"
    location        = "https://github.com/klimnyuk/codebuild.git"
    git_clone_depth = 1
    buildspec = "buildspec.yml"
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
 /* filter_group {
    filter {
      type    = "EVENT"
      pattern = "PUSH"
    }

    filter {
      type    = "HEAD_REF"
      pattern = "master"
    }
  }*/
}
resource "aws_iam_role" "example" {
  name = "example"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "codebuild.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "example" {
  role = aws_iam_role.example.name

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Resource": [
        "*"
      ],
      "Action": [
        "ec2:*",
        "logs:*",
        "iam:*",
        "ecs:*",
        "ecr:*"
      ]
    }
  ]
}
POLICY
}