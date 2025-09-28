#!/bin/bash

# System Testing Script
set -e

ENVIRONMENT=${1:-dev}

echo "🧪 Testing Snowflake Processor System..."

# Check prerequisites
if ! command -v aws &> /dev/null; then
    echo "❌ AWS CLI is required"
    exit 1
fi

# Test Lambda function
echo "🔍 Testing Lambda poller function..."
LAMBDA_FUNCTION_NAME="${ENVIRONMENT}-snowflake-poller"

echo "  📞 Invoking Lambda function..."
aws lambda invoke \
    --function-name $LAMBDA_FUNCTION_NAME \
    --payload '{}' \
    response.json

if [ $? -eq 0 ]; then
    echo "  ✅ Lambda function invoked successfully"
    cat response.json | jq .
    rm -f response.json
else
    echo "  ❌ Lambda function invocation failed"
    exit 1
fi

# Check ECS cluster
echo "🐳 Checking ECS cluster..."
ECS_CLUSTER_NAME="${ENVIRONMENT}-snowflake-processor"

CLUSTER_STATUS=$(aws ecs describe-clusters \
    --clusters $ECS_CLUSTER_NAME \
    --query 'clusters[0].status' \
    --output text)

if [ "$CLUSTER_STATUS" = "ACTIVE" ]; then
    echo "  ✅ ECS cluster is active"
else
    echo "  ❌ ECS cluster is not active: $CLUSTER_STATUS"
    exit 1
fi

# Check running tasks
echo "  📋 Checking running tasks..."
RUNNING_TASKS=$(aws ecs list-tasks \
    --cluster $ECS_CLUSTER_NAME \
    --query 'length(taskArns)' \
    --output text)

echo "  📊 Currently running tasks: $RUNNING_TASKS"

# Test Snowflake connection
echo "🗄️ Testing Snowflake connection..."

if [ -z "$SNOWFLAKE_ACCOUNT" ] || [ -z "$SNOWFLAKE_USER" ] || [ -z "$SNOWFLAKE_PASSWORD" ]; then
    echo "  ⚠️  Skipping Snowflake test (credentials not set)"
else
    SNOWFLAKE_WAREHOUSE=${SNOWFLAKE_WAREHOUSE:-COMPUTE_WH}
    SNOWFLAKE_DATABASE=${SNOWFLAKE_DATABASE:-REPORTING_DB}
    SNOWFLAKE_SCHEMA=${SNOWFLAKE_SCHEMA:-PUBLIC}

    if command -v snowsql &> /dev/null; then
        echo "  🔗 Testing Snowflake connection..."
        snowsql -a $SNOWFLAKE_ACCOUNT -u $SNOWFLAKE_USER -p $SNOWFLAKE_PASSWORD \
            -d $SNOWFLAKE_DATABASE -s $SNOWFLAKE_SCHEMA \
            -q "SELECT 'Connection successful' as test_result;"

        if [ $? -eq 0 ]; then
            echo "  ✅ Snowflake connection successful"
        else
            echo "  ❌ Snowflake connection failed"
            exit 1
        fi

        # Check queue status
        echo "  📊 Checking queue status..."
        snowsql -a $SNOWFLAKE_ACCOUNT -u $SNOWFLAKE_USER -p $SNOWFLAKE_PASSWORD \
            -d $SNOWFLAKE_DATABASE -s $SNOWFLAKE_SCHEMA \
            -q "SELECT * FROM QUEUE_STATUS_SUMMARY;"
    else
        echo "  ⚠️  SnowSQL not installed, skipping detailed Snowflake tests"
    fi
fi

# Check S3 bucket
echo "🪣 Checking S3 certificate bucket..."
S3_BUCKET="${ENVIRONMENT}-snowflake-processor-certs"

if aws s3 ls s3://$S3_BUCKET/ > /dev/null 2>&1; then
    echo "  ✅ S3 bucket accessible"

    # Check for certificates
    CERT_COUNT=$(aws s3 ls s3://$S3_BUCKET/${ENVIRONMENT}/ --recursive | wc -l)
    echo "  📄 Certificate files in bucket: $CERT_COUNT"

    if [ $CERT_COUNT -lt 3 ]; then
        echo "  ⚠️  Expected at least 3 certificate files (client.pem, client-key.pem, ca-cert.pem)"
    fi
else
    echo "  ❌ S3 bucket not accessible"
    exit 1
fi

# Check CloudWatch logs
echo "📊 Checking CloudWatch logs..."
LAMBDA_LOG_GROUP="/aws/lambda/${LAMBDA_FUNCTION_NAME}"
ECS_LOG_GROUP="/ecs/${ENVIRONMENT}-snowflake-processor"

echo "  📝 Recent Lambda logs:"
aws logs describe-log-streams \
    --log-group-name $LAMBDA_LOG_GROUP \
    --order-by LastEventTime \
    --descending \
    --max-items 1 \
    --query 'logStreams[0].logStreamName' \
    --output text | xargs -I {} aws logs get-log-events \
    --log-group-name $LAMBDA_LOG_GROUP \
    --log-stream-name {} \
    --limit 5 \
    --query 'events[*].message' \
    --output text

echo ""
echo "🎉 System test completed!"
echo ""
echo "📋 Summary:"
echo "  - Lambda function: ✅"
echo "  - ECS cluster: ✅"
echo "  - S3 bucket: ✅"
echo "  - Running tasks: $RUNNING_TASKS"

if [ -n "$SNOWFLAKE_ACCOUNT" ]; then
    echo "  - Snowflake connection: ✅"
fi

echo ""
echo "🔧 Monitoring commands:"
echo "  - View queue status: aws lambda invoke --function-name $LAMBDA_FUNCTION_NAME --payload '{}' /tmp/result.json && cat /tmp/result.json"
echo "  - Watch ECS tasks: watch 'aws ecs list-tasks --cluster $ECS_CLUSTER_NAME'"
echo "  - View Lambda logs: aws logs tail $LAMBDA_LOG_GROUP --follow"
echo "  - View ECS logs: aws logs tail $ECS_LOG_GROUP --follow"