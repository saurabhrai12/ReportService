# Enhanced Report Service

A production-ready, scalable report generation service built on AWS with Snowflake integration, supporting dual trigger modes (ADHOC and SCHEDULED) with automatic scaling capabilities.

> **📋 Project Status**: This project has been successfully developed and tested. The AWS infrastructure has been decommissioned but all source code, documentation, and deployment scripts remain available for reference or future deployment.

## 🚀 Features

### Core Capabilities
- **Dual Trigger Architecture**: Support for both immediate ADHOC reports and time-based SCHEDULED reports
- **Auto-Scaling**: ECS service automatically scales to 0 when idle and scales up when work is available
- **Cloud-Native**: Fully serverless architecture using AWS services
- **High Performance**: Parallel processing with optimized resource utilization
- **Cost Efficient**: 30-minute polling interval with intelligent scaling

### Integration Support
- **Snowflake Integration**: Native integration with Snowflake data warehouse
- **AWS Secrets Manager**: Secure credential management
- **API Gateway**: RESTful triggers for external systems
- **CloudWatch**: Comprehensive monitoring and logging
- **Lambda Functions**: Serverless trigger endpoints

### Report Management
- **Priority-Based Processing**: ADHOC reports processed with high priority
- **Status Tracking**: Real-time report status (PENDING → PROCESSING → COMPLETED/FAILED)
- **Multiple Output Formats**: Support for PDF, EXCEL, CSV formats
- **Notification System**: Email/SNS notifications on completion
- **Audit Trail**: Complete processing history and metrics

## 🏗️ Architecture

The architecture uses a simple, event-driven flow from Snowflake to AWS:

**Snowflake:**
1.  **`REPORT_CONFIG` Table**: Stores all report requests.
2.  **`..._INSERT_STREAM`**: A single stream captures any new report inserted into the table.
3.  **`ECS_TRIGGER_TASK`**: A single task runs every 2 minutes, checks the stream for data.
4.  **`SEND_ECS_TRIGGER` Procedure**: If the stream has data, the task calls this procedure.
5.  **`TRIGGER_ECS_SERVICE` Function**: The procedure calls this external function.

**AWS:**
6.  **API Gateway**: The external function makes a secure call to a single `/trigger` endpoint.
7.  **Lambda Function**: The API Gateway invokes a single, generic Lambda function.
8.  **ECS Service**: The Lambda function starts the ECS service by setting its desired count to 1. The service runs the report engine, processes ALL pending reports from the Snowflake table, and then automatically scales back down to 0.

## 📋 Prerequisites

- AWS CLI configured with appropriate permissions
- Terraform >= 1.0
- Docker with BuildKit support
- Snowflake account with:
  - CORTEX_USER_ROLE permissions
  - COMPUTE_WH warehouse access
  - REPORTING_DB database access

## 🛠️ Setup Instructions

> **⚠️ Infrastructure Removed**: The AWS infrastructure for this project has been destroyed. The codebase remains available for reference and future deployment.

### 1. Environment Configuration

```bash
# Clone and setup
git clone <repository-url>
cd ReportService

# Configure AWS credentials (if deploying)
aws configure

# Create Python virtual environment
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

### 2. Snowflake Setup

```bash
# Update Snowflake configuration (if deploying)
cp terraform/terraform.tfvars.example terraform/terraform.tfvars

# Edit terraform.tfvars with your values:
# snowflake_account = "YOUR-ACCOUNT-ID"
# aws_region = "us-east-1"
# environment = "production"
```

### 3. Deploy Infrastructure (Optional)

```bash
# Deploy all AWS resources (if needed)
./scripts/deploy.sh --image-tag <account-id>.dkr.ecr.<region>.amazonaws.com/report-service:latest
```

### 4. Snowflake Database Setup

Execute the SQL scripts in the `snowflake/` directory in numerical order (`01` to `04`). After you run the main deployment script (`deploy.sh`), it will generate a final script named `snowflake/run_after_deploy.sql`. You must run this script last to finalize the connection from Snowflake to your new AWS API Gateway endpoint.

```bash
# Connect to Snowflake and run:
USE ROLE CORTEX_USER_ROLE; # Or your appropriate role

# Execute scripts in order:
# 1. snowflake/01_enhanced_config_table.sql
# 2. snowflake/02_streams_setup.sql  
# 3. snowflake/03_stored_procedures.sql
# 4. snowflake/04_tasks_setup.sql
# 5. snowflake/run_after_deploy.sql (After running ./scripts/deploy.sh)
```

### 5. Configure Secrets

Update AWS Secrets Manager with Snowflake credentials:
```bash
# Create consolidated secret
aws secretsmanager create-secret \
  --name "report-service/snowflake" \
  --description "Snowflake credentials for report service" \
  --secret-string '{
    "account": "YOUR-ACCOUNT-ID",
    "user": "YOUR-USERNAME", 
    "password": "YOUR-PASSWORD",
    "database": "REPORTING_DB",
    "warehouse": "COMPUTE_WH",
    "schema": "CONFIG"
  }'
