# Report Service - Complete Setup Guide

This guide provides step-by-step instructions to set up the entire Report Service infrastructure from scratch, including AWS resources, Snowflake configuration, and auto-trigger functionality.

## Prerequisites

Before starting, ensure you have:

1. **AWS CLI configured** with appropriate permissions
2. **Terraform installed** (v1.0+)
3. **SnowSQL installed** and configured
4. **Docker installed** (for building container images)
5. **Snowflake account** with ACCOUNTADMIN role access

## Project Structure

```
ReportService/
├── terraform/           # Infrastructure as Code
│   ├── main.tf         # Main Terraform configuration
│   ├── variables.tf    # Variable definitions
│   ├── outputs.tf      # Output values
│   └── index.py        # Lambda function code
├── snowflake/          # Snowflake SQL scripts
│   ├── 01_database_setup.sql
│   ├── 02_streams_and_views.sql
│   ├── 03_stored_procedures.sql
│   ├── 04_tasks_setup.sql
│   └── 05_api_integration_setup.sql
├── src/                # Python application code
│   ├── report_service.py
│   ├── requirements.txt
│   └── Dockerfile
└── SETUP.md           # This setup guide
```

## Step 1: Infrastructure Deployment

### 1.1 Navigate to Terraform Directory

⚠️ **IMPORTANT**: All Terraform commands must be run from the `terraform` directory!

```bash
# From project root
cd terraform
```

### 1.2 Initialize Terraform

```bash
# Ensure you're in the terraform directory
pwd  # Should show: .../ReportService/terraform
terraform init
```

### 1.3 Deploy Infrastructure

```bash
# Deploy from terraform directory only
terraform apply -auto-approve
```

**Expected Outputs:**
- API Gateway URL: `https://xxxxx.execute-api.us-east-1.amazonaws.com/prod/trigger`
- IAM Role ARN: `arn:aws:iam::ACCOUNT:role/report-service-snowflake-integration-role`
- ECS Cluster: `report-service-cluster`
- ECS Service: `report-service`

### 1.4 Note Important Values

Save these values from Terraform output:
```bash
# Run from terraform directory
terraform output
```

## Step 2: Snowflake Configuration

### 2.1 Configure SnowSQL Connection

Create or update SnowSQL configuration:

```bash
# Location: ~/.snowflake/config.toml
[connections.retailworks-dev]
account = "OILZKIQ-ID94597"
user = "SAURABHMAC"
authenticator = "snowflake"
password = "AwsSnowAdmin1234"
database = "REPORTING_DB"
schema = "CONFIG"
warehouse = "COMPUTE_WH"
role = "ACCOUNTADMIN"
```

### 2.2 Execute Snowflake Setup Scripts

Run each script in order:

```bash
# From project root, execute Snowflake scripts
# 1. Database and schema setup
snowsql -c retailworks-dev -f snowflake/01_database_setup.sql

# 2. Streams and views
snowsql -c retailworks-dev -f snowflake/02_streams_and_views.sql

# 3. Stored procedures
snowsql -c retailworks-dev -f snowflake/03_stored_procedures.sql

# 4. Tasks setup
snowsql -c retailworks-dev -f snowflake/04_tasks_setup.sql
```

### 2.3 Update API Integration

Edit the `05_api_integration_setup.sql` file with actual values from Terraform output:

```sql
-- Update with your actual values
CREATE OR REPLACE API INTEGRATION AWS_ECS_TRIGGER_INTEGRATION
    API_PROVIDER = 'aws_api_gateway'
    API_AWS_ROLE_ARN = 'arn:aws:iam::203977009513:role/report-service-snowflake-integration-role'
    ENABLED = TRUE
    API_ALLOWED_PREFIXES = ('https://cjozwgpj6h.execute-api.us-east-1.amazonaws.com/')
    COMMENT = 'Integration for triggering ECS service from Snowflake';

CREATE OR REPLACE EXTERNAL FUNCTION TRIGGER_ECS_SERVICE()
RETURNS VARIANT
API_INTEGRATION = AWS_ECS_TRIGGER_INTEGRATION
HEADERS = ('Content-Type' = 'application/json')
MAX_BATCH_ROWS = 1
AS 'https://cjozwgpj6h.execute-api.us-east-1.amazonaws.com/prod/trigger';
```

