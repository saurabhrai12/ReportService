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
          valueFrom = "${aws_secretsmanager_secret.snowflake_creds.arn}:username::"
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