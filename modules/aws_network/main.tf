#TO DO = Define the Provider
#TO DO = Define Availability Zone
#TO DO = Define VPC and Subnets
#TO DO = Define Internate Gateway
#TO DO = Define Network Gateway
#TO DO = Define Elastic IP
#TO DO = Define Route Tables
#TO DO = Associate Route tables with Subnets
#TO DO = Define Security Groups
#TO DO = Create Bastion VM
#TO DO = Define Security Group for Bastion
#TO DO = Define Auto Scaling Group
#TO DO = Define Scaling Policies
#TO DO = Define Launch Configuration
#TO DO = Configuration  for NLB
#TO DO = Target group for ALB
#TO DO = Define Internal Security Group

# Define the provider
provider "aws" {
  region = "us-east-1"
}

# Data source for availability zones in us-east-1
data "aws_availability_zones" "available" {
  state = "available"
}

# Define VPC and Subnets
resource "aws_vpc" "vpc" {
  cidr_block = "10.${var.environment == "Development" ? 100 : var.environment == "Staging" ? 200 : 250}.0.0/16"
  tags = {
    Name = "${var.group_name}-${var.environment}-VPC"
  }
}

resource "aws_subnet" "public_subnet" {
  count                   = 3
  cidr_block              = "10.${var.environment == "Development" ? 100 : var.environment == "Staging" ? 200 : 250}.${count.index}.0/24"
  vpc_id                  = aws_vpc.vpc.id
  availability_zone       = "${data.aws_availability_zones.available.names[count.index + 1]}"
  map_public_ip_on_launch = true
  tags = {
    Name = "${var.group_name}-${var.environment}-Public-Subnet-${count.index + 1}"
  }
}

resource "aws_subnet" "private_subnet" {
  count                   = 3
  cidr_block              = "10.${var.environment == "Development" ? 100 : var.environment == "Staging" ? 200 : 250}.${3 + count.index}.0/24"
  vpc_id                  = aws_vpc.vpc.id
  availability_zone       = "${data.aws_availability_zones.available.names[count.index + 1]}"
  map_public_ip_on_launch = true
  tags = {
    Name = "${var.group_name}-${var.environment}-Private-Subnet-${count.index + 1}"
  }
}

# Define Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = "${var.group_name}-${var.environment}-IGW"
  }
}

# Define Network Gateway
resource "aws_nat_gateway" "ngw" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_subnet[1].id

  tags = {
    Name = "${var.group_name}-${var.environment}-NGW"
  }

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.igw]
}

# Define Elastic IP
resource "aws_eip" "nat_eip" {
  # instance = aws_instance.web.id
  vpc      = true
  
  tags = {
    Name = "${var.group_name}-${var.environment}-EIP"
  }
}

# Define Route Tables
resource "aws_route_table" "public_route_table" {
  count  = 3
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Name = "${var.group_name}-${var.environment}-Public-Route-Table-${count.index + 1}"
  }
}

resource "aws_route_table" "private_route_table" {
  count  = 3
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.ngw.id
  }
  tags = {
    Name = "${var.group_name}-${var.environment}-Private-Route-Table-${count.index + 1}"
  }
}

# Associate Route Tables with Subnets
resource "aws_route_table_association" "public_route_table_association" {
  count          = 3
  subnet_id      = aws_subnet.public_subnet[count.index].id
  route_table_id = aws_route_table.public_route_table[count.index].id
}

resource "aws_route_table_association" "private_route_table_association" {
  count          = 3
  subnet_id      = aws_subnet.private_subnet[count.index].id
  route_table_id = aws_route_table.private_route_table[count.index].id
}

# Define Security Group
resource "aws_security_group" "web_server_sg" {
  name_prefix = "${var.group_name}-${var.environment}-Web-Server-SG"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  
  tags = {
    Name = "${var.group_name}-${var.environment}-SecurityGroup"
  }
}

# Create Bastion VM
resource "aws_instance" "bastion" {
  ami                         = var.ami
  instance_type               = "t2.micro"
  key_name                    = "bastion_key"
  subnet_id                   = aws_subnet.public_subnet[0].id
  security_groups             = [aws_security_group.web_server_sg_bastion.id]
  associate_public_ip_address = true
  user_data                   = <<EOF
    #!/bin/bash
    yum -y update
    yum -y install httpd
    echo "Hello, World!" > /var/ww/html/index.html
    # nohup python -m SimpleHTTPServer 80 &
    sudo systemctl httpd start
    sudo systemctl httpd enable
  EOF
  
  root_block_device {
    encrypted = var.environment == "Production" ? true : false
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    "Name" = "${var.group_name}-${var.environment}-Bastion"
  }
}

