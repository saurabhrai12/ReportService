# Deployment Guide

This guide provides step-by-step instructions for deploying the Snowflake Processor System.

## Prerequisites

### Software Requirements

1. **AWS CLI** - Version 2.0 or higher
   ```bash
   aws --version
   ```

2. **Terraform** - Version 1.0 or higher
   ```bash
   terraform --version
   ```

3. **Docker** - For building container images
   ```bash
   docker --version
   ```

4. **SnowSQL** - For database setup
   ```bash
   snowsql --version
   ```

5. **jq** - For JSON processing
   ```bash
   jq --version
   ```

### AWS Permissions

Your AWS credentials need the following permissions:
- EC2 (VPC, Subnets, Security Groups, NAT Gateways)
- ECS (Clusters, Task Definitions, Services)
- Lambda (Functions, Triggers)
- CloudWatch (Logs, Alarms, Dashboards)
- IAM (Roles, Policies)
- S3 (Buckets, Objects)
- Secrets Manager
- EventBridge/CloudWatch Events
- ECR (Repositories)

### Snowflake Requirements

- Snowflake account with SYSADMIN role or equivalent
- Warehouse with sufficient compute resources
- Database and schema creation permissions

## Step-by-Step Deployment

### Step 1: Prepare Configuration

1. **Clone the repository** (if not already done)
   ```bash
   git clone <repository-url>
   cd snowflake-processor
   ```

2. **Configure Terraform variables**
   ```bash
   cp terraform/terraform.tfvars.example terraform/terraform.tfvars
   ```

3. **Edit terraform.tfvars** with your specific values:
   ```hcl
   environment = "dev"
   aws_region  = "us-east-1"

   # Snowflake Configuration
   snowflake_account   = "xy12345.us-east-1"
   snowflake_warehouse = "COMPUTE_WH"
   snowflake_database  = "REPORTING_DB"
   snowflake_schema    = "PUBLIC"
   snowflake_table     = "PROCESSING_QUEUE"

   # Credentials (consider using environment variables)
   snowflake_user     = "your-username"
   snowflake_password = "your-password"

   # Optional: Email for alerts
   alert_email = "admin@yourcompany.com"
   ```

4. **Set up environment variables** (recommended for sensitive data):
   ```bash
   export TF_VAR_snowflake_user="your-username"
   export TF_VAR_snowflake_password="your-password"
   ```

### Step 2: Deploy Infrastructure

1. **Run the deployment script**
   ```bash
   ./scripts/deploy.sh dev us-east-1
   ```

   This script will:
   - Package the Lambda function
   - Create ECR repository
   - Build and push Docker image
   - Deploy all AWS infrastructure

2. **Verify deployment**
   ```bash
   # Check Terraform state
   cd terraform
   terraform output

   # Verify AWS resources
   aws ecs describe-clusters --clusters dev-snowflake-processor
   aws lambda get-function --function-name dev-snowflake-poller
   ```

### Step 3: Set Up Database

1. **Set Snowflake environment variables**
   ```bash
   export SNOWFLAKE_ACCOUNT="xy12345.us-east-1"
   export SNOWFLAKE_USER="your-username"
   export SNOWFLAKE_PASSWORD="your-password"
   export SNOWFLAKE_WAREHOUSE="COMPUTE_WH"
   export SNOWFLAKE_DATABASE="REPORTING_DB"
   export SNOWFLAKE_SCHEMA="PUBLIC"
   ```

2. **Run database setup**
   ```bash
   ./scripts/setup_database.sh
   ```

3. **Verify database setup**
   ```bash
   snowsql -a $SNOWFLAKE_ACCOUNT -u $SNOWFLAKE_USER -p $SNOWFLAKE_PASSWORD \
           -d $SNOWFLAKE_DATABASE -s $SNOWFLAKE_SCHEMA \
           -q "DESCRIBE TABLE PROCESSING_QUEUE;"
   ```

### Step 4: Upload SSL Certificates

1. **Prepare certificates**
   - `client.pem` - Client certificate
   - `client-key.pem` - Client private key
   - `ca-cert.pem` - Certificate Authority certificate

2. **Upload to S3**
   ```bash
   BUCKET_NAME="dev-snowflake-processor-certs"

   aws s3 cp client.pem s3://$BUCKET_NAME/dev/
   aws s3 cp client-key.pem s3://$BUCKET_NAME/dev/
   aws s3 cp ca-cert.pem s3://$BUCKET_NAME/dev/
   ```

3. **Verify upload**
   ```bash
   aws s3 ls s3://$BUCKET_NAME/dev/
   ```

### Step 5: Configure Monitoring

1. **Set up CloudWatch monitoring**
   ```bash
   ./scripts/setup_monitoring.sh dev us-east-1
   ```

2. **Configure email alerts** (optional)
   ```bash
   # Subscribe to SNS topic for alerts
   aws sns subscribe \
     --topic-arn arn:aws:sns:us-east-1:123456789012:dev-snowflake-processor-alerts \
     --protocol email \
     --notification-endpoint admin@yourcompany.com
   ```

### Step 6: Test Deployment

1. **Run system tests**
   ```bash
   ./scripts/test_system.sh dev
   ```

2. **Manual testing**
   ```bash
   # Insert test data
   snowsql -a $SNOWFLAKE_ACCOUNT -u $SNOWFLAKE_USER -p $SNOWFLAKE_PASSWORD \
           -d $SNOWFLAKE_DATABASE -s $SNOWFLAKE_SCHEMA \
           -q "INSERT INTO PROCESSING_QUEUE (data) VALUES ('{\"test\": \"data\"}');"

   # Trigger Lambda manually
   aws lambda invoke \
     --function-name dev-snowflake-poller \
     --payload '{}' \
     response.json

   cat response.json | jq .
   ```

