#!/bin/bash

# Snowflake Integration Setup Script
# Creates the necessary AWS IAM role for Snowflake to call API Gateway

set -e

# Configuration
PROJECT_NAME="report-service"
AWS_REGION="${AWS_REGION:-us-east-1}"
ROLE_NAME="${PROJECT_NAME}-snowflake-integration-role"

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

# Get AWS account ID
get_aws_account_id() {
    if ! aws sts get-caller-identity &> /dev/null; then
        log_error "AWS credentials not configured. Please run 'aws configure' first."
        exit 1
    fi
    
    AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
    log_info "AWS Account ID: $AWS_ACCOUNT_ID"
}

# Create IAM role for Snowflake
create_snowflake_role() {
    log_info "Creating IAM role for Snowflake integration..."
    
    # Check if role already exists
    if aws iam get-role --role-name "$ROLE_NAME" &> /dev/null; then
        log_warning "Role $ROLE_NAME already exists"
        ROLE_ARN=$(aws iam get-role --role-name "$ROLE_NAME" --query 'Role.Arn' --output text)
        log_info "Existing role ARN: $ROLE_ARN"
        return 0
    fi
    
    # Create trust policy for Snowflake
    local trust_policy=$(cat << EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "AWS": "arn:aws:iam::$AWS_ACCOUNT_ID:root"
            },
            "Action": "sts:AssumeRole",
            "Condition": {
                "StringEquals": {
                    "sts:ExternalId": "snowflake_external_id"
                }
            }
        }
    ]
}
EOF
)
    
    # Create the role
    aws iam create-role \
        --role-name "$ROLE_NAME" \
        --assume-role-policy-document "$trust_policy" \
        --description "Role for Snowflake to call API Gateway" \
        --tags Key=Project,Value="$PROJECT_NAME" Key=Purpose,Value=SnowflakeIntegration
    
    # Get the role ARN
    ROLE_ARN=$(aws iam get-role --role-name "$ROLE_NAME" --query 'Role.Arn' --output text)
    
    log_success "Created IAM role: $ROLE_NAME"
    log_success "Role ARN: $ROLE_ARN"
}

# Create policy for API Gateway access
create_api_policy() {
    log_info "Creating API Gateway access policy..."
    
    local policy_name="${ROLE_NAME}-api-policy"
    
    # Check if policy already exists
    local policy_arn="arn:aws:iam::$AWS_ACCOUNT_ID:policy/$policy_name"
    if aws iam get-policy --policy-arn "$policy_arn" &> /dev/null; then
        log_warning "Policy $policy_name already exists"
        
        # Attach to role if not already attached
        aws iam attach-role-policy --role-name "$ROLE_NAME" --policy-arn "$policy_arn" 2>/dev/null || true
        return 0
    fi
    
    # Create policy document
    local policy_document=$(cat << EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "execute-api:Invoke"
            ],
            "Resource": "arn:aws:execute-api:$AWS_REGION:$AWS_ACCOUNT_ID:*/*"
        }
    ]
}
EOF
)
    
    # Create the policy
    aws iam create-policy \
        --policy-name "$policy_name" \
        --policy-document "$policy_document" \
        --description "Allows Snowflake to invoke API Gateway"
    
    # Attach policy to role
    aws iam attach-role-policy \
        --role-name "$ROLE_NAME" \
        --policy-arn "$policy_arn"
    
    log_success "Created and attached API Gateway policy"
}

