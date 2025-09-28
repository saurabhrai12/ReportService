# Snowflake Processing System - Complete Solution

## Table of Contents
1. [Architecture Overview](#architecture-overview)
2. [Infrastructure as Code (Terraform)](#1-infrastructure-as-code-terraform)
3. [Application Code](#2-application-code)
4. [Docker Configuration](#3-docker-configuration)
5. [Database Schema](#4-database-schema)
6. [Monitoring and Alerting](#5-monitoring-and-alerting)
7. [Deployment Guide](#6-deployment-guide)
8. [Testing Strategy](#7-testing-strategy)
9. [Operational Procedures](#8-operational-procedures)

## Architecture Overview

The solution uses a serverless approach with EventBridge triggering a Lambda function every minute to poll Snowflake and dynamically launch ECS Fargate containers based on workload.

```
EventBridge (1min) → Lambda Poller → Snowflake Query
                            ↓
                    Calculate Containers
                            ↓
                    Launch ECS Tasks → Process Entries → External Services
```

## 1. Infrastructure as Code (Terraform)

### 1.1 Main Infrastructure Configuration

```hcl
# terraform/main.tf

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Variables
variable "aws_region" {
  default = "us-east-1"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "snowflake_account" {
  description = "Snowflake account identifier"
  type        = string
}

variable "snowflake_warehouse" {
  description = "Snowflake warehouse name"
  type        = string
}

variable "snowflake_database" {
  description = "Snowflake database name"
  type        = string
}

variable "snowflake_schema" {
  description = "Snowflake schema name"
  type        = string
}

variable "snowflake_table" {
  description = "Snowflake table name"
  type        = string
}
```

### 1.2 S3 Bucket for Certificates

```hcl
# terraform/s3.tf

resource "aws_s3_bucket" "certificates" {
  bucket = "${var.environment}-snowflake-processor-certs"
}

resource "aws_s3_bucket_versioning" "certificates" {
  bucket = aws_s3_bucket.certificates.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "certificates" {
  bucket = aws_s3_bucket.certificates.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "certificates" {
  bucket = aws_s3_bucket.certificates.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
```

### 1.3 VPC and Networking

```hcl
# terraform/vpc.tf

resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "${var.environment}-snowflake-processor-vpc"
    Environment = var.environment
  }
}

resource "aws_subnet" "private" {
  count             = 2
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.${count.index + 1}.0/24"
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name        = "${var.environment}-private-subnet-${count.index + 1}"
    Environment = var.environment
  }
}

resource "aws_subnet" "public" {
  count                   = 2
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.${count.index + 101}.0/24"
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name        = "${var.environment}-public-subnet-${count.index + 1}"
    Environment = var.environment
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name        = "${var.environment}-igw"
    Environment = var.environment
  }
}

resource "aws_eip" "nat" {
  count  = 2
  domain = "vpc"

  tags = {
    Name        = "${var.environment}-nat-eip-${count.index + 1}"
    Environment = var.environment
  }
}

resource "aws_nat_gateway" "main" {
  count         = 2
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = {
    Name        = "${var.environment}-nat-${count.index + 1}"
    Environment = var.environment
  }
}

resource "aws_route_table" "private" {
  count  = 2
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main[count.index].id
  }

  tags = {
    Name        = "${var.environment}-private-rt-${count.index + 1}"
    Environment = var.environment
  }
}

resource "aws_route_table_association" "private" {
  count          = 2
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name        = "${var.environment}-public-rt"
    Environment = var.environment
  }
}

resource "aws_route_table_association" "public" {
  count          = 2
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

data "aws_availability_zones" "available" {
  state = "available"
}
```

### 1.4 ECS Cluster and Task Definition

```hcl
# terraform/ecs.tf

resource "aws_ecs_cluster" "main" {
  name = "${var.environment}-snowflake-processor"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = {
    Environment = var.environment
  }
}

resource "aws_ecs_task_definition" "processor" {
  family                   = "${var.environment}-snowflake-processor"
  network_mode            = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                     = "1024"
  memory                  = "2048"
  execution_role_arn      = aws_iam_role.ecs_execution_role.arn
  task_role_arn          = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name  = "processor"
      image = "${aws_ecr_repository.processor.repository_url}:latest"
      
      environment = [
        {
          name  = "ENVIRONMENT"
          value = var.environment
        },
        {
          name  = "CERT_BUCKET"
          value = aws_s3_bucket.certificates.id
        },
        {
          name  = "SNOWFLAKE_ACCOUNT"
          value = var.snowflake_account
        },
        {
          name  = "SNOWFLAKE_WAREHOUSE"
          value = var.snowflake_warehouse
        },
        {
          name  = "SNOWFLAKE_DATABASE"
          value = var.snowflake_database
        },
        {
          name  = "SNOWFLAKE_SCHEMA"
          value = var.snowflake_schema
        },
        {
          name  = "SNOWFLAKE_TABLE"
          value = var.snowflake_table
        }
      ]

      secrets = [
        {
          name      = "SNOWFLAKE_USER"
          valueFrom = aws_secretsmanager_secret.snowflake_creds.arn
        },
        {
          name      = "SNOWFLAKE_PASSWORD"
          valueFrom = "${aws_secretsmanager_secret.snowflake_creds.arn}:password::"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.ecs.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }

      essential = true
    }
  ])
}

resource "aws_ecr_repository" "processor" {
  name                 = "${var.environment}-snowflake-processor"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Environment = var.environment
  }
}

resource "aws_cloudwatch_log_group" "ecs" {
  name              = "/ecs/${var.environment}-snowflake-processor"
  retention_in_days = 30

  tags = {
    Environment = var.environment
  }
}
```

### 1.5 Lambda Poller Function

```hcl
# terraform/lambda.tf

resource "aws_lambda_function" "poller" {
  filename         = "lambda_poller.zip"
  function_name    = "${var.environment}-snowflake-poller"
  role            = aws_iam_role.lambda_role.arn
  handler         = "index.handler"
  runtime         = "python3.11"
  timeout         = 60
  memory_size     = 512

  environment {
    variables = {
      ENVIRONMENT          = var.environment
      ECS_CLUSTER         = aws_ecs_cluster.main.name
      ECS_TASK_DEFINITION = aws_ecs_task_definition.processor.arn
      ECS_SUBNETS         = jsonencode(aws_subnet.private[*].id)
      ECS_SECURITY_GROUP  = aws_security_group.ecs_tasks.id
      SNOWFLAKE_ACCOUNT   = var.snowflake_account
      SNOWFLAKE_WAREHOUSE = var.snowflake_warehouse
      SNOWFLAKE_DATABASE  = var.snowflake_database
      SNOWFLAKE_SCHEMA    = var.snowflake_schema
      SNOWFLAKE_TABLE     = var.snowflake_table
    }
  }

  vpc_config {
    subnet_ids         = aws_subnet.private[*].id
    security_group_ids = [aws_security_group.lambda.id]
  }

  tags = {
    Environment = var.environment
  }
}

resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${aws_lambda_function.poller.function_name}"
  retention_in_days = 30

  tags = {
    Environment = var.environment
  }
}

resource "aws_security_group" "lambda" {
  name_prefix = "${var.environment}-lambda-sg"
  vpc_id      = aws_vpc.main.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.environment}-lambda-sg"
    Environment = var.environment
  }
}

resource "aws_security_group" "ecs_tasks" {
  name_prefix = "${var.environment}-ecs-tasks-sg"
  vpc_id      = aws_vpc.main.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.environment}-ecs-tasks-sg"
    Environment = var.environment
  }
}
```

### 1.6 EventBridge Schedule

```hcl
# terraform/eventbridge.tf

resource "aws_scheduler_schedule" "poller_trigger" {
  name       = "${var.environment}-snowflake-poller-schedule"
  group_name = "default"

  flexible_time_window {
    mode = "OFF"
  }

  schedule_expression = "rate(1 minute)"

  target {
    arn      = aws_lambda_function.poller.arn
    role_arn = aws_iam_role.scheduler_role.arn
  }
}
```

### 1.7 IAM Roles and Policies

```hcl
# terraform/iam.tf

# Lambda Execution Role
resource "aws_iam_role" "lambda_role" {
  name = "${var.environment}-snowflake-poller-lambda-role"

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
}

resource "aws_iam_role_policy" "lambda_policy" {
  name = "${var.environment}-snowflake-poller-lambda-policy"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:CreateNetworkInterface",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DeleteNetworkInterface",
          "ec2:AssignPrivateIpAddresses",
          "ec2:UnassignPrivateIpAddresses"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ecs:RunTask",
          "ecs:DescribeTasks"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "iam:PassRole"
        ]
        Resource = [
          aws_iam_role.ecs_execution_role.arn,
          aws_iam_role.ecs_task_role.arn
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = aws_secretsmanager_secret.snowflake_creds.arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_vpc_execution" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

# ECS Execution Role
resource "aws_iam_role" "ecs_execution_role" {
  name = "${var.environment}-ecs-execution-role"

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
}

resource "aws_iam_role_policy_attachment" "ecs_execution_role_policy" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy" "ecs_execution_secrets" {
  name = "${var.environment}-ecs-execution-secrets"
  role = aws_iam_role.ecs_execution_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = aws_secretsmanager_secret.snowflake_creds.arn
      }
    ]
  })
}

# ECS Task Role
resource "aws_iam_role" "ecs_task_role" {
  name = "${var.environment}-ecs-task-role"

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
}

resource "aws_iam_role_policy" "ecs_task_policy" {
  name = "${var.environment}-ecs-task-policy"
  role = aws_iam_role.ecs_task_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.certificates.arn,
          "${aws_s3_bucket.certificates.arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = aws_secretsmanager_secret.snowflake_creds.arn
      }
    ]
  })
}

# EventBridge Scheduler Role
resource "aws_iam_role" "scheduler_role" {
  name = "${var.environment}-scheduler-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "scheduler.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "scheduler_policy" {
  name = "${var.environment}-scheduler-policy"
  role = aws_iam_role.scheduler_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "lambda:InvokeFunction"
        ]
        Resource = aws_lambda_function.poller.arn
      }
    ]
  })
}
```

### 1.8 Secrets Manager

```hcl
# terraform/secrets.tf

resource "aws_secretsmanager_secret" "snowflake_creds" {
  name = "${var.environment}-snowflake-credentials"
}

resource "aws_secretsmanager_secret_version" "snowflake_creds" {
  secret_id = aws_secretsmanager_secret.snowflake_creds.id
  secret_string = jsonencode({
    username = var.snowflake_user
    password = var.snowflake_password
  })
}

variable "snowflake_user" {
  description = "Snowflake username"
  type        = string
  sensitive   = true
}

variable "snowflake_password" {
  description = "Snowflake password"
  type        = string
  sensitive   = true
}
```

## 2. Application Code

### 2.1 Lambda Poller Function

```python
# lambda_poller/index.py

import os
import json
import boto3
import snowflake.connector
from datetime import datetime, timedelta
import math
import uuid
import logging

logger = logging.getLogger()
logger.setLevel(logging.INFO)

ecs_client = boto3.client('ecs')
secrets_client = boto3.client('secretsmanager')

# Configuration
ENVIRONMENT = os.environ['ENVIRONMENT']
ECS_CLUSTER = os.environ['ECS_CLUSTER']
ECS_TASK_DEFINITION = os.environ['ECS_TASK_DEFINITION']
ECS_SUBNETS = json.loads(os.environ['ECS_SUBNETS'])
ECS_SECURITY_GROUP = os.environ['ECS_SECURITY_GROUP']

# Snowflake configuration
SNOWFLAKE_ACCOUNT = os.environ['SNOWFLAKE_ACCOUNT']
SNOWFLAKE_WAREHOUSE = os.environ['SNOWFLAKE_WAREHOUSE']
SNOWFLAKE_DATABASE = os.environ['SNOWFLAKE_DATABASE']
SNOWFLAKE_SCHEMA = os.environ['SNOWFLAKE_SCHEMA']
SNOWFLAKE_TABLE = os.environ['SNOWFLAKE_TABLE']

# Processing configuration
ENTRIES_PER_CONTAINER = 8
MAX_CONTAINERS = 25
STALE_THRESHOLD_MINUTES = 30

def get_snowflake_credentials():
    """Retrieve Snowflake credentials from Secrets Manager"""
    secret_name = f"{ENVIRONMENT}-snowflake-credentials"
    response = secrets_client.get_secret_value(SecretId=secret_name)
    secret = json.loads(response['SecretString'])
    return secret['username'], secret['password']

def get_snowflake_connection():
    """Create Snowflake connection"""
    username, password = get_snowflake_credentials()
    return snowflake.connector.connect(
        user=username,
        password=password,
        account=SNOWFLAKE_ACCOUNT,
        warehouse=SNOWFLAKE_WAREHOUSE,
        database=SNOWFLAKE_DATABASE,
        schema=SNOWFLAKE_SCHEMA
    )

def reset_stale_entries(conn):
    """Reset entries that have been processing for too long"""
    cursor = conn.cursor()
    try:
        stale_time = datetime.utcnow() - timedelta(minutes=STALE_THRESHOLD_MINUTES)
        
        query = f"""
        UPDATE {SNOWFLAKE_TABLE}
        SET status = 'pending',
            processor_id = NULL,
            claimed_at = NULL,
            retry_count = retry_count + 1
        WHERE status = 'processing'
          AND claimed_at < %s
        """
        
        cursor.execute(query, (stale_time,))
        stale_count = cursor.rowcount
        
        if stale_count > 0:
            logger.info(f"Reset {stale_count} stale entries")
            
        conn.commit()
        return stale_count
        
    finally:
        cursor.close()

def get_pending_entries_count(conn):
    """Get count of pending entries"""
    cursor = conn.cursor()
    try:
        query = f"""
        SELECT COUNT(*) 
        FROM {SNOWFLAKE_TABLE}
        WHERE status = 'pending'
          AND (retry_count < 3 OR retry_count IS NULL)
        """
        
        cursor.execute(query)
        result = cursor.fetchone()
        return result[0] if result else 0
        
    finally:
        cursor.close()

def calculate_containers_needed(entry_count):
    """Calculate number of containers needed"""
    if entry_count == 0:
        return 0
    
    containers_needed = math.ceil(entry_count / ENTRIES_PER_CONTAINER)
    return min(containers_needed, MAX_CONTAINERS)

def launch_ecs_tasks(count):
    """Launch ECS tasks"""
    launched = []
    
    for i in range(count):
        try:
            processor_id = f"{ENVIRONMENT}-{datetime.utcnow().strftime('%Y%m%d%H%M%S')}-{uuid.uuid4().hex[:8]}"
            
            response = ecs_client.run_task(
                cluster=ECS_CLUSTER,
                taskDefinition=ECS_TASK_DEFINITION,
                launchType='FARGATE',
                networkConfiguration={
                    'awsvpcConfiguration': {
                        'subnets': ECS_SUBNETS,
                        'securityGroups': [ECS_SECURITY_GROUP],
                        'assignPublicIp': 'DISABLED'
                    }
                },
                overrides={
                    'containerOverrides': [
                        {
                            'name': 'processor',
                            'environment': [
                                {
                                    'name': 'PROCESSOR_ID',
                                    'value': processor_id
                                },
                                {
                                    'name': 'MAX_ENTRIES',
                                    'value': str(ENTRIES_PER_CONTAINER)
                                }
                            ]
                        }
                    ]
                }
            )
            
            if response['tasks']:
                task_arn = response['tasks'][0]['taskArn']
                launched.append({
                    'taskArn': task_arn,
                    'processorId': processor_id
                })
                logger.info(f"Launched task {task_arn} with processor_id {processor_id}")
            
        except Exception as e:
            logger.error(f"Failed to launch task {i+1}/{count}: {str(e)}")
    
    return launched

def handler(event, context):
    """Lambda handler function"""
    logger.info(f"Starting Snowflake poller - Environment: {ENVIRONMENT}")
    
    conn = None
    try:
        # Connect to Snowflake
        conn = get_snowflake_connection()
        
        # Reset stale entries
        stale_count = reset_stale_entries(conn)
        
        # Get pending entries count
        pending_count = get_pending_entries_count(conn)
        logger.info(f"Found {pending_count} pending entries")
        
        # Calculate containers needed
        containers_needed = calculate_containers_needed(pending_count)
        logger.info(f"Need to launch {containers_needed} containers")
        
        # Launch ECS tasks
        if containers_needed > 0:
            launched_tasks = launch_ecs_tasks(containers_needed)
            logger.info(f"Successfully launched {len(launched_tasks)} tasks")
            
            return {
                'statusCode': 200,
                'body': json.dumps({
                    'pendingEntries': pending_count,
                    'staleEntriesReset': stale_count,
                    'containersLaunched': len(launched_tasks),
                    'tasks': launched_tasks
                })
            }
        else:
            logger.info("No entries to process")
            return {
                'statusCode': 200,
                'body': json.dumps({
                    'pendingEntries': 0,
                    'staleEntriesReset': stale_count,
                    'containersLaunched': 0,
                    'tasks': []
                })
            }
            
    except Exception as e:
        logger.error(f"Error in poller: {str(e)}")
        raise
        
    finally:
        if conn:
            conn.close()
```

### 2.2 Container Processor Application

```python
# container/processor.py

import os
import sys
import json
import boto3
import snowflake.connector
import asyncio
import aiohttp
import ssl
import tempfile
from datetime import datetime
import logging
import signal
from concurrent.futures import ThreadPoolExecutor

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Configuration
PROCESSOR_ID = os.environ.get('PROCESSOR_ID', 'unknown')
MAX_ENTRIES = int(os.environ.get('MAX_ENTRIES', '8'))
ENVIRONMENT = os.environ['ENVIRONMENT']
CERT_BUCKET = os.environ['CERT_BUCKET']

# Snowflake configuration
SNOWFLAKE_ACCOUNT = os.environ['SNOWFLAKE_ACCOUNT']
SNOWFLAKE_WAREHOUSE = os.environ['SNOWFLAKE_WAREHOUSE']
SNOWFLAKE_DATABASE = os.environ['SNOWFLAKE_DATABASE']
SNOWFLAKE_SCHEMA = os.environ['SNOWFLAKE_SCHEMA']
SNOWFLAKE_TABLE = os.environ['SNOWFLAKE_TABLE']
SNOWFLAKE_USER = os.environ['SNOWFLAKE_USER']
SNOWFLAKE_PASSWORD = os.environ['SNOWFLAKE_PASSWORD']

# External service configuration
EXTERNAL_SERVICE_URL = os.environ.get('EXTERNAL_SERVICE_URL', 'https://api.example.com/process')

s3_client = boto3.client('s3')

class CertificateManager:
    """Manages downloading and storing certificates"""
    
    def __init__(self):
        self.cert_dir = tempfile.mkdtemp()
        self.cert_path = None
        self.key_path = None
        self.ca_path = None
    
    def download_certificates(self):
        """Download certificates from S3"""
        try:
            cert_prefix = f"{ENVIRONMENT}/"
            
            # Download client certificate
            self.cert_path = os.path.join(self.cert_dir, 'client.pem')
            s3_client.download_file(
                CERT_BUCKET,
                f"{cert_prefix}client.pem",
                self.cert_path
            )
            
            # Download client key
            self.key_path = os.path.join(self.cert_dir, 'client-key.pem')
            s3_client.download_file(
                CERT_BUCKET,
                f"{cert_prefix}client-key.pem",
                self.key_path
            )
            
            # Download CA certificate
            self.ca_path = os.path.join(self.cert_dir, 'ca-cert.pem')
            s3_client.download_file(
                CERT_BUCKET,
                f"{cert_prefix}ca-cert.pem",
                self.ca_path
            )
            
            logger.info("Successfully downloaded certificates")
            return True
            
        except Exception as e:
            logger.error(f"Failed to download certificates: {str(e)}")
            return False
    
    def get_ssl_context(self):
        """Create SSL context with client certificates"""
        ssl_context = ssl.create_default_context(cafile=self.ca_path)
        ssl_context.load_cert_chain(certfile=self.cert_path, keyfile=self.key_path)
        return ssl_context
    
    def cleanup(self):
        """Clean up temporary certificate files"""
        try:
            if self.cert_path and os.path.exists(self.cert_path):
                os.remove(self.cert_path)
            if self.key_path and os.path.exists(self.key_path):
                os.remove(self.key_path)
            if self.ca_path and os.path.exists(self.ca_path):
                os.remove(self.ca_path)
            if self.cert_dir and os.path.exists(self.cert_dir):
                os.rmdir(self.cert_dir)
        except Exception as e:
            logger.warning(f"Certificate cleanup error: {str(e)}")

class SnowflakeProcessor:
    """Main processor class"""
    
    def __init__(self):
        self.processor_id = PROCESSOR_ID
        self.cert_manager = CertificateManager()
        self.conn = None
        self.shutdown = False
        
    def get_connection(self):
        """Get Snowflake connection"""
        return snowflake.connector.connect(
            user=SNOWFLAKE_USER,
            password=SNOWFLAKE_PASSWORD,
            account=SNOWFLAKE_ACCOUNT,
            warehouse=SNOWFLAKE_WAREHOUSE,
            database=SNOWFLAKE_DATABASE,
            schema=SNOWFLAKE_SCHEMA
        )
    
    def claim_entries(self, count):
        """Atomically claim entries for processing"""
        cursor = self.conn.cursor()
        try:
            # Use a single UPDATE statement with LIMIT for atomic claiming
            query = f"""
            UPDATE {SNOWFLAKE_TABLE}
            SET status = 'processing',
                processor_id = %s,
                claimed_at = %s
            WHERE id IN (
                SELECT id 
                FROM {SNOWFLAKE_TABLE}
                WHERE status = 'pending'
                  AND (retry_count < 3 OR retry_count IS NULL)
                ORDER BY created_at ASC
                LIMIT %s
                FOR UPDATE
            )
            RETURNING id, data
            """
            
            cursor.execute(query, (self.processor_id, datetime.utcnow(), count))
            
            entries = []
            for row in cursor:
                entries.append({
                    'id': row[0],
                    'data': json.loads(row[1]) if isinstance(row[1], str) else row[1]
                })
            
            self.conn.commit()
            logger.info(f"Claimed {len(entries)} entries")
            return entries
            
        except Exception as e:
            self.conn.rollback()
            logger.error(f"Failed to claim entries: {str(e)}")
            return []
        finally:
            cursor.close()
    
    def mark_entry_completed(self, entry_id):
        """Mark an entry as completed"""
        cursor = self.conn.cursor()
        try:
            query = f"""
            UPDATE {SNOWFLAKE_TABLE}
            SET status = 'completed',
                completed_at = %s
            WHERE id = %s AND processor_id = %s
            """
            
            cursor.execute(query, (datetime.utcnow(), entry_id, self.processor_id))
            self.conn.commit()
            
        except Exception as e:
            self.conn.rollback()
            logger.error(f"Failed to mark entry {entry_id} as completed: {str(e)}")
        finally:
            cursor.close()
    
    def mark_entry_failed(self, entry_id, error_message):
        """Mark an entry as failed"""
        cursor = self.conn.cursor()
        try:
            query = f"""
            UPDATE {SNOWFLAKE_TABLE}
            SET status = 'failed',
                failed_at = %s,
                error_message = %s
            WHERE id = %s AND processor_id = %s
            """
            
            cursor.execute(query, (datetime.utcnow(), error_message[:1000], entry_id, self.processor_id))
            self.conn.commit()
            
        except Exception as e:
            self.conn.rollback()
            logger.error(f"Failed to mark entry {entry_id} as failed: {str(e)}")
        finally:
            cursor.close()
    
    async def process_entry(self, session, entry, ssl_context):
        """Process a single entry by calling external service"""
        entry_id = entry['id']
        
        try:
            logger.info(f"Processing entry {entry_id}")
            
            # Prepare request payload
            payload = {
                'entry_id': entry_id,
                'data': entry['data'],
                'processor_id': self.processor_id,
                'timestamp': datetime.utcnow().isoformat()
            }
            
            # Call external service
            async with session.post(
                EXTERNAL_SERVICE_URL,
                json=payload,
                ssl=ssl_context,
                timeout=aiohttp.ClientTimeout(total=30)
            ) as response:
                
                if response.status == 200:
                    result = await response.json()
                    logger.info(f"Successfully processed entry {entry_id}")
                    self.mark_entry_completed(entry_id)
                    return {'entry_id': entry_id, 'status': 'success', 'result': result}
                else:
                    error_msg = f"External service returned status {response.status}"
                    logger.error(f"Failed to process entry {entry_id}: {error_msg}")
                    self.mark_entry_failed(entry_id, error_msg)
                    return {'entry_id': entry_id, 'status': 'failed', 'error': error_msg}
                    
        except asyncio.TimeoutError:
            error_msg = "External service timeout"
            logger.error(f"Timeout processing entry {entry_id}")
            self.mark_entry_failed(entry_id, error_msg)
            return {'entry_id': entry_id, 'status': 'failed', 'error': error_msg}
            
        except Exception as e:
            error_msg = str(e)
            logger.error(f"Error processing entry {entry_id}: {error_msg}")
            self.mark_entry_failed(entry_id, error_msg)
            return {'entry_id': entry_id, 'status': 'failed', 'error': error_msg}
    
    async def process_batch(self, entries):
        """Process a batch of entries concurrently"""
        ssl_context = self.cert_manager.get_ssl_context()
        
        connector = aiohttp.TCPConnector(ssl=ssl_context)
        async with aiohttp.ClientSession(connector=connector) as session:
            tasks = [
                self.process_entry(session, entry, ssl_context)
                for entry in entries
            ]
            
            results = await asyncio.gather(*tasks, return_exceptions=True)
            
            # Log results
            successful = sum(1 for r in results if isinstance(r, dict) and r.get('status') == 'success')
            failed = len(results) - successful
            
            logger.info(f"Batch processing completed: {successful} successful, {failed} failed")
            return results
    
    def signal_handler(self, signum, frame):
        """Handle shutdown signals"""
        logger.info(f"Received signal {signum}, initiating shutdown...")
        self.shutdown = True
    
    def run(self):
        """Main processing loop"""
        # Set up signal handlers
        signal.signal(signal.SIGTERM, self.signal_handler)
        signal.signal(signal.SIGINT, self.signal_handler)
        
        try:
            # Download certificates
            if not self.cert_manager.download_certificates():
                logger.error("Failed to download certificates, exiting")
                return 1
            
            # Connect to Snowflake
            self.conn = self.get_connection()
            logger.info(f"Connected to Snowflake as processor {self.processor_id}")
            
            # Claim entries
            entries = self.claim_entries(MAX_ENTRIES)
            
            if not entries:
                logger.info("No entries to process")
                return 0
            
            logger.info(f"Starting to process {len(entries)} entries")
            
            # Process entries
            loop = asyncio.new_event_loop()
            asyncio.set_event_loop(loop)
            results = loop.run_until_complete(self.process_batch(entries))
            loop.close()
            
            # Summary
            successful = sum(1 for r in results if isinstance(r, dict) and r.get('status') == 'success')
            logger.info(f"Processing complete: {successful}/{len(entries)} successful")
            
            return 0
            
        except Exception as e:
            logger.error(f"Fatal error: {str(e)}")
            return 1
            
        finally:
            # Cleanup
            if self.conn:
                self.conn.close()
            self.cert_manager.cleanup()

def main():
    """Entry point"""
    processor = SnowflakeProcessor()
    sys.exit(processor.run())

if __name__ == '__main__':
    main()