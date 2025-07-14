# IDC OCR System

A serverless document processing system that uses AWS Bedrock to extract text and generate summaries from uploaded documents.

![IDC OCR Architecture](docs/idp-ocr.jpeg)

## 🚀 Quick Start

### Prerequisites

1. **AWS CLI** installed and configured
2. **Terragrunt** installed
3. **AWS Bedrock** access enabled in your account

### Deployment

```bash
# Deploy the system
./scripts/deploy.sh

# Destroy all resources
./scripts/destroy.sh
```

## 📁 Project Structure

```
idc-ocr/
├── infra/                          # Infrastructure as Code
│   ├── terraform/                  # Terraform configuration
│   │   ├── lambda/                 # Lambda function code
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

- **S3 Bucket**: Document storage with automatic processing triggers
- **Lambda Function**: Serverless document processing using AWS Bedrock
- **DynamoDB Table**: Document metadata and extracted content storage
- **IAM Roles**: Secure permissions for Lambda and Bedrock access
- **CloudWatch**: Logging and monitoring

## 🔧 Configuration

Edit `infra/terragrunt.hcl` to customize:

```hcl
locals {
  project_name = "idc-ocr"          # Project name
  environment  = "dev"              # Environment
  region       = "ca-central-1"     # AWS region
}
```

## 📝 Usage

### Upload Documents

```bash
# Upload a document to trigger processing
aws s3 cp your-document.pdf s3://your-bucket-name/
```

### Monitor Processing

```bash
# Check Lambda logs
aws logs tail /aws/lambda/your-lambda-name --follow --region ca-central-1
```

### View Results

```bash
# Scan DynamoDB for processed documents
aws dynamodb scan --table-name your-table-name --region ca-central-1
```

## 🔍 Features

- **Automatic Processing**: Documents are processed immediately upon upload
- **Text Extraction**: Uses AWS Bedrock for OCR and text extraction
- **Smart Summarization**: AI-powered document summarization
- **Metadata Storage**: Complete document information and processing history
- **Scalable**: Serverless architecture scales automatically

## 🛠️ Development

### Lambda Function

The Lambda function is located in `infra/terraform/lambda/` and includes:

- `lambda_function.py`: Main processing logic
- `requirements.txt`: Python dependencies

### Adding Features

1. Modify `infra/terraform/lambda/lambda_function.py`
2. Update `infra/terraform/lambda/requirements.txt` if needed
3. Redeploy with `./scripts/deploy.sh`

## 🚨 Important Notes

- **Region**: Ensure Bedrock is available in your chosen region
- **Model Access**: Request access to Bedrock models in AWS Console
- **Costs**: Monitor AWS costs, especially Bedrock API usage
- **Data**: All data is stored in AWS and subject to AWS terms

## 🆘 Troubleshooting

### Common Issues

1. **Bedrock Access Denied**: Request model access in AWS Console
2. **Region Issues**: Use `us-east-1` or `us-west-2` for Bedrock
3. **IAM Permissions**: Ensure Lambda has proper Bedrock permissions

### Getting Help

- Check CloudWatch logs for Lambda errors
- Verify AWS credentials and permissions
- Ensure Bedrock models are accessible in your region

## 📄 License

This project is for educational and development purposes. 