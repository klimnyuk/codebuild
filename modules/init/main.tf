provider "aws" {
  region  = var.region
}

terraform {
  backend "s3" {}
  required_providers {
    aws = {
      version = "~> 3.35"
    }
  }
}

output "ecr_repository_url" {
  value = aws_ecr_repository.demo_repository.repository_url
}