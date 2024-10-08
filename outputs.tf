
output "vpc_id" {
  value       = aws_vpc.demo_vpc.id
  description = "The ID of the VPC"
}

output "ecr_repository_url" {
  value       = aws_ecr_repository.demo_ecr_repository.repository_url
  description = "The URL of the ECR repository."
}

output "db_instance_endpoint" {
  value       = aws_db_instance.demo_db_instance.endpoint
  description = "The endpoint of the RDS MySQL database."
}

output "db_instance_username" {
  value       = aws_db_instance.demo_db_instance.username
  description = "The username for the RDS MySQL database."
  sensitive   = true
}

output "db_instance_password" {
  value       = random_string.password
  description = "The password for the RDS MySQL database"
  sensitive   = true
}

output "ec2_instance_id" {
  value       = aws_instance.demo_server.host_id
  description = "The Host ID of the instance"
}
