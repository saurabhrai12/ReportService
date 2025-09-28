#!/bin/bash

# Snowflake Processor Deployment Script
set -e

ENVIRONMENT=${1:-dev}
AWS_REGION=${2:-us-east-1}

echo "🚀 Starting deployment for environment: $ENVIRONMENT"

# Check prerequisites
echo "🔍 Checking prerequisites..."

if ! command -v terraform &> /dev/null; then
    echo "❌ Terraform is required but not installed"
    exit 1
fi

if ! command -v aws &> /dev/null; then
    echo "❌ AWS CLI is required but not installed"
    exit 1
fi

if ! command -v docker &> /dev/null; then
    echo "❌ Docker is required but not installed"
    exit 1
fi

# Check if terraform.tfvars exists
if [ ! -f "terraform/terraform.tfvars" ]; then
    echo "❌ terraform/terraform.tfvars not found"
    echo "Please copy terraform/terraform.tfvars.example to terraform/terraform.tfvars and configure it"
    exit 1
fi

echo "✅ Prerequisites check passed"

# Package Lambda function
echo "📦 Packaging Lambda function..."
cd lambda_poller
pip install -r requirements.txt -t .
zip -r lambda_poller.zip . -x "*.pyc" "__pycache__/*"
mv lambda_poller.zip ../terraform/
cd ..

# Build and push container image
echo "🐳 Building and pushing container image..."

# Get ECR repository URL from Terraform output or create it
cd terraform
terraform init
terraform plan

# Apply Terraform to create ECR repository first
terraform apply -target=aws_ecr_repository.processor -auto-approve

# Get ECR repository URL
ECR_REPO_URL=$(terraform output -raw ecr_repository_url || echo "")

if [ -z "$ECR_REPO_URL" ]; then
    echo "❌ Failed to get ECR repository URL"
    exit 1
fi

echo "🐳 ECR Repository: $ECR_REPO_URL"

# Login to ECR
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ECR_REPO_URL

# Build and push Docker image
cd ../container
docker build -t snowflake-processor .
docker tag snowflake-processor:latest $ECR_REPO_URL:latest
docker push $ECR_REPO_URL:latest

echo "✅ Container image pushed successfully"

# Deploy infrastructure
echo "🏗️  Deploying infrastructure..."
cd ../terraform

# Apply full Terraform configuration
terraform apply -auto-approve

echo "✅ Infrastructure deployed successfully"

# Output important information
echo "📋 Deployment Summary:"
echo "Environment: $ENVIRONMENT"
echo "Region: $AWS_REGION"
echo "ECR Repository: $ECR_REPO_URL"

# Get Lambda function name
LAMBDA_FUNCTION_NAME=$(terraform output -raw lambda_function_name || echo "")
if [ -n "$LAMBDA_FUNCTION_NAME" ]; then
    echo "Lambda Function: $LAMBDA_FUNCTION_NAME"
fi

# Get ECS cluster name
ECS_CLUSTER_NAME=$(terraform output -raw ecs_cluster_name || echo "")
if [ -n "$ECS_CLUSTER_NAME" ]; then
    echo "ECS Cluster: $ECS_CLUSTER_NAME"
fi

echo "🎉 Deployment completed successfully!"
echo ""
echo "Next steps:"
echo "1. Upload SSL certificates to S3 bucket: ${ENVIRONMENT}-snowflake-processor-certs"
echo "2. Run database setup: ./scripts/setup_database.sh"
echo "3. Test the system: ./scripts/test_system.sh"