```

## 🎯 Usage

### Triggering the Report Service

The simplified architecture uses a single, generic trigger. Any new report inserted into the Snowflake `REPORT_CONFIG` table will be detected, and a trigger will be sent to start the ECS service. The service will then process all available pending reports.

You can manually trigger the service to wake it up and process any pending reports using the following API call:

```bash
# Trigger via API Gateway
curl -X POST https://<api-gateway-id>.execute-api.<region>.amazonaws.com/prod/trigger \
  -H "Content-Type: application/json" \
  -d '{}' # The body can be empty as the service processes all pending reports from the database

# Or use the updated test payload script
./scripts/invoke_lambdas.sh
```


### Monitor Status

```bash
# Check ECS service status
aws ecs describe-services --cluster report-service-cluster --services report-service

# View logs
aws logs tail /ecs/report-service --follow
```

## 📊 Monitoring & Operations

### CloudWatch Dashboards
- **ECS Metrics**: Task count, CPU/memory utilization
- **Lambda Metrics**: Invocation count, duration, errors
- **Snowflake Metrics**: Connection status, query performance

### Key Metrics
- Reports processed per hour
- Average processing time
- Error rates and types
- Cost optimization metrics

### Operational Commands

```bash
# Scale service manually
aws ecs update-service --cluster report-service-cluster --service report-service --desired-count 1

# Force new deployment
aws ecs update-service --cluster report-service-cluster --service report-service --force-new-deployment

# Check Snowflake integration
python test_snowflake_connection.py
```

## 🔧 Configuration

### Report Types
Configure in `snowflake/01_enhanced_config_table.sql`:
- **ADHOC**: Immediate processing, high priority
- **SCHEDULED**: Time-based processing, batch mode

### Polling Frequency
Default: 30 minutes (configurable in `src/report_service.py:576`)

### Output Formats
- PDF: High-quality formatted reports
- EXCEL: Data analysis and manipulation
- CSV: Raw data export

### Notification Settings
- Email recipients per report
- SNS topic integration
- Slack webhook support (optional)

## 🚦 Troubleshooting

### Common Issues

**Snowflake Connection Failed**
```bash
# Check credentials
aws secretsmanager get-secret-value --secret-id report-service/snowflake

# Test connection
source .venv/bin/activate
python test_snowflake_connection.py
```

**ECS Task Failing**
```bash
# Check logs
aws logs get-log-events --log-group-name "/ecs/report-service" \
  --log-stream-name $(aws logs describe-log-streams --log-group-name "/ecs/report-service" \
  --order-by LastEventTime --descending --max-items 1 --query 'logStreams[0].logStreamName' --output text)
```

**Lambda Permission Errors**
```bash
# Check IAM roles
aws iam get-role-policy --role-name report-service-lambda-role --policy-name LambdaECSAccess
```

### Debug Mode
Enable verbose logging by setting `LOG_LEVEL=DEBUG` in ECS task definition.

## 📈 Performance Optimization

### Scaling Configuration
- **Min Capacity**: 0 (cost-efficient)
- **Max Capacity**: 10 (configurable)
- **Scaling Trigger**: Queue depth > 5 reports

### Resource Allocation
- **CPU**: 512 (0.5 vCPU)
- **Memory**: 1024 MB
- **Network**: awsvpc mode with public IP

### Database Optimization
- Snowflake streams for change detection
- Indexed queries on CONFIG_ID and STATUS
- Batch processing for scheduled reports

## 🛡️ Security

### AWS IAM Roles
- **Lambda Execution Role**: ECS service control
- **ECS Task Role**: Secrets Manager + Snowflake access
- **Snowflake Integration Role**: API Gateway invoke permissions

### Network Security
- ECS tasks in private subnets (optional)
- Security groups with minimal required ports
- API Gateway with authentication (optional)

### Data Protection
- Secrets encrypted at rest in Secrets Manager
- TLS encryption for all API communications
- Snowflake OCSP certificate validation

## 🔄 CI/CD Integration

### GitHub Actions (Example)
```yaml
name: Deploy Report Service
on:
  push:
    branches: [main]
jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Deploy to AWS
        run: ./scripts/deploy.sh --image-tag ${{ secrets.ECR_REGISTRY }}/report-service:${{ github.sha }}
```

### Deployment Pipeline
1. **Build**: Docker image with latest code
2. **Test**: Unit tests + integration tests  
3. **Deploy**: Terraform apply + ECS service update
4. **Verify**: Health checks + smoke tests

## 📝 API Reference

### Trigger Endpoint

**Unified Trigger**
- **URL**: `POST /prod/trigger`
- **Payload**: The request body is optional and currently not used. Any valid JSON object (e.g., `{}`) is sufficient.
- **Response**: `{"message": "ECS service triggered successfully...", ...}`

### Status Codes
- **200**: Success
- **500**: Internal server error

## 📄 License

MIT License - see LICENSE file for details.

## 🤝 Contributing

1. Fork the repository
2. Create feature branch (`git checkout -b feature/new-feature`)
3. Commit changes (`git commit -am 'Add new feature'`)
4. Push to branch (`git push origin feature/new-feature`)
5. Create Pull Request

## 📞 Support

For issues and questions:
- Create GitHub issue for bugs/features
- Check CloudWatch logs for operational issues  
- Review Snowflake query history for data problems

---

**Built with ❤️ using AWS, Snowflake, and modern DevOps practices**