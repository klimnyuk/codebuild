provider "aws" {
  region  = var.region
}

terraform {
  backend "s3" {}
}

output "ecr_repository_url" {
  value = aws_ecr_repository.demo_repository.repository_url
}