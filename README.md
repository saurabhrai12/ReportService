# Snowflake Processor System

A serverless system for processing Snowflake queue entries using AWS Lambda, ECS Fargate, and external services with SSL certificate authentication.

## Architecture

The system uses a polling architecture where:
1. EventBridge triggers a Lambda function every minute
2. Lambda queries Snowflake for pending entries
3. Lambda calculates the number of containers needed
4. Lambda launches ECS Fargate tasks to process entries
5. ECS containers process entries by calling external services
6. Results are updated back to Snowflake

## Features

- **Serverless scaling**: Automatically scales processing containers based on queue depth
- **Fault tolerance**: Automatic retry logic and stale entry recovery
- **SSL/TLS security**: Secure communication with external services using client certificates
- **Monitoring**: Comprehensive CloudWatch dashboards and alarms
- **Cost efficient**: Pay-per-use model with automatic shutdown of idle containers

## Quick Start

### Prerequisites

- AWS CLI configured with appropriate permissions
- Terraform >= 1.0
- Docker
- SnowSQL (for database setup)
- jq (for JSON processing)

### 1. Configuration

```bash
# Copy and configure Terraform variables
cp terraform/terraform.tfvars.example terraform/terraform.tfvars
# Edit terraform/terraform.tfvars with your values
```

### 2. Deploy Infrastructure

```bash
./scripts/deploy.sh dev us-east-1
```

### 3. Setup Database

```bash
export SNOWFLAKE_ACCOUNT="your-account"
export SNOWFLAKE_USER="your-user"
export SNOWFLAKE_PASSWORD="your-password"
./scripts/setup_database.sh
```

### 4. Upload SSL Certificates

Upload your SSL certificates to the S3 bucket created by Terraform:

```bash
# Upload to: s3://dev-snowflake-processor-certs/dev/
aws s3 cp client.pem s3://dev-snowflake-processor-certs/dev/
aws s3 cp client-key.pem s3://dev-snowflake-processor-certs/dev/
aws s3 cp ca-cert.pem s3://dev-snowflake-processor-certs/dev/
```

### 5. Setup Monitoring

```bash
./scripts/setup_monitoring.sh dev us-east-1
```

### 6. Test the System

```bash
./scripts/test_system.sh dev
```

## Project Structure

```
.
├── terraform/              # Infrastructure as Code
│   ├── main.tf             # Main Terraform configuration
│   ├── vpc.tf              # VPC and networking
│   ├── ecs.tf              # ECS cluster and task definitions
│   ├── lambda.tf           # Lambda function configuration
│   ├── iam.tf              # IAM roles and policies
│   ├── secrets.tf          # Secrets Manager configuration
│   └── s3.tf               # S3 bucket for certificates
├── lambda_poller/          # Lambda function code
│   ├── index.py            # Main Lambda handler
│   └── requirements.txt    # Python dependencies
├── container/              # ECS container application
│   ├── processor.py        # Main processor application
│   ├── requirements.txt    # Python dependencies
│   └── Dockerfile          # Container image definition
├── snowflake/              # Database schema and setup
│   ├── 01_create_table.sql # Main table creation
│   ├── 02_sample_data.sql  # Sample data for testing
│   └── 03_monitoring_views.sql # Monitoring views
├── scripts/                # Deployment and utility scripts
│   ├── deploy.sh           # Main deployment script
│   ├── setup_database.sh   # Database setup
│   ├── test_system.sh      # System testing
│   ├── setup_monitoring.sh # Monitoring setup
│   └── cleanup.sh          # Infrastructure cleanup
├── monitoring/             # Monitoring configuration
│   ├── cloudwatch_alarms.tf # CloudWatch alarms
│   └── cloudwatch_dashboard.json # Dashboard definition
└── docker-compose.yml     # Local development setup
```

## Configuration

### Environment Variables

