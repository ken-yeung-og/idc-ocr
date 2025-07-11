# IDC OCR System Architecture

## Overview

The IDC OCR (Intelligent Document Capture - Optical Character Recognition) system is a serverless document processing solution built on AWS services. It automatically processes documents uploaded to S3, extracts text using AWS Bedrock Data Automation with AI-powered vision capabilities, and generates intelligent summaries.

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

### 3. AI Text Extraction Layer
- **AWS Bedrock Data Automation**: Advanced AI-powered document processing
- **Claude 3 Sonnet Vision**: Multi-modal AI for intelligent text extraction
- **Direct Reading**: For text-based files
- **Supported Formats**:
  - PDF documents (processed with AI vision)
  - Image files (PNG, JPG, JPEG, TIFF, GIF, BMP)
  - Text files (TXT, CSV, JSON, etc.)
- **Advanced Capabilities**:
  - Table structure preservation
  - Layout understanding
  - Multi-language support
  - Handwriting recognition

### 4. AI Processing Layer
- **AWS Bedrock**: Dual-purpose AI service for document processing and summarization
- **Models**: 
  - Claude 3 Sonnet (document processing with vision)
  - Claude 3 Haiku (summarization - configurable)
- **Features**:
  - Intelligent document understanding
  - Advanced text extraction with context
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
4. **AI Text Extraction**: 
   - Bedrock Data Automation with Claude 3 Sonnet Vision for PDFs/images
   - Direct reading for text files
5. **AI Processing**: Bedrock generates intelligent document summary
6. **Storage**: Results stored in DynamoDB
7. **Logging**: All operations logged to CloudWatch

## Processing Pipeline

```
Document Upload → S3 Event → Lambda Function
                                    ↓
                        Document Metadata Extraction
                                    ↓
                   AI Text Extraction (Bedrock Data Automation)
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
  - Small documents: 45-90 seconds (enhanced AI processing)
  - Large documents: 3-7 minutes (comprehensive analysis)
- **Reliability**: Built-in retry mechanisms with intelligent fallbacks
- **Availability**: 99.9% uptime (AWS SLA)
- **Accuracy**: Enhanced accuracy with AI-powered document understanding

## Cost Optimization

- **S3**: Lifecycle policies for archival
- **Lambda**: Right-sized memory allocation (may need higher for AI processing)
- **DynamoDB**: On-demand billing
- **Bedrock**: Optimized prompt engineering and model selection
  - Claude 3 Sonnet for document processing (higher accuracy)
  - Claude 3 Haiku for summarization (cost-effective)
- **Document Size**: Optimize document size before processing to reduce token usage

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

- **Enhanced Multi-language Support**: Leverage Claude 3's multilingual capabilities
- **Advanced Analytics**: Document classification and entity extraction
- **Real-time Processing**: Stream processing for high-volume scenarios
- **API Gateway**: RESTful API endpoints for direct integration
- **Custom AI Models**: Fine-tuning for specific document types
- **Structured Data Extraction**: Enhanced table and form processing
- **Document Comparison**: AI-powered document similarity analysis 