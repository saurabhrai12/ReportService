#!/bin/bash

# Enhanced Report Service Deployment Script
# This script handles the complete deployment of the dual-trigger report service

set -e  # Exit on any error

# Configuration
PROJECT_NAME="report-service"
AWS_REGION="us-east-1"
TERRAFORM_DIR="terraform"
DOCKER_DIR="."
SNOWFLAKE_DIR="snowflake"

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
    
    # Check for required tools
    local deps=("aws" "terraform" "docker" "git")
    local missing_deps=()
    
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            missing_deps+=("$dep")
        fi
    done
    
    if [ ${#missing_deps[@]} -ne 0 ]; then
        log_error "Missing required dependencies: ${missing_deps[*]}"
        log_error "Please install the missing dependencies and try again."
        exit 1
    fi
    
    # Check AWS credentials
    if ! aws sts get-caller-identity &> /dev/null; then
        log_error "AWS credentials not configured. Please run 'aws configure' first."
        exit 1
    fi
    
    log_success "All dependencies are available"
}

# Validate environment
validate_environment() {
    log_info "Validating environment..."
    
    # Check for required files
    local required_files=(
        "$TERRAFORM_DIR/main.tf"
        "$TERRAFORM_DIR/terraform.tfvars"
        "Dockerfile"
        "src/report_service.py"
    )
    
    for file in "${required_files[@]}"; do
        if [ ! -f "$file" ]; then
            log_error "Required file not found: $file"
            exit 1
        fi
    done
    
    # Validate Terraform configuration
    cd "$TERRAFORM_DIR"
    if ! terraform validate; then
        log_error "Terraform configuration is invalid"
        exit 1
    fi
    cd ..
    
    log_success "Environment validation passed"
}

# Build and push Docker image
build_and_push_image() {
    local image_tag="$1"
    log_info "Building and pushing Docker image: $image_tag"
    
    # Extract registry from full image tag
    local ecr_registry=$(echo "$image_tag" | awk -F/ '{print $1}')
    
    # ECR login
    aws ecr get-login-password --region "$AWS_REGION" | docker login --username AWS --password-stdin "$ecr_registry"
    
    # Ensure buildx builder exists
    if ! docker buildx ls | grep -q "report-service-builder"; then
        log_info "Creating Docker Buildx builder 'report-service-builder'"
        docker buildx create --name report-service-builder --use >/dev/null
    else
        docker buildx use report-service-builder >/dev/null
    fi
    
    # Build and push linux/amd64 only
    docker buildx build \
        --platform linux/amd64 \
        --build-arg BUILD_DATE="$(date -u +'%Y-%m-%dT%H:%M:%SZ')" \
        --build-arg VERSION="$(git rev-parse --short HEAD)" \
        --build-arg VCS_REF="$(git rev-parse HEAD)" \
        -t "$image_tag" \
        --push \
        "$DOCKER_DIR"
    
    log_success "Docker image built and pushed: $image_tag"
}

# Deploy AWS infrastructure
deploy_infrastructure() {
    log_info "Deploying AWS infrastructure with Terraform..."
    
    cd "$TERRAFORM_DIR"
    
    # Initialize Terraform
    terraform init
    
    # Plan deployment
    log_info "Creating Terraform execution plan..."
    terraform plan -out=tfplan
    
    # Apply if plan succeeds
    log_info "Applying Terraform configuration..."
    terraform apply tfplan
    
    # Clean up plan file
    rm -f tfplan
    
    cd ..
    
    log_success "AWS infrastructure deployed successfully"
}

# Update Snowflake configuration
update_snowflake_config() {
    log_info "Updating Snowflake configuration..."
    
    cd "$TERRAFORM_DIR"
    
    # Get API Gateway URLs from Terraform output
    local adhoc_url=$(terraform output -raw trigger_adhoc_url)
    local scheduled_url=$(terraform output -raw trigger_scheduled_url)
    local snowflake_role_arn=$(terraform output -raw snowflake_integration_role_arn)
    local api_gateway_id=$(terraform output -raw api_gateway_id)
    
    cd ..
    
    log_info "API Gateway URLs:"
    log_info "  ADHOC: $adhoc_url"
    log_info "  SCHEDULED: $scheduled_url"
    log_info "  Snowflake Role ARN: $snowflake_role_arn"
    
    # Extract account ID and API Gateway ID for Snowflake script
    local account_id=$(echo "$snowflake_role_arn" | cut -d':' -f5)
    
    # Create updated Snowflake integration script
    local temp_script="/tmp/snowflake_integration_updated.sql"
    
    sed "s/YOUR_ACCOUNT/$account_id/g; s/YOUR_API_GATEWAY_ID/$api_gateway_id/g" \
        "$SNOWFLAKE_DIR/05_api_integration_setup.sql" > "$temp_script"
    
    log_warning "Snowflake integration script updated at: $temp_script"
    log_warning "Please run this script in your Snowflake environment to complete the integration."
    
    # Save URLs to a file for reference
    cat > deployment_urls.txt << EOF
# Deployment URLs and Information
# Generated on: $(date)

ADHOC Trigger URL: $adhoc_url
SCHEDULED Trigger URL: $scheduled_url
Snowflake Role ARN: $snowflake_role_arn
API Gateway ID: $api_gateway_id
AWS Account ID: $account_id

# Next Steps:
1. Run the updated Snowflake integration script: $temp_script
2. Update your Snowflake secrets with the correct URLs
3. Test the integration using the Snowflake test procedures
EOF
    
    log_success "Snowflake configuration prepared. See deployment_urls.txt for details."
}

# Run deployment tests
run_deployment_tests() {
    log_info "Running deployment tests..."
    
    cd "$TERRAFORM_DIR"
    
    # Get resource information
    local lambda_function=$(terraform output -raw lambda_function_name)
    local ecs_service=$(terraform output -raw ecs_service_arn)
    local ecs_cluster=$(terraform output -raw ecs_cluster_arn)
    
    cd ..
    
    # Test Lambda function
    log_info "Testing Lambda function: $lambda_function"
    aws lambda invoke \
        --function-name "$lambda_function" \
        --cli-binary-format raw-in-base64-out \
        --payload '{"resource": "/trigger/adhoc", "pathParameters": {"trigger_type": "adhoc"}, "httpMethod": "POST"}' \
        --region "$AWS_REGION" \
        lambda_test_output.json
    
    if [ $? -eq 0 ]; then
        log_success "Lambda function test passed"
        cat lambda_test_output.json
        rm -f lambda_test_output.json
    else
        log_error "Lambda function test failed"
    fi
    
    # Test ECS service status
    log_info "Checking ECS service status: $ecs_service"
    local service_status=$(aws ecs describe-services --cluster "$ecs_cluster" --services "$ecs_service" --region "$AWS_REGION" --query 'services[0].status' --output text)
    
    if [ "$service_status" = "ACTIVE" ]; then
        log_success "ECS service is active"
    else
        log_warning "ECS service status: $service_status"
    fi
    
    log_success "Deployment tests completed"
}

# Display deployment summary
show_deployment_summary() {
    log_info "Deployment Summary"
    echo "=================="
    
    cd "$TERRAFORM_DIR"
    
    echo "AWS Resources:"
    terraform output
    
    cd ..
    
    echo ""
    echo "Next Steps:"
    echo "1. Review deployment_urls.txt for API Gateway URLs"
    echo "2. Run the generated Snowflake integration script"
    echo "3. Test the complete integration"
    echo "4. Monitor the CloudWatch logs for the services"
    echo ""
    echo "Useful Commands:"
    echo "  - Check ECS service: aws ecs describe-services --services \$(terraform output -raw ecs_service_arn)"
    echo "  - Check Lambda logs: aws logs describe-log-groups --log-group-name-prefix /aws/lambda/$PROJECT_NAME"
    echo "  - Tail ECS logs: aws logs tail /ecs/$PROJECT_NAME --follow"
}

# Cleanup function
cleanup_on_error() {
    local exit_code=$?
    if [ $exit_code -ne 0 ]; then
        log_error "Deployment failed with exit code $exit_code"
        log_warning "You may need to manually clean up resources"
    fi
    exit $exit_code
}

# Main deployment function
main() {
    log_info "Starting Enhanced Report Service deployment..."
    
    # Set up error handling
    trap cleanup_on_error EXIT
    
    # Parse command line arguments
    local skip_docker=false
    local skip_terraform=false
    local image_tag=""
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            --skip-docker)
                skip_docker=true
                shift
                ;;
            --skip-terraform)
                skip_terraform=true
                shift
                ;;
            --image-tag)
                image_tag="$2"
                shift 2
                ;;
            --help)
                echo "Usage: $0 [OPTIONS]"
                echo "Options:"
                echo "  --skip-docker      Skip Docker image build and push"
                echo "  --skip-terraform   Skip Terraform infrastructure deployment"
                echo "  --image-tag TAG    Use specific Docker image tag"
                echo "  --help             Show this help message"
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                exit 1
                ;;
        esac
    done
    
    # Default image tag if not provided
    if [ -z "$image_tag" ] && [ "$skip_docker" = false ]; then
        # This should be your ECR repository URL
        log_error "Image tag not provided. Use --image-tag or --skip-docker"
        log_info "Example: $0 --image-tag 123456789.dkr.ecr.us-east-1.amazonaws.com/report-service:latest"
        exit 1
    fi
    
    # Run deployment steps
    check_dependencies
    validate_environment
    
    if [ "$skip_docker" = false ]; then
        build_and_push_image "$image_tag"
    fi
    
    if [ "$skip_terraform" = false ]; then
        deploy_infrastructure
        update_snowflake_config
        run_deployment_tests
    fi
    
    show_deployment_summary
    
    log_success "Enhanced Report Service deployment completed successfully!"
    
    # Remove error trap on successful completion
    trap - EXIT
}

# Run main function with all arguments
main "$@"