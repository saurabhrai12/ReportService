# Example Terraform Variables File
# Copy this to terraform.tfvars and fill in your actual values

# AWS Configuration
aws_region = "us-east-1"
environment = "production"
project_name = "report-service"

# Network Configuration
vpc_id = "vpc-00390a7180e3cf3e7"
subnet_ids = ["subnet-0c8ae010a9215f951", "subnet-0535fa2e0264d0701"]

# Snowflake Configuration
snowflake_account = "OILZKIQ-ID94597"
# This should be the ARN of your Snowflake service account
snowflake_role_arn = "arn:aws:iam::203977009513:role/report-service-snowflake-integration-role"

# Container Configuration
container_image = "203977009513.dkr.ecr.us-east-1.amazonaws.com/report-service:latest"

# Storage Configuration
reports_bucket = "oas-report-service-bucket"