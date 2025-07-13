# Security Setup Guide

## Overview

This guide provides security configurations and best practices for the IDC OCR system's GitHub repository and AWS infrastructure.

## GitHub Repository Security

### 1. Branch Protection Rules

Navigate to: `Settings → Branches → Add rule`

#### Main Branch Protection
```yaml
Branch name pattern: main
Settings:
  ✅ Require a pull request before merging
    ✅ Require approvals: 1
    ✅ Dismiss stale PR approvals when new commits are pushed
    ✅ Require review from code owners
  ✅ Require status checks to pass before merging
    ✅ Require branches to be up to date before merging
    Required checks:
      - validate
      - plan (if applicable)
  ✅ Require conversation resolution before merging
  ✅ Require signed commits
  ✅ Require linear history
  ✅ Include administrators
  ✅ Restrict pushes that create files larger than 100MB
```

#### Development Branch Protection
```yaml
Branch name pattern: develop
Settings:
  ✅ Require a pull request before merging
    ✅ Require approvals: 1
  ✅ Require status checks to pass before merging
  ✅ Include administrators
```

### 2. Environment Protection

Navigate to: `Settings → Environments`

#### Development Environment
```yaml
Environment name: dev
Protection rules:
  ✅ Required reviewers: (none)
  ✅ Wait timer: 0 minutes
  ✅ Deployment branches: main, develop
```

#### Staging Environment
```yaml
Environment name: staging
Protection rules:
  ✅ Required reviewers: 1 person
  ✅ Wait timer: 2 minutes
  ✅ Deployment branches: main only
```

#### Production Environment
```yaml
Environment name: prod
Protection rules:
  ✅ Required reviewers: 2 people
  ✅ Wait timer: 5 minutes
  ✅ Deployment branches: main only
  ✅ Restrict to specific teams/users
```

### 3. Repository Security Settings

Navigate to: `Settings → Security`

#### Security Analysis
```yaml
✅ Dependency graph
✅ Dependabot alerts
✅ Dependabot security updates
✅ Code scanning (if available)
✅ Secret scanning
✅ Push protection for secrets
```

#### Vulnerability Reporting
```yaml
✅ Enable private vulnerability reporting
Contact: security@yourcompany.com
```

## AWS Security Configuration

### 1. IAM User for GitHub Actions

#### Create Dedicated IAM User
```bash
# Create IAM user
aws iam create-user --user-name github-actions-idc-ocr

# Create access key
aws iam create-access-key --user-name github-actions-idc-ocr
```

#### Attach Minimal Required Policies
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:CreateBucket",
        "s3:DeleteBucket",
        "s3:GetBucketVersioning",
        "s3:PutBucketVersioning",
        "s3:GetBucketEncryption",
        "s3:PutBucketEncryption",
        "s3:GetBucketPublicAccessBlock",
        "s3:PutBucketPublicAccessBlock",
        "s3:GetBucketNotification",
        "s3:PutBucketNotification",
        "s3:ListBucket",
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject"
      ],
      "Resource": [
        "arn:aws:s3:::idc-ocr-*",
        "arn:aws:s3:::idc-ocr-*/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "dynamodb:CreateTable",
        "dynamodb:DeleteTable",
        "dynamodb:DescribeTable",
        "dynamodb:PutItem",
        "dynamodb:GetItem",
        "dynamodb:UpdateItem",
        "dynamodb:Query",
        "dynamodb:Scan",
        "dynamodb:TagResource",
        "dynamodb:UntagResource"
      ],
      "Resource": "arn:aws:dynamodb:*:*:table/idc-ocr-*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "lambda:CreateFunction",
        "lambda:DeleteFunction",
        "lambda:GetFunction",
        "lambda:UpdateFunctionCode",
        "lambda:UpdateFunctionConfiguration",
        "lambda:AddPermission",
        "lambda:RemovePermission",
        "lambda:TagResource",
        "lambda:UntagResource"
      ],
      "Resource": "arn:aws:lambda:*:*:function:idc-ocr-*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "iam:CreateRole",
        "iam:DeleteRole",
        "iam:GetRole",
        "iam:PutRolePolicy",
        "iam:DeleteRolePolicy",
        "iam:AttachRolePolicy",
        "iam:DetachRolePolicy",
        "iam:PassRole",
        "iam:TagRole",
        "iam:UntagRole"
      ],
      "Resource": "arn:aws:iam::*:role/idc-ocr-*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:DeleteLogGroup",
        "logs:DescribeLogGroups",
        "logs:PutRetentionPolicy",
        "logs:TagLogGroup",
        "logs:UntagLogGroup"
      ],
      "Resource": "arn:aws:logs:*:*:log-group:/aws/lambda/idc-ocr-*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "bedrock:InvokeModel",
        "bedrock:GetFoundationModel",
        "bedrock:ListFoundationModels"
      ],
      "Resource": "*"
    }
  ]
}
```

### 2. Cross-Account Role (Alternative)

For enhanced security, use cross-account roles:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::GITHUB-ACCOUNT:root"
      },
      "Action": "sts:AssumeRole",
      "Condition": {
        "StringEquals": {
          "sts:ExternalId": "unique-external-id"
        }
      }
    }
  ]
}
```

### 3. Bedrock Model Access

Ensure proper Bedrock model access:

```bash
# Enable Claude 3 models in Bedrock console
# Required regions: us-east-1, us-west-2
aws bedrock put-model-invocation-logging-configuration \
  --logging-config cloudWatchConfig='{logGroupName="/aws/bedrock/modelinvocations",roleArn="arn:aws:iam::ACCOUNT:role/service-role/AmazonBedrockExecutionRoleForLogging"}'
```

