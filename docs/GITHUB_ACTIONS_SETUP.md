# GitHub Actions CI/CD Setup Guide

## Overview

The IDC OCR system includes a comprehensive GitHub Actions CI/CD pipeline that automates deployment, testing, and infrastructure management using AWS credentials.

## Architecture

```
GitHub Repository
├── .github/workflows/
│   ├── deploy.yml       # Main deployment workflow
│   ├── destroy.yml      # Infrastructure cleanup workflow
│   └── test.yml         # Automated testing workflow
├── infra/               # Infrastructure as Code
└── src/                 # Application source code
```

## Prerequisites

### 1. AWS Account Setup
- **AWS Account** with appropriate permissions
- **AWS CLI** access configured
- **Bedrock Model Access** enabled for Claude 3 models
- **IAM User/Role** with required permissions

### 2. GitHub Repository
- **GitHub repository** with the IDC OCR code
- **GitHub Actions** enabled
- **Repository secrets** configured
- **Environment protection** (optional but recommended)

## AWS Permissions Required

Your AWS user/role needs the following permissions:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:*",
        "dynamodb:*",
        "lambda:*",
        "iam:*",
        "logs:*",
        "bedrock:*",
        "events:*"
      ],
      "Resource": "*"
    }
  ]
}
```

## GitHub Secrets Configuration

### Required Secrets

Navigate to your GitHub repository → Settings → Secrets and variables → Actions

#### Repository Secrets
- **`AWS_ACCESS_KEY_ID`**: Your AWS access key ID
- **`AWS_SECRET_ACCESS_KEY`**: Your AWS secret access key  
- **`AWS_SESSION_TOKEN`**: Your AWS session token (if using temporary credentials)

### Setting Up Secrets

1. **Go to Repository Settings**
   ```
   GitHub Repo → Settings → Secrets and variables → Actions
   ```

2. **Add New Repository Secret**
   - Click "New repository secret"
   - Name: `AWS_ACCESS_KEY_ID`
   - Value: Your AWS access key ID
   - Click "Add secret"

3. **Repeat for all required secrets**
   - `AWS_SECRET_ACCESS_KEY`
   - `AWS_SESSION_TOKEN` (if needed)

### Security Best Practices

- **Use IAM roles** instead of long-term access keys when possible
- **Rotate secrets regularly** (recommended: every 90 days)
- **Use least privilege** principle for IAM permissions
- **Enable branch protection** for main branch
- **Require PR reviews** before merging

## Environment Configuration

### Setting Up Environments

1. **Navigate to Environments**
   ```
   GitHub Repo → Settings → Environments
   ```

2. **Create Environments**
   - `dev` - Development environment
   - `staging` - Staging environment  
   - `prod` - Production environment

3. **Configure Environment Protection**
   ```yaml
   # Example protection rules:
   - Required reviewers: 1-2 people
   - Wait timer: 5 minutes for prod
   - Deployment branches: main, develop
   ```

### Environment-Specific Configuration

Each environment can have specific settings:

```yaml
# Environment variables per environment
dev:
  AWS_REGION: us-east-1
  PROJECT_NAME: idc-ocr-dev
  
staging:
  AWS_REGION: us-east-1  
  PROJECT_NAME: idc-ocr-staging
  
prod:
  AWS_REGION: us-east-1
  PROJECT_NAME: idc-ocr-prod
```

## Workflow Overview

### 1. Deploy Workflow (`.github/workflows/deploy.yml`)

**Triggers:**
- Push to `main` branch
- Pull request to `main` branch
- Manual dispatch with environment selection

**Jobs:**
- **Validate**: Code validation and linting
- **Plan**: Terraform planning (for PRs)
- **Deploy**: Infrastructure deployment (for main branch)
- **Test**: Automated testing of deployed system

**Usage:**
```bash
# Automatic trigger on push to main
git push origin main

# Manual deployment
# Go to Actions → Deploy IDC OCR System → Run workflow
# Select environment: dev/staging/prod
# Select action: plan/apply
```

### 2. Destroy Workflow (`.github/workflows/destroy.yml`)

**Triggers:**
- Manual dispatch only (safety measure)

**Jobs:**
- **Validate Input**: Confirms destruction intent
- **Plan Destroy**: Shows resources to be destroyed
- **Destroy**: Executes infrastructure destruction

**Usage:**
```bash
# Manual destruction only
# Go to Actions → Destroy IDC OCR System → Run workflow
# Select environment: dev/staging/prod
# Type "DESTROY" in confirmation field
```

### 3. Test Workflow (`.github/workflows/test.yml`)

**Triggers:**
- Manual dispatch with test type selection
- Scheduled daily runs at 6 AM UTC

**Jobs:**
- **Test Connectivity**: Basic AWS services connectivity
- **Test Full Pipeline**: Complete document processing test
- **Cleanup Test Data**: Removes test artifacts

**Usage:**
```bash
# Manual testing
# Go to Actions → Test IDC OCR System → Run workflow
# Select environment: dev/staging/prod
# Select test type: connectivity/full/performance
```

## Deployment Process

### First-Time Setup

1. **Configure AWS Credentials**
   ```bash
   # Set up GitHub secrets as described above
   ```

2. **Enable Bedrock Models**
   ```bash
   # In AWS Console, enable Claude 3 models in Bedrock
   # Required models: Claude 3 Sonnet, Claude 3 Haiku
   ```

3. **Deploy to Development**
   ```bash
   # Go to GitHub Actions
   # Run "Deploy IDC OCR System" workflow
   # Environment: dev
   # Action: apply
   ```

4. **Test Deployment**
   ```bash
   # Run "Test IDC OCR System" workflow
   # Environment: dev
   # Test type: full
   ```

### Regular Development Workflow

1. **Create Feature Branch**
   ```bash
   git checkout -b feature/your-feature
   ```

2. **Make Changes**
   ```bash
   # Edit code in src/ or infra/
   git add .
   git commit -m "Add new feature"
   git push origin feature/your-feature
   ```

3. **Create Pull Request**
   ```bash
   # GitHub will automatically run validation and plan
   # Review the Terraform plan in PR comments
   ```

4. **Merge to Main**
   ```bash
   # After PR approval, merge will trigger deployment
   ```

### Production Deployment

1. **Deploy to Staging**
   ```bash
   # Manual workflow dispatch
   # Environment: staging
   # Action: apply
   ```

2. **Test Staging**
   ```bash
   # Run full tests on staging
   # Verify functionality
   ```

3. **Deploy to Production**
   ```bash
   # Manual workflow dispatch with approval
   # Environment: prod
   # Action: apply
   ```

## Monitoring and Troubleshooting

### Workflow Monitoring

```bash
# View workflow runs
GitHub Repo → Actions

