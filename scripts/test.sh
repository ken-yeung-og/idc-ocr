#!/bin/bash

# IDC OCR System Test Script
# This script tests the deployed system with a sample document

set -e

echo "================================================"
echo "IDC OCR System Test"
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

# Navigate to infrastructure directory
cd infra

# Get deployment outputs
print_status "Retrieving deployment information..."
if ! terragrunt output s3_bucket_name &> /dev/null; then
    print_error "No deployment found. Please run ./scripts/deploy.sh first."
    exit 1
fi

S3_BUCKET=$(terragrunt output -raw s3_bucket_name)
DYNAMODB_TABLE=$(terragrunt output -raw dynamodb_table_name)
LAMBDA_FUNCTION=$(terragrunt output -raw lambda_function_name)

# Return to root directory
cd ..

print_status "Testing with deployment:"
print_status "- S3 Bucket: $S3_BUCKET"
print_status "- DynamoDB Table: $DYNAMODB_TABLE"
print_status "- Lambda Function: $LAMBDA_FUNCTION"

# Create a test document
TEST_FILE="test-document.txt"
cat > $TEST_FILE << 'EOF'
# Test Document for IDC OCR System

This is a test document to validate the IDC OCR system.

## Features Being Tested
1. Document upload to S3
2. Lambda function triggering
3. Text extraction
4. AI summarization with Bedrock
5. Data storage in DynamoDB

## Sample Content
The quick brown fox jumps over the lazy dog. This sentence contains every letter of the alphabet and is commonly used for testing text processing systems.

Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.

## Technical Details
- System: IDC OCR Document Processing
- Technology: AWS Lambda, S3, DynamoDB, Bedrock
- Language: Python
- Infrastructure: Terragrunt/Terraform

This document should be processed automatically when uploaded to the S3 bucket.
EOF

print_status "Created test document: $TEST_FILE"

# Upload test document
print_status "Uploading test document to S3..."
aws s3 cp $TEST_FILE s3://$S3_BUCKET/ --quiet
print_status "Document uploaded successfully"

# Wait for processing
print_status "Waiting for processing to complete..."
sleep 30

# Check if document was processed
print_status "Checking DynamoDB for processed document..."
ITEM_COUNT=$(aws dynamodb scan --table-name $DYNAMODB_TABLE --select "COUNT" --query "Count" --output text)

if [ "$ITEM_COUNT" -gt 0 ]; then
    print_status "✓ Document processing successful! Found $ITEM_COUNT item(s) in DynamoDB"
    
    # Get the latest item
    LATEST_ITEM=$(aws dynamodb scan --table-name $DYNAMODB_TABLE --limit 1 --query "Items[0]" --output json)
    
    if [ "$LATEST_ITEM" != "null" ]; then
        echo ""
        print_status "Latest processed document details:"
        echo "$LATEST_ITEM" | jq -r '
        "Document ID: " + .document_id.S + 
        "\nBucket: " + .bucket.S + 
        "\nObject Key: " + .object_key.S + 
        "\nText Length: " + (.text_length.N // "0") + " characters" +
        "\nSummary Length: " + (.summary_length.N // "0") + " characters" +
        "\nProcessed At: " + .processed_at.S
        '
        
        # Show first 200 chars of summary
        SUMMARY=$(echo "$LATEST_ITEM" | jq -r '.summary.S // "No summary available"')
        echo ""
        print_status "Summary preview:"
        echo "${SUMMARY:0:200}..."
    fi
else
    print_error "✗ No items found in DynamoDB. Processing may have failed."
    
    # Check Lambda logs for errors
    print_status "Checking Lambda logs for errors..."
    aws logs tail /aws/lambda/$LAMBDA_FUNCTION --since 5m --format short
fi

# Check Lambda function health
print_status "Checking Lambda function status..."
LAMBDA_STATE=$(aws lambda get-function --function-name $LAMBDA_FUNCTION --query "Configuration.State" --output text)
if [ "$LAMBDA_STATE" = "Active" ]; then
    print_status "✓ Lambda function is active"
else
    print_warning "⚠ Lambda function state: $LAMBDA_STATE"
fi

# Test API access
print_status "Testing AWS service access..."

# Check S3 access
if aws s3 ls s3://$S3_BUCKET/ --quiet; then
    print_status "✓ S3 bucket access working"
else
    print_error "✗ S3 bucket access failed"
fi

# Check DynamoDB access
if aws dynamodb describe-table --table-name $DYNAMODB_TABLE --query "Table.TableName" --output text &> /dev/null; then
    print_status "✓ DynamoDB table access working"
else
    print_error "✗ DynamoDB table access failed"
fi

# Check Bedrock access
if aws bedrock list-foundation-models --region $(aws configure get region) --query "modelSummaries[0].modelId" --output text &> /dev/null; then
    print_status "✓ Bedrock service access working"
else
    print_warning "⚠ Bedrock service access may be limited"
fi

# Cleanup test file
rm -f $TEST_FILE
print_status "Test file cleaned up"

echo ""
print_status "Test completed! Check the results above."
print_status "To view all processed documents:"
print_status "aws dynamodb scan --table-name $DYNAMODB_TABLE"
print_status ""
print_status "To monitor ongoing processing:"
print_status "aws logs tail /aws/lambda/$LAMBDA_FUNCTION --follow" 