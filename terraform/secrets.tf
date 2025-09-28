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