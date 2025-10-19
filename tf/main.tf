provider "aws" {
  region = "eu-north-1" # Changeable
}


# Find Default VPC
data "aws_vpc" "default" {
  default = true
}

# Find Default Subnets (one from each AZ)
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

resource "aws_instance" "instance-1" {
  ami           = "ami-0854d4f8e4bd6b834" # Amazon Linux 2023 (kernel-6.1) # Changeable
  instance_type = "t3.micro"              # t3 Micro Instance  (Free tier eligible) # Changeable

  vpc_security_group_ids = [aws_security_group.ec2_sg.id]
  count                  = 4 # Instance number
  user_data              = templatefile("${path.module}/user_data.sh", {})

  tags = {
    Name = "instance-${count.index + 1}" # Name of the instance
  }
}


# Create a security group for EC2 Instances
resource "aws_security_group" "ec2_sg" {
  name_prefix = "ec2-sg-allow-all-traffic"
  description = "Allow SSH and HTTP access"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "ec2-sg" }
}

# Create a security group for ALB
resource "aws_security_group" "alb_sg" {
  name        = "alb-sg"
  description = "Allow HTTP inbound from anywhere"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "alb-sg" }
}

# Create a target group for ALB
resource "aws_lb_target_group" "alb_tg" {
  name     = "alb-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default.id
  health_check {
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

# Attach EC2 instances to Target Group
resource "aws_lb_target_group_attachment" "web_attachment" {
  count            = length(aws_instance.instance-1)
  target_group_arn = aws_lb_target_group.alb_tg.arn
  target_id        = aws_instance.instance-1[count.index].id
  port             = 80
}


resource "aws_lb" "web_alb" {
  name               = "web-alb"
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets = [
    data.aws_subnets.default.ids[0],
    data.aws_subnets.default.ids[1]
  ]

  tags = {
    Name = "web-alb"
  }
}


resource "aws_lb_listener" "web_listener" {
  load_balancer_arn = aws_lb.web_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb_tg.arn
  }
}

output "alb_dns_name" {
  value = aws_lb.web_alb.dns_name
}
