#!/bin/bash

# Non-interactive script to update terraform.tfvars with existing IAM role

set -e

# Configuration
ROLE_NAME="report-service-snowflake-integration-role"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

# Get AWS account ID
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text 2>/dev/null)
if [ -z "$AWS_ACCOUNT_ID" ]; then
    log_error "Failed to get AWS Account ID. Check AWS credentials."
    exit 1
fi

# Get existing role ARN
log_info "Getting existing IAM role ARN..."
if ! ROLE_ARN=$(aws iam get-role --role-name "$ROLE_NAME" --query 'Role.Arn' --output text 2>/dev/null); then
    log_error "IAM role $ROLE_NAME not found. Run setup_snowflake_integration.sh first."
    exit 1
fi

log_success "Found IAM role: $ROLE_ARN"

# Create terraform.tfvars if it doesn't exist
TFVARS_FILE="terraform/terraform.tfvars"
EXAMPLE_FILE="terraform/terraform.tfvars.example"

if [ ! -f "$TFVARS_FILE" ]; then
    if [ -f "$EXAMPLE_FILE" ]; then
        cp "$EXAMPLE_FILE" "$TFVARS_FILE"
        log_success "Created $TFVARS_FILE from example"
    else
        log_error "Neither $TFVARS_FILE nor $EXAMPLE_FILE found"
        exit 1
    fi
fi

# Update the role ARN in terraform.tfvars
log_info "Updating terraform.tfvars with role ARN..."
sed -i.bak "s|snowflake_role_arn = \".*\"|snowflake_role_arn = \"$ROLE_ARN\"|g" "$TFVARS_FILE"

# Remove backup file
rm -f "${TFVARS_FILE}.bak"

log_success "Updated $TFVARS_FILE"

# Show current configuration
log_info "Current terraform.tfvars configuration:"
echo "======================================"
cat "$TFVARS_FILE"
echo "======================================"

log_success "Setup completed! Next steps:"
echo "1. Edit terraform.tfvars to add your Snowflake account identifier"
echo "2. Complete other required variables (vpc_id, subnet_ids, etc.)"
echo "3. Run: ./scripts/deploy.sh"