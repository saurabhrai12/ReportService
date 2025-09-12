#!/bin/bash

# ECR Setup Script for Enhanced Report Service
# Creates ECR repository and sets up permissions

set -e

# Configuration
PROJECT_NAME="report-service"
AWS_REGION="${AWS_REGION:-us-east-1}"

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

# Check if AWS CLI is configured
check_aws_cli() {
    log_info "Checking AWS CLI configuration..."
    
    if ! command -v aws &> /dev/null; then
        log_error "AWS CLI not found. Please install AWS CLI first."
        exit 1
    fi
    
    if ! aws sts get-caller-identity &> /dev/null; then
        log_error "AWS credentials not configured. Please run 'aws configure' first."
        exit 1
    fi
    
    local account_id=$(aws sts get-caller-identity --query Account --output text)
    log_success "AWS CLI configured for account: $account_id"
    
    export AWS_ACCOUNT_ID="$account_id"
}

# Create ECR repository
create_ecr_repository() {
    log_info "Creating ECR repository: $PROJECT_NAME"
    
    # Check if repository already exists
    if aws ecr describe-repositories --repository-names "$PROJECT_NAME" --region "$AWS_REGION" &> /dev/null; then
        log_warning "ECR repository '$PROJECT_NAME' already exists"
        return 0
    fi
    
    # Create repository
    aws ecr create-repository \
        --repository-name "$PROJECT_NAME" \
        --region "$AWS_REGION" \
        --image-scanning-configuration scanOnPush=true \
        --tags Key=Project,Value="$PROJECT_NAME" Key=Environment,Value=production
    
    log_success "ECR repository '$PROJECT_NAME' created successfully"
}

# Set lifecycle policy
set_lifecycle_policy() {
    log_info "Setting ECR lifecycle policy..."
    
    # Create lifecycle policy
    local lifecycle_policy=$(cat << 'EOF'
{
    "rules": [
        {
            "rulePriority": 1,
            "description": "Keep last 10 production images",
            "selection": {
                "tagStatus": "tagged",
                "tagPrefixList": ["v", "release"],
                "countType": "imageCountMoreThan",
                "countNumber": 10
            },
            "action": {
                "type": "expire"
            }
        },
        {
            "rulePriority": 2,
            "description": "Keep last 5 untagged images",
            "selection": {
                "tagStatus": "untagged",
                "countType": "imageCountMoreThan",
                "countNumber": 5
            },
            "action": {
                "type": "expire"
            }
        }
    ]
}
EOF
)
    
    aws ecr put-lifecycle-policy \
        --repository-name "$PROJECT_NAME" \
        --region "$AWS_REGION" \
        --lifecycle-policy-text "$lifecycle_policy"
    
    log_success "Lifecycle policy set for repository '$PROJECT_NAME'"
}

# Set repository policy (optional)
set_repository_policy() {
    log_info "Setting ECR repository policy..."
    
    # Allow ECS to pull images
    local repo_policy=$(cat << EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "AllowECSPull",
            "Effect": "Allow",
            "Principal": {
                "Service": "ecs-tasks.amazonaws.com"
            },
            "Action": [
                "ecr:GetDownloadUrlForLayer",
                "ecr:BatchGetImage"
            ]
        }
    ]
}
EOF
)
    
    aws ecr set-repository-policy \
        --repository-name "$PROJECT_NAME" \
        --region "$AWS_REGION" \
        --policy-text "$repo_policy"
    
    log_success "Repository policy set for '$PROJECT_NAME'"
}

# Get repository URI
get_repository_uri() {
    local repo_uri=$(aws ecr describe-repositories \
        --repository-names "$PROJECT_NAME" \
        --region "$AWS_REGION" \
        --query 'repositories[0].repositoryUri' \
        --output text)
    
    export ECR_REPOSITORY_URI="$repo_uri"
    
    log_info "Repository URI: $repo_uri"
}

# Test Docker login
test_docker_login() {
    log_info "Testing Docker login to ECR..."
    
    # Get login token and login to Docker
    aws ecr get-login-password --region "$AWS_REGION" | \
        docker login --username AWS --password-stdin "$ECR_REPOSITORY_URI"
    
    log_success "Docker login to ECR successful"
}

# Build and push initial image
build_and_push_initial() {
    log_info "Building and pushing initial Docker image..."
    
    local image_tag="$ECR_REPOSITORY_URI:latest"
    local git_tag="$ECR_REPOSITORY_URI:$(git rev-parse --short HEAD)"
    
    # Check if Dockerfile exists
    if [ ! -f "Dockerfile" ]; then
        log_warning "Dockerfile not found in current directory"
        log_warning "Skipping initial image build"
        return 0
    fi
    
    # Build image
    docker build \
        --build-arg BUILD_DATE="$(date -u +'%Y-%m-%dT%H:%M:%SZ')" \
        --build-arg VERSION="$(git rev-parse --short HEAD 2>/dev/null || echo 'unknown')" \
        --build-arg VCS_REF="$(git rev-parse HEAD 2>/dev/null || echo 'unknown')" \
        -t "$image_tag" \
        -t "$git_tag" \
        .
    
    # Push images
    docker push "$image_tag"
    docker push "$git_tag"
    
    log_success "Initial Docker images pushed:"
    log_success "  Latest: $image_tag"
    log_success "  Git: $git_tag"
}

# Display setup summary
show_summary() {
    log_info "ECR Setup Summary"
    echo "=================="
    echo "AWS Account ID: $AWS_ACCOUNT_ID"
    echo "AWS Region: $AWS_REGION"
    echo "Repository Name: $PROJECT_NAME"
    echo "Repository URI: $ECR_REPOSITORY_URI"
    echo ""
    echo "Next Steps:"
    echo "1. Update terraform.tfvars with the repository URI:"
    echo "   container_image = \"$ECR_REPOSITORY_URI:latest\""
    echo ""
    echo "2. Build and push your application image:"
    echo "   ./scripts/deploy.sh --image-tag $ECR_REPOSITORY_URI:latest"
    echo ""
    echo "3. Or manually build and push:"
    echo "   docker build -t $ECR_REPOSITORY_URI:latest ."
    echo "   aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ECR_REPOSITORY_URI"
    echo "   docker push $ECR_REPOSITORY_URI:latest"
    echo ""
    echo "Repository Information:"
    aws ecr describe-repositories --repository-names "$PROJECT_NAME" --region "$AWS_REGION"
}

# Main function
main() {
    log_info "Starting ECR setup for Enhanced Report Service..."
    
    # Parse command line arguments
    local skip_build=false
    local skip_policies=false
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            --skip-build)
                skip_build=true
                shift
                ;;
            --skip-policies)
                skip_policies=true
                shift
                ;;
            --region)
                AWS_REGION="$2"
                shift 2
                ;;
            --help)
                echo "Usage: $0 [OPTIONS]"
                echo "Options:"
                echo "  --skip-build      Skip initial Docker image build and push"
                echo "  --skip-policies   Skip setting repository and lifecycle policies"
                echo "  --region REGION   AWS region (default: us-east-1)"
                echo "  --help            Show this help message"
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                exit 1
                ;;
        esac
    done
    
    # Run setup steps
    check_aws_cli
    create_ecr_repository
    get_repository_uri
    
    if [ "$skip_policies" = false ]; then
        set_lifecycle_policy
        set_repository_policy
    fi
    
    test_docker_login
    
    if [ "$skip_build" = false ]; then
        build_and_push_initial
    fi
    
    show_summary
    
    log_success "ECR setup completed successfully!"
}

# Run main function with all arguments
main "$@"