# Define Security Group for Bastion
resource "aws_security_group" "web_server_sg_bastion" {
  name_prefix = "${var.group_name}-${var.environment}-Web-Server-SG-Bastion"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    from_port     = 22
    to_port       = 22
    protocol      = "tcp"
    # cidr_blocks = [aws_subnet.private_subnet[0].id, aws_subnet.private_subnet[1].id, aws_subnet.private_subnet[2].id]
    # private_cidrs = [for j in range(3): aws_subnet.private_subnet["${j}"].cidr_block]
    # cidr_blocks   = "${concate(private_cidrs, "35.153.70.210/24")}"
    cidr_blocks      = ["0.0.0.0/0"]
  }
  
  ingress {
    from_port     = 80
    to_port       = 80
    protocol      = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }
  
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}


###
resource "aws_instance" "my_amazon" {
  ami                         = var.ami
  instance_type               = var.instance_type
  key_name                    = "access"
  subnet_id                   = aws_subnet.public_subnet[0].id
  security_groups             = [aws_security_group.web_server_sg.id]
  user_data                   = <<EOF
    #!/bin/bash
    yum -y update
    yum -y install httpd
    echo "Hello, World!" > /var/ww/html/index.html
    # nohup python -m SimpleHTTPServer 80 &
    sudo systemctl start httpd
    sudo systemctl enable httpd
  EOF

  root_block_device {
    encrypted = var.environment == "Production" ? true : false
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "${var.group_name}-${var.environment}-Web-Server-ASG"
  }
}
###

