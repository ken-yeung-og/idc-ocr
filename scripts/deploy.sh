#!/bin/bash

# IDC OCR System Deployment Script
# This script deploys the entire document processing system using Terragrunt

set -e

echo "================================================"
echo "IDC OCR System Deployment"
echo "================================================"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to extract values from terragrunt.hcl
extract_terragrunt_value() {
    local key=$1
    local file="infra/terragrunt.hcl"
    
    if [[ ! -f "$file" ]]; then
        print_error "terragrunt.hcl not found at $file"
        exit 1
    fi
    
    # Extract value using grep and sed
    local value=$(grep -E "^[[:space:]]*$key[[:space:]]*=" "$file" | sed 's/.*=[[:space:]]*"\([^"]*\)".*/\1/')
    
    if [[ -z "$value" ]]; then
        print_error "Could not extract $key from terragrunt.hcl"
        exit 1
    fi
    
    echo "$value"
}

# Check if terragrunt is installed
if ! command -v terragrunt &> /dev/null; then
    print_error "Terragrunt is not installed. Please install it first."
    print_status "Installation instructions: https://terragrunt.gruntwork.io/docs/getting-started/install/"
    exit 1
fi

# Check if AWS CLI is installed and configured
if ! command -v aws &> /dev/null; then
    print_error "AWS CLI is not installed. Please install it first."
    exit 1
fi

# Check AWS credentials
if ! aws sts get-caller-identity &> /dev/null; then
    print_error "AWS credentials are not configured. Please run 'aws configure' first."
    exit 1
fi

# Extract configuration from terragrunt.hcl
print_status "Reading configuration from terragrunt.hcl..."
DEPLOYMENT_REGION=$(extract_terragrunt_value "region")
PROJECT_NAME=$(extract_terragrunt_value "project_name")
ENVIRONMENT=$(extract_terragrunt_value "environment")

# Get AWS account ID
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

print_status "Project: $PROJECT_NAME"
print_status "Environment: $ENVIRONMENT"
print_status "Deployment Region: $DEPLOYMENT_REGION"
print_status "AWS Account ID: $AWS_ACCOUNT_ID"

# Validate region configuration
if [[ -z "$DEPLOYMENT_REGION" ]]; then
    print_error "Region not found in terragrunt.hcl"
    exit 1
fi

# Check if Bedrock models are available in the deployment region
print_status "Checking Bedrock model availability in $DEPLOYMENT_REGION..."
if aws bedrock list-foundation-models --region $DEPLOYMENT_REGION &> /dev/null; then
    print_status "✅ Bedrock is available in region $DEPLOYMENT_REGION"
else
    print_warning "❌ Bedrock might not be available in region $DEPLOYMENT_REGION"
    print_warning "Consider using us-east-1 or us-west-2 for Bedrock access"
    read -p "Do you want to continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_status "Deployment cancelled."
        exit 0
    fi
fi

# Create .terragrunt-cache directory if it doesn't exist
mkdir -p .terragrunt-cache

# Navigate to infrastructure directory
cd infra

# Initialize and validate Terragrunt configuration
print_status "Initializing Terragrunt..."
terragrunt init

print_status "Validating Terragrunt configuration..."
terragrunt validate

# Plan the deployment
print_status "Planning deployment..."
terragrunt plan -out=tfplan

# Ask for confirmation
echo ""
echo "================================================"
echo "Deployment Plan Summary"
echo "================================================"
print_status "Project: $PROJECT_NAME"
print_status "Environment: $ENVIRONMENT"
print_status "Region: $DEPLOYMENT_REGION"
print_status "AWS Account: $AWS_ACCOUNT_ID"
echo ""
print_status "The above plan will create the following resources:"
print_status "- S3 bucket for document uploads"
print_status "- DynamoDB table for document storage"
print_status "- Lambda function for document processing"
print_status "- IAM roles and policies"
print_status "- CloudWatch log groups"
print_status "- S3 event notifications"
echo ""

read -p "Do you want to proceed with the deployment? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    print_status "Deployment cancelled."
    exit 0
fi

# Apply the deployment
print_status "Starting deployment..."
terragrunt apply tfplan

# Get outputs
print_status "Retrieving deployment outputs..."
S3_BUCKET=$(terragrunt output -raw s3_bucket_name)
DYNAMODB_TABLE=$(terragrunt output -raw dynamodb_table_name)
LAMBDA_FUNCTION=$(terragrunt output -raw lambda_function_name)

# Return to root directory
cd ..

# Display deployment summary
echo ""
echo "================================================"
echo "Deployment Completed Successfully!"
echo "================================================"
print_status "Project: $PROJECT_NAME"
print_status "Environment: $ENVIRONMENT"
print_status "Region: $DEPLOYMENT_REGION"
print_status "S3 Bucket: $S3_BUCKET"
print_status "DynamoDB Table: $DYNAMODB_TABLE"
print_status "Lambda Function: $LAMBDA_FUNCTION"
echo ""
print_status "You can now upload documents to the S3 bucket:"
print_status "aws s3 cp your-document.pdf s3://$S3_BUCKET/ --region $DEPLOYMENT_REGION"
echo ""
print_status "To monitor processing, check CloudWatch logs:"
print_status "aws logs tail /aws/lambda/$LAMBDA_FUNCTION --follow --region $DEPLOYMENT_REGION"
echo ""
print_status "To view stored documents in DynamoDB:"
print_status "aws dynamodb scan --table-name $DYNAMODB_TABLE --region $DEPLOYMENT_REGION"
echo ""
print_status "To test the system, upload a document:"
print_status "echo 'Test document content' > test.txt"
print_status "aws s3 cp test.txt s3://$S3_BUCKET/ --region $DEPLOYMENT_REGION"

# Clean up
rm -f tfplan

print_status "Deployment script completed!" 