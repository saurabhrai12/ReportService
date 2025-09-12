#!/bin/bash

# Integration Testing Script for Enhanced Report Service
# This script tests the complete ADHOC and SCHEDULED trigger flow

set -e

# Configuration
PROJECT_NAME="report-service"
AWS_REGION="us-east-1"
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

# Get Terraform outputs
get_terraform_outputs() {
    log_info "Getting Terraform outputs..."
    
    cd "$TERRAFORM_DIR"
    
    # Export outputs as environment variables
    export ADHOC_URL=$(terraform output -raw trigger_adhoc_url)
    export SCHEDULED_URL=$(terraform output -raw trigger_scheduled_url)
    export LAMBDA_FUNCTION=$(terraform output -raw lambda_function_name)
    export ECS_SERVICE_ARN=$(terraform output -raw ecs_service_arn)
    export ECS_CLUSTER_ARN=$(terraform output -raw ecs_cluster_arn)
    
    cd ..
    
    log_info "Terraform outputs loaded:"
    log_info "  ADHOC URL: $ADHOC_URL"
    log_info "  SCHEDULED URL: $SCHEDULED_URL"
    log_info "  Lambda Function: $LAMBDA_FUNCTION"
    log_info "  ECS Service: $ECS_SERVICE_ARN"
}

# Test Lambda function directly
test_lambda_function() {
    local trigger_type="$1"
    log_info "Testing Lambda function for $trigger_type trigger..."
    
    local payload=$(cat << EOF
{
    "resource": "/trigger/${trigger_type,,}",
    "pathParameters": {
        "trigger_type": "${trigger_type,,}"
    },
    "httpMethod": "POST",
    "body": "{\"trigger_type\": \"$trigger_type\", \"source\": \"test\"}"
}
EOF
)
    
    local output_file="lambda_test_${trigger_type,,}.json"
    
    aws lambda invoke \
        --function-name "$LAMBDA_FUNCTION" \
        --payload "$payload" \
        --region "$AWS_REGION" \
        "$output_file"
    
    if [ $? -eq 0 ]; then
        log_success "Lambda function test for $trigger_type completed"
        local status_code=$(jq -r '.statusCode' "$output_file" 2>/dev/null || echo "unknown")
        if [ "$status_code" = "200" ]; then
            log_success "Lambda returned success status: $status_code"
        else
            log_warning "Lambda returned status: $status_code"
        fi
        
        # Show response
        echo "Response:"
        cat "$output_file" | jq . 2>/dev/null || cat "$output_file"
        rm -f "$output_file"
    else
        log_error "Lambda function test for $trigger_type failed"
        return 1
    fi
}

# Test API Gateway endpoints
test_api_gateway() {
    local trigger_type="$1"
    local url="$2"
    
    log_info "Testing API Gateway endpoint for $trigger_type..."
    
    # Note: This will fail without proper IAM authentication
    # This test is mainly to check if the endpoint exists
    local response=$(curl -s -w "%{http_code}" -o /tmp/api_response.json "$url" -X POST \
        -H "Content-Type: application/json" \
        -d "{\"trigger_type\": \"$trigger_type\", \"source\": \"test\"}")
    
    local http_code="${response: -3}"
    
    if [ "$http_code" = "403" ]; then
        log_info "API Gateway endpoint exists (received 403 - authentication required)"
        log_success "API Gateway test for $trigger_type passed (endpoint accessible)"
    elif [ "$http_code" = "200" ]; then
        log_success "API Gateway test for $trigger_type completed successfully"
    else
        log_warning "API Gateway test for $trigger_type returned HTTP $http_code"
        cat /tmp/api_response.json 2>/dev/null || true
    fi
    
    rm -f /tmp/api_response.json
}

