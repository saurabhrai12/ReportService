# Terraform Outputs

output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = aws_subnet.private[*].id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = aws_subnet.public[*].id
}

output "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  value       = aws_ecs_cluster.main.name
}

output "ecs_cluster_arn" {
  description = "ARN of the ECS cluster"
  value       = aws_ecs_cluster.main.arn
}

output "ecs_task_definition_arn" {
  description = "ARN of the ECS task definition"
  value       = aws_ecs_task_definition.processor.arn
}

output "lambda_function_name" {
  description = "Name of the Lambda function"
  value       = aws_lambda_function.poller.function_name
}

output "lambda_function_arn" {
  description = "ARN of the Lambda function"
  value       = aws_lambda_function.poller.arn
}

output "ecr_repository_url" {
  description = "URL of the ECR repository"
  value       = aws_ecr_repository.processor.repository_url
}

output "s3_certificates_bucket" {
  description = "Name of the S3 certificates bucket"
  value       = aws_s3_bucket.certificates.id
}

output "secrets_manager_secret_arn" {
  description = "ARN of the Secrets Manager secret"
  value       = aws_secretsmanager_secret.snowflake_creds.arn
}

output "scheduler_rule_name" {
  description = "Name of the EventBridge scheduler rule"
  value       = aws_scheduler_schedule.poller_trigger.name
}

output "cloudwatch_log_groups" {
  description = "CloudWatch log group names"
  value = {
    lambda = aws_cloudwatch_log_group.lambda.name
    ecs    = aws_cloudwatch_log_group.ecs.name
  }
}