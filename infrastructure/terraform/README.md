# OSRP Terraform Infrastructure

This directory contains Terraform infrastructure-as-code for the OSRP (Open Sensing Research Platform) AWS environment. It provides a modern, maintainable alternative to CloudFormation templates.

## Table of Contents

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Directory Structure](#directory-structure)
- [Deployment Guide](#deployment-guide)
- [Configuration](#configuration)
- [Modules](#modules)
- [State Management](#state-management)
- [Best Practices](#best-practices)
- [Troubleshooting](#troubleshooting)
- [Migration from CloudFormation](#migration-from-cloudformation)

---

## Overview

The OSRP Terraform configuration deploys a complete mobile sensing research platform including:

- **DynamoDB Tables**: ParticipantStatus, SensorTimeSeries, EventLog, DeviceState
- **S3 Buckets**: Data storage with lifecycle policies, logging bucket
- **Cognito**: User Pool, User Pool Client, Identity Pool, IAM roles
- **Lambda Functions**: Authentication handler, data upload handler
- **API Gateway**: REST API with Cognito authorization

**Key Advantages over CloudFormation**:
- **Modularity**: Reusable modules for each component
- **State management**: Track infrastructure changes with state files
- **Plan preview**: See changes before applying
- **Better validation**: Catch errors before deployment
- **Ecosystem**: Access to thousands of providers beyond AWS
- **Readability**: HCL is more concise than CloudFormation YAML

---

## Prerequisites

### Required Tools

1. **Terraform** (>= 1.5.0)
   ```bash
   # macOS
   brew install terraform

   # Linux
   wget https://releases.hashicorp.com/terraform/1.5.0/terraform_1.5.0_linux_amd64.zip
   unzip terraform_1.5.0_linux_amd64.zip
   sudo mv terraform /usr/local/bin/
   ```

2. **AWS CLI** (>= 2.0)
   ```bash
   # macOS
   brew install awscli

   # Linux
   curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
   unzip awscliv2.zip
   sudo ./aws/install
   ```

### AWS Credentials

Configure AWS credentials using one of these methods:

**Method 1: AWS CLI** (Recommended)
```bash
aws configure
# Enter: Access Key ID, Secret Access Key, Region (us-west-2), Output (json)
```

**Method 2: Environment Variables**
```bash
export AWS_ACCESS_KEY_ID="your_access_key"
export AWS_SECRET_ACCESS_KEY="your_secret_key"
export AWS_DEFAULT_REGION="us-west-2"
```

**Method 3: AWS Credentials File**
```bash
# ~/.aws/credentials
[default]
aws_access_key_id = your_access_key
aws_secret_access_key = your_secret_key
```

### Permissions Required

Your AWS credentials need the following permissions:
- `dynamodb:*` - DynamoDB tables
- `s3:*` - S3 buckets
- `cognito-idp:*` - Cognito User Pool
- `cognito-identity:*` - Cognito Identity Pool
- `lambda:*` - Lambda functions
- `apigateway:*` - API Gateway
- `iam:*` - IAM roles and policies
- `logs:*` - CloudWatch Logs

---

## Quick Start

### Deploy Development Environment

```bash
# 1. Navigate to Terraform directory
cd infrastructure/terraform

# 2. Initialize Terraform
terraform init

# 3. Copy dev environment variables
cp environments/dev/terraform.tfvars terraform.tfvars

# 4. Validate configuration
terraform validate

# 5. Preview changes
terraform plan

# 6. Deploy infrastructure
terraform apply

# 7. Save outputs
terraform output > outputs.txt
```

### Verify Deployment

```bash
# Get API endpoint
API_ENDPOINT=$(terraform output -raw api_endpoint)

# Test health endpoint (should return 404 for non-existent route)
curl $API_ENDPOINT/health

# Test auth register (should accept requests)
curl -X POST $API_ENDPOINT/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"Test1234!"}'
```

---

## Directory Structure

```
infrastructure/terraform/
├── main.tf                        # Main orchestration file
├── provider.tf                    # AWS provider configuration
├── variables.tf                   # Input variables
├── outputs.tf                     # Output values
├── README.md                      # This file
│
├── modules/                       # Reusable modules
│   ├── dynamodb/                  # DynamoDB tables module
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── s3/                        # S3 buckets module
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── cognito/                   # Cognito authentication module
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── lambda/                    # Lambda functions module
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── placeholder.zip        # Placeholder Lambda code
│   └── api_gateway/               # API Gateway module
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
│
└── environments/                  # Environment-specific configs
    ├── dev/
    │   └── terraform.tfvars       # Dev environment variables
    ├── staging/
    │   └── terraform.tfvars       # Staging environment variables
    └── prod/
        └── terraform.tfvars       # Production environment variables
```

---

## Deployment Guide

### Step 1: Initialize Terraform

```bash
cd infrastructure/terraform
terraform init
```

This downloads required providers and initializes the backend.

### Step 2: Select Environment

Choose an environment configuration:

```bash
# Development
cp environments/dev/terraform.tfvars terraform.tfvars

# Staging
cp environments/staging/terraform.tfvars terraform.tfvars

# Production
cp environments/prod/terraform.tfvars terraform.tfvars
```

Or specify the tfvars file directly:

```bash
terraform plan -var-file="environments/dev/terraform.tfvars"
terraform apply -var-file="environments/dev/terraform.tfvars"
```

### Step 3: Review Configuration

Edit `terraform.tfvars` to customize:

```hcl
environment = "dev"
study_name  = "osrp"
aws_region  = "us-west-2"

# Adjust other variables as needed
```

### Step 4: Plan Deployment

Preview changes before applying:

```bash
terraform plan

# Save plan for review
terraform plan -out=tfplan
```

Review the output carefully:
- **Green (+)**: Resources to be created
- **Yellow (~)**: Resources to be modified
- **Red (-)**: Resources to be destroyed

### Step 5: Apply Changes

Deploy the infrastructure:

```bash
# Interactive apply (requires confirmation)
terraform apply

# Auto-approve (use with caution)
terraform apply -auto-approve

# Apply saved plan
terraform apply tfplan
```

### Step 6: Deploy Lambda Code

After infrastructure is created, deploy actual Lambda code:

```bash
# Get function names
AUTH_FUNCTION=$(terraform output -raw auth_lambda_function_name)
DATA_FUNCTION=$(terraform output -raw data_upload_lambda_function_name)

# Deploy auth Lambda
aws lambda update-function-code \
  --function-name $AUTH_FUNCTION \
  --zip-file fileb://../../lambda/auth_handler.zip

# Deploy data upload Lambda
aws lambda update-function-code \
  --function-name $DATA_FUNCTION \
  --zip-file fileb://../../lambda/data_upload_handler.zip
```

### Step 7: Configure Mobile Apps

Use the Terraform outputs to configure mobile apps:

```bash
# Save all outputs to file
terraform output -json > outputs.json

# Get specific outputs
terraform output api_endpoint
terraform output user_pool_id
terraform output user_pool_client_id
terraform output identity_pool_id
```

---

## Configuration

### Environment Variables

Key variables in `terraform.tfvars`:

| Variable | Description | Default | Dev | Prod |
|----------|-------------|---------|-----|------|
| `environment` | Environment name | - | `dev` | `prod` |
| `study_name` | Study name for resources | `osrp` | `osrp` | `osrp` |
| `aws_region` | AWS region | `us-west-2` | `us-west-2` | `us-west-2` |
| `enable_point_in_time_recovery` | DynamoDB PITR | `true` | `false` | `true` |
| `enable_deletion_protection` | Cognito deletion protection | `false` | `false` | `true` |
| `lambda_log_retention` | Lambda log retention (days) | `30` | `7` | `30` |
| `api_throttle_burst_limit` | API burst limit | `5000` | `500` | `5000` |

### Customization Examples

**Change study name:**
```hcl
study_name = "depression-study"
```

**Adjust Lambda memory:**
```hcl
auth_lambda_memory = 512
data_upload_lambda_memory = 1024
```

**Increase API limits:**
```hcl
api_throttle_burst_limit = 10000
api_throttle_rate_limit = 20000
```

**Add custom tags:**
```hcl
additional_tags = {
  PI          = "Dr. Smith"
  Grant       = "NIH-R01-123456"
  IRB         = "2024-001"
  DataType    = "PHI"
}
```

---

## Resource Tagging

### Tagging Strategy

All AWS resources deployed by OSRP are automatically tagged for cost tracking, resource management, and compliance.

### Mandatory Tags (Applied Automatically)

Every resource receives these tags:

| Tag | Value | Purpose |
|-----|-------|---------|
| `Tool` | `OSRP` | Identifies resources deployed by OSRP |
| `Project` | `{study_name}` | Study/project identifier for cost allocation |
| `Environment` | `{dev\|staging\|prod}` | Environment identifier |
| `ManagedBy` | `OSRP-CLI` | Tool managing these resources |
| `Version` | `{osrp_version}` | OSRP version for tracking changes |

These tags are defined in `main.tf` as `common_tags` and automatically applied to all modules.

### Additional Tags (Optional)

You can add custom tags via the `additional_tags` variable:

```hcl
# In terraform.tfvars
additional_tags = {
  Owner       = "john.doe@university.edu"  # Resource owner
  CostCenter  = "Research-PSY-001"        # Billing cost center
  IRB         = "2024-001"                # IRB protocol number
  Grant       = "NIH-R01-123456"          # Funding source
  StudyPI     = "Dr. Jane Smith"          # Principal investigator
  Department  = "Psychology"              # Academic department
  Compliance  = "PHI"                     # Data classification
}
```

### Cost Allocation Tags

Enable cost allocation in AWS Billing Console:

1. Open **AWS Billing Console** → **Cost Allocation Tags**
2. Activate these tags:
   - `Project`
   - `Environment`
   - `Tool`
   - `Owner` (if using)
   - `CostCenter` (if using)
3. Cost reports will be available in 24 hours

**AWS CLI Method**:
```bash
aws ce list-cost-allocation-tags
aws ce update-cost-allocation-tags-status \
  --cost-allocation-tags-status TagKey=Project,Status=Active
```

### View Resources by Tag

**AWS Console**:
1. Go to **Resource Groups & Tag Editor**
2. Search by tag: `Tool = OSRP`
3. View all OSRP resources across services

**AWS CLI**:
```bash
# Find all OSRP resources
aws resourcegroupstaggingapi get-resources \
  --tag-filters Key=Tool,Values=OSRP \
  --output table

# Filter by study
aws resourcegroupstaggingapi get-resources \
  --tag-filters Key=Project,Values=depression-study \
  --output table

# Filter by environment
aws resourcegroupstaggingapi get-resources \
  --tag-filters Key=Environment,Values=prod \
  --output table
```

### Tag Validation

Terraform validates tags before deployment:
- Tag keys must be ≤ 128 characters
- Tag values must be ≤ 256 characters
- Keys must match pattern: `^[a-zA-Z0-9+\-=._:/@]+$`

### Best Practices

1. **Always use `additional_tags`** for study-specific metadata
2. **Include contact information** in `Owner` tag
3. **Use consistent naming** across all studies
4. **Document tag usage** in your study protocol
5. **Review tags regularly** for accuracy
6. **Enable cost allocation tags** for budget tracking

---

## Modules

### DynamoDB Module

**Location**: `modules/dynamodb/`

Creates four DynamoDB tables with:
- Pay-per-request billing
- Global secondary indexes
- Streams enabled
- Point-in-time recovery
- Server-side encryption
- TTL enabled (where applicable)

**Tables**:
1. **ParticipantStatus**: Participant enrollment and activity
2. **SensorTimeSeries**: Time series sensor data
3. **EventLog**: Discrete events
4. **DeviceState**: Device state snapshots

### S3 Module

**Location**: `modules/s3/`

Creates two S3 buckets:
1. **Data Bucket**: Main data storage with:
   - Versioning enabled
   - Lifecycle policies (IA at 30 days, Glacier at 90 days)
   - CORS configuration
   - Access logging

2. **Logging Bucket**: Access log storage with:
   - Lifecycle policy (delete after 90 days)
   - Public access blocked

### Cognito Module

**Location**: `modules/cognito/`

Creates authentication infrastructure:
- **User Pool**: Email-based authentication with password policy
- **User Pool Client**: Mobile app client with token configuration
- **Identity Pool**: AWS credentials for authenticated users
- **IAM Role**: Permissions for authenticated users
- **Custom Attributes**: studyCode, participantId

### Lambda Module

**Location**: `modules/lambda/`

Creates two Lambda functions:
1. **Auth Lambda**: Handles registration, login, token refresh
2. **Data Upload Lambda**: Handles sensor data, events, device state

Both functions include:
- IAM execution roles with least-privilege permissions
- CloudWatch Log Groups
- Environment variables for configuration

### API Gateway Module

**Location**: `modules/api_gateway/`

Creates REST API with:
- **Auth endpoints**: /auth/register, /auth/login, /auth/refresh
- **Data endpoints**: /data/sensor, /data/event, /data/device-state, /data/presigned-url
- **Cognito authorizer**: For protected endpoints
- **Lambda integrations**: AWS_PROXY integration
- **Throttling**: Configurable burst and rate limits
- **Logging**: CloudWatch API Gateway logs

---

## State Management

### Local State (Default)

By default, Terraform stores state locally in `terraform.tfstate`.

**Pros**:
- Simple setup
- No additional AWS resources

**Cons**:
- No collaboration support
- No state locking
- Risk of state file loss

### Remote State (Recommended for Production)

For production deployments, use S3 backend with DynamoDB locking:

**Step 1: Create S3 bucket and DynamoDB table**
```bash
# Create S3 bucket for state
aws s3 mb s3://osrp-terraform-state --region us-west-2

# Enable versioning
aws s3api put-bucket-versioning \
  --bucket osrp-terraform-state \
  --versioning-configuration Status=Enabled

# Create DynamoDB table for locking
aws dynamodb create-table \
  --table-name osrp-terraform-locks \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region us-west-2
```

**Step 2: Configure backend in `provider.tf`**

Uncomment and configure the backend block:

```hcl
terraform {
  backend "s3" {
    bucket         = "osrp-terraform-state"
    key            = "osrp/terraform.tfstate"
    region         = "us-west-2"
    encrypt        = true
    dynamodb_table = "osrp-terraform-locks"
  }
}
```

**Step 3: Initialize backend**
```bash
terraform init -migrate-state
```

---

## Best Practices

### 1. Use Workspaces for Environments

```bash
# Create workspaces
terraform workspace new dev
terraform workspace new staging
terraform workspace new prod

# Switch workspace
terraform workspace select dev

# List workspaces
terraform workspace list
```

### 2. Use `-out` flag for plan

```bash
# Save plan
terraform plan -out=tfplan

# Review plan (optional)
terraform show tfplan

# Apply exact plan
terraform apply tfplan
```

### 3. Lock Terraform Version

In `provider.tf`:
```hcl
terraform {
  required_version = "~> 1.5.0"
}
```

### 4. Use Variables for Sensitive Data

Never commit sensitive data to Git. Use:
- Environment variables: `TF_VAR_variable_name`
- AWS Secrets Manager
- HashiCorp Vault

### 5. Tag All Resources

```hcl
additional_tags = {
  Project     = "OSRP"
  Environment = "prod"
  Owner       = "research-team@example.com"
  CostCenter  = "12345"
  IRB         = "2024-001"
}
```

### 6. Enable Deletion Protection

For production:
```hcl
enable_deletion_protection = true
enable_point_in_time_recovery = true
```

### 7. Use Module Versioning

When using modules from external sources:
```hcl
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"
}
```

### 8. Regular State Backups

```bash
# Backup state
terraform state pull > backup-$(date +%Y%m%d-%H%M%S).tfstate
```

### 9. Use `terraform fmt`

```bash
# Format all files
terraform fmt -recursive

# Check formatting
terraform fmt -check
```

### 10. Validate Before Apply

```bash
terraform validate
terraform plan
terraform apply
```

---

## Troubleshooting

### Common Issues

#### Issue 1: "Error: Initialization required"

```
Error: Terraform has been successfully initialized!
```

**Solution**:
```bash
terraform init
```

#### Issue 2: "Error: No valid credential sources found"

```
Error: error configuring Terraform AWS Provider: no valid credential sources for Terraform AWS Provider found.
```

**Solution**:
```bash
aws configure
# Or set environment variables
export AWS_ACCESS_KEY_ID="your_key"
export AWS_SECRET_ACCESS_KEY="your_secret"
```

#### Issue 3: "Resource already exists"

```
Error: error creating S3 bucket: BucketAlreadyExists: The requested bucket name is not available
```

**Solution**: Change the bucket name or import existing resource:
```bash
terraform import module.s3.aws_s3_bucket.data osrp-data-dev-123456789012
```

#### Issue 4: "Error locking state"

```
Error: Error acquiring the state lock
```

**Solution**: Release the lock (use with caution):
```bash
terraform force-unlock LOCK_ID
```

#### Issue 5: Lambda placeholder.zip not found

```
Error: error reading "placeholder.zip": no such file or directory
```

**Solution**: Recreate placeholder.zip:
```bash
cd modules/lambda
echo 'import json
def lambda_handler(event, context):
    return {"statusCode": 200}' > placeholder.py
zip placeholder.zip placeholder.py
rm placeholder.py
```

### Debugging

Enable detailed logging:
```bash
export TF_LOG=DEBUG
terraform apply
```

Log levels: `TRACE`, `DEBUG`, `INFO`, `WARN`, `ERROR`

### Get Help

```bash
# Show providers
terraform providers

# Show state
terraform show

# List resources
terraform state list

# Show specific resource
terraform state show module.dynamodb.aws_dynamodb_table.participant_status
```

---

## Migration from CloudFormation

### Comparison

| Feature | CloudFormation | Terraform |
|---------|---------------|-----------|
| **Language** | JSON/YAML | HCL |
| **Provider** | AWS only | Multi-cloud |
| **State** | Managed by AWS | Local or remote |
| **Preview** | Change sets | `terraform plan` |
| **Modularity** | Nested stacks | Modules |
| **Loops** | Limited | Full support |
| **Conditionals** | Limited | Full support |
| **Cost** | Free | Free (open source) |

### Migration Steps

If migrating from existing CloudFormation:

**Option 1: Fresh Deployment** (Recommended)
1. Deploy Terraform infrastructure to new AWS region/account
2. Test thoroughly
3. Migrate data from CloudFormation resources
4. Update mobile apps to use new endpoints
5. Decommission CloudFormation stack

**Option 2: Import Existing Resources**
1. Create Terraform configuration matching existing resources
2. Import resources into Terraform state:
   ```bash
   terraform import module.dynamodb.aws_dynamodb_table.participant_status osrp-ParticipantStatus-dev
   terraform import module.s3.aws_s3_bucket.data osrp-data-dev-123456789012
   # ... import all resources
   ```
3. Run `terraform plan` to verify no changes
4. Gradually adopt Terraform for changes

**Option 3: Parallel Deployment**
1. Deploy Terraform infrastructure alongside CloudFormation
2. Gradually migrate traffic
3. Delete CloudFormation stack when confident

---

## Additional Resources

### Terraform Documentation
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Terraform Language](https://www.terraform.io/language)
- [Terraform CLI](https://www.terraform.io/cli)

### AWS Services
- [DynamoDB Developer Guide](https://docs.aws.amazon.com/dynamodb/)
- [S3 User Guide](https://docs.aws.amazon.com/s3/)
- [Cognito Developer Guide](https://docs.aws.amazon.com/cognito/)
- [Lambda Developer Guide](https://docs.aws.amazon.com/lambda/)
- [API Gateway Developer Guide](https://docs.aws.amazon.com/apigateway/)

### OSRP Documentation
- [Project README](../../README.md)
- [Quick Start Guide](../../QUICK_START.md)
- [Technical Specification](../../docs/TECHNICAL_SPECIFICATION.md)
- [Data Access Guide](../../docs/DATA_ACCESS_GUIDE.md)

---

## Support

For issues or questions:
- GitHub Issues: https://github.com/open-sensor-research-platform/osrp/issues
- Email: support@osrp.io

---

**Version**: 1.0.0
**Last Updated**: January 2026
**Maintained by**: OSRP Contributors