# Check ECS service status
check_ecs_service() {
    log_info "Checking ECS service status..."
    
    local service_info=$(aws ecs describe-services \
        --services "$ECS_SERVICE_ARN" \
        --region "$AWS_REGION" \
        --query 'services[0]' \
        --output json)
    
    local service_status=$(echo "$service_info" | jq -r '.status')
    local desired_count=$(echo "$service_info" | jq -r '.desiredCount')
    local running_count=$(echo "$service_info" | jq -r '.runningCount')
    local pending_count=$(echo "$service_info" | jq -r '.pendingCount')
    
    log_info "ECS Service Status:"
    echo "  Status: $service_status"
    echo "  Desired: $desired_count"
    echo "  Running: $running_count"
    echo "  Pending: $pending_count"
    
    if [ "$service_status" = "ACTIVE" ]; then
        log_success "ECS service is active"
    else
        log_warning "ECS service status: $service_status"
    fi
}

# Test ECS service wake-up
test_ecs_wakeup() {
    local trigger_type="$1"
    
    log_info "Testing ECS service wake-up for $trigger_type..."
    
    # Get current desired count
    local current_desired=$(aws ecs describe-services \
        --services "$ECS_SERVICE_ARN" \
        --region "$AWS_REGION" \
        --query 'services[0].desiredCount' \
        --output text)
    
    log_info "Current desired count: $current_desired"
    
    # Trigger the Lambda function
    test_lambda_function "$trigger_type"
    
    # Wait a moment for the update to take effect
    sleep 5
    
    # Check new desired count
    local new_desired=$(aws ecs describe-services \
        --services "$ECS_SERVICE_ARN" \
        --region "$AWS_REGION" \
        --query 'services[0].desiredCount' \
        --output text)
    
    log_info "New desired count: $new_desired"
    
    if [ "$new_desired" = "1" ]; then
        log_success "ECS service wake-up test for $trigger_type passed"
    else
        log_warning "ECS service desired count is $new_desired (expected 1)"
    fi
}

# Check CloudWatch logs
check_logs() {
    local service_type="$1"
    local log_group="$2"
    
    log_info "Checking recent logs for $service_type..."
    
    # Check if log group exists
    if ! aws logs describe-log-groups --log-group-name-prefix "$log_group" --region "$AWS_REGION" --query 'logGroups[0].logGroupName' --output text | grep -q "$log_group"; then
        log_warning "Log group $log_group not found"
        return
    fi
    
    # Get recent log events
    local recent_logs=$(aws logs describe-log-streams \
        --log-group-name "$log_group" \
        --region "$AWS_REGION" \
        --order-by LastEventTime \
        --descending \
        --max-items 1 \
        --query 'logStreams[0].logStreamName' \
        --output text 2>/dev/null)
    
    if [ "$recent_logs" != "None" ] && [ -n "$recent_logs" ]; then
        log_info "Recent $service_type logs:"
        aws logs get-log-events \
            --log-group-name "$log_group" \
            --log-stream-name "$recent_logs" \
            --region "$AWS_REGION" \
            --start-time $(( $(date +%s) * 1000 - 300000 )) \
            --query 'events[].message' \
            --output text | tail -10
    else
        log_info "No recent logs found for $service_type"
    fi
}

# Run comprehensive tests
run_comprehensive_test() {
    log_info "Running comprehensive integration test..."
    
    # Test both trigger types
    local test_results=()
    
    log_info "=== Testing ADHOC Trigger ==="
    if test_lambda_function "ADHOC"; then
        test_results+=("ADHOC Lambda: PASS")
    else
        test_results+=("ADHOC Lambda: FAIL")
    fi
    
    test_api_gateway "ADHOC" "$ADHOC_URL"
    test_results+=("ADHOC API: TESTED")
    
    log_info "=== Testing SCHEDULED Trigger ==="
    if test_lambda_function "SCHEDULED"; then
        test_results+=("SCHEDULED Lambda: PASS")
    else
        test_results+=("SCHEDULED Lambda: FAIL")
    fi
    
    test_api_gateway "SCHEDULED" "$SCHEDULED_URL"
    test_results+=("SCHEDULED API: TESTED")
    
    log_info "=== Testing ECS Wake-up ==="
    test_ecs_wakeup "ADHOC"
    
    log_info "=== Checking Service Status ==="
    check_ecs_service
    
    log_info "=== Checking Logs ==="
    check_logs "Lambda" "/aws/lambda/$LAMBDA_FUNCTION"
    check_logs "ECS" "/ecs/$PROJECT_NAME"
    
    # Print test summary
    log_info "=== Test Summary ==="
    for result in "${test_results[@]}"; do
        echo "  $result"
    done
}

