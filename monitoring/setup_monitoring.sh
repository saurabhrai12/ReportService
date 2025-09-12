#!/bin/bash

# Monitoring Setup Script for Enhanced Report Service
# Sets up CloudWatch dashboards, alarms, and log insights queries

set -e

# Configuration
PROJECT_NAME="report-service"
AWS_REGION="${AWS_REGION:-us-east-1}"
TERRAFORM_DIR="terraform"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check dependencies
check_dependencies() {
    log_info "Checking dependencies..."
    
    if ! command -v aws &> /dev/null; then
        log_error "AWS CLI not found"
        exit 1
    fi
    
    if ! command -v jq &> /dev/null; then
        log_error "jq not found. Please install jq for JSON processing"
        exit 1
    fi
    
    if ! aws sts get-caller-identity &> /dev/null; then
        log_error "AWS credentials not configured"
        exit 1
    fi
    
    log_success "Dependencies check passed"
}

# Get Terraform outputs
get_terraform_outputs() {
    log_info "Getting Terraform outputs..."
    
    if [ ! -d "$TERRAFORM_DIR" ]; then
        log_error "Terraform directory not found: $TERRAFORM_DIR"
        exit 1
    fi
    
    cd "$TERRAFORM_DIR"
    
    # Get outputs
    LAMBDA_FUNCTION=$(terraform output -raw lambda_function_name 2>/dev/null || echo "")
    ECS_SERVICE=$(terraform output -raw ecs_service_arn 2>/dev/null || echo "")
    ECS_CLUSTER=$(terraform output -raw ecs_cluster_arn 2>/dev/null || echo "")
    API_GATEWAY_ID=$(terraform output -raw api_gateway_id 2>/dev/null || echo "")
    SNS_TOPIC_ARN=$(terraform output -raw sns_topic_arn 2>/dev/null || echo "")
    
    cd ..
    
    # Extract names from ARNs
    if [ -n "$ECS_SERVICE" ]; then
        ECS_SERVICE_NAME=$(echo "$ECS_SERVICE" | cut -d'/' -f3)
        ECS_CLUSTER_NAME=$(echo "$ECS_SERVICE" | cut -d'/' -f2)
    fi
    
    log_info "Terraform outputs:"
    log_info "  Lambda Function: $LAMBDA_FUNCTION"
    log_info "  ECS Service: $ECS_SERVICE_NAME"
    log_info "  ECS Cluster: $ECS_CLUSTER_NAME"
    log_info "  API Gateway ID: $API_GATEWAY_ID"
    log_info "  SNS Topic: $SNS_TOPIC_ARN"
}

# Create CloudWatch dashboard
create_dashboard() {
    log_info "Creating CloudWatch dashboard..."
    
    local dashboard_name="${PROJECT_NAME}-monitoring"
    
    # Create dashboard JSON with actual resource names
    local dashboard_body=$(cat << EOF
{
    "widgets": [
        {
            "type": "metric",
            "x": 0,
            "y": 0,
            "width": 12,
            "height": 6,
            "properties": {
                "metrics": [
                    [ "ReportService/Triggers", "TriggerRequests", "TriggerType", "ADHOC", "Status", "Success" ],
                    [ ".", ".", ".", ".", ".", "Error" ],
                    [ ".", ".", ".", "SCHEDULED", ".", "Success" ],
                    [ ".", ".", ".", ".", ".", "Error" ]
                ],
                "view": "timeSeries",
                "stacked": false,
                "region": "$AWS_REGION",
                "title": "Trigger Requests by Type",
                "period": 300,
                "stat": "Sum",
                "yAxis": {
                    "left": {
                        "min": 0
                    }
                }
            }
        },
        {
            "type": "metric",
            "x": 12,
            "y": 0,
            "width": 12,
            "height": 6,
            "properties": {
                "metrics": [
                    [ "AWS/Lambda", "Duration", "FunctionName", "$LAMBDA_FUNCTION" ],
                    [ ".", "Errors", ".", "." ],
                    [ ".", "Invocations", ".", "." ]
                ],
                "view": "timeSeries",
                "stacked": false,
                "region": "$AWS_REGION",
                "title": "Lambda Function Metrics",
                "period": 300,
                "stat": "Average"
            }
        },
        {
            "type": "metric",
            "x": 0,
            "y": 6,
            "width": 12,
            "height": 6,
            "properties": {
                "metrics": [
                    [ "AWS/ECS", "CPUUtilization", "ServiceName", "$ECS_SERVICE_NAME", "ClusterName", "$ECS_CLUSTER_NAME" ],
                    [ ".", "MemoryUtilization", ".", ".", ".", "." ]
                ],
                "view": "timeSeries",
                "stacked": false,
                "region": "$AWS_REGION",
                "title": "ECS Service Resource Utilization",
                "period": 300,
                "stat": "Average",
                "yAxis": {
                    "left": {
                        "min": 0,
                        "max": 100
                    }
                }
            }
        },
        {
            "type": "metric",
            "x": 12,
            "y": 6,
            "width": 12,
            "height": 6,
            "properties": {
                "metrics": [
                    [ "AWS/ECS", "RunningTaskCount", "ServiceName", "$ECS_SERVICE_NAME", "ClusterName", "$ECS_CLUSTER_NAME" ],
                    [ ".", "DesiredCount", ".", ".", ".", "." ],
                    [ ".", "PendingTaskCount", ".", ".", ".", "." ]
                ],
                "view": "timeSeries",
                "stacked": false,
                "region": "$AWS_REGION",
                "title": "ECS Service Task Counts",
                "period": 300,
                "stat": "Average",
                "yAxis": {
                    "left": {
                        "min": 0
                    }
                }
            }
        },
        {
            "type": "log",
            "x": 0,
            "y": 12,
            "width": 24,
            "height": 6,
            "properties": {
                "query": "SOURCE '/aws/lambda/$LAMBDA_FUNCTION' | fields @timestamp, @message\\n| filter @message like /ERROR/\\n| sort @timestamp desc\\n| limit 20",
                "region": "$AWS_REGION",
                "title": "Recent Lambda Errors",
                "view": "table"
            }
        },
        {
            "type": "log",
            "x": 0,
            "y": 18,
            "width": 24,
            "height": 6,
            "properties": {
                "query": "SOURCE '/ecs/$PROJECT_NAME' | fields @timestamp, @message\\n| filter @message like /ERROR/\\n| sort @timestamp desc\\n| limit 20",
                "region": "$AWS_REGION",
                "title": "Recent ECS Service Errors",
                "view": "table"
            }
        }
    ]
}
EOF
)
    
    # Create the dashboard
    aws cloudwatch put-dashboard \
        --dashboard-name "$dashboard_name" \
        --dashboard-body "$dashboard_body" \
        --region "$AWS_REGION"
    
    local dashboard_url="https://${AWS_REGION}.console.aws.amazon.com/cloudwatch/home?region=${AWS_REGION}#dashboards:name=${dashboard_name}"
    
    log_success "CloudWatch dashboard created: $dashboard_name"
    log_info "Dashboard URL: $dashboard_url"
    
    # Save URL to file
    echo "$dashboard_url" > monitoring_dashboard_url.txt
}