# Get Snowflake account information
get_snowflake_info() {
    log_info "Snowflake Account Information Needed"
    echo "===================="
    echo ""
    echo "To complete the setup, you need your Snowflake account identifier."
    echo ""
    echo "🔍 How to find your Snowflake account identifier:"
    echo ""
    echo "Method 1 - From Snowflake Web UI:"
    echo "  1. Login to Snowflake in your browser"
    echo "  2. Look at the URL: https://app.snowflake.com/REGION/ACCOUNT/"
    echo "  3. Your identifier is: ACCOUNT.REGION"
    echo ""
    echo "Method 2 - From Snowflake SQL:"
    echo "  Run: SELECT CURRENT_ACCOUNT() || '.' || CURRENT_REGION();"
    echo ""
    echo "Method 3 - From SnowSQL CLI:"
    echo "  snowsql -q \"SELECT CURRENT_ACCOUNT() || '.' || CURRENT_REGION();\""
    echo ""
    echo "Examples:"
    echo "  - ab12345.us-east-1"
    echo "  - xy67890.eu-west-1" 
    echo "  - pq13579.us-central1.gcp"
    echo ""
    
    # Try to get user input
    read -p "Enter your Snowflake account identifier (or press Enter to skip): " SNOWFLAKE_ACCOUNT
    
    if [ -n "$SNOWFLAKE_ACCOUNT" ]; then
        log_success "Snowflake account set to: $SNOWFLAKE_ACCOUNT"
        export SNOWFLAKE_ACCOUNT
    else
        log_warning "Snowflake account not provided - you'll need to update terraform.tfvars manually"
        SNOWFLAKE_ACCOUNT="your-account.us-east-1"
    fi
}

# Update terraform.tfvars
update_terraform_vars() {
    log_info "Updating Terraform variables..."
    
    local tfvars_file="terraform/terraform.tfvars"
    local example_file="terraform/terraform.tfvars.example"
    
    # Create terraform.tfvars from example if it doesn't exist
    if [ ! -f "$tfvars_file" ]; then
        if [ -f "$example_file" ]; then
            cp "$example_file" "$tfvars_file"
            log_info "Created $tfvars_file from example"
        else
            log_error "Neither $tfvars_file nor $example_file found"
            return 1
        fi
    fi
    
    # Update the values in terraform.tfvars
    sed -i.bak "s|snowflake_account = \".*\"|snowflake_account = \"$SNOWFLAKE_ACCOUNT\"|g" "$tfvars_file"
    sed -i.bak "s|snowflake_role_arn = \".*\"|snowflake_role_arn = \"$ROLE_ARN\"|g" "$tfvars_file"
    
    # Remove backup file
    rm -f "${tfvars_file}.bak"
    
    log_success "Updated $tfvars_file with:"
    log_success "  snowflake_account = \"$SNOWFLAKE_ACCOUNT\""
    log_success "  snowflake_role_arn = \"$ROLE_ARN\""
}

# Display setup summary
show_summary() {
    log_info "Snowflake Integration Setup Summary"
    echo "================================="
    echo "✅ AWS Account ID: $AWS_ACCOUNT_ID"
    echo "✅ AWS Region: $AWS_REGION"
    echo "✅ IAM Role Name: $ROLE_NAME"
    echo "✅ IAM Role ARN: $ROLE_ARN"
    echo "✅ Snowflake Account: $SNOWFLAKE_ACCOUNT"
    echo ""
    echo "📝 Configuration Files Updated:"
    echo "  - terraform/terraform.tfvars"
    echo ""
    echo "🔄 Next Steps:"
    echo "1. Verify terraform/terraform.tfvars has correct values"
    echo "2. Complete other required variables in terraform.tfvars:"
    echo "   - vpc_id"
    echo "   - subnet_ids"
    echo "   - container_image (from ECR setup)"
    echo "   - reports_bucket"
    echo "3. Deploy infrastructure: ./scripts/deploy.sh"
    echo "4. Configure Snowflake integration with generated SQL scripts"
    echo ""
    echo "🔐 Snowflake External ID for integration:"
    echo "   snowflake_external_id"
    echo ""
    echo "📋 Values for your reference:"
    cat << EOF

# Copy these values to your terraform.tfvars:
snowflake_account = "$SNOWFLAKE_ACCOUNT"
snowflake_role_arn = "$ROLE_ARN"

EOF
}

# Main function
main() {
    log_info "Setting up Snowflake integration for Enhanced Report Service..."
    
    get_aws_account_id
    create_snowflake_role
    create_api_policy
    get_snowflake_info
    update_terraform_vars
    show_summary
    
    log_success "Snowflake integration setup completed!"
}

# Run main function
main "$@"