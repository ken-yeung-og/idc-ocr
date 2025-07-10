# IDC OCR System Architecture

## Overview

The IDC OCR (Intelligent Document Capture - Optical Character Recognition) system is a serverless document processing solution built on AWS services. It automatically processes documents uploaded to S3, extracts text using OCR, and generates AI-powered summaries.

## System Architecture

![IDC OCR System Architecture](./idp-ocr.jpeg)

## Architecture Components

### 1. Document Upload Layer
- **S3 Bucket**: Central storage for document uploads
- **Features**: 
  - Server-side encryption (AES-256)
  - Versioning enabled
  - Public access blocked
  - Event notifications configured

### 2. Processing Layer
- **AWS Lambda**: Serverless compute for document processing
- **Configuration**:
  - Runtime: Python 3.11
  - Memory: 1GB (configurable)
  - Timeout: 5 minutes
  - Trigger: S3 Object Created events

### 3. Text Extraction Layer
- **AWS Textract**: OCR service for PDF and image files
- **Direct Reading**: For text-based files
- **Supported Formats**:
  - PDF documents
  - Image files (PNG, JPG, JPEG, TIFF, GIF, BMP)
  - Text files (TXT, CSV, JSON, etc.)

### 4. AI Processing Layer
- **AWS Bedrock**: AI service for text summarization
- **Model**: Claude 3 Haiku (configurable)
- **Features**:
  - Intelligent summarization
  - Key point extraction
  - Structured output

### 5. Storage Layer
- **DynamoDB**: NoSQL database for document metadata and results
- **Schema**:
  - Primary Key: `document_id` (UUID)
  - Global Secondary Index: `upload_timestamp`
  - Billing: Pay-per-request

### 6. Monitoring & Security
- **CloudWatch**: Logging and monitoring
- **IAM**: Role-based access control
- **Security Features**:
  - Least privilege access
  - Encryption at rest and in transit
  - Network isolation ready

## Data Flow

1. **Upload**: User uploads document to S3 bucket
2. **Trigger**: S3 event triggers Lambda function
3. **Metadata**: Lambda extracts document metadata
4. **Text Extraction**: 
   - Textract for PDFs/images
   - Direct reading for text files
5. **AI Processing**: Bedrock generates document summary
6. **Storage**: Results stored in DynamoDB
7. **Logging**: All operations logged to CloudWatch

## Processing Pipeline

```
Document Upload → S3 Event → Lambda Function
                                    ↓
                        Document Metadata Extraction
                                    ↓
                          Text Extraction (Textract)
                                    ↓
                         AI Summarization (Bedrock)
                                    ↓
                          Data Storage (DynamoDB)
                                    ↓
                             Logging (CloudWatch)
```

## Key Features

- **Serverless**: No server management required
- **Scalable**: Automatically scales based on demand
- **Cost-Effective**: Pay-per-use pricing model
- **Secure**: AWS security best practices implemented
- **Flexible**: Supports multiple document formats
- **Monitored**: Comprehensive logging and monitoring

## Performance Characteristics

- **Throughput**: Scales automatically with demand
- **Latency**: 
  - Small documents: 30-60 seconds
  - Large documents: 2-5 minutes
- **Reliability**: Built-in retry mechanisms
- **Availability**: 99.9% uptime (AWS SLA)

## Cost Optimization

- **S3**: Lifecycle policies for archival
- **Lambda**: Right-sized memory allocation
- **DynamoDB**: On-demand billing
- **Textract**: Efficient document processing
- **Bedrock**: Optimized prompt engineering

## Security Architecture

- **Network**: Private subnets ready
- **Encryption**: AES-256 at rest, TLS in transit
- **Access Control**: IAM roles and policies
- **Monitoring**: CloudTrail for audit logging
- **Compliance**: SOC 2, ISO 27001 ready

## Deployment Architecture

- **Infrastructure as Code**: Terraform + Terragrunt
- **CI/CD Ready**: Automated deployment scripts
- **Environment Support**: Dev, staging, production
- **Rollback**: Version-controlled infrastructure

## Future Enhancements

- **Multi-language Support**: Additional OCR languages
- **Advanced Analytics**: Document classification
- **Real-time Processing**: Stream processing
- **API Gateway**: RESTful API endpoints
- **Machine Learning**: Custom model training 