# Create CloudWatch log insights queries
create_log_insights_queries() {
    log_info "Creating CloudWatch log insights queries..."
    
    # Query 1: Lambda errors
    local query_1=$(cat << 'EOF'
fields @timestamp, @message
| filter @message like /ERROR/
| sort @timestamp desc
| limit 100
EOF
)
    
    # Query 2: ECS service performance
    local query_2=$(cat << 'EOF'
fields @timestamp, @message
| filter @message like /Processing/ or @message like /Completed/
| stats count() by bin(5m)
| sort @timestamp desc
EOF
)
    
    # Query 3: Trigger analysis
    local query_3=$(cat << 'EOF'
fields @timestamp, @message
| filter @message like /trigger/
| parse @message "Processing * trigger"
| stats count() by trigger_type
EOF
)
    
    # Save queries to files
    cat > "lambda_errors_query.txt" << EOF
# Lambda Errors Query
# Use in CloudWatch Logs Insights for log group: /aws/lambda/$LAMBDA_FUNCTION

$query_1
EOF
    
    cat > "ecs_performance_query.txt" << EOF
# ECS Performance Query  
# Use in CloudWatch Logs Insights for log group: /ecs/$PROJECT_NAME

$query_2
EOF
    
    cat > "trigger_analysis_query.txt" << EOF
# Trigger Analysis Query
# Use in CloudWatch Logs Insights for log group: /ecs/$PROJECT_NAME

$query_3
EOF
    
    log_success "CloudWatch log insights queries created"
}

