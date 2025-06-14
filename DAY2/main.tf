# ---------- Provider ----------
provider "aws" {
  region = var.aws_region
}

# ---------- VPC ----------
resource "aws_vpc" "aws_vpc" {
  cidr_block = var.vpc_cidr
  tags = {
    Name = "aws_vpc"
  }
}

# ---------- Internet Gateway ----------
resource "aws_internet_gateway" "myig" {
  vpc_id = aws_vpc.aws_vpc.id
  tags = {
    Name = "myig"
  }
}

# ---------- Subnets ----------
resource "aws_subnet" "public_subnet1" {
  vpc_id                  = aws_vpc.aws_vpc.id
  cidr_block              = var.public_subnet1_cidr
  availability_zone       = var.availability_zone1
  map_public_ip_on_launch = true
  tags = {
    Name = "public_subnet1"
  }
}

resource "aws_subnet" "public_subnet2" {
  vpc_id                  = aws_vpc.aws_vpc.id
  cidr_block              = var.public_subnet2_cidr
  availability_zone       = var.availability_zone2
  map_public_ip_on_launch = true
  tags = {
    Name = "public_subnet2"
  }
}

resource "aws_subnet" "private_subnet1" {
  vpc_id            = aws_vpc.aws_vpc.id
  cidr_block        = var.private_subnet1_cidr
  availability_zone = var.availability_zone1
  tags = {
    Name = "private_subnet1"
  }
}

resource "aws_subnet" "private_subnet2" {
  vpc_id            = aws_vpc.aws_vpc.id
  cidr_block        = var.private_subnet2_cidr
  availability_zone = var.availability_zone2
  tags = {
    Name = "private_subnet2"
  }
}

# ---------- NAT Gateway ----------
resource "aws_eip" "nat_eip" {
  domain = "vpc"
  tags = {
    Name = "nat-eip"
  }
}

resource "aws_nat_gateway" "nat_gateway" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_subnet1.id
  depends_on    = [aws_internet_gateway.myig]
  tags = {
    Name = "nat_gateway"
  }
}

# ---------- Route Tables ----------
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.aws_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.myig.id
  }
  tags = {
    Name = "public-route-table"
  }
}

resource "aws_route_table_association" "public_assoc" {
  route_table_id = aws_route_table.public_rt.id
  subnet_id      = aws_subnet.public_subnet1.id
}

resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.aws_vpc.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gateway.id
  }
  tags = {
    Name = "private-route-table"
  }
}

resource "aws_route_table_association" "private_assoc" {
  route_table_id = aws_route_table.private_rt.id
  subnet_id      = aws_subnet.private_subnet1.id
}

# ---------- Security Groups ----------
resource "aws_security_group" "pub_sg" {
  name        = "pub_sg"
  description = "Allow web & SSH traffic from anywhere"
  vpc_id      = aws_vpc.aws_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "pvt_sg" {
  name        = "pvt_sg"
  description = "Allow traffic from public subnets"
  vpc_id      = aws_vpc.aws_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.public_subnet1_cidr, var.public_subnet2_cidr]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.public_subnet1_cidr, var.public_subnet2_cidr]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.public_subnet1_cidr, var.public_subnet2_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ---------- EC2 Instances ----------
resource "aws_instance" "pub_ec2" {
  ami                         = var.ami
  instance_type               = var.instance_type
  key_name                    = var.key_name
  subnet_id                   = aws_subnet.public_subnet1.id
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.pub_sg.id]

  tags = {
    Name = "${var.instance_name}-public"
  }
}

resource "aws_instance" "pvt_ec2" {
  ami                         = var.ami
  instance_type               = var.instance_type
  key_name                    = var.key_name
  subnet_id                   = aws_subnet.private_subnet1.id
  associate_public_ip_address = false
  vpc_security_group_ids      = [aws_security_group.pvt_sg.id]

  tags = {
    Name = "${var.instance_name}-private"
  }
}


# ---------- Create AMI from Private Instance ----------
/*resource "aws_ami_from_instance" "pvt_ec2_ami" {
  name               = "${var.instance_name}-custom-ami"
  source_instance_id = aws_instance.pvt_ec2.id
  depends_on         = [aws_instance.pvt_ec2]
}

# ---------- Launch Template ----------
resource "aws_launch_template" "my_lt" {
  name_prefix   = "lt-${var.instance_name}-"
  image_id      = aws_ami_from_instance.pvt_ec2_ami.id
  instance_type = var.instance_type
  key_name      = var.key_name

  vpc_security_group_ids = [aws_security_group.pvt_sg.id]

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${var.instance_name}-lt-instance"
    }
  }
}

# ---------- Target Group ----------
resource "aws_lb_target_group" "my_tg" {
  name     = "${var.instance_name}-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.aws_vpc.id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 3
    unhealthy_threshold = 2
  }
}

# ---------- Application Load Balancer ----------
resource "aws_lb" "my_alb" {
  name               = "${var.instance_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.pub_sg.id]
  subnets            = [aws_subnet.public_subnet1.id, aws_subnet.public_subnet2.id]

  tags = {
    Name = "${var.instance_name}-alb"
  }
}

resource "aws_lb_listener" "alb_listener" {
  load_balancer_arn = aws_lb.my_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.my_tg.arn
  }
}

# ---------- Auto Scaling Group ----------
resource "aws_autoscaling_group" "my_asg" {
  name                      = "${var.instance_name}-asg"
  desired_capacity          = 1
  max_size                  = 3
  min_size                  = 1
  vpc_zone_identifier       = [aws_subnet.private_subnet1.id, aws_subnet.private_subnet2.id]
  target_group_arns         = [aws_lb_target_group.my_tg.arn]
  health_check_type         = "EC2"
  health_check_grace_period = 300

  launch_template {
    id      = aws_launch_template.my_lt.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${var.instance_name}-asg-instance"
    propagate_at_launch = true
  }

  depends_on = [aws_lb_listener.alb_listener]
}
*/

