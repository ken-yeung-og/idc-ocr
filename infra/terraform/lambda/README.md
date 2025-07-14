# Lambda Function

This directory contains the Lambda function code for the IDC OCR system.

## Files

- `lambda_function.py` - Main Lambda function handler
- `requirements.txt` - Python dependencies

## Structure

The Lambda function is co-located with the Terraform configuration to avoid path resolution issues when Terragrunt runs from its cache directory.

## Deployment

The Lambda function is automatically packaged and deployed by Terraform using the `archive_file` data source.

## Environment Variables

The Lambda function expects these environment variables:
- `DYNAMODB_TABLE_NAME` - DynamoDB table name
- `BEDROCK_MODEL_ID` - Bedrock model ID
- `S3_BUCKET_NAME` - S3 bucket name 