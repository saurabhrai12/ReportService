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