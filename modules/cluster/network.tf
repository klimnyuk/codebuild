data "aws_availability_zones" "AZ" {}

resource "aws_vpc" "my_VPC" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "my_VPC"
  }
}

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