data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

locals {
  user_data = <<-EOT
    #!/bin/bash
    set -eux
    if command -v apt-get >/dev/null 2>&1; then
      export DEBIAN_FRONTEND=noninteractive
      apt-get update -y
      apt-get install -y apache2
      PKG=apache2
    else
      yum install -y httpd || dnf install -y httpd
      PKG=httpd
    fi
    systemctl enable --now "$PKG"
    echo "<html><body><h1>Apache on $(hostname)</h1></body></html>" > /var/www/html/index.html
  EOT
}

resource "aws_security_group" "instances" {
  name        = "SG_CMD521_Instances"
  description = "Security group for CMD521 EC2 instances behind ALB"

  vpc_id = data.aws_vpc.default.id

  tags = merge(var.common_tags, {
    Name = "SG_CMD521_Instances"
  })
}

resource "aws_security_group_rule" "instances_ingress" {
  for_each = {
    "ssh"  = { from_port = 22, to_port = 22, protocol = "tcp", description = "SSH access" }
    "http" = { from_port = 80, to_port = 80, protocol = "tcp", description = "HTTP access" }
    "icmp" = { from_port = -1, to_port = -1, protocol = "icmp", description = "ICMP ping" }
  }

  type              = "ingress"
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  protocol          = each.value.protocol
  cidr_blocks       = ["0.0.0.0/0"]
  description       = each.value.description
  security_group_id = aws_security_group.instances.id
}

resource "aws_security_group_rule" "instances_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.instances.id
}

resource "aws_instance" "primary" {
  ami                         = var.aws_image_id
  instance_type               = var.aws_instance_type
  key_name                    = var.aws_key_name
  associate_public_ip_address = true
  user_data                   = local.user_data

  ebs_block_device {
    device_name = "/dev/sda1"
    volume_size = 20
    volume_type = "gp3"

    tags = {
      Name = "RootVolume"
    }
  }

  vpc_security_group_ids = [aws_security_group.instances.id]

  tags = merge(var.common_tags, {
    Name = "Ubuntu Apache"
  })
}

resource "aws_instance" "secondary" {
  ami                         = var.aws_image_id_2
  instance_type               = var.aws_instance_type
  key_name                    = var.aws_key_name
  associate_public_ip_address = true
  user_data                   = local.user_data

  ebs_block_device {
    device_name = "/dev/sda1"
    volume_size = 20
    volume_type = "gp3"

    tags = {
      Name = "RootVolume"
    }
  }

  vpc_security_group_ids = [aws_security_group.instances.id]

  tags = merge(var.common_tags, {
    Name = "Amazon Linux HTTPD"
  })
}

resource "aws_security_group" "alb" {
  name        = "SG_CMD521_ALB"
  description = "Security group for CMD521 Application Load Balancer"

  vpc_id = data.aws_vpc.default.id

  tags = merge(var.common_tags, {
    Name = "SG_CMD521_ALB"
  })
}

resource "aws_security_group_rule" "alb_ingress_http" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "HTTP access from anywhere"
  security_group_id = aws_security_group.alb.id
}

resource "aws_security_group_rule" "alb_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.alb.id
}

resource "aws_lb" "this" {
  name               = var.alb_name
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = data.aws_subnets.default.ids

  tags = merge(var.common_tags, {
    Name = var.alb_name
  })
}

resource "aws_lb_target_group" "this" {
  name     = "${var.alb_name}-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default.id

  health_check {
    enabled             = true
    path                = var.alb_health_check_path
    port                = "traffic-port"
    protocol            = "HTTP"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 15
  }

  tags = merge(var.common_tags, {
    Name = "${var.alb_name}-tg"
  })
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.arn
  }
}

resource "aws_lb_target_group_attachment" "primary" {
  target_group_arn = aws_lb_target_group.this.arn
  target_id        = aws_instance.primary.id
  port             = 80
}

resource "aws_lb_target_group_attachment" "secondary" {
  target_group_arn = aws_lb_target_group.this.arn
  target_id        = aws_instance.secondary.id
  port             = 80
}
