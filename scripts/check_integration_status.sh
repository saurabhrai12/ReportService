#!/bin/bash

# Check Snowflake Integration Status
# Shows current state of AWS resources and configuration

set -e

# Configuration
ROLE_NAME="report-service-snowflake-integration-role"
POLICY_NAME="report-service-snowflake-integration-role-api-policy"
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

echo "🔍 Snowflake Integration Status Check"
echo "===================================="
echo ""

# Check AWS credentials
log_info "Checking AWS credentials..."
if aws sts get-caller-identity &> /dev/null; then
    AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
    AWS_REGION=$(aws configure get region)
    log_success "AWS Account: $AWS_ACCOUNT_ID"
    log_success "AWS Region: $AWS_REGION"
else
    log_error "AWS credentials not configured"
    exit 1
fi

echo ""

# Check IAM Role
log_info "Checking IAM Role..."
if aws iam get-role --role-name "$ROLE_NAME" &> /dev/null; then
    ROLE_ARN=$(aws iam get-role --role-name "$ROLE_NAME" --query 'Role.Arn' --output text)
    ROLE_CREATED=$(aws iam get-role --role-name "$ROLE_NAME" --query 'Role.CreateDate' --output text)
    
    log_success "✅ Role exists: $ROLE_NAME"
    log_success "✅ Role ARN: $ROLE_ARN"
    log_info "Created: $ROLE_CREATED"
else
    log_error "❌ Role not found: $ROLE_NAME"
    echo "Run: ./scripts/setup_snowflake_integration.sh"
fi

echo ""

# Check IAM Policy
log_info "Checking IAM Policy..."
POLICY_ARN="arn:aws:iam::$AWS_ACCOUNT_ID:policy/$POLICY_NAME"
if aws iam get-policy --policy-arn "$POLICY_ARN" &> /dev/null; then
    log_success "✅ Policy exists: $POLICY_NAME"
    log_success "✅ Policy ARN: $POLICY_ARN"
    
    # Check if policy is attached to role
    if aws iam list-attached-role-policies --role-name "$ROLE_NAME" --query 'AttachedPolicies[?PolicyArn==`'$POLICY_ARN'`]' --output text | grep -q "$POLICY_ARN"; then
        log_success "✅ Policy attached to role"
    else
        log_warning "⚠️  Policy not attached to role"
    fi
else
    log_error "❌ Policy not found: $POLICY_NAME"
fi

echo ""

# Check terraform.tfvars
log_info "Checking Terraform configuration..."
TFVARS_FILE="$TERRAFORM_DIR/terraform.tfvars"
if [ -f "$TFVARS_FILE" ]; then
    log_success "✅ terraform.tfvars exists"
    
    # Extract values from tfvars
    SNOWFLAKE_ACCOUNT=$(grep '^snowflake_account' "$TFVARS_FILE" | cut -d'"' -f2)
    TFVARS_ROLE_ARN=$(grep '^snowflake_role_arn' "$TFVARS_FILE" | cut -d'"' -f2)
    VPC_ID=$(grep '^vpc_id' "$TFVARS_FILE" | cut -d'"' -f2 2>/dev/null || echo "not_set")
    
    echo "📋 Current terraform.tfvars values:"
    echo "   snowflake_account: $SNOWFLAKE_ACCOUNT"
    echo "   snowflake_role_arn: $TFVARS_ROLE_ARN"
    echo "   vpc_id: $VPC_ID"
    
    # Validate role ARN matches
    if [ "$ROLE_ARN" = "$TFVARS_ROLE_ARN" ]; then
        log_success "✅ Role ARN matches in terraform.tfvars"
    else
        log_warning "⚠️  Role ARN mismatch between AWS and terraform.tfvars"
    fi
    
else
    log_error "❌ terraform.tfvars not found"
    echo "Expected location: $TFVARS_FILE"
fi

echo ""

# Check what still needs to be configured
log_info "Configuration Status:"
echo "====================="

if [ "$SNOWFLAKE_ACCOUNT" != "your-account.us-east-1" ] && [ -n "$SNOWFLAKE_ACCOUNT" ]; then
    log_success "✅ Snowflake account configured"
else
    log_warning "⚠️  Snowflake account needs configuration"
fi

if [ "$VPC_ID" != "not_set" ] && [ "$VPC_ID" != "vpc-12345678" ]; then
    log_success "✅ VPC ID configured"
else
    log_warning "⚠️  VPC ID needs configuration"
fi

# Check other required variables
CONTAINER_IMAGE=$(grep '^container_image' "$TFVARS_FILE" | cut -d'"' -f2 2>/dev/null || echo "not_set")
REPORTS_BUCKET=$(grep '^reports_bucket' "$TFVARS_FILE" | cut -d'"' -f2 2>/dev/null || echo "not_set")

if [[ "$CONTAINER_IMAGE" == *"ecr"* ]] && [[ "$CONTAINER_IMAGE" != *"your-account"* ]]; then
    log_success "✅ Container image configured"
else
    log_warning "⚠️  Container image needs configuration (run ./scripts/setup_ecr.sh)"
fi

if [ "$REPORTS_BUCKET" != "not_set" ] && [ "$REPORTS_BUCKET" != "your-reports-bucket" ]; then
    log_success "✅ Reports bucket configured"
else
    log_warning "⚠️  Reports bucket needs configuration"
fi

echo ""

# Show next steps
log_info "Next Steps:"
echo "==========="
echo "1. ✅ Snowflake integration role created"
echo "2. Complete terraform.tfvars configuration:"
echo "   - Set vpc_id and subnet_ids (your VPC details)"
echo "   - Set container_image (run ./scripts/setup_ecr.sh first)"
echo "   - Set reports_bucket (S3 bucket name)"
echo "3. Deploy infrastructure: ./scripts/deploy.sh"
echo "4. Configure Snowflake with generated SQL scripts"

echo ""
echo "📋 Copy these values for reference:"
echo "=================================="
echo "AWS Account ID: $AWS_ACCOUNT_ID"
echo "Role ARN: $ROLE_ARN"
echo "Snowflake Account: $SNOWFLAKE_ACCOUNT"
echo ""