## Secret Management

### 1. GitHub Secrets Rotation

#### Automated Rotation Script
```bash
#!/bin/bash
# rotate-github-secrets.sh

# Generate new AWS access key
NEW_KEY=$(aws iam create-access-key --user-name github-actions-idc-ocr --query 'AccessKey')
ACCESS_KEY_ID=$(echo $NEW_KEY | jq -r '.AccessKeyId')
SECRET_ACCESS_KEY=$(echo $NEW_KEY | jq -r '.SecretAccessKey')

# Update GitHub secrets (requires GitHub CLI)
gh secret set AWS_ACCESS_KEY_ID --body "$ACCESS_KEY_ID"
gh secret set AWS_SECRET_ACCESS_KEY --body "$SECRET_ACCESS_KEY"

# Wait and test
sleep 60

# If successful, delete old key
# aws iam delete-access-key --user-name github-actions-idc-ocr --access-key-id OLD_KEY_ID
```

### 2. Secret Scanning Configuration

Add to `.github/workflows/security.yml`:

```yaml
name: Security Scan

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

jobs:
  secret-scan:
    name: Secret Detection
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4
        with:
          fetch-depth: 0
      
      - name: Run Gitleaks
        uses: gitleaks/gitleaks-action@v2
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

## Monitoring and Alerting

### 1. AWS CloudTrail Configuration

```bash
# Create CloudTrail for audit logging
aws cloudtrail create-trail \
  --name idc-ocr-audit-trail \
  --s3-bucket-name idc-ocr-cloudtrail-logs \
  --include-global-service-events \
  --is-multi-region-trail \
  --enable-log-file-validation

# Start logging
aws cloudtrail start-logging --name idc-ocr-audit-trail
```

### 2. GitHub Audit Log Monitoring

```bash
# Monitor repository events
# Settings → Security → Audit log
# Filter for:
# - Secret access
# - Permission changes
# - Workflow modifications
```

### 3. AWS Cost Monitoring

```json
{
  "AlarmName": "IDC-OCR-Cost-Alert",
  "ComparisonOperator": "GreaterThanThreshold",
  "EvaluationPeriods": 1,
  "MetricName": "EstimatedCharges",
  "Namespace": "AWS/Billing",
  "Period": 86400,
  "Statistic": "Maximum",
  "Threshold": 100.0,
  "ActionsEnabled": true,
  "AlarmActions": [
    "arn:aws:sns:us-east-1:ACCOUNT:cost-alerts"
  ],
  "AlarmDescription": "Alert when AWS costs exceed $100",
  "Dimensions": [
    {
      "Name": "Currency",
      "Value": "USD"
    }
  ]
}
```

## Incident Response

### 1. Security Incident Checklist

#### Immediate Response
- [ ] Revoke compromised credentials immediately
- [ ] Check CloudTrail logs for unauthorized actions
- [ ] Review GitHub audit logs
- [ ] Disable affected workflows
- [ ] Rotate all secrets

#### Investigation
- [ ] Identify scope of compromise
- [ ] Check for data exfiltration
- [ ] Review access patterns
- [ ] Document timeline of events

#### Recovery
- [ ] Update security configurations
- [ ] Implement additional controls
- [ ] Test system functionality
- [ ] Update documentation

### 2. Emergency Contacts

```yaml
Security Team: security@company.com
DevOps Team: devops@company.com
AWS Support: Premium Support Case
GitHub Support: Enterprise Support
```

## Compliance Considerations

### 1. Data Privacy

- **Encryption**: All data encrypted at rest and in transit
- **Access Logs**: Comprehensive logging of all access
- **Data Retention**: Automated data lifecycle management
- **Geographic Restrictions**: Region-specific deployments

### 2. Audit Requirements

- **Change Management**: All changes via PR with approval
- **Deployment Tracking**: Full audit trail of deployments
- **Access Control**: Role-based access with regular reviews
- **Vulnerability Management**: Automated scanning and patching

### 3. Regulatory Compliance

#### SOC 2 Type II
- [ ] Access controls implemented
- [ ] Monitoring and logging configured
- [ ] Incident response procedures documented
- [ ] Regular security assessments

#### ISO 27001
- [ ] Information security management system
- [ ] Risk assessment procedures
- [ ] Security controls implementation
- [ ] Continuous improvement process

## Security Checklist

### Initial Setup
- [ ] Branch protection rules configured
- [ ] Environment protection enabled
- [ ] GitHub secrets configured with least privilege
- [ ] AWS IAM policies restricted to minimum required
- [ ] Bedrock model access properly configured
- [ ] CloudTrail logging enabled
- [ ] Cost monitoring alerts set up

### Ongoing Maintenance
- [ ] Monthly secret rotation
- [ ] Quarterly access review
- [ ] Regular security scanning
- [ ] Dependency updates
- [ ] Audit log review
- [ ] Incident response testing

### Before Production
- [ ] Security assessment completed
- [ ] Penetration testing performed
- [ ] Compliance requirements verified
- [ ] Backup and recovery tested
- [ ] Disaster recovery plan documented
- [ ] Security training completed

## Additional Resources

- [AWS Security Best Practices](https://aws.amazon.com/security/security-learning/)
- [GitHub Security Features](https://docs.github.com/en/code-security)
- [OWASP Security Guidelines](https://owasp.org/www-project-top-ten/)
- [Cloud Security Alliance](https://cloudsecurityalliance.org/)

## Contact

For security questions or concerns:
- **Security Team**: security@company.com
- **GitHub Issues**: Create a private security advisory
- **Emergency**: Use incident response procedures 