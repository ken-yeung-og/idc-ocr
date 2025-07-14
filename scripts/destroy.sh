#!/bin/bash

# IDC OCR System Destroy Script
# This script destroys all resources created by the document processing system

set -e

echo "================================================"
echo "IDC OCR System Destroy"
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

# Check if terragrunt is installed
if ! command -v terragrunt &> /dev/null; then
    print_error "Terragrunt is not installed. Please install it first."
    exit 1
fi

# Navigate to infrastructure directory
cd infra

# Get current resources before destruction
print_status "Retrieving current resource information..."
if terragrunt output s3_bucket_name &> /dev/null; then
    S3_BUCKET=$(terragrunt output -raw s3_bucket_name)
    DYNAMODB_TABLE=$(terragrunt output -raw dynamodb_table_name)
    LAMBDA_FUNCTION=$(terragrunt output -raw lambda_function_name)
    
    print_status "Current resources:"
    print_status "- S3 Bucket: $S3_BUCKET"
    print_status "- DynamoDB Table: $DYNAMODB_TABLE"
    print_status "- Lambda Function: $LAMBDA_FUNCTION"
else
    print_warning "No current deployment found or resources already destroyed."
    exit 0
fi

# Warning message
echo ""
print_error "WARNING: This will permanently destroy all resources!"
print_error "This action cannot be undone!"
echo ""
print_warning "Resources to be destroyed:"
print_warning "- S3 bucket and ALL its contents"
print_warning "- DynamoDB table and ALL stored data"
print_warning "- Lambda function and logs"
print_warning "- IAM roles and policies"
print_warning "- CloudWatch log groups"
echo ""

# Ask for confirmation
read -p "Are you sure you want to destroy all resources? Type 'yes' to confirm: " -r
echo
if [[ ! $REPLY == "yes" ]]; then
    print_status "Destruction cancelled."
    exit 0
fi

# Empty S3 bucket first (required before destruction)
print_status "Emptying S3 bucket..."
if aws s3 ls "s3://$S3_BUCKET" &> /dev/null; then
    aws s3 rm "s3://$S3_BUCKET" --recursive
    print_status "S3 bucket emptied."
else
    print_warning "S3 bucket is already empty or doesn't exist."
fi

# Plan the destruction
print_status "Planning destruction..."
terragrunt plan -destroy -out=destroy-plan

# Final confirmation
echo ""
read -p "Final confirmation - proceed with destruction? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    print_status "Destruction cancelled."
    rm -f destroy-plan
    exit 0
fi

# Apply the destruction
print_status "Starting resource destruction..."
terragrunt apply destroy-plan

# Clean up
rm -f destroy-plan

# Return to root directory
cd ..

print_status "All resources have been destroyed successfully!"
print_status "Cleanup completed." 