# Setup custom metrics
setup_custom_metrics() {
    log_info "Setting up custom metrics documentation..."
    
    cat > "custom_metrics.md" << EOF
# Custom Metrics for Enhanced Report Service

## Metrics Published by the Lambda Function

The Lambda function publishes the following custom metrics to CloudWatch:

### Namespace: ReportService/Triggers

#### TriggerRequests
- **Description**: Count of trigger requests processed
- **Dimensions**:
  - TriggerType: ADHOC | SCHEDULED  
  - Status: Success | Error
- **Unit**: Count
- **Statistic**: Sum

### Usage Examples

#### View trigger success rate:
\`\`\`bash
aws cloudwatch get-metric-statistics \\
  --namespace ReportService/Triggers \\
  --metric-name TriggerRequests \\
  --dimensions Name=TriggerType,Value=ADHOC Name=Status,Value=Success \\
  --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \\
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \\
  --period 300 \\
  --statistics Sum
\`\`\`

#### Create custom alarm:
\`\`\`bash
aws cloudwatch put-metric-alarm \\
  --alarm-name "ReportService-TriggerFailures" \\
  --alarm-description "Monitor trigger failures" \\
  --metric-name TriggerRequests \\
  --namespace ReportService/Triggers \\
  --statistic Sum \\
  --period 300 \\
  --threshold 5 \\
  --comparison-operator GreaterThanThreshold \\
  --dimensions Name=Status,Value=Error \\
  --evaluation-periods 2
\`\`\`
EOF
    
    log_success "Custom metrics documentation created"
}

# Create monitoring scripts
create_monitoring_scripts() {
    log_info "Creating monitoring utility scripts..."
    
    # Script to check service health
    cat > "check_service_health.sh" << EOF
#!/bin/bash
# Service Health Check Script

AWS_REGION="$AWS_REGION"
LAMBDA_FUNCTION="$LAMBDA_FUNCTION"
ECS_SERVICE="$ECS_SERVICE"

echo "=== Enhanced Report Service Health Check ==="
echo "Timestamp: \$(date)"
echo ""

# Check Lambda function
echo "Lambda Function Status:"
aws lambda get-function --function-name "\$LAMBDA_FUNCTION" --region "\$AWS_REGION" --query 'Configuration.State' --output text
echo ""

# Check ECS service
echo "ECS Service Status:"
aws ecs describe-services --services "\$ECS_SERVICE" --region "\$AWS_REGION" --query 'services[0].{Status:status,Desired:desiredCount,Running:runningCount}' --output table
echo ""

# Check recent Lambda invocations
echo "Lambda Invocations (last hour):"
aws cloudwatch get-metric-statistics \\
  --namespace AWS/Lambda \\
  --metric-name Invocations \\
  --dimensions Name=FunctionName,Value="\$LAMBDA_FUNCTION" \\
  --start-time \$(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \\
  --end-time \$(date -u +%Y-%m-%dT%H:%M:%S) \\
  --period 3600 \\
  --statistics Sum \\
  --region "\$AWS_REGION" \\
  --query 'Datapoints[0].Sum' --output text
echo ""

# Check recent Lambda errors
echo "Lambda Errors (last hour):"
aws cloudwatch get-metric-statistics \\
  --namespace AWS/Lambda \\
  --metric-name Errors \\
  --dimensions Name=FunctionName,Value="\$LAMBDA_FUNCTION" \\
  --start-time \$(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \\
  --end-time \$(date -u +%Y-%m-%dT%H:%M:%S) \\
  --period 3600 \\
  --statistics Sum \\
  --region "\$AWS_REGION" \\
  --query 'Datapoints[0].Sum' --output text
echo ""
EOF
    
    chmod +x "check_service_health.sh"
    
    # Script to tail logs
    cat > "tail_logs.sh" << EOF
#!/bin/bash
# Log Tailing Script

SERVICE_TYPE="\${1:-all}"
AWS_REGION="$AWS_REGION"

case "\$SERVICE_TYPE" in
    lambda)
        echo "Tailing Lambda logs..."
        aws logs tail /aws/lambda/$LAMBDA_FUNCTION --follow --region "\$AWS_REGION"
        ;;
    ecs)
        echo "Tailing ECS logs..."
        aws logs tail /ecs/$PROJECT_NAME --follow --region "\$AWS_REGION"
        ;;
    all)
        echo "Use 'lambda' or 'ecs' as parameter to tail specific logs"
        echo "Example: ./tail_logs.sh lambda"
        ;;
    *)
        echo "Unknown service type: \$SERVICE_TYPE"
        echo "Use 'lambda' or 'ecs'"
        ;;
esac
EOF
    
    chmod +x "tail_logs.sh"
    
    log_success "Monitoring utility scripts created"
}

# Main function
main() {
    log_info "Setting up monitoring for Enhanced Report Service..."
    
    check_dependencies
    get_terraform_outputs
    
    # Check if we have the required Terraform outputs
    if [ -z "$LAMBDA_FUNCTION" ] || [ -z "$ECS_SERVICE" ]; then
        log_error "Required Terraform outputs not found. Make sure infrastructure is deployed."
        exit 1
    fi
    
    create_dashboard
    create_log_insights_queries
    setup_custom_metrics
    create_monitoring_scripts
    
    log_info "=== Monitoring Setup Summary ==="
    echo "✓ CloudWatch Dashboard created"
    echo "✓ Log Insights queries prepared"
    echo "✓ Custom metrics documented"
    echo "✓ Monitoring scripts created"
    echo ""
    echo "Files created:"
    echo "  - monitoring_dashboard_url.txt"
    echo "  - lambda_errors_query.txt"
    echo "  - ecs_performance_query.txt"
    echo "  - trigger_analysis_query.txt"
    echo "  - custom_metrics.md"
    echo "  - check_service_health.sh"
    echo "  - tail_logs.sh"
    echo ""
    echo "Next steps:"
    echo "1. Open the CloudWatch dashboard: $(cat monitoring_dashboard_url.txt)"
    echo "2. Set up alerting by providing email in Terraform variables"
    echo "3. Run ./check_service_health.sh to verify service status"
    echo "4. Use ./tail_logs.sh [lambda|ecs] to monitor real-time logs"
    
    log_success "Monitoring setup completed successfully!"
}

# Run main function
main "$@"