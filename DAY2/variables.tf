# ---------- Global ----------
variable "aws_region" {
  description = "AWS region to deploy resources in"
  type        = string
}

# ---------- EC2 Configuration ----------
variable "ami" {
  description = "AMI ID for EC2 instance"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
}

variable "key_name" {
  description = "Key pair name to SSH into EC2 instance"
  type        = string
}

variable "instance_name" {
  description = "Name tag for the EC2 instance"
  type        = string
}

/*variable "subnet_id" {
  description = "Subnet ID where the EC2 instance will be launched"
  type        = string
}
*/
# ---------- Networking ----------
variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "public_subnet1_cidr" {
  description = "CIDR block for public subnet 1"
  type        = string
}

variable "public_subnet2_cidr" {
  description = "CIDR block for public subnet 2"
  type        = string
}

variable "private_subnet1_cidr" {
  description = "CIDR block for private subnet 1"
  type        = string
}

variable "private_subnet2_cidr" {
  description = "CIDR block for private subnet 2"
  type        = string
}

# ---------- Availability Zones ----------
variable "availability_zone1" {
  description = "First availability zone (e.g., ap-south-1a)"
  type        = string
}

variable "availability_zone2" {
  description = "Second availability zone (e.g., ap-south-1b)"
  type        = string
}
