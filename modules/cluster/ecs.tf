resource "aws_ecs_cluster" "ecs_cluster" {
  name               = "my-cluster"
  capacity_providers = [aws_ecs_capacity_provider.test.name]
  
}

resource "aws_ecs_task_definition" "service" {
  family = "service"
  container_definitions = jsonencode([
    {
      name          = "worker"
      image         = format("%s:%s", var.ecr_repository_url, var.tag)
      cpu           = var.fargate_cpu
      memory        = var.fargate_memory
      essential     = true
      portMappings  = [
        {
          containerPort = var.port
          hostPort      = var.port
        }
      ]
    }
  ])
}

resource "aws_ecs_service" "worker" {
  name                                = "worker"
  cluster                             = aws_ecs_cluster.ecs_cluster.id
  task_definition                     = aws_ecs_task_definition.service.arn
  desired_count                       = var.zones_count
  deployment_minimum_healthy_percent  = 90

  capacity_provider_strategy {
  capacity_provider = aws_ecs_capacity_provider.test.name
  weight = 1
  base   = 0
}
}

resource "aws_ecs_capacity_provider" "test" {
  name = "test"
  
  auto_scaling_group_provider {
    auto_scaling_group_arn         = aws_autoscaling_group.my_ASG.arn
    managed_termination_protection = "DISABLED"

    managed_scaling {
      maximum_scaling_step_size = var.zones_count * 2
      minimum_scaling_step_size = var.zones_count
      status                    = "ENABLED"
      target_capacity           = 100
    }
  }
}