terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.4"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Data sources
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# Variables
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "vpc_id" {
  description = "VPC ID for ECS resources"
  type        = string
}

variable "subnet_ids" {
  description = "Subnet IDs for ECS tasks"
  type        = list(string)
}

variable "snowflake_account" {
  description = "Snowflake account identifier"
  type        = string
}

variable "snowflake_role_arn" {
  description = "IAM role ARN for Snowflake integration"
  type        = string
}

variable "container_image" {
  description = "Container image URI for report service"
  type        = string
  default     = "your-account.dkr.ecr.us-east-1.amazonaws.com/report-service:latest"
}

variable "reports_bucket" {
  description = "S3 bucket for storing reports"
  type        = string
  default     = "your-reports-bucket"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "production"
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "report-service"
}

# Lambda function code for ECS trigger
data "archive_file" "lambda_zip" {
  type        = "zip"
  output_path = "lambda_function.zip"
  source {
    content = <<EOF
import json
import boto3
import os
import logging

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

ecs_client = boto3.client('ecs')

def lambda_handler(event, context):
    try:
        # Extract trigger type from the request path or body
        trigger_type = 'ADHOC'  # Default
        
        # Check if trigger type is specified in the path
        if 'pathParameters' in event and event['pathParameters']:
            if 'trigger_type' in event['pathParameters']:
                trigger_type = event['pathParameters']['trigger_type'].upper()
        
        # Check if trigger type is in the request body
        if 'body' in event and event['body']:
            try:
                body = json.loads(event['body'])
                if 'trigger_type' in body:
                    trigger_type = body['trigger_type'].upper()
            except json.JSONDecodeError:
                pass
        
        logger.info(f"Processing {trigger_type} trigger request")
        
        service_arn = os.environ['ECS_SERVICE_ARN']
        
        # Extract cluster and service name from ARN
        # ARN format: arn:aws:ecs:region:account:service/cluster-name/service-name
        arn_parts = service_arn.split('/')
        if len(arn_parts) >= 3:
            cluster_name = arn_parts[-2]
            service_name = arn_parts[-1]
        else:
            # Fallback to default cluster if parsing fails
            cluster_name = 'default'
            service_name = service_arn
        
        logger.info(f"Updating ECS service: {service_name} in cluster: {cluster_name}")
        
        # Update service desired count to 1 (wake it up)
        response = ecs_client.update_service(
            cluster=cluster_name,
            service=service_name,
            desiredCount=1
        )
        
        logger.info(f"ECS service update response: {response}")
        
        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Methods': 'POST, OPTIONS',
                'Access-Control-Allow-Headers': 'Content-Type, Authorization'
            },
            'body': json.dumps({
                'message': f'ECS service triggered successfully for {trigger_type} processing',
                'service': service_arn,
                'trigger_type': trigger_type,
                'desired_count': 1,
                'timestamp': context.aws_request_id
            })
        }
        
    except Exception as e:
        logger.error(f"Error: {str(e)}", exc_info=True)
        return {
            'statusCode': 500,
            'headers': {
                'Content-Type': 'application/json'
            },
            'body': json.dumps({
                'error': str(e),
                'message': 'Failed to trigger ECS service'
            })
        }
EOF
    filename = "index.py"
  }
}

# CloudWatch Log Group for Lambda
resource "aws_cloudwatch_log_group" "lambda_logs" {
  name              = "/aws/lambda/${var.project_name}-ecs-trigger"
  retention_in_days = 14

  tags = {
    Name        = "${var.project_name}-lambda-logs"
    Environment = var.environment
  }
}

# CloudWatch Log Group for ECS
resource "aws_cloudwatch_log_group" "report_service_logs" {
  name              = "/ecs/${var.project_name}"
  retention_in_days = 7

  tags = {
    Name        = "${var.project_name}-ecs-logs"
    Environment = var.environment
  }
}

# Security Group for ECS
resource "aws_security_group" "ecs_security_group" {
  name_prefix = "${var.project_name}-ecs-"
  description = "Security group for report service ECS tasks"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-ecs-sg"
    Environment = var.environment
  }
}

# IAM Role for Lambda
resource "aws_iam_role" "lambda_role" {
  name = "${var.project_name}-ecs-trigger-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "${var.project_name}-lambda-role"
    Environment = var.environment
  }
}

resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "lambda_ecs_policy" {
  name = "ECSServiceUpdate"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecs:UpdateService",
          "ecs:DescribeServices"
        ]
        Resource = "arn:aws:ecs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:service/${aws_ecs_cluster.report_cluster.name}/${var.project_name}"
      }
    ]
  })
}

