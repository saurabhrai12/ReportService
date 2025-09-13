#!/bin/bash
# Test Report Service - Quick service health check and trigger test

echo "=== Report Service Health Check ==="
echo

# Check AWS credentials
if ! aws sts get-caller-identity > /dev/null 2>&1; then
    echo "❌ AWS credentials not configured. Run 'aws configure' first."
    exit 1
fi

echo "✅ AWS credentials configured"

# Get service status
echo "📊 ECS Service Status:"
aws ecs describe-services --cluster report-service-cluster --services report-service \
    --query 'services[0].{DesiredCount:desiredCount,RunningCount:runningCount,PendingCount:pendingCount,Status:status}' \
    --output table

echo
echo "🚀 Triggering Lambda function..."
aws lambda invoke --function-name report-service-ecs-trigger --payload '{}' /tmp/lambda-response.json

if [ $? -eq 0 ]; then
    echo "✅ Lambda function invoked successfully"
    echo "Response:"
    cat /tmp/lambda-response.json | jq -r '.body' | jq .
    rm -f /tmp/lambda-response.json
else
    echo "❌ Lambda function failed"
    exit 1
fi

echo
echo "⏱️  Waiting 10 seconds for ECS to react..."
sleep 10

echo "📊 Updated ECS Service Status:"
aws ecs describe-services --cluster report-service-cluster --services report-service \
    --query 'services[0].{DesiredCount:desiredCount,RunningCount:runningCount,PendingCount:pendingCount,Status:status}' \
    --output table

echo
echo "📝 Recent Lambda logs (last 5 minutes):"
aws logs tail /aws/lambda/report-service-ecs-trigger --since 5m

echo
echo "🎯 Testing complete! Service should be scaling up if not already running."
echo "💡 Monitor ECS logs with: aws logs tail /ecs/report-service --follow"