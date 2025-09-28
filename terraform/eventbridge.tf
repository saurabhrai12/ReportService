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