# IAM Role for Snowflake Integration
resource "aws_iam_role" "snowflake_integration_role" {
  name = "${var.project_name}-snowflake-integration-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = var.snowflake_role_arn
        }
        Action = "sts:AssumeRole"
        Condition = {
          StringEquals = {
            "sts:ExternalId" = "snowflake_external_id"
          }
        }
      }
    ]
  })

  tags = {
    Name        = "${var.project_name}-snowflake-role"
    Environment = var.environment
  }
}

resource "aws_iam_role_policy" "snowflake_api_policy" {
  name = "SnowflakeAPIGatewayAccess"
  role = aws_iam_role.snowflake_integration_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "execute-api:Invoke"
        ]
        Resource = "${aws_api_gateway_rest_api.trigger_api.execution_arn}/*"
      }
    ]
  })
}

# IAM Role for ECS Execution
resource "aws_iam_role" "ecs_execution_role" {
  name = "${var.project_name}-ecs-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "${var.project_name}-ecs-execution-role"
    Environment = var.environment
  }
}

resource "aws_iam_role_policy_attachment" "ecs_execution_role_policy" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy" "ecs_secrets_policy" {
  name = "SecretsManagerAccess"
  role = aws_iam_role.ecs_execution_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = [
          aws_secretsmanager_secret.snowflake_user.arn,
          aws_secretsmanager_secret.snowflake_password.arn
        ]
      }
    ]
  })
}

# IAM Role for ECS Task
resource "aws_iam_role" "ecs_task_role" {
  name = "${var.project_name}-ecs-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "${var.project_name}-ecs-task-role"
    Environment = var.environment
  }
}

resource "aws_iam_role_policy" "ecs_task_s3_policy" {
  name = "S3ReportAccess"
  role = aws_iam_role.ecs_task_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:PutObjectAcl",
          "s3:GetObject"
        ]
        Resource = "arn:aws:s3:::${var.reports_bucket}/*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket"
        ]
        Resource = "arn:aws:s3:::${var.reports_bucket}"
      }
    ]
  })
}

resource "aws_iam_role_policy" "ecs_task_service_control" {
  name = "ECSServiceControl"
  role = aws_iam_role.ecs_task_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecs:UpdateService",
          "ecs:DescribeServices"
        ]
        Resource = "arn:aws:ecs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:service/${aws_ecs_cluster.report_cluster.name}/${var.project_name}"
      }
    ]
  })
}

resource "aws_iam_role_policy" "ecs_task_cloudwatch_policy" {
  name = "CloudWatchAccess"
  role = aws_iam_role.ecs_task_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "${aws_cloudwatch_log_group.report_service_logs.arn}:*"
      }
    ]
  })
}

# Secrets Manager
resource "aws_secretsmanager_secret" "snowflake_user" {
  name                    = "${var.project_name}/snowflake/username"
  description             = "Snowflake username for report service"
  recovery_window_in_days = 0 # For demo purposes - use 7-30 in production

  tags = {
    Name        = "${var.project_name}-snowflake-user"
    Environment = var.environment
  }
}

resource "aws_secretsmanager_secret_version" "snowflake_user" {
  secret_id     = aws_secretsmanager_secret.snowflake_user.id
  secret_string = "your-snowflake-username"
}

resource "aws_secretsmanager_secret" "snowflake_password" {
  name                    = "${var.project_name}/snowflake/password"
  description             = "Snowflake password for report service"
  recovery_window_in_days = 0 # For demo purposes - use 7-30 in production

  tags = {
    Name        = "${var.project_name}-snowflake-password"
    Environment = var.environment
  }
}

resource "aws_secretsmanager_secret_version" "snowflake_password" {
  secret_id     = aws_secretsmanager_secret.snowflake_password.id
  secret_string = "your-snowflake-password"
}

# Lambda Function
resource "aws_lambda_function" "trigger_lambda" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "${var.project_name}-ecs-trigger"
  role            = aws_iam_role.lambda_role.arn
  handler         = "index.lambda_handler"
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  runtime         = "python3.9"
  timeout         = 30

  environment {
    variables = {
      ECS_SERVICE_ARN = "arn:aws:ecs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:service/${aws_ecs_cluster.report_cluster.name}/${var.project_name}"
    }
  }

  depends_on = [
    aws_iam_role_policy_attachment.lambda_basic,
    aws_cloudwatch_log_group.lambda_logs,
  ]

  tags = {
    Name        = "${var.project_name}-ecs-trigger"
    Environment = var.environment
  }
}