# Define Auto Scaling Group
resource "aws_autoscaling_group" "web_server_asg" {
  name                 = "${var.group_name}-${var.environment}-Web-Server-ASG"
  vpc_zone_identifier  = [for j in range(3): aws_subnet.private_subnet["${j}"].id] #aws_subnet.public_subnet[0].id, aws_subnet.public_subnet[1].id, aws_subnet.public_subnet[2].id]
  min_size             = 1
  max_size             = 4
  desired_capacity     = "${var.environment == "Development" ? 2 : 3}"
  launch_configuration = aws_launch_configuration.web_server_lc.name

  tag {
    key                 = "Name"
    value               = "${var.group_name}-${var.environment}-Web-Server-ASG"
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Define Scaling Policies
resource "aws_autoscaling_policy" "scale-out" {
  name               = "scale-out"
  adjustment_type    = "ChangeInCapacity"
  scaling_adjustment = 1
  cooldown           = 300
  policy_type        = "SimpleScaling"
  # alarm_name         = "cpu-greater"
  autoscaling_group_name = "${aws_autoscaling_group.web_server_asg.name}"
}

resource "aws_autoscaling_policy" "scale-in" {
  name               = "scale-in"
  adjustment_type    = "ChangeInCapacity"
  scaling_adjustment = -1
  cooldown           = 300
  policy_type        = "SimpleScaling"
  # alarm_name         = "cpu-less"
  autoscaling_group_name = "${aws_autoscaling_group.web_server_asg.name}"
}

# Define Launch Configuration
resource "aws_launch_configuration" "web_server_lc" {
  name            = "${var.group_name}-${var.environment}-Web-Server-LC"
  image_id        = var.ami
  instance_type   = "${var.environment == "Development" ? "t2.micro" : var.environment == "Staging" ? "t3.small" : "t3.medium"}"
  key_name        = var.key_name
  security_groups = [aws_security_group.web_server_sg.id]
  # associate_public_ip_address = false
  user_data       = <<-EOF
  #!/bin/bash
  echo "Hello, World!" > index.html
  nohup python -m SimpleHTTPServer 80 &
  EOF
}

resource "aws_cloudwatch_metric_alarm" "cpu_greater" {
  alarm_name = "${var.group_name}-${var.environment}-CPU-Greater-Than-10"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods = "2"
  metric_name = "CPUUtilization"
  namespace = "AWS/EC2"
  period = "120"
  statistic = "Average"
  threshold = "10"
  alarm_description = "This metric checks if CPU utilization is greater than or equal to 10%"
  dimensions = {
    AutoScalingGroupName = "${aws_autoscaling_group.web_server_asg.name}"
  }
}

resource "aws_cloudwatch_metric_alarm" "cpu_less" {
  alarm_name = "${var.group_name}-${var.environment}-CPU-Less-Than-5"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods = "2"
  metric_name = "CPUUtilization"
  namespace = "AWS/EC2"
  period = "120"
  statistic = "Average"
  threshold = "5"
  alarm_description = "This metric checks if CPU utilization is less than or equal to 5%"
  dimensions = {
    AutoScalingGroupName = "${aws_autoscaling_group.web_server_asg.name}"
  }
}

resource "aws_elb" "web_server_lb" {
    name            = "${var.group_name}-${var.environment}-Load-Bal"
    security_groups = [aws_security_group.web_server_sg.id]
    subnets         = [for j in range(3): aws_subnet.public_subnet["${j}"].id] #[aws_subnet.public_subnet[0].id, aws_subnet.public_subnet[1].id, aws_subnet.public_subnet[2].id]
  
    listener {
      instance_port     = 80
      instance_protocol = "HTTP"
      lb_port           = 80
      lb_protocol       = "HTTP"
    }
  
    health_check {
      healthy_threshold   = 2
      unhealthy_threshold = 2
      timeout             = 3
      interval            = 30
      target              = "HTTP:80/"
    }
  
    tags = {
      Name = "${var.group_name}-${var.environment}-Load-Balancer"
    }
}

# resource "aws_lb" "internal_lb" {
#     name            = "${var.group_name}-${var.environment}-Internal-LB"
#     internal        = true
#     security_groups = [aws_security_group.internal_lb_sg.id]
#     subnets         = [for j in range(3): aws_subnet.private_subnet["${j}"].id] #[aws_subnet.private_subnet_a.id, aws_subnet.private_subnet_b.id, aws_subnet.private_subnet_c.id]
  
#     load_balancer_type = "network" # for NLB, or "application" for ALB
  
#     # Configuration for NLB
#     depends_on = [
#       aws_lb_target_group.web_server_target_group
#     ]
  
#     # listener {
#     #   port     = 80
#     #   protocol = "HTTP"
  
#     #   default_action {
#     #     type             = "forward"
#     #     target_group_arn = aws_lb_target_group.web_server_target_group.arn
#     #   }
#     # }
  
#     tags = {
#       Name = "${var.group_name}-${var.environment}-Internal-Load-Balancer"
#     }
#   }
  
 resource "aws_lb" "internal_lb" {
  name               = "${var.group_name}-${var.environment}-Internal-LB"
  internal           = true
  load_balancer_type = "network"

  # dynamic "private_subnet" {
  #   for_each = aws_subnet.private_subnet
  #   subnet_mapping {
  #     subnet_id            = aws_subnet.private_subnet.id
  #     private_ipv4_address = "10.${var.environment == "Development" ? 100 : var.environment == "Staging" ? 200 : 250}.${255-each.key}.0"
  #   }
  # }
  
    subnet_mapping {
      subnet_id            = aws_subnet.private_subnet[0].id
      private_ipv4_address = "10.${var.environment == "Development" ? 100 : var.environment == "Staging" ? 200 : 250}.3.10"
    }
    
    subnet_mapping {
      subnet_id            = aws_subnet.private_subnet[1].id
      private_ipv4_address = "10.${var.environment == "Development" ? 100 : var.environment == "Staging" ? 200 : 250}.4.10"
    }
    
    subnet_mapping {
      subnet_id            = aws_subnet.private_subnet[2].id
      private_ipv4_address = "10.${var.environment == "Development" ? 100 : var.environment == "Staging" ? 200 : 250}.5.10"
    }
  
  # Configuration for NLB
  depends_on = [
    aws_lb_target_group.web_server_target_group
  ]
  
  tags = {
    Name = "${var.group_name}-${var.environment}-Internal-Load-Balancer"
  }
}
  
  # Target group for ALB
  resource "aws_lb_target_group" "web_server_target_group" {
    name     = "${var.group_name}-${var.environment}-Web-TG"
    port     = 80
    protocol = "HTTP"
    vpc_id   = aws_vpc.vpc.id
  
    health_check {
      healthy_threshold   = 2
      unhealthy_threshold = 2
      timeout             = 3
      interval            = 30
      path                = "/"
    }
  
    depends_on = [
      aws_security_group.web_server_sg
    ]
}

# Define Internal Security Group
resource "aws_security_group" "internal_lb_sg" {
  name_prefix = "${var.group_name}-${var.environment}-Internal-LB-SG"
  vpc_id = aws_vpc.vpc.id

  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    security_groups = [aws_security_group.web_server_sg.id]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
