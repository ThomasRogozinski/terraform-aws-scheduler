provider "aws" {
  region = local.region
}

locals {
  region = "ap-southeast-2"
}

data "aws_ami" "ubuntu" {
  most_recent = true
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  owners = ["099720109477"] 
}

# -------------------------------------------------------------------
# vpc and subnets 
# -------------------------------------------------------------------

data "aws_availability_zones" "available" {}

resource "aws_vpc" "this" {
  cidr_block = var.vpc_cidr_block 
}

resource "aws_subnet" "primary" {
  availability_zone = data.aws_availability_zones.available.names[0]
  vpc_id            = aws_vpc.this.id
  cidr_block        = var.vpc_subnet_primary_block
}

resource "aws_subnet" "secondary" {
  availability_zone = data.aws_availability_zones.available.names[1]
  vpc_id            = aws_vpc.this.id
  cidr_block        = var.vpc_subnet_secondary_block
}

resource "aws_db_subnet_group" "rds" {
  name       = "rds-subnet"
  subnet_ids = [aws_subnet.primary.id, aws_subnet.secondary.id]
}

# -------------------------------------------------------------------
# autoscaling groups 
# -------------------------------------------------------------------

resource "aws_launch_configuration" "this" {
  name          = "scheduler-config"
  image_id      = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"
}

resource "aws_autoscaling_group" "asg_dev" {
  name                      = "scheduled-asg-dev-${count.index}"
  count                     = var.asg_dev_count  
  max_size                  = var.cap_dev_count 
  min_size                  = var.cap_dev_count
  desired_capacity          = var.cap_dev_count
  health_check_grace_period = 300
  health_check_type         = "EC2"
  force_delete              = true
  launch_configuration      = aws_launch_configuration.this.name
  vpc_zone_identifier       = [aws_subnet.primary.id]

  tags = [
    {
      key                 = "scheduled-dev"
      value               = "true"
      propagate_at_launch = true
    },
    {
      key                 = "Name"
      value               = "scheduled-asg-dev" 
      propagate_at_launch = true
    }
  ]
}

resource "aws_autoscaling_group" "asg_tst" {
  name                      = "scheduled-asg-tst-${count.index}"
  count                     = var.asg_tst_count  
  max_size                  = var.cap_tst_count 
  min_size                  = var.cap_tst_count
  desired_capacity          = var.cap_tst_count
  health_check_grace_period = 300
  health_check_type         = "EC2"
  force_delete              = true
  launch_configuration      = aws_launch_configuration.this.name
  vpc_zone_identifier       = [aws_subnet.primary.id]

  tags = [
    {
      key                 = "scheduled-tst"
      value               = "true"
      propagate_at_launch = true
    },
    {
      key                 = "Name"
      value               = "scheduled-asg-tst" 
      propagate_at_launch = true
    }
  ]
}

resource "aws_autoscaling_group" "asg_prd" {
  name                      = "scheduled-asg-prd-${count.index}"
  count                     = var.asg_prd_count  
  max_size                  = var.cap_prd_count 
  min_size                  = var.cap_prd_count
  desired_capacity          = var.cap_prd_count
  health_check_grace_period = 300
  health_check_type         = "EC2"
  force_delete              = true
  launch_configuration      = aws_launch_configuration.this.name
  vpc_zone_identifier       = [aws_subnet.primary.id]

  tags = [
    {
      key                 = "scheduled-prd"
      value               = "false"
      propagate_at_launch = true
    },
    {
      key                 = "Name"
      value               = "scheduled-asg-prd" 
      propagate_at_launch = true
    }
  ]
}

# -------------------------------------------------------------------
# ec2 instances 
# -------------------------------------------------------------------

resource "aws_instance" "ec2_dev" {
  count         = var.ec2_dev_count 
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"
  tags = {
    Name              = "scheduled-ec2-dev"
    scheduled-dev    = "true"
  }
}

resource "aws_instance" "ec2_tst" {
  count         = var.ec2_tst_count 
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"
  tags = {
    Name              = "scheduled-ec2-tst"
    scheduled-tst     = "true"
  }
}

resource "aws_instance" "ec2_prd" {
  count         = var.ec2_prd_count 
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"
  tags = {
    Name              = "scheduled-ec2-prd"
    scheduled-prd      = "false"
  }
}

# -------------------------------------------------------------------
# rds instances 
# -------------------------------------------------------------------

resource "aws_db_instance" "rds_dev" {
  count                = var.rds_dev_count
  identifier           = "scheduled-rds-dev"
  db_subnet_group_name = aws_db_subnet_group.rds.id
  username             = "user"
  password             = "password"
  engine               = "mariadb"
  engine_version       = "10.5"
  instance_class       = "db.t3.micro"
  allocated_storage    = 10
  storage_type         = "gp2"
  skip_final_snapshot  = "true"

  tags = {
    Name              = "scheduled-rds-dev"
    scheduled-dev     = "true"
  }
}

resource "aws_db_instance" "rds_tst" {
  count                = var.rds_tst_count
  identifier           = "scheduled-rds-tst"
  db_subnet_group_name = aws_db_subnet_group.rds.id
  username             = "user"
  password             = "password"
  engine               = "mariadb"
  engine_version       = "10.5"
  instance_class       = "db.t3.micro"
  allocated_storage    = 10
  storage_type         = "gp2"
  skip_final_snapshot  = "true"

  tags = {
    Name              = "scheduled-rds-tst"
    scheduled-tst     = "true"
  }
}

resource "aws_db_instance" "rds_prd" {
  count                = var.rds_prd_count
  identifier           = "scheduled-rds-prd"
  db_subnet_group_name = aws_db_subnet_group.rds.id
  username             = "user"
  password             = "password"
  engine               = "mariadb"
  engine_version       = "10.5"
  instance_class       = "db.t3.micro"
  allocated_storage    = 10
  storage_type         = "gp2"
  skip_final_snapshot  = "true"

  tags = {
    Name              = "scheduled-rds-prd"
    scheduled-prd     = "false"
  }
}

# to replace mariadb with sqlserver
# use below attributes:
#  engine               = "sqlserver-ex"
#  engine_version       = "14.00"
#  instance_class       = "db.t3.small"
#  license_model        = "license-included"
#  allocated_storage    = 20