```bash
# Execute the API integration setup
snowsql -c retailworks-dev -f snowflake/05_api_integration_setup.sql
```

## Step 3: AWS IAM Trust Policy Setup

### 3.1 Get Snowflake External ID

```bash
snowsql -c retailworks-dev -q "DESC INTEGRATION AWS_ECS_TRIGGER_INTEGRATION;"
```

Look for the `API_AWS_EXTERNAL_ID` value (e.g., `ZE37870_SFCRole=23_Z3tj8JgLMtZogASpegcoQo1OoNw=`)

### 3.2 Update IAM Trust Policy

```bash
# Create trust policy file
cat > /tmp/trust-policy.json << 'EOF'
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "AWS": "arn:aws:iam::529587499086:user/wnu31000-s"
            },
            "Action": "sts:AssumeRole",
            "Condition": {
                "StringEquals": {
                    "sts:ExternalId": "ZE37870_SFCRole=23_Z3tj8JgLMtZogASpegcoQo1OoNw="
                }
            }
        }
    ]
}
EOF

# Update the IAM role trust policy
aws iam update-assume-role-policy \
    --role-name report-service-snowflake-integration-role \
    --policy-document file:///tmp/trust-policy.json
```

## Step 4: Testing the Integration

### 4.1 Test External Function

```bash
snowsql -c retailworks-dev -q "SELECT TRIGGER_ECS_SERVICE();"
```

**Expected Response:**
```json
{
  "message": "ECS service triggered successfully for ADHOC processing",
  "service": "arn:aws:ecs:us-east-1:203977009513:service/report-service-cluster/report-service",
  "trigger_type": "ADHOC",
  "desired_count": 1,
  "timestamp": "uuid-here"
}
```

### 4.2 Test Stored Procedure

```bash
snowsql -c retailworks-dev -q "CALL REPORTING_DB.CONFIG.SEND_ECS_TRIGGER();"
```

### 4.3 Verify ECS Service

```bash
aws ecs describe-services \
    --cluster report-service-cluster \
    --services report-service \
    --query 'services[0].{DesiredCount:desiredCount,RunningCount:runningCount,Status:status}'
```

## Step 5: Start Auto-Trigger System

### 5.1 Start Snowflake Tasks

```bash
snowsql -c retailworks-dev -q "CALL REPORTING_DB.CONFIG.START_ALL_TASKS();"
```

### 5.2 Verify Task Status

```bash
snowsql -c retailworks-dev -q "SHOW TASKS IN SCHEMA REPORTING_DB.CONFIG;"
```

Both tasks should show `state = started`.

## Step 6: End-to-End Testing

### 6.1 Add Test Report

```bash
snowsql -c retailworks-dev -q "
INSERT INTO REPORTING_DB.CONFIG.REPORT_CONFIG (
    CONFIG_ID,
    REPORT_NAME,
    TRIGGER_TYPE,
    STATUS
) VALUES (
    'TEST_REPORT_' || TO_CHAR(CURRENT_TIMESTAMP(), 'YYYYMMDDHH24MISS'),
    'End-to-End Test Report',
    'ADHOC',
    'PENDING'
);"
```

### 6.2 Monitor Auto-Trigger

Wait 1-5 minutes and check:

```bash
# Check stream status
snowsql -c retailworks-dev -q "SELECT COUNT(*) FROM REPORTING_DB.CONFIG.V_INSERT_STREAM_DATA;"

# Check ECS service
aws ecs describe-services --cluster report-service-cluster --services report-service --query 'services[0].desiredCount'

# Check trigger audit log
snowsql -c retailworks-dev -q "SELECT * FROM REPORTING_DB.CONFIG.TRIGGER_AUDIT_LOG ORDER BY TRIGGER_TIMESTAMP DESC LIMIT 5;"
```

