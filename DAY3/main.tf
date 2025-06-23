provider "aws" {
  region = var.region
}

resource "aws_db_subnet_group" "rds_subnet_group" {
  name       = "rds-subnet-group"
  subnet_ids = var.subnet_ids

  tags = {
    Name = "RDS Subnet Group"
  }
}

output "engine_type" {
  value = var.engine
}


resource "aws_db_instance" "rds_instance" {
  allocated_storage      = var.db_allocated_storage
  engine                 = var.engine
  engine_version         = var.engine_version
  instance_class         = var.db_instance_class
  #name                   = var.db_name
  username               = var.db_username
  password               = var.db_password
  db_subnet_group_name   = aws_db_subnet_group.rds_subnet_group.name
  vpc_security_group_ids = var.vpc_security_group_ids

  skip_final_snapshot = true
  publicly_accessible = false
  multi_az            = false
  storage_encrypted   = true

  tags = {
    Name = "Terraform-RDS"
  }
}