| Variable | Description | Required |
|----------|-------------|----------|
| `ENVIRONMENT` | Environment name (dev/staging/prod) | Yes |
| `SNOWFLAKE_ACCOUNT` | Snowflake account identifier | Yes |
| `SNOWFLAKE_USER` | Snowflake username | Yes |
| `SNOWFLAKE_PASSWORD` | Snowflake password | Yes |
| `SNOWFLAKE_WAREHOUSE` | Snowflake warehouse name | Yes |
| `SNOWFLAKE_DATABASE` | Snowflake database name | Yes |
| `SNOWFLAKE_SCHEMA` | Snowflake schema name | Yes |
| `SNOWFLAKE_TABLE` | Snowflake table name | Yes |
| `EXTERNAL_SERVICE_URL` | URL of external service to call | Yes |
| `ALERT_EMAIL` | Email for CloudWatch alerts | No |

### Processing Configuration

- **Entries per container**: 8 (configurable in Lambda code)
- **Max containers**: 25 (configurable in Lambda code)
- **Stale threshold**: 30 minutes (configurable in Lambda code)
- **Container timeout**: 60 seconds
- **External service timeout**: 30 seconds

## Monitoring

### CloudWatch Dashboard

Access the dashboard at:
```
https://us-east-1.console.aws.amazon.com/cloudwatch/home?region=us-east-1#dashboards:name=dev-snowflake-processor
```

### Key Metrics

- Lambda invocations and errors
- ECS CPU and memory utilization
- ECS task counts
- Processing completion rates

### Alarms

- Lambda function errors
- Lambda function duration
- ECS high CPU utilization
- ECS high memory utilization

### Snowflake Monitoring Views

```sql
-- Queue status summary
SELECT * FROM QUEUE_STATUS_SUMMARY;

-- Daily processing metrics
SELECT * FROM PROCESSING_METRICS;

-- Processor performance
SELECT * FROM PROCESSOR_PERFORMANCE;

-- Stale entries
SELECT * FROM STALE_ENTRIES;

-- Failed entries analysis
SELECT * FROM FAILED_ENTRIES_ANALYSIS;
```

## Development

### Local Testing

1. Set up environment variables in `.env` file
2. Run with Docker Compose:

```bash
docker-compose up --build
```

### Adding New Entry Types

1. Insert data into the `PROCESSING_QUEUE` table:

```sql
INSERT INTO PROCESSING_QUEUE (data) VALUES
('{"type": "new_type", "payload": {...}}');
```

2. The system will automatically pick up and process new entries

## Troubleshooting

### Common Issues

1. **Lambda timeouts**: Check Snowflake connectivity and increase timeout if needed
2. **ECS tasks failing**: Check SSL certificates are uploaded correctly
3. **No entries processed**: Verify Snowflake credentials and table permissions
4. **High costs**: Adjust `MAX_CONTAINERS` and `ENTRIES_PER_CONTAINER` settings

### Logs

```bash
# Lambda logs
aws logs tail /aws/lambda/dev-snowflake-poller --follow

# ECS logs
aws logs tail /ecs/dev-snowflake-processor --follow
```

### Manual Testing

```bash
# Invoke Lambda manually
aws lambda invoke --function-name dev-snowflake-poller --payload '{}' result.json

# Check ECS tasks
aws ecs list-tasks --cluster dev-snowflake-processor
```

## Security

- All communication uses HTTPS/TLS
- SSL client certificates for external service authentication
- Secrets stored in AWS Secrets Manager
- IAM roles with minimal required permissions
- VPC isolation for ECS tasks

## Cost Optimization

- Containers automatically shut down when no work available
- CloudWatch log retention set to 30 days
- ECS Fargate spot instances can be used for cost savings
- Monitoring helps identify optimization opportunities

## Cleanup

To destroy all infrastructure:

```bash
./scripts/cleanup.sh dev
```

**Note**: This will stop all running tasks and destroy all AWS resources. Snowflake tables are not automatically deleted.

## Support

For issues and questions:
1. Check the troubleshooting section
2. Review CloudWatch logs
3. Verify configuration settings
4. Check AWS service limits