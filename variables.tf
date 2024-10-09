variable "aws_region" {
  description = "The AWS region where the resources will be created."
  default     = "us-east-1"
}

variable "vpc_cidr_block" {
  description = "The CIDR block for the VPC"
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr_blocks" {
  description = "The CIDR blocks for the public subnets."
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

variable "ecr_repository_name" {
  description = "The name of the ECR repository."
  default     = "demo-ecr-repository"
}

variable "db_instance_identifier" {
  description = "The identifier for the RDS MySQL database instance."
  default     = "demo-db-instance"
}

variable "db_instance_username" {
  description = "The username for the RDS MySQL database."
  default     = "admin"
}

variable "key_pair_name" {
  description = "EC2 Key Pair Name"
  default     = "demo-key-pair-name"
}