# View specific run details
Click on workflow run → View job details

# Download logs
Click on job → Download logs
```

### Common Issues

#### 1. AWS Credentials Error
```yaml
Error: Unable to locate credentials
```
**Solution:**
- Verify AWS secrets are correctly set
- Check secret names match exactly
- Ensure IAM user has required permissions

#### 2. Terraform State Lock
```yaml
Error: state locked
```
**Solution:**
- Wait for other operations to complete
- Manually unlock if needed:
  ```bash
  terragrunt force-unlock LOCK_ID
  ```

#### 3. Bedrock Access Denied
```yaml
Error: bedrock:InvokeModel access denied
```
**Solution:**
- Enable Claude 3 models in Bedrock console
- Verify region availability
- Check IAM permissions

#### 4. Environment Protection
```yaml
Error: Environment protection rules failed
```
**Solution:**
- Wait for required approvals
- Check branch protection rules
- Verify reviewer requirements

### Debugging Workflows

1. **Enable Debug Logging**
   ```yaml
   # Add to workflow
   env:
     ACTIONS_STEP_DEBUG: true
     ACTIONS_RUNNER_DEBUG: true
   ```

2. **Check AWS Service Status**
   ```bash
   # In workflow, add debugging steps
   - name: Debug AWS Access
     run: |
       aws sts get-caller-identity
       aws bedrock list-foundation-models
   ```

3. **Manual Terraform Commands**
   ```bash
   # Local debugging
   cd infra
   terragrunt init
   terragrunt plan
   ```

## Security Considerations

### Access Control

1. **Branch Protection**
   ```yaml
   # Settings → Branches → Add rule
   - Require PR reviews
   - Require status checks
   - Restrict pushes to main
   ```

2. **Environment Protection**
   ```yaml
   # Settings → Environments → Add protection
   - Required reviewers for prod
   - Deployment branches
   - Wait timers
   ```

3. **Secret Management**
   ```yaml
   # Best practices
   - Use short-lived credentials
   - Rotate secrets regularly
   - Monitor secret usage
   ```

### Audit and Compliance

1. **Workflow Logs**
   - All deployments logged in GitHub Actions
   - CloudTrail for AWS API calls
   - DynamoDB for application events

2. **Approval Process**
   - PR reviews for code changes
   - Environment approvals for prod
   - Manual confirmation for destruction

3. **Access Monitoring**
   ```bash
   # Monitor AWS access
   aws cloudtrail lookup-events --lookup-attributes AttributeKey=Username,AttributeValue=github-actions
   ```

## Cost Optimization

### GitHub Actions Usage

```yaml
# Free tier: 2,000 minutes/month
# Optimize by:
- Using efficient workflows
- Avoiding unnecessary runs
- Caching dependencies
```

### AWS Resources

```yaml
# Monitor costs:
- Use AWS Cost Explorer
- Set up billing alerts
- Regular resource cleanup
```

## Advanced Configuration

### Matrix Builds

```yaml
# Deploy to multiple environments
strategy:
  matrix:
    environment: [dev, staging]
```

### Conditional Deployments

```yaml
# Deploy only on specific conditions
if: github.ref == 'refs/heads/main' && contains(github.event.head_commit.message, '[deploy]')
```

### Custom Notifications

```yaml
# Slack/Teams notifications
- name: Notify on Success
  uses: 8398a7/action-slack@v3
  with:
    status: success
```

## Troubleshooting Guide

### Quick Fixes

| Issue | Solution |
|-------|----------|
| Workflow fails to start | Check GitHub Actions quota |
| AWS permissions denied | Verify IAM permissions and secrets |
| Terraform fails | Check state lock and AWS resources |
| Tests fail | Verify deployment and Bedrock access |
| Environment protection | Get required approvals |

### Support Resources

- **GitHub Actions Documentation**: https://docs.github.com/en/actions
- **AWS IAM Documentation**: https://docs.aws.amazon.com/iam/
- **Terraform Documentation**: https://terraform.io/docs
- **Terragrunt Documentation**: https://terragrunt.gruntwork.io/docs/

## Conclusion

The GitHub Actions CI/CD pipeline provides a robust, automated deployment system for the IDC OCR project. With proper setup and configuration, it enables:

- ✅ **Automated deployments** on code changes
- ✅ **Environment-specific configurations** 
- ✅ **Comprehensive testing** of deployments
- ✅ **Security controls** with approvals and reviews
- ✅ **Infrastructure management** with proper state handling
- ✅ **Monitoring and debugging** capabilities

Follow this guide to set up your CI/CD pipeline and ensure smooth, reliable deployments of your IDC OCR system. 