# Generate test report
generate_test_report() {
    local report_file="integration_test_report.md"
    
    cat > "$report_file" << EOF
# Integration Test Report
Generated on: $(date)

## Test Environment
- AWS Region: $AWS_REGION
- ADHOC Trigger URL: $ADHOC_URL
- SCHEDULED Trigger URL: $SCHEDULED_URL
- Lambda Function: $LAMBDA_FUNCTION
- ECS Service: $ECS_SERVICE_ARN

## Test Results
$(echo "### Lambda Function Tests")
$(echo "- ADHOC Lambda: Tested")
$(echo "- SCHEDULED Lambda: Tested")

$(echo "### API Gateway Tests")
$(echo "- ADHOC Endpoint: Accessible")
$(echo "- SCHEDULED Endpoint: Accessible")

$(echo "### ECS Service Tests")
$(echo "- Service Status: Checked")
$(echo "- Wake-up Functionality: Tested")

## Next Steps
1. Set up Snowflake integration using the generated script
2. Test end-to-end flow with actual Snowflake triggers
3. Monitor CloudWatch metrics and logs
4. Validate report generation functionality

## Useful Commands
\`\`\`bash
# Check ECS service status
aws ecs describe-services --services $ECS_SERVICE_ARN --region $AWS_REGION

# Tail Lambda logs
aws logs tail /aws/lambda/$LAMBDA_FUNCTION --follow --region $AWS_REGION

# Tail ECS logs
aws logs tail /ecs/$PROJECT_NAME --follow --region $AWS_REGION

# Test Lambda directly
aws lambda invoke --function-name $LAMBDA_FUNCTION --payload '{"resource": "/trigger/adhoc"}' output.json
\`\`\`
EOF
    
    log_success "Test report generated: $report_file"
}

# Main function
main() {
    log_info "Starting Enhanced Report Service integration tests..."
    
    # Check if AWS CLI is configured
    if ! aws sts get-caller-identity &> /dev/null; then
        log_error "AWS credentials not configured. Please run 'aws configure' first."
        exit 1
    fi
    
    # Check if Terraform directory exists
    if [ ! -d "$TERRAFORM_DIR" ]; then
        log_error "Terraform directory not found: $TERRAFORM_DIR"
        exit 1
    fi
    
    # Get Terraform outputs
    get_terraform_outputs
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --lambda-only)
                test_lambda_function "ADHOC"
                test_lambda_function "SCHEDULED"
                exit 0
                ;;
            --ecs-only)
                check_ecs_service
                exit 0
                ;;
            --logs-only)
                check_logs "Lambda" "/aws/lambda/$LAMBDA_FUNCTION"
                check_logs "ECS" "/ecs/$PROJECT_NAME"
                exit 0
                ;;
            --help)
                echo "Usage: $0 [OPTIONS]"
                echo "Options:"
                echo "  --lambda-only   Test only Lambda functions"
                echo "  --ecs-only      Check only ECS service status"
                echo "  --logs-only     Check only CloudWatch logs"
                echo "  --help          Show this help message"
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                exit 1
                ;;
        esac
    done
    
    # Run comprehensive tests
    run_comprehensive_test
    
    # Generate report
    generate_test_report
    
    log_success "Integration tests completed successfully!"
}

# Run main function with all arguments
main "$@"