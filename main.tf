provider "aws" {
  region = var.aws_region
}

# Create a VPC
resource "aws_vpc" "demo_vpc" {
  cidr_block           = var.vpc_cidr_block
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "Demo VPC"
  }
}

resource "aws_internet_gateway" "demo_igw" {
  vpc_id = aws_vpc.demo_vpc.id
  tags = {
    Name = "demo_igw"
  }
}

# Create  subnets
resource "aws_subnet" "public_subnets" {
  count = length(var.public_subnet_cidr_blocks)

  vpc_id     = aws_vpc.demo_vpc.id
  cidr_block = var.public_subnet_cidr_blocks[count.index]

  # availability_zone = element(data.aws_availability_zones.available.names, count.index)
  availability_zone = "us-east-1a"

  tags = {
    Name = "PublicSubnet${count.index + 1}"
  }
}

resource "aws_subnet" "private_subnet" {
  count = length(var.private_subnet_cidr_blocks)

  vpc_id = aws_vpc.demo_vpc.id

  cidr_block = var.private_subnet_cidr_blocks[count.index]

  # availability_zone = data.aws_availability_zones.available.names[count.index]
  availability_zone = "us-east-1a"
  tags = {
    Name = "PrivateSubnet${count.index + 1}"
  }
}

resource "aws_route_table" "demo_public_rt" {
  vpc_id = aws_vpc.demo_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.demo_igw.id
  }
}

resource "aws_route_table_association" "public" {
  count = length(var.public_subnet_cidr_blocks)

  route_table_id = aws_route_table.demo_public_rt.id
  subnet_id      = aws_subnet.public_subnets[count.index].id
}

resource "aws_route_table" "demo_private_rt" {
  vpc_id = aws_vpc.demo_vpc.id

}
resource "aws_route_table_association" "private" {
  count = length(var.private_subnet_cidr_blocks)

  route_table_id = aws_route_table.demo_private_rt.id

  subnet_id = aws_subnet.private_subnet[count.index].id
}

# Create an Elastic Container Registry (ECR)
resource "aws_ecr_repository" "demo_ecr_repository" {
  name = var.ecr_repository_name

  image_tag_mutability = "IMMUTABLE"
}

resource "random_string" "password" {
  length  = 16
  special = false
}

# Create an Amazon RDS MySQL database
resource "aws_db_instance" "demo_db_instance" {
  identifier          = var.db_instance_identifier
  engine              = "mysql"
  allocated_storage   = 20
  instance_class      = "db.t3.micro"
  username            = var.db_instance_username
  password            = random_string.password.result
  publicly_accessible = false
  skip_final_snapshot = true
}

# data "aws_ami" "ubuntu" {
#   most_recent = true

#   filter {
#     name   = "name"
#     values = ["amazon/al2023-ami-*"]
#   }

#   # filter {
#   #   name   = "virtualization-type"
#   #   values = ["hvm"]
#   # }

#   owners = ["099720109477"] # Canonical
# }


resource "tls_private_key" "rsa-demo" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "tf_key" {
  key_name   = var.key_pair_name
  public_key = tls_private_key.rsa-demo.public_key_openssh
}

resource "local_file" "ssh_key_file" {
  filename = "ssh_key_file"
  content  = tls_private_key.rsa-demo.private_key_pem
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
  # TODO Improve to only allow HTTP/HTTPS traffic
  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "demo_server" {
  ami                    = "ami-0fff1b9a61dec8a5f"
  instance_type          = "t2.micro"
  key_name               = aws_key_pair.tf_key.key_name
  vpc_security_group_ids = [aws_security_group.ec2.id]
  subnet_id              = aws_subnet.public_subnets[0].id
  tags = {
    Name = "Demo-App"
  }
  user_data = <<-EOF
              #!/bin/bash
              sudo yum install docker -y
              sudo systemctl start docker
              sudo systemctl enable docker 
              EOF
}

resource "aws_eip" "demo_web_eip" {
  instance = aws_instance.demo_server.id
  domain   = "vpc"
  tags = {
    Name = "demo_server_eip"
  }
}
