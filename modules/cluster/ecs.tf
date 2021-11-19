resource "aws_ecs_cluster" "ecs_cluster" {
  name               = "my-cluster"
}

resource "aws_ecs_task_definition" "service" {
  family = "service"
  container_definitions = jsonencode([
    {
      name      = "worker"
      image     = format("%s:%s", var.ecr_repository_url, var.tag)
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