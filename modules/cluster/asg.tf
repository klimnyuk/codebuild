resource "aws_autoscaling_group" "my_ASG" {
  name                      = "my_ASG"
  vpc_zone_identifier       = aws_subnet.private.*.id
  launch_configuration      = aws_launch_configuration.ecs_launch_config.name
  target_group_arns         = [aws_alb_target_group.asg.arn]
  min_size                  = var.zones_count
  max_size                  = var.zones_count * 2
  //desired_capacity          = var.zones_count + 1
  health_check_grace_period = 20
  health_check_type         = "EC2"

  protect_from_scale_in = false
  
  lifecycle {
    create_before_destroy = true
     }

  tag {
    key                 = "AmazonECSManaged"
    value               = "ecs"
    propagate_at_launch = true
  }
}

resource "aws_launch_configuration" "ecs_launch_config" {
  image_id             = var.ami_id
  iam_instance_profile = aws_iam_instance_profile.ecs_agent.name
  security_groups      = [aws_security_group.my_SG.id]
  user_data            = "#!/bin/bash\necho ECS_CLUSTER=my-cluster >> /etc/ecs/ecs.config"
  instance_type        = "t2.micro"
//  key_name             = "test"

lifecycle {
    create_before_destroy = true
  }
}