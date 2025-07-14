# IDC OCR System

A serverless document processing system that uses AWS Bedrock to extract text and generate summaries from uploaded documents. The system automatically processes documents when they are uploaded to S3, extracting text content and creating intelligent summaries using AI.

![IDC OCR Architecture](docs/idp-ocr.jpeg)

## 🚀 Quick Start

### Prerequisites

1. **AWS CLI** installed and configured with appropriate permissions
2. **Terragrunt** installed (v0.45+ recommended)
3. **AWS Bedrock** access enabled in your account
4. **Terraform** (automatically managed by Terragrunt)

### Deployment

```bash
# Deploy the complete system
./scripts/deploy.sh

# Destroy all resources when done
./scripts/destroy.sh
```

## 📁 Project Structure

```
idc-ocr/
├── infra/                          # Infrastructure as Code
│   ├── terraform/                  # Terraform configuration
│   │   ├── lambda/                 # Lambda function code
│   │   │   ├── lambda_function.py  # Main processing logic
│   │   │   └── requirements.txt    # Python dependencies
│   │   ├── main.tf                 # Main infrastructure
│   │   ├── variables.tf            # Input variables
│   │   └── outputs.tf              # Output values
│   └── terragrunt.hcl             # Terragrunt configuration
├── scripts/                        # Deployment scripts
│   ├── deploy.sh                   # Deploy the system
│   └── destroy.sh                  # Remove all resources
├── docs/                           # Documentation
│   └── idp-ocr.jpeg               # Architecture diagram
└── README.md                       # This file
```

## 🏗️ Architecture

The system is built on AWS serverless services for scalability and cost-effectiveness:

### Core Components

- **S3 Bucket**: Document storage with automatic event triggers
- **Lambda Function**: Serverless document processing using AWS Bedrock
- **DynamoDB Table**: Document metadata and extracted content storage
- **AWS Bedrock**: AI/ML service for text extraction and summarization
- **IAM Roles & Policies**: Secure permissions for Lambda and Bedrock access
- **CloudWatch**: Logging, monitoring, and error tracking
- **S3 Event Notifications**: Automatic processing triggers

### Data Flow

1. **Document Upload**: User uploads document to S3 bucket
2. **Event Trigger**: S3 event notification triggers Lambda function
3. **Document Processing**: Lambda downloads document and processes with Bedrock
4. **Text Extraction**: Bedrock extracts text content from document
5. **AI Summarization**: Bedrock generates intelligent summary
6. **Data Storage**: Results stored in DynamoDB with metadata
7. **Logging**: All activities logged to CloudWatch

## 🔧 Configuration

### Environment Variables

Edit `infra/terragrunt.hcl` to customize your deployment:

```hcl
locals {
  project_name = "idc-ocr"          # Project name for resource naming
  environment  = "dev"              # Environment (dev/staging/prod)
  region       = "ca-central-1"     # AWS region (ensure Bedrock available)
}
```

### Bedrock Model Configuration

The Lambda function uses the following Bedrock models:
- **Text Extraction**: `anthropic.claude-3-sonnet-20240229-v1:0`
- **Summarization**: Same model for content summarization

## 📝 Usage

### Upload Documents

```bash
# Upload any document type (PDF, images, etc.)
aws s3 cp your-document.pdf s3://your-bucket-name/

# Upload multiple documents
aws s3 cp ./documents/ s3://your-bucket-name/ --recursive
```

### Monitor Processing

```bash
# Real-time Lambda logs
aws logs tail /aws/lambda/your-lambda-name --follow --region ca-central-1

# Check recent logs
aws logs describe-log-streams --log-group-name /aws/lambda/your-lambda-name --region ca-central-1
```

### View Results

```bash
# Scan all processed documents
aws dynamodb scan --table-name your-table-name --region ca-central-1

# Query specific document
aws dynamodb get-item --table-name your-table-name --key '{"document_id":{"S":"your-document-id"}}' --region ca-central-1
```

### Check System Status

```bash
# Verify S3 bucket contents
aws s3 ls s3://your-bucket-name/ --region ca-central-1

# Check Lambda function status
aws lambda get-function --function-name your-lambda-name --region ca-central-1
```