## System Architecture

### AWS Components

- **ECS Fargate Cluster**: Runs the report processing service
- **API Gateway**: Receives trigger requests from Snowflake
- **Lambda Function**: Triggers ECS service scaling (0→1)
- **IAM Roles**: Secure communication between services
- **CloudWatch**: Logging and monitoring

### Snowflake Components

- **Database**: `REPORTING_DB` with `CONFIG` schema
- **Tables**: `REPORT_CONFIG`, `TRIGGER_AUDIT_LOG`
- **Stream**: `REPORT_CONFIG_INSERT_STREAM` for change data capture
- **View**: `V_INSERT_STREAM_DATA` for filtered stream data
- **External Function**: `TRIGGER_ECS_SERVICE()` calls AWS API Gateway
- **Stored Procedure**: `SEND_ECS_TRIGGER()` processes stream and triggers ECS
- **Tasks**: Auto-running tasks that monitor streams every 5 minutes

### Data Flow

1. **Report Insert**: New report added to `REPORT_CONFIG` table
2. **Stream Capture**: Change captured in `REPORT_CONFIG_INSERT_STREAM`
3. **Task Trigger**: `ECS_TRIGGER_TASK` runs every 5 minutes
4. **Stream Check**: Task checks if stream has data
5. **API Call**: If data exists, calls `TRIGGER_ECS_SERVICE()` external function
6. **ECS Scaling**: Lambda scales ECS service from 0 to 1
7. **Report Processing**: ECS container processes reports and scales back to 0
8. **Stream Consumption**: Stream data consumed and cleared

## Troubleshooting

### Common Issues

1. **External Function 403 Error**
   - Check IAM trust policy External ID matches Snowflake integration
   - Verify API Gateway URL in external function definition

2. **ECS Service Not Scaling**
   - Check Lambda function logs in CloudWatch
   - Verify ECS service ARN in Lambda environment variables

3. **Tasks Not Running**
   - Ensure tasks are started: `CALL START_ALL_TASKS()`
   - Check warehouse permissions and credits

4. **Stream Not Consuming**
   - Verify stored procedure creates temporary table to consume stream
   - Check that tasks have proper permissions

### Monitoring Commands

```bash
# Check task execution history
snowsql -c retailworks-dev -q "SELECT * FROM TABLE(INFORMATION_SCHEMA.TASK_HISTORY()) WHERE NAME = 'ECS_TRIGGER_TASK' ORDER BY SCHEDULED_TIME DESC LIMIT 10;"

# Check Lambda logs
aws logs tail /aws/lambda/report-service-ecs-trigger --follow

# Check ECS service events
aws ecs describe-services --cluster report-service-cluster --services report-service --query 'services[0].events'
```

## Security Notes

- **Credentials**: Snowflake credentials stored in AWS Secrets Manager
- **IAM Roles**: Least privilege access for all components
- **Network**: ECS tasks run in private subnets with NAT gateway access
- **API Gateway**: CORS enabled, no authentication (internal use)
- **External ID**: Unique identifier for Snowflake→AWS trust relationship

## Cleanup

To remove all resources:

```bash
# Stop Snowflake tasks first
snowsql -c retailworks-dev -q "CALL REPORTING_DB.CONFIG.STOP_ALL_TASKS();"

# Navigate to terraform directory for infrastructure cleanup
cd terraform

# Verify you're in the correct directory
pwd  # Should show: .../ReportService/terraform

# Destroy AWS infrastructure
terraform destroy -auto-approve

# Optional: Remove Snowflake objects
snowsql -c retailworks-dev -q "DROP DATABASE REPORTING_DB;"
```

⚠️ **CRITICAL**: Always run `terraform destroy` from the `terraform` directory to ensure proper state management!

---

## Support

For issues or questions, refer to:
- AWS CloudWatch logs for Lambda and ECS
- Snowflake Query History for SQL execution details
- Terraform state for infrastructure status