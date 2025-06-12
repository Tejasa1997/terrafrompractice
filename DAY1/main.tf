# VPC
resource "aws_vpc" "aws_vpc" {

  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "aws_vpc"
  }

}

# Internet Gateway
resource "aws_internet_gateway" "myig" {

  vpc_id = aws_vpc.aws_vpc.id

  tags = {
    Name = "myig"

  }

}
# Public Subnet1
resource "aws_subnet" "public_subnet1" {

  vpc_id = aws_vpc.aws_vpc.id

  cidr_block = "10.0.0.0/24"

  map_public_ip_on_launch = true

  availability_zone = "us-west-1b"

  tags = {

    Name = "public_subnet1"
  }
}
# Public Subnet2
resource "aws_subnet" "public_subnet2" {

  vpc_id = aws_vpc.aws_vpc.id

  cidr_block = "10.0.1.0/24"

  availability_zone = "us-west-1c"

  map_public_ip_on_launch = true

  tags = {

    Name = "public_subnet2"
  }
}
# Private Subnet1
resource "aws_subnet" "private_subnet1" {

  vpc_id = aws_vpc.aws_vpc.id

  cidr_block = "10.0.2.0/24"

  availability_zone = "us-west-1b"

  tags = {

    Name = "private_subnet1"
  }
}
# Private Subnet2
resource "aws_subnet" "private_subnet2" {

  vpc_id = aws_vpc.aws_vpc.id

  cidr_block = "10.0.3.0/24"

  availability_zone = "us-west-1c"

  tags = {

    Name = "private_subnet2"
  }
}
# ellastic ip for Nat gateway
resource "aws_eip" "nat_eip" {

  domain = "vpc"

  tags = {

    Name = "nat-eip"

  }
}
# Nat gateway
resource "aws_nat_gateway" "nat_gateway" {

  allocation_id = aws_eip.nat_eip.id

  subnet_id = aws_subnet.public_subnet1.id

  tags = {

    Name = "nat_gateway"

  }

  depends_on = [aws_internet_gateway.myig]

}
# Route table for public subnet
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
# Route table for private subnet
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
# Security group creation 
resource "aws_security_group" "pub_sg" {

  tags = {
    Name = "pub_sg"
  }

  description = "allow TLS traffics"
  vpc_id      = aws_vpc.aws_vpc.id

  ingress {
    description = "Access from HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Access from SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Access from HTTPS"
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

  tags = {
    Name = "pvt_sg"
  }

  description = "allow TLS traffics"
  vpc_id      = aws_vpc.aws_vpc.id

  ingress {
    description = "Access from HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/24", "10.0.1.0/24"]
  }

  ingress {
    description = "Access from SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/24", "10.0.1.0/24"]
  }

  ingress {
    description = "Access from HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/24", "10.0.1.0/24"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
# Public EC2
resource "aws_instance" "pub_ec2" {
  ami                         = "ami-0cbad6815f3a09a6d"
  instance_type               = "t2.micro"
  key_name                    = "my-keypair-tf"
  subnet_id                   = aws_subnet.public_subnet1.id
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.pub_sg.id]


}
# Private EC2
resource "aws_instance" "pvt_ec2" {
  ami                         = "ami-0cbad6815f3a09a6d"
  instance_type               = "t2.micro"
  key_name                    = "my-keypair-tf"
  subnet_id                   = aws_subnet.private_subnet1.id
  associate_public_ip_address = false
  vpc_security_group_ids      = [aws_security_group.pvt_sg.id]


}
# Generate a new private key
#resource "tls_private_key" "my_key" {
# algorithm = "RSA"
#rsa_bits  = 4096
#}

# Create an AWS key pair using the public key
#resource "aws_key_pair" "my_ec2_key" {
# key_name   = "my-keypair-tf"
# public_key = tls_private_key.my_key.public_key_openssh
#}

# Save private key locally
#resource "local_file" "private_key_pem" {
# content         = tls_private_key.my_key.private_key_pem
# filename = "C:/Users/tejas/Downloads/my-keypair-tf.pem"
# file_permission = "0400"
#}