resource "aws_lambda_permission" "api_gateway" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.trigger_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.trigger_api.execution_arn}/*/*"
}

# API Gateway
resource "aws_api_gateway_rest_api" "trigger_api" {
  name        = "${var.project_name}-ecs-trigger"
  description = "API for triggering ECS service from Snowflake"

  endpoint_configuration {
    types = ["REGIONAL"]
  }

  tags = {
    Name        = "${var.project_name}-api"
    Environment = var.environment
  }
}

# API Gateway Resources and Methods
resource "aws_api_gateway_resource" "trigger_resource" {
  rest_api_id = aws_api_gateway_rest_api.trigger_api.id
  parent_id   = aws_api_gateway_rest_api.trigger_api.root_resource_id
  path_part   = "trigger"
}

resource "aws_api_gateway_resource" "adhoc_resource" {
  rest_api_id = aws_api_gateway_rest_api.trigger_api.id
  parent_id   = aws_api_gateway_resource.trigger_resource.id
  path_part   = "adhoc"
}

resource "aws_api_gateway_resource" "scheduled_resource" {
  rest_api_id = aws_api_gateway_rest_api.trigger_api.id
  parent_id   = aws_api_gateway_resource.trigger_resource.id
  path_part   = "scheduled"
}

# Methods for ADHOC triggers
resource "aws_api_gateway_method" "adhoc_method" {
  rest_api_id   = aws_api_gateway_rest_api.trigger_api.id
  resource_id   = aws_api_gateway_resource.adhoc_resource.id
  http_method   = "POST"
  authorization = "AWS_IAM"
}

resource "aws_api_gateway_integration" "adhoc_lambda_integration" {
  rest_api_id = aws_api_gateway_rest_api.trigger_api.id
  resource_id = aws_api_gateway_resource.adhoc_resource.id
  http_method = aws_api_gateway_method.adhoc_method.http_method

  integration_http_method = "POST"
  type                   = "AWS_PROXY"
  uri                    = aws_lambda_function.trigger_lambda.invoke_arn
}

# Methods for SCHEDULED triggers
resource "aws_api_gateway_method" "scheduled_method" {
  rest_api_id   = aws_api_gateway_rest_api.trigger_api.id
  resource_id   = aws_api_gateway_resource.scheduled_resource.id
  http_method   = "POST"
  authorization = "AWS_IAM"
}

resource "aws_api_gateway_integration" "scheduled_lambda_integration" {
  rest_api_id = aws_api_gateway_rest_api.trigger_api.id
  resource_id = aws_api_gateway_resource.scheduled_resource.id
  http_method = aws_api_gateway_method.scheduled_method.http_method

  integration_http_method = "POST"
  type                   = "AWS_PROXY"
  uri                    = aws_lambda_function.trigger_lambda.invoke_arn
}

# OPTIONS methods for CORS support
resource "aws_api_gateway_method" "adhoc_options" {
  rest_api_id   = aws_api_gateway_rest_api.trigger_api.id
  resource_id   = aws_api_gateway_resource.adhoc_resource.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "adhoc_options_integration" {
  rest_api_id = aws_api_gateway_rest_api.trigger_api.id
  resource_id = aws_api_gateway_resource.adhoc_resource.id
  http_method = aws_api_gateway_method.adhoc_options.http_method
  type        = "MOCK"

  request_templates = {
    "application/json" = jsonencode({
      statusCode = 200
    })
  }
}

resource "aws_api_gateway_method_response" "adhoc_options_response" {
  rest_api_id = aws_api_gateway_rest_api.trigger_api.id
  resource_id = aws_api_gateway_resource.adhoc_resource.id
  http_method = aws_api_gateway_method.adhoc_options.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}

resource "aws_api_gateway_integration_response" "adhoc_options_integration_response" {
  rest_api_id = aws_api_gateway_rest_api.trigger_api.id
  resource_id = aws_api_gateway_resource.adhoc_resource.id
  http_method = aws_api_gateway_method.adhoc_options.http_method
  status_code = aws_api_gateway_method_response.adhoc_options_response.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'"
    "method.response.header.Access-Control-Allow-Methods" = "'POST,OPTIONS'"
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }
}

resource "aws_api_gateway_deployment" "trigger_deployment" {
  depends_on = [
    aws_api_gateway_integration.adhoc_lambda_integration,
    aws_api_gateway_integration.scheduled_lambda_integration,
    aws_api_gateway_integration.adhoc_options_integration,
  ]

  rest_api_id = aws_api_gateway_rest_api.trigger_api.id

  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.trigger_resource.id,
      aws_api_gateway_resource.adhoc_resource.id,
      aws_api_gateway_resource.scheduled_resource.id,
      aws_api_gateway_method.adhoc_method.id,
      aws_api_gateway_method.scheduled_method.id,
      aws_api_gateway_integration.adhoc_lambda_integration.id,
      aws_api_gateway_integration.scheduled_lambda_integration.id,
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "prod" {
  deployment_id = aws_api_gateway_deployment.trigger_deployment.id
  rest_api_id   = aws_api_gateway_rest_api.trigger_api.id
  stage_name    = "prod"

  tags = {
    Name        = "${var.project_name}-api-stage"
    Environment = var.environment
  }
}

# ECS Cluster
resource "aws_ecs_cluster" "report_cluster" {
  name = "${var.project_name}-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = {
    Name        = "${var.project_name}-cluster"
    Environment = var.environment
  }
}

# ECS Task Definition
resource "aws_ecs_task_definition" "report_task" {
  family                   = var.project_name
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 1024
  memory                   = 2048
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn
  task_role_arn           = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name      = var.project_name
      image     = var.container_image
      essential = true
      
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.report_service_logs.name
          "awslogs-region"        = data.aws_region.current.name
          "awslogs-stream-prefix" = "ecs"
        }
      }

      environment = [
        {
          name  = "SERVICE_MODE"
          value = "TRIGGER_BASED"
        },
        {
          name  = "SNOWFLAKE_ACCOUNT"
          value = var.snowflake_account
        },
        {
          name  = "SNOWFLAKE_DATABASE"
          value = "REPORTING_DB"
        },
        {
          name  = "SNOWFLAKE_SCHEMA"
          value = "CONFIG"
        },
        {
          name  = "SNOWFLAKE_WAREHOUSE"
          value = "COMPUTE_WH"
        },
        {
          name  = "AWS_DEFAULT_REGION"
          value = data.aws_region.current.name
        },
        {
          name  = "ECS_SERVICE_ARN"
          value = "arn:aws:ecs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:service/${aws_ecs_cluster.report_cluster.name}/${var.project_name}"
        },
        {
          name  = "REPORTS_BUCKET"
          value = var.reports_bucket
        }
      ]

      secrets = [
        {
          name      = "SNOWFLAKE_USER"
          valueFrom = aws_secretsmanager_secret.snowflake_user.arn
        },
        {
          name      = "SNOWFLAKE_PASSWORD"
          valueFrom = aws_secretsmanager_secret.snowflake_password.arn
        }
      ]
    }
  ])

  tags = {
    Name        = "${var.project_name}-task"
    Environment = var.environment
  }
}

# ECS Service
resource "aws_ecs_service" "report_service" {
  name            = var.project_name
  cluster         = aws_ecs_cluster.report_cluster.id
  task_definition = aws_ecs_task_definition.report_task.arn
  launch_type     = "FARGATE"
  desired_count   = 0 # Starts at 0, wakes up on trigger

  network_configuration {
    subnets          = var.subnet_ids
    security_groups  = [aws_security_group.ecs_security_group.id]
    assign_public_ip = true
  }

  tags = {
    Name        = var.project_name
    Environment = var.environment
  }
}

# Outputs
output "trigger_adhoc_url" {
  description = "API Gateway URL for triggering ADHOC reports"
  value       = "https://${aws_api_gateway_rest_api.trigger_api.id}.execute-api.${data.aws_region.current.name}.amazonaws.com/${aws_api_gateway_stage.prod.stage_name}/trigger/adhoc"
}

output "trigger_scheduled_url" {
  description = "API Gateway URL for triggering SCHEDULED reports"
  value       = "https://${aws_api_gateway_rest_api.trigger_api.id}.execute-api.${data.aws_region.current.name}.amazonaws.com/${aws_api_gateway_stage.prod.stage_name}/trigger/scheduled"
}

output "ecs_cluster_arn" {
  description = "ECS Cluster ARN"
  value       = aws_ecs_cluster.report_cluster.arn
}

output "ecs_service_arn" {
  description = "ECS Service ARN"
  value       = aws_ecs_service.report_service.id
}

output "lambda_function_name" {
  description = "Lambda function name"
  value       = aws_lambda_function.trigger_lambda.function_name
}

output "snowflake_integration_role_arn" {
  description = "IAM role ARN for Snowflake integration"
  value       = aws_iam_role.snowflake_integration_role.arn
}

output "api_gateway_id" {
  description = "API Gateway REST API ID"
  value       = aws_api_gateway_rest_api.trigger_api.id
}

output "secrets_manager_arns" {
  description = "Secrets Manager ARNs for Snowflake credentials"
  value = {
    username = aws_secretsmanager_secret.snowflake_user.arn
    password = aws_secretsmanager_secret.snowflake_password.arn
  }
}