## 🔍 Features

### Document Processing
- **Multi-format Support**: PDF, images (PNG, JPG, etc.), text files
- **Automatic OCR**: Text extraction from scanned documents
- **AI Summarization**: Intelligent document summarization
- **Metadata Extraction**: File information, processing timestamps, status

### Scalability & Reliability
- **Serverless**: Automatic scaling based on demand
- **Event-driven**: Immediate processing upon upload
- **Error Handling**: Comprehensive error logging and retry logic
- **Cost-effective**: Pay only for actual processing time

### Security & Compliance
- **IAM Security**: Least-privilege access policies
- **Data Encryption**: At-rest and in-transit encryption
- **Audit Trail**: Complete processing history in CloudWatch
- **Secure Storage**: S3 and DynamoDB with encryption

## 🛠️ Development

### Lambda Function

The Lambda function (`infra/terraform/lambda/lambda_function.py`) handles:

- Document download from S3
- Bedrock API integration for text extraction
- Content summarization using AI
- DynamoDB data storage
- Error handling and logging

### Dependencies

Key Python packages in `requirements.txt`:
- `boto3`: AWS SDK for Python
- `botocore`: Low-level AWS service access
- `requests`: HTTP library for API calls

### Adding Features

1. **Modify Lambda Code**: Edit `infra/terraform/lambda/lambda_function.py`
2. **Update Dependencies**: Modify `infra/terraform/lambda/requirements.txt`
3. **Add Infrastructure**: Update Terraform files in `infra/terraform/`
4. **Redeploy**: Run `./scripts/deploy.sh`

### Local Testing

```bash
# Test Lambda function locally (requires AWS credentials)
cd infra/terraform/lambda
python lambda_function.py
```

## 🚨 Important Notes

### AWS Requirements
- **Bedrock Access**: Request access to Bedrock models in AWS Console
- **Region Support**: Ensure Bedrock is available in your chosen region
- **IAM Permissions**: Lambda needs Bedrock, S3, and DynamoDB permissions
- **Model Quotas**: Be aware of Bedrock API rate limits and quotas

### Cost Considerations
- **S3 Storage**: Pay for document storage
- **Lambda Execution**: Pay per 100ms of execution time
- **DynamoDB**: Pay for storage and read/write capacity
- **Bedrock API**: Pay per API call (text extraction and summarization)
- **CloudWatch**: Pay for log storage and ingestion

### Best Practices
- **Monitor Costs**: Set up AWS Cost Explorer alerts
- **Backup Strategy**: Consider S3 lifecycle policies for old documents
- **Security**: Regularly review IAM policies and access
- **Performance**: Monitor Lambda execution times and memory usage

## 🆘 Troubleshooting

### Common Issues

1. **Bedrock Access Denied**
   ```bash
   # Check Lambda IAM role permissions
   aws iam get-role-policy --role-name your-lambda-role --policy-name bedrock-policy
   ```

2. **Region Issues**
   - Use `us-east-1`, `us-west-2`, or `ca-central-1` for Bedrock
   - Verify model availability: `aws bedrock list-foundation-models --region your-region`

3. **Lambda Errors**
   ```bash
   # Check recent errors
   aws logs filter-log-events --log-group-name /aws/lambda/your-lambda-name --filter-pattern ERROR
   ```

4. **S3 Upload Issues**
   ```bash
   # Verify bucket permissions
   aws s3api get-bucket-policy --bucket your-bucket-name
   ```

### Debugging Steps

1. **Check CloudWatch Logs**: Look for Lambda execution errors
2. **Verify IAM Permissions**: Ensure Lambda has proper Bedrock access
3. **Test Bedrock Access**: Manually test Bedrock API calls
4. **Check S3 Events**: Verify S3 event notifications are configured
5. **Monitor DynamoDB**: Check if data is being stored correctly

### Getting Help

- **CloudWatch Logs**: Primary source for debugging
- **AWS Console**: Check resource status and configurations
- **Terraform State**: Use `terragrunt show` to inspect current state
- **AWS Support**: For AWS service-specific issues

## 📄 License

This project is for educational and development purposes. Please ensure compliance with AWS terms of service and applicable data protection regulations when processing documents. 