provider "aws" {
  region = var.aws_region
}

# Create a VPC
resource "aws_vpc" "demo_vpc" {
  cidr_block           = var.vpc_cidr_block
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "taskVPC"
  }
}

# Create  subnets
resource "aws_subnet" "public_subnets" {
  count = length(var.public_subnet_cidr_blocks)

  vpc_id     = aws_vpc.demo_vpc.id
  cidr_block = var.public_subnet_cidr_blocks[count.index]

  availability_zone = element(data.aws_availability_zones.available.names, count.index)

  tags = {
    Name = "PublicSubnet${count.index + 1}"
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}

# Create an Elastic Container Registry (ECR)
resource "aws_ecr_repository" "my_ecr_repository" {
  name = var.ecr_repository_name

  image_tag_mutability = "IMMUTABLE"
}

resource "random_string" "password" {
  length  = 16
  special = false
}

# Create an Amazon RDS MySQL database
resource "aws_db_instance" "my_db_instance" {
  identifier          = var.db_instance_identifier
  engine              = "mysql"
  allocated_storage   = 20
  instance_class      = "db.t3.micro"
  username            = var.db_instance_username
  password            = random_string.password.result
  publicly_accessible = false
  skip_final_snapshot = true
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_instance" "demo_server" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"
  tags = {
    Name = "Demo-App"
  }
}

resource "aws_security_group" "ec2" {
  name = "demo-ec2-sg"

  description = "EC2 security group"
  vpc_id      = aws_vpc.demo_vpc.id

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    description = "MySQL"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    description = "Telnet"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    description = "HTTP"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    description = "HTTPS"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
