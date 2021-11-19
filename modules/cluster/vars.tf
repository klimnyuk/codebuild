variable "region" {}

variable "tag" {
  type    = string
}

variable "zones_count" {}

variable "port" {
  default = 80
}

variable "fargate_memory" {
  default = 256
}

variable "fargate_cpu" {
  default = 128
}

variable "ecr_repository_url" {
  type = string
}