#!/bin/bash

# Setup CloudWatch Monitoring
set -e

ENVIRONMENT=${1:-dev}
AWS_REGION=${2:-us-east-1}

echo "📊 Setting up CloudWatch monitoring for environment: $ENVIRONMENT"

# Check prerequisites
if ! command -v aws &> /dev/null; then
    echo "❌ AWS CLI is required but not installed"
    exit 1
fi

if ! command -v jq &> /dev/null; then
    echo "❌ jq is required but not installed"
    exit 1
fi

# Create CloudWatch dashboard
echo "📈 Creating CloudWatch dashboard..."

# Read the dashboard template and replace placeholders
DASHBOARD_BODY=$(cat monitoring/cloudwatch_dashboard.json | sed "s/ENVIRONMENT/$ENVIRONMENT/g")

# Create the dashboard
aws cloudwatch put-dashboard \
    --region $AWS_REGION \
    --dashboard-name "${ENVIRONMENT}-snowflake-processor" \
    --dashboard-body "$DASHBOARD_BODY"

if [ $? -eq 0 ]; then
    echo "✅ CloudWatch dashboard created successfully"
    echo "🔗 Dashboard URL: https://${AWS_REGION}.console.aws.amazon.com/cloudwatch/home?region=${AWS_REGION}#dashboards:name=${ENVIRONMENT}-snowflake-processor"
else
    echo "❌ Failed to create CloudWatch dashboard"
    exit 1
fi

# Create custom metrics
echo "📏 Setting up custom metrics..."

# Create a custom metric for queue depth (this would be populated by the application)
aws cloudwatch put-metric-data \
    --region $AWS_REGION \
    --namespace "SnowflakeProcessor" \
    --metric-data MetricName=QueueDepth,Value=0,Unit=Count,Dimensions=[{Name=Environment,Value=$ENVIRONMENT}]

echo "✅ Custom metrics namespace created"

# Create log insights queries
echo "🔍 Creating useful Log Insights queries..."

cat << EOF > monitoring/useful_queries.txt
CloudWatch Log Insights Queries for ${ENVIRONMENT}-snowflake-processor:

1. Lambda Function Errors:
SOURCE '/aws/lambda/${ENVIRONMENT}-snowflake-poller'
| fields @timestamp, @message
| filter @message like /ERROR/
| sort @timestamp desc

2. Processing Performance:
SOURCE '/ecs/${ENVIRONMENT}-snowflake-processor'
| fields @timestamp, @message
| filter @message like /Processing complete/
| parse @message /Processing complete: (?<successful>\d+)\/(?<total>\d+) successful/
| stats avg(successful), avg(total) by bin(5m)

3. Container Launch Events:
SOURCE '/aws/lambda/${ENVIRONMENT}-snowflake-poller'
| fields @timestamp, @message
| filter @message like /Launched task/
| stats count() by bin(5m)

4. Failed Entries:
SOURCE '/ecs/${ENVIRONMENT}-snowflake-processor'
| fields @timestamp, @message
| filter @message like /Failed to process entry/
| stats count() by bin(5m)

5. Stale Entry Resets:
SOURCE '/aws/lambda/${ENVIRONMENT}-snowflake-poller'
| fields @timestamp, @message
| filter @message like /Reset.*stale entries/
| parse @message /Reset (?<count>\d+) stale entries/
| stats sum(count) by bin(5m)
EOF

echo "✅ Log Insights queries saved to monitoring/useful_queries.txt"

# Set up log retention
echo "🗃️ Setting up log retention policies..."

# Lambda logs - 30 days
aws logs put-retention-policy \
    --region $AWS_REGION \
    --log-group-name "/aws/lambda/${ENVIRONMENT}-snowflake-poller" \
    --retention-in-days 30 \
    2>/dev/null || echo "  ⚠️ Lambda log group may not exist yet"

# ECS logs - 30 days
aws logs put-retention-policy \
    --region $AWS_REGION \
    --log-group-name "/ecs/${ENVIRONMENT}-snowflake-processor" \
    --retention-in-days 30 \
    2>/dev/null || echo "  ⚠️ ECS log group may not exist yet"

echo "✅ Log retention policies configured"

# Create SNS topic for alerts (if it doesn't exist)
echo "🔔 Setting up alert notifications..."

SNS_TOPIC_ARN=$(aws sns create-topic \
    --region $AWS_REGION \
    --name "${ENVIRONMENT}-snowflake-processor-alerts" \
    --query 'TopicArn' \
    --output text)

echo "✅ SNS topic created: $SNS_TOPIC_ARN"

# Optionally subscribe an email
read -p "Would you like to subscribe an email address for alerts? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    read -p "Enter email address: " EMAIL_ADDRESS
    aws sns subscribe \
        --region $AWS_REGION \
        --topic-arn $SNS_TOPIC_ARN \
        --protocol email \
        --notification-endpoint $EMAIL_ADDRESS
    echo "✅ Email subscription created (check your email to confirm)"
fi

echo ""
echo "🎉 Monitoring setup completed!"
echo ""
echo "📋 What was created:"
echo "  - CloudWatch Dashboard: ${ENVIRONMENT}-snowflake-processor"
echo "  - Custom metrics namespace: SnowflakeProcessor"
echo "  - Log retention policies: 30 days"
echo "  - SNS topic for alerts: $SNS_TOPIC_ARN"
echo "  - Log Insights queries: monitoring/useful_queries.txt"
echo ""
echo "🔗 Useful links:"
echo "  - Dashboard: https://${AWS_REGION}.console.aws.amazon.com/cloudwatch/home?region=${AWS_REGION}#dashboards:name=${ENVIRONMENT}-snowflake-processor"
echo "  - Log Insights: https://${AWS_REGION}.console.aws.amazon.com/cloudwatch/home?region=${AWS_REGION}#logsV2:logs-insights"
echo "  - Alarms: https://${AWS_REGION}.console.aws.amazon.com/cloudwatch/home?region=${AWS_REGION}#alarmsV2:"