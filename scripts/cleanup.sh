#!/bin/bash

# Cleanup Script - Destroys all infrastructure
set -e

ENVIRONMENT=${1:-dev}

echo "🧹 Cleaning up Snowflake Processor infrastructure..."
echo "⚠️  This will destroy ALL infrastructure for environment: $ENVIRONMENT"

read -p "Are you sure you want to continue? (type 'yes' to confirm): " -r
if [ "$REPLY" != "yes" ]; then
    echo "❌ Cleanup cancelled"
    exit 1
fi

echo "🗑️  Starting cleanup..."

# Stop all running ECS tasks
echo "🛑 Stopping ECS tasks..."
ECS_CLUSTER_NAME="${ENVIRONMENT}-snowflake-processor"

TASK_ARNS=$(aws ecs list-tasks --cluster $ECS_CLUSTER_NAME --query 'taskArns' --output text)

if [ -n "$TASK_ARNS" ] && [ "$TASK_ARNS" != "None" ]; then
    echo "  🛑 Stopping $(echo $TASK_ARNS | wc -w) running tasks..."
    for TASK_ARN in $TASK_ARNS; do
        aws ecs stop-task --cluster $ECS_CLUSTER_NAME --task $TASK_ARN > /dev/null
    done
    echo "  ✅ All tasks stopped"
else
    echo "  ℹ️  No running tasks found"
fi

# Wait for tasks to stop
echo "  ⏳ Waiting for tasks to stop completely..."
sleep 30

# Destroy Terraform infrastructure
echo "🏗️  Destroying Terraform infrastructure..."
cd terraform

# Delete ECR images first
ECR_REPO_NAME="${ENVIRONMENT}-snowflake-processor"
echo "  🐳 Deleting ECR images..."

IMAGE_TAGS=$(aws ecr list-images --repository-name $ECR_REPO_NAME --query 'imageIds[*].imageTag' --output text 2>/dev/null || echo "")

if [ -n "$IMAGE_TAGS" ] && [ "$IMAGE_TAGS" != "None" ]; then
    for TAG in $IMAGE_TAGS; do
        aws ecr batch-delete-image --repository-name $ECR_REPO_NAME --image-ids imageTag=$TAG > /dev/null 2>&1 || true
    done
    echo "  ✅ ECR images deleted"
fi

# Destroy all infrastructure
terraform destroy -auto-approve

echo "✅ Infrastructure destroyed"

# Clean up local files
echo "🧹 Cleaning up local files..."
rm -f lambda_poller.zip
rm -f response.json

echo "🎉 Cleanup completed successfully!"
echo ""
echo "📋 What was cleaned up:"
echo "  - All ECS tasks stopped"
echo "  - All AWS infrastructure destroyed"
echo "  - ECR repository and images deleted"
echo "  - Local build artifacts removed"
echo ""
echo "⚠️  Note: Snowflake database and tables are NOT automatically deleted"
echo "If you want to clean up Snowflake resources, run the following manually:"
echo "  DROP TABLE IF EXISTS PROCESSING_QUEUE;"
echo "  DROP VIEW IF EXISTS QUEUE_STATUS_SUMMARY;"
echo "  DROP VIEW IF EXISTS PROCESSING_METRICS;"
echo "  DROP VIEW IF EXISTS PROCESSOR_PERFORMANCE;"
echo "  DROP VIEW IF EXISTS STALE_ENTRIES;"
echo "  DROP VIEW IF EXISTS FAILED_ENTRIES_ANALYSIS;"