provider "aws" {
  region = var.region
}

variable "region" {
  default = "eu-central-1"
}

variable "env" {
  type    = string
  default = "dev"
}

variable "app_name" {
  type    = string
  default = "my-app"
}

variable "tag" {
  type    = string
  default = "v0.0"
}

data "aws_caller_identity" "current" {}

resource "null_resource" "docker" {
  provisioner "local-exec" {
    command     = "build.sh"
    interpreter = ["bash"]
    working_dir = "./app"
    environment = {
      ecr_repository_url = local.ecr_repository_url
      id                 = data.aws_caller_identity.current.account_id
      region             = var.region
    }
  }
}

resource "aws_ecr_repository" "demo_repository" {
  name = format("%s-%s", var.app_name, var.env)
}

variable "zones_count" {
  default = 2
}

variable "port" {
  default = 80
}

variable "fargate_memory" {
  default = 256
}

variable "fargate_cpu" {
  default = 128
}

locals {
  ecr_repository_url = format("%s.%s.%s.%s/%s-%s:%s", data.aws_caller_identity.current.account_id, "dkr.ecr", var.region, "amazonaws.com", var.app_name, var.env, var.tag)
}

resource "aws_alb" "my_ALB" {
  name            = "my-ALB"
  subnets         = aws_subnet.public.*.id
  security_groups = [aws_security_group.my_SG.id]
}

resource "aws_alb_listener" "my_loadbalancer_listener" {
  load_balancer_arn = aws_alb.my_ALB.arn
  port              = var.port
  protocol          = "HTTP"
  default_action {
    target_group_arn = aws_alb_target_group.asg.id
    type             = "forward"
  }
}

resource "aws_alb_target_group" "asg" {
  name     = "my-target-group"
  port     = var.port
  protocol = "HTTP"
  vpc_id   = aws_vpc.my_VPC.id
  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 5
    timeout             = 3
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_vpc" "my_VPC" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "my_VPC"
  }
}

data "aws_availability_zones" "AZ" {}

resource "aws_subnet" "public" {
  count                   = var.zones_count
  cidr_block              = cidrsubnet(aws_vpc.my_VPC.cidr_block, 8, count.index)
  availability_zone       = data.aws_availability_zones.AZ.names[count.index]
  vpc_id                  = aws_vpc.my_VPC.id
  map_public_ip_on_launch = true
  tags = {
    Name = "public${count.index + 1}"
  }
}

resource "aws_subnet" "private" {
  count             = var.zones_count
  cidr_block        = cidrsubnet(aws_vpc.my_VPC.cidr_block, 8, count.index + var.zones_count)
  availability_zone = data.aws_availability_zones.AZ.names[count.index]
  vpc_id            = aws_vpc.my_VPC.id

  tags = {
    Name = "private${count.index + 1}"
  }
}

resource "aws_internet_gateway" "my_GW" {
  vpc_id = aws_vpc.my_VPC.id
  tags = {
    Name = "my-internet-gateway"
  }
}

resource "aws_route" "my_route" {
  route_table_id         = aws_vpc.my_VPC.main_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.my_GW.id
}

resource "aws_eip" "gw" {
  count      = var.zones_count
  vpc        = true
  depends_on = [aws_internet_gateway.my_GW]
  tags = {
    Name = "my-EIP"
  }
}

resource "aws_nat_gateway" "my_NAT_gw" {
  count         = var.zones_count
  subnet_id     = element(aws_subnet.public.*.id, count.index)
  allocation_id = element(aws_eip.gw.*.id, count.index)
  tags = {
    Name = "NAT-GW"
  }
}

resource "aws_route_table" "for_private" {
  count  = var.zones_count
  vpc_id = aws_vpc.my_VPC.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = element(aws_nat_gateway.my_NAT_gw.*.id, count.index)
  }
  tags = {
    Name = "for private RT"
  }
}

resource "aws_route_table_association" "private" {
  count          = var.zones_count
  subnet_id      = element(aws_subnet.private.*.id, count.index)
  route_table_id = element(aws_route_table.for_private.*.id, count.index)
}

resource "aws_security_group" "my_SG" {
  name   = "my_SG"
  vpc_id = aws_vpc.my_VPC.id

  ingress {
    protocol    = "tcp"
    from_port   = var.port
    to_port     = var.port
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol    = "tcp"
    from_port   = 22
    to_port     = 22
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

data "aws_iam_policy_document" "ecs_agent" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ecs_agent" {
  name               = "ecs-agent"
  assume_role_policy = data.aws_iam_policy_document.ecs_agent.json
}

resource "aws_iam_role_policy_attachment" "ecs_agent" {
  role       = aws_iam_role.ecs_agent.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_instance_profile" "ecs_agent" {
  name = "ecs-agent"
  role = aws_iam_role.ecs_agent.name
}


resource "aws_ecs_cluster" "ecs_cluster" {
  name               = "my-cluster"
}

resource "aws_ecs_task_definition" "service" {
  family = "service"
  container_definitions = jsonencode([
    {
      name      = "worker"
      image     = local.ecr_repository_url
      cpu       = var.fargate_cpu
      memory    = var.fargate_memory
      essential = true
      portMappings = [
        {
          containerPort = var.port
          hostPort      = var.port
        }
      ]
    }
  ])
}

resource "aws_ecs_service" "worker" {
  name                 = "worker"
  cluster              = aws_ecs_cluster.ecs_cluster.id
  task_definition      = aws_ecs_task_definition.service.arn
  desired_count        = var.zones_count
}

resource "aws_launch_configuration" "ecs_launch_config" {
  image_id             = "ami-088d915ff2a776984"
  iam_instance_profile = aws_iam_instance_profile.ecs_agent.name
  security_groups      = [aws_security_group.my_SG.id]
  user_data            = "#!/bin/bash\necho ECS_CLUSTER=my-cluster >> /etc/ecs/ecs.config"
  instance_type        = "t2.micro"
  key_name             = "test"
}

resource "aws_autoscaling_group" "my_ASG" {
  name                      = "my_ASG"
  vpc_zone_identifier       = aws_subnet.private.*.id
  launch_configuration      = aws_launch_configuration.ecs_launch_config.name
  target_group_arns         = [aws_alb_target_group.asg.arn]
  min_size                  = var.zones_count
  max_size                  = var.zones_count * 2
  desired_capacity          = var.zones_count + 1
  health_check_grace_period = 30
  health_check_type         = "EC2"
}

output "load_balancer_link" {
  value = aws_alb.my_ALB.dns_name
}

terraform {
  backend "s3" {
    bucket = "my-klimnyuk-bucket"
    key    = "codebuild/ec2"
    region = "eu-central-1"
  }
}