## Environment-Specific Configurations

### Development Environment

```hcl
# terraform/environments/dev.tfvars
environment = "dev"
alert_email = "dev-team@yourcompany.com"

# Smaller instance sizes for cost optimization
lambda_memory_size = 512
ecs_cpu = 256
ecs_memory = 512
```

### Staging Environment

```hcl
# terraform/environments/staging.tfvars
environment = "staging"
alert_email = "staging-alerts@yourcompany.com"

# Production-like sizing
lambda_memory_size = 512
ecs_cpu = 1024
ecs_memory = 2048
```

### Production Environment

```hcl
# terraform/environments/prod.tfvars
environment = "prod"
alert_email = "production-alerts@yourcompany.com"

# Full production sizing
lambda_memory_size = 1024
ecs_cpu = 2048
ecs_memory = 4096

# Enhanced monitoring
enable_detailed_monitoring = true
```

## Multi-Environment Deployment

To deploy multiple environments:

1. **Create environment-specific variable files**
   ```bash
   mkdir -p terraform/environments
   # Create dev.tfvars, staging.tfvars, prod.tfvars
   ```

2. **Deploy each environment**
   ```bash
   # Development
   terraform apply -var-file="environments/dev.tfvars"

   # Staging
   terraform apply -var-file="environments/staging.tfvars"

   # Production
   terraform apply -var-file="environments/prod.tfvars"
   ```

## Rollback Procedures

### Application Rollback

1. **Rollback container image**
   ```bash
   # Tag previous working image as latest
   docker tag $ECR_REPO_URL:previous-tag $ECR_REPO_URL:latest
   docker push $ECR_REPO_URL:latest

   # Force ECS to use new image
   aws ecs update-service \
     --cluster dev-snowflake-processor \
     --service processor \
     --force-new-deployment
   ```

2. **Rollback Lambda function**
   ```bash
   # Get previous version
   aws lambda list-versions-by-function \
     --function-name dev-snowflake-poller

   # Update alias to previous version
   aws lambda update-alias \
     --function-name dev-snowflake-poller \
     --name LIVE \
     --function-version 2
   ```

### Infrastructure Rollback

1. **Use Terraform state**
   ```bash
   # View Terraform history
   terraform state list

   # Rollback specific resource
   terraform import aws_lambda_function.poller <function-arn>
   terraform apply
   ```

2. **Complete rollback**
   ```bash
   # Checkout previous commit
   git checkout <previous-commit>

   # Apply previous configuration
   terraform apply
   ```

## Monitoring Deployment Health

### Key Metrics to Monitor

1. **Lambda Function**
   - Invocation count
   - Error rate
   - Duration
   - Throttles

2. **ECS Cluster**
   - Running task count
   - CPU utilization
   - Memory utilization
   - Task failure rate

3. **Snowflake**
   - Queue depth
   - Processing rate
   - Error rate

### Health Check Commands

```bash
# Check Lambda function health
aws lambda get-function --function-name dev-snowflake-poller

# Check ECS cluster health
aws ecs describe-clusters --clusters dev-snowflake-processor

# Check recent Lambda invocations
aws logs filter-log-events \
  --log-group-name /aws/lambda/dev-snowflake-poller \
  --start-time $(date -d '1 hour ago' +%s)000

# Check queue status in Snowflake
snowsql -a $SNOWFLAKE_ACCOUNT -u $SNOWFLAKE_USER -p $SNOWFLAKE_PASSWORD \
        -d $SNOWFLAKE_DATABASE -s $SNOWFLAKE_SCHEMA \
        -q "SELECT * FROM QUEUE_STATUS_SUMMARY;"
```

## Troubleshooting Common Issues

### Issue: Lambda Function Timeouts

**Symptoms**: Lambda function consistently timing out

**Solutions**:
1. Increase Lambda timeout in Terraform
2. Optimize Snowflake queries
3. Check VPC connectivity
4. Verify Snowflake credentials

### Issue: ECS Tasks Failing to Start

**Symptoms**: ECS tasks stuck in PENDING or immediately fail

**Solutions**:
1. Check ECS task definition
2. Verify IAM permissions
3. Check ECR image availability
4. Review VPC/subnet configuration

### Issue: SSL Certificate Errors

**Symptoms**: Container logs show SSL/certificate errors

**Solutions**:
1. Verify certificates are uploaded to correct S3 path
2. Check certificate file permissions
3. Validate certificate format and content
4. Ensure CA certificate is included

### Issue: No Entries Being Processed

**Symptoms**: System running but no entries processed

**Solutions**:
1. Check Snowflake table has pending entries
2. Verify Snowflake credentials in Secrets Manager
3. Check Lambda function logs
4. Validate external service URL

## Security Considerations

### During Deployment

1. **Secure credential handling**
   - Use environment variables for sensitive data
   - Consider AWS Systems Manager Parameter Store
   - Implement credential rotation

2. **Network security**
   - Deploy in private subnets
   - Use security groups with minimal required access
   - Enable VPC flow logs

3. **Access control**
   - Use IAM roles with least privilege
   - Enable CloudTrail for audit logging
   - Implement resource tagging

### Post-Deployment

1. **Monitor security**
   - Set up CloudWatch alarms for unusual activity
   - Enable AWS Config for compliance
   - Regular security assessments

2. **Certificate management**
   - Implement certificate rotation
   - Monitor certificate expiration
   - Secure certificate storage

## Cleanup

To completely remove the deployment:

```bash
./scripts/cleanup.sh dev
```

This will:
- Stop all running ECS tasks
- Destroy all AWS infrastructure
- Clean up local build artifacts

**Note**: Snowflake tables and data are not automatically deleted.