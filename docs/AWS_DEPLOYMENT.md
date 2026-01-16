# AWS Deployment Guide

Complete guide for deploying OSRP infrastructure to Amazon Web Services.

**Version**: 0.2.0 (MVP)
**Last Updated**: January 16, 2026

---

## Table of Contents

1. [Overview](#overview)
2. [Prerequisites](#prerequisites)
3. [Quick Start](#quick-start)
4. [What Gets Deployed](#what-gets-deployed)
5. [Step-by-Step Deployment](#step-by-step-deployment)
6. [Testing Your Deployment](#testing-your-deployment)
7. [Configuration Options](#configuration-options)
8. [Troubleshooting](#troubleshooting)
9. [Cost Estimation](#cost-estimation)
10. [Cleanup and Teardown](#cleanup-and-teardown)
11. [Next Steps](#next-steps)

---

## Overview

OSRP uses AWS CloudFormation to deploy a complete serverless infrastructure for mobile sensing research studies. The deployment creates:

- **API Gateway**: REST API with Cognito authentication
- **Lambda Functions**: Serverless compute for auth and data processing
- **DynamoDB Tables**: NoSQL database for participant and sensor data
- **S3 Buckets**: File storage for screenshots and large files
- **Cognito User Pool**: User authentication and management
- **CloudWatch Logs**: Monitoring and debugging

**Deployment time**: 5-10 minutes
**Cost**: ~$0.01/month for MVP testing (within AWS Free Tier)

---

## Prerequisites

### 1. AWS Account

You need an active AWS account:

- Sign up at [aws.amazon.com](https://aws.amazon.com)
- Credit card required (for charges beyond free tier)
- Free tier includes most OSRP services for 12 months

### 2. AWS CLI

Install and configure the AWS Command Line Interface:

#### macOS
```bash
brew install awscli
```

#### Linux
```bash
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
```

#### Windows
Download and run the installer from [AWS CLI website](https://aws.amazon.com/cli/)

#### Configure AWS CLI
```bash
aws configure
```

You'll be prompted for:
- **AWS Access Key ID**: Get from AWS IAM Console
- **AWS Secret Access Key**: Get from AWS IAM Console
- **Default region**: Use `us-west-2` (recommended)
- **Default output format**: Use `json`

**Test your configuration**:
```bash
aws sts get-caller-identity
```

If successful, you'll see your AWS account ID, user ARN, and user ID.

### 3. Required Tools

Install these tools if not already present:

```bash
# jq (JSON processor)
brew install jq  # macOS
sudo apt install jq  # Linux

# zip (usually pre-installed)
which zip  # Verify it exists
```

### 4. OSRP Repository

Clone the OSRP repository:

```bash
git clone https://github.com/open-sensor-research-platform/osrp.git
cd osrp
```

---

## Quick Start

Deploy to AWS in three commands:

```bash
# Navigate to infrastructure directory
cd infrastructure

# Make deploy script executable
chmod +x deploy.sh

# Deploy to development environment
./deploy.sh dev us-west-2
```

That's it! The script will:
1. ✅ Validate CloudFormation template
2. ✅ Create or update the stack
3. ✅ Deploy all AWS resources
4. ✅ Package and upload Lambda code
5. ✅ Display connection details

**Time**: 5-10 minutes

---

## What Gets Deployed

### DynamoDB Tables (4)

| Table | Purpose | Billing |
|-------|---------|---------|
| `osrp-ParticipantStatus-dev` | User enrollment and tracking | Pay-per-request |
| `osrp-SensorTimeSeries-dev` | Sensor data (accelerometer, GPS, etc.) | Pay-per-request |
| `osrp-EventLog-dev` | App events and interactions | Pay-per-request |
| `osrp-DeviceState-dev` | Device state snapshots | Pay-per-request |

**Features**:
- ✅ Global Secondary Indexes for efficient queries
- ✅ Time-To-Live (90 days) for automatic data cleanup
- ✅ Point-in-time recovery enabled
- ✅ Encryption at rest (AES-256)

### S3 Buckets (2)

| Bucket | Purpose |
|--------|---------|
| `osrp-data-dev-{account-id}` | Screenshots, large files |
| `osrp-logs-dev-{account-id}` | Access logs |

**Features**:
- ✅ Lifecycle policies (move to Glacier after 90 days)
- ✅ Versioning enabled
- ✅ CORS configured for mobile apps
- ✅ Encryption at rest

### Cognito User Pool

**User authentication system**:
- ✅ Email-based authentication
- ✅ Strong password policy
- ✅ Email verification
- ✅ Custom attributes: `studyCode`, `participantId`
- ✅ Token refresh (30 days)

### Lambda Functions (2)

| Function | Purpose | Memory | Timeout |
|----------|---------|--------|---------|
| `osrp-auth-dev` | User authentication (register, login, refresh) | 256 MB | 30s |
| `osrp-data-upload-dev` | Data upload (sensor, events, files) | 512 MB | 30s |

**Features**:
- ✅ Python 3.11 runtime
- ✅ CloudWatch logging (30-day retention)
- ✅ IAM roles with least privilege
- ✅ Environment variables configured

### API Gateway

**REST API**: `https://{api-id}.execute-api.us-west-2.amazonaws.com/dev`

**Endpoints**:
- `POST /auth/register` - User registration
- `POST /auth/login` - User login
- `POST /auth/refresh` - Token refresh
- `POST /data/sensor` - Upload sensor data (auth required)
- `POST /data/event` - Log events (auth required)
- `POST /data/device-state` - Upload device state (auth required)
- `GET /data/presigned-url` - Get S3 upload URL (auth required)

**Features**:
- ✅ Cognito User Pool authorizer
- ✅ Rate limiting (10,000 req/sec)
- ✅ CORS enabled
- ✅ CloudWatch logging

---

## Step-by-Step Deployment

### Step 1: Navigate to Infrastructure Directory

```bash
cd osrp/infrastructure
```

### Step 2: Make Deploy Script Executable

```bash
chmod +x deploy.sh
```

### Step 3: Run Deployment Script

```bash
./deploy.sh dev us-west-2
```

**Arguments**:
- `dev` - Environment name (dev, staging, or prod)
- `us-west-2` - AWS region

**Optional third argument**: Custom stack name
```bash
./deploy.sh dev us-west-2 my-custom-stack
```

### Step 4: Wait for Deployment

The script will display progress:

```
========================================
OSRP Infrastructure Deployment
========================================

Environment: dev
Region: us-west-2
Stack Name: osrp-dev

✓ AWS credentials valid (Account: 123456789012)
✓ Template is valid
Creating new stack: osrp-dev
Deploying CloudFormation stack...
Waiting for stack creation to complete...
✓ Stack deployed successfully
```

**Deployment time**: 5-10 minutes

### Step 5: Review Outputs

After successful deployment, the script displays:

```
========================================
Deployment Complete!
========================================

API Endpoint:
  https://abc123xyz.execute-api.us-west-2.amazonaws.com/dev

Cognito User Pool:
  Pool ID: us-west-2_abc123xyz
  Client ID: abc123xyz456

Lambda Functions:
  Auth: osrp-auth-dev
  Data Upload: osrp-data-upload-dev
```

**Save these values!** You'll need them for mobile app configuration and testing.

### Step 6: Save Configuration

Save your deployment details to a `.env` file:

```bash
echo "API_ENDPOINT=https://abc123xyz.execute-api.us-west-2.amazonaws.com/dev" > .env
echo "USER_POOL_ID=us-west-2_abc123xyz" >> .env
echo "USER_POOL_CLIENT_ID=abc123xyz456" >> .env
```

---

## Testing Your Deployment

### Create a Test User

```bash
# Set your User Pool ID
export USER_POOL_ID="us-west-2_abc123xyz"

# Create test user
aws cognito-idp admin-create-user \
  --user-pool-id $USER_POOL_ID \
  --username test@example.com \
  --user-attributes \
    Name=email,Value=test@example.com \
    Name=email_verified,Value=true \
    Name=custom:studyCode,Value=test_study \
    Name=custom:participantId,Value=TEST001 \
  --message-action SUPPRESS \
  --region us-west-2

# Set permanent password
aws cognito-idp admin-set-user-password \
  --user-pool-id $USER_POOL_ID \
  --username test@example.com \
  --password Test1234! \
  --permanent \
  --region us-west-2
```

### Test Authentication

```bash
# Set your API endpoint
export API_ENDPOINT="https://abc123xyz.execute-api.us-west-2.amazonaws.com/dev"

# Test login
curl -X POST $API_ENDPOINT/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "Test1234!"
  }' | jq .
```

**Expected response**:
```json
{
  "accessToken": "eyJraWQiOiI...",
  "idToken": "eyJraWQiOiI...",
  "refreshToken": "eyJjdHk...",
  "expiresIn": 3600,
  "tokenType": "Bearer"
}
```

### Test Data Upload

**⚠️ IMPORTANT**: Use the **ID token** (not access token) for authenticated endpoints.

```bash
# Save ID token
export ID_TOKEN=$(curl -s -X POST $API_ENDPOINT/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"Test1234!"}' \
  | jq -r '.idToken')

# Upload sensor data
curl -X POST $API_ENDPOINT/data/sensor \
  -H "Authorization: Bearer $ID_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "sensorType": "accelerometer",
    "readings": [
      {
        "timestamp": 1705334400123,
        "data": {"x": 0.234, "y": -9.812, "z": 0.156},
        "accuracy": 3
      }
    ],
    "studyCode": "test_study"
  }' | jq .
```

**Expected response**:
```json
{
  "message": "Sensor data uploaded successfully",
  "count": 1,
  "sensorType": "accelerometer"
}
```

### Verify Data in DynamoDB

```bash
aws dynamodb scan \
  --table-name osrp-SensorTimeSeries-dev \
  --region us-west-2 \
  --limit 5
```

You should see your uploaded sensor data.

---

## Configuration Options

### Environment Options

The deploy script accepts three environments:

1. **dev** - Development environment
   - Minimal security restrictions
   - Used for testing and development
   - Lower costs

2. **staging** - Pre-production environment
   - Mirrors production setup
   - Used for final testing before release
   - Same configuration as production

3. **prod** - Production environment
   - Full security restrictions
   - Used for live research studies
   - Higher availability settings

**Deploy to different environments**:
```bash
./deploy.sh dev us-west-2      # Development
./deploy.sh staging us-west-2  # Staging
./deploy.sh prod us-west-2     # Production
```

### Region Options

OSRP can be deployed to any AWS region. Recommended regions:

- **us-west-2** (Oregon) - Default, lowest latency for West Coast
- **us-east-1** (N. Virginia) - Lowest cost, most AWS services
- **eu-west-1** (Ireland) - Europe studies
- **ap-southeast-1** (Singapore) - Asia studies

**Deploy to different regions**:
```bash
./deploy.sh dev us-west-2     # Oregon
./deploy.sh dev us-east-1     # Virginia
./deploy.sh dev eu-west-1     # Ireland
```

### Custom Stack Names

Use custom stack names for multiple studies:

```bash
./deploy.sh dev us-west-2 depression-study
./deploy.sh dev us-west-2 anxiety-study
./deploy.sh dev us-west-2 sleep-study
```

---

## Troubleshooting

### Issue: AWS credentials not configured

**Error message**:
```
Error: AWS credentials not configured
Run: aws configure
```

**Solution**:
```bash
aws configure
```

Enter your AWS Access Key ID and Secret Access Key.

**Get credentials**:
1. Log into AWS Console
2. Navigate to IAM → Users → Your User → Security Credentials
3. Create Access Key
4. Copy Access Key ID and Secret Access Key

---

### Issue: CloudFormation template validation failed

**Error message**:
```
Error: CloudFormation template validation failed
```

**Solution**:
1. Check that you're in the `infrastructure/` directory
2. Verify the template file exists:
   ```bash
   ls -la cloudformation-master.yaml
   ```
3. Validate template manually:
   ```bash
   aws cloudformation validate-template \
     --template-body file://cloudformation-master.yaml \
     --region us-west-2
   ```

---

### Issue: Stack creation failed - S3 bucket already exists

**Error message**:
```
CREATE_FAILED: BucketAlreadyExists
```

**Cause**: S3 bucket names must be globally unique across all AWS accounts.

**Solution**:
1. Check stack events to see which bucket failed:
   ```bash
   aws cloudformation describe-stack-events \
     --stack-name osrp-dev \
     --region us-west-2 \
     --max-items 20
   ```

2. Use a custom stack name with a unique suffix:
   ```bash
   ./deploy.sh dev us-west-2 osrp-$(date +%s)
   ```

---

### Issue: Lambda function not updating

**Error message**: Lambda code seems old after deployment.

**Solution**:
1. Check Lambda function status:
   ```bash
   aws lambda get-function \
     --function-name osrp-auth-dev \
     --region us-west-2
   ```

2. Manually update Lambda code:
   ```bash
   cd lambda
   zip auth_handler.zip auth_handler.py

   aws lambda update-function-code \
     --function-name osrp-auth-dev \
     --zip-file fileb://auth_handler.zip \
     --region us-west-2

   aws lambda wait function-updated \
     --function-name osrp-auth-dev \
     --region us-west-2
   ```

---

### Issue: API returns 401 Unauthorized on protected endpoints

**Error message**:
```json
{"message": "Unauthorized"}
```

**Cause**: Using access token instead of ID token.

**Solution**: API Gateway Cognito authorizer validates **ID tokens**, not access tokens.

Use the ID token in your Authorization header:

```bash
# ❌ Wrong:
export TOKEN=$(curl -s ... | jq -r '.accessToken')

# ✅ Correct:
export TOKEN=$(curl -s ... | jq -r '.idToken')

# Use in requests:
curl -H "Authorization: Bearer $TOKEN" ...
```

---

### Issue: High AWS costs

**Solution**: Check your resource usage:

```bash
# View cost breakdown
aws ce get-cost-and-usage \
  --time-period Start=2026-01-01,End=2026-01-31 \
  --granularity MONTHLY \
  --metrics BlendedCost \
  --region us-east-1
```

**Cost optimization tips**:
1. Delete unused stacks
2. Use lifecycle policies (already configured)
3. Enable TTL on DynamoDB (already configured)
4. Monitor CloudWatch logs size
5. Set billing alarms:
   ```bash
   aws cloudwatch put-metric-alarm \
     --alarm-name osrp-billing-alarm \
     --alarm-description "Alert when monthly charges exceed $10" \
     --metric-name EstimatedCharges \
     --namespace AWS/Billing \
     --statistic Maximum \
     --period 21600 \
     --evaluation-periods 1 \
     --threshold 10 \
     --comparison-operator GreaterThanThreshold \
     --region us-east-1
   ```

---

### Issue: Cannot delete stack - S3 buckets not empty

**Error message**:
```
DELETE_FAILED: The bucket you tried to delete is not empty
```

**Solution**: Empty S3 buckets before deleting stack:

```bash
# Get bucket names
aws cloudformation describe-stacks \
  --stack-name osrp-dev \
  --region us-west-2 \
  --query 'Stacks[0].Outputs[?OutputKey==`DataBucketName`].OutputValue' \
  --output text

# Empty data bucket
aws s3 rm s3://osrp-data-dev-123456789012 --recursive --region us-west-2

# Empty logs bucket
aws s3 rm s3://osrp-logs-dev-123456789012 --recursive --region us-west-2

# Now delete stack
aws cloudformation delete-stack \
  --stack-name osrp-dev \
  --region us-west-2
```

---

## Cost Estimation

### Free Tier (First 12 Months)

AWS Free Tier includes:
- **Lambda**: 1M requests/month, 400K GB-seconds
- **API Gateway**: 1M requests/month
- **DynamoDB**: 25 GB storage, 25 WCU, 25 RCU (pay-per-request)
- **S3**: 5 GB storage, 20K GET, 2K PUT
- **Cognito**: 50K Monthly Active Users (MAU)

### MVP Cost (10 Participants)

**Assumptions**:
- 10 active participants
- 100 API calls/day/participant
- 1 GB sensor data/month
- 1 GB screenshots/month

**Monthly costs**:
- Lambda: **FREE** (within free tier)
- API Gateway: **FREE** (30K requests < 1M limit)
- DynamoDB: **FREE** (within free tier)
- S3: **$0.10** (2 GB storage)
- Cognito: **FREE** (10 MAU < 50K limit)
- CloudWatch Logs: **$0.01**

**Total**: **~$0.11/month**

### Production Cost (100 Participants)

**Assumptions**:
- 100 active participants
- 100 API calls/day/participant
- 10 GB sensor data/month
- 10 GB screenshots/month

**Monthly costs**:
- Lambda: **$0.50** (300K requests/month)
- API Gateway: **$1.05** (300K requests)
- DynamoDB: **$0.48** (writes + storage)
- S3: **$6.22** (20 GB with lifecycle)
- Cognito: **FREE** (100 MAU < 50K limit)
- CloudWatch Logs: **$0.25**

**Total**: **~$8.50/month**

### Cost Optimization

OSRP includes these cost optimizations:

1. **S3 Lifecycle Policies**: 81% savings
   - Day 0-29: STANDARD storage
   - Day 30-89: STANDARD_IA (lower cost)
   - Day 90+: GLACIER (archive)

2. **DynamoDB TTL**: Automatic deletion after 90 days
   - No storage costs for old data
   - Compliance with data retention policies

3. **Pay-Per-Request DynamoDB**: No idle capacity costs
   - Only pay for actual reads/writes
   - Scales automatically

4. **Lambda Memory Optimization**: Right-sized allocations
   - Auth: 256 MB (adequate)
   - Data Upload: 512 MB (adequate)

---

## Cleanup and Teardown

### Delete Entire Stack

**⚠️ WARNING**: This will permanently delete all data, users, and configurations.

```bash
# Empty S3 buckets first
export ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

aws s3 rm s3://osrp-data-dev-$ACCOUNT_ID --recursive --region us-west-2
aws s3 rm s3://osrp-logs-dev-$ACCOUNT_ID --recursive --region us-west-2

# Delete stack
aws cloudformation delete-stack \
  --stack-name osrp-dev \
  --region us-west-2

# Wait for deletion to complete
aws cloudformation wait stack-delete-complete \
  --stack-name osrp-dev \
  --region us-west-2
```

**Time**: 2-5 minutes

### What Gets Deleted

When you delete the stack, AWS removes:
- ✅ All DynamoDB tables and data
- ✅ All S3 buckets (if empty)
- ✅ All Lambda functions and code
- ✅ API Gateway configuration
- ✅ Cognito User Pool and all users
- ✅ CloudWatch Log Groups
- ✅ IAM roles and policies

### Partial Cleanup

To save costs while preserving data:

#### Option 1: Delete Lambda Functions Only

```bash
aws lambda delete-function \
  --function-name osrp-auth-dev \
  --region us-west-2

aws lambda delete-function \
  --function-name osrp-data-upload-dev \
  --region us-west-2
```

**Savings**: ~$0.50/month (if outside free tier)

#### Option 2: Export Data Before Deletion

```bash
# Export DynamoDB table
aws dynamodb scan \
  --table-name osrp-SensorTimeSeries-dev \
  --region us-west-2 \
  --output json \
  > sensor-data-backup.json

# Export to S3 for long-term storage
aws s3 cp sensor-data-backup.json s3://my-backup-bucket/osrp/
```

#### Option 3: Disable But Keep Infrastructure

```bash
# Disable Cognito User Pool (prevent new logins)
aws cognito-idp update-user-pool \
  --user-pool-id us-west-2_abc123xyz \
  --region us-west-2 \
  --user-pool-add-ons AdvancedSecurityMode=OFF

# This keeps infrastructure but prevents new data ingestion
```

---

## Next Steps

### 1. Configure Mobile Apps

Now that your AWS infrastructure is deployed, configure your mobile apps:

**Android** (Issue #11):
1. Add AWS Amplify to project
2. Configure Cognito authentication
3. Set API endpoint in app config
4. Implement sensor data collection

**iOS** (Issue #18):
1. Add AWS SDK to project
2. Configure Cognito authentication
3. Set API endpoint in app config
4. Implement sensor data collection

### 2. Set Up Monitoring

Create CloudWatch dashboard:
```bash
aws cloudwatch put-dashboard \
  --dashboard-name osrp-dev-dashboard \
  --dashboard-body file://dashboard.json \
  --region us-west-2
```

Set up alarms:
```bash
# Lambda errors
aws cloudwatch put-metric-alarm \
  --alarm-name osrp-auth-errors \
  --alarm-description "Alert on Lambda errors" \
  --metric-name Errors \
  --namespace AWS/Lambda \
  --statistic Sum \
  --period 300 \
  --evaluation-periods 1 \
  --threshold 5 \
  --comparison-operator GreaterThanThreshold \
  --dimensions Name=FunctionName,Value=osrp-auth-dev \
  --region us-west-2
```

### 3. Deploy to Additional Environments

Deploy staging environment:
```bash
./deploy.sh staging us-west-2
```

Deploy production environment:
```bash
./deploy.sh prod us-west-2
```

### 4. Set Up CI/CD

Automate deployments with GitHub Actions:

Create `.github/workflows/deploy-aws.yml`:
```yaml
name: Deploy OSRP to AWS

on:
  push:
    branches: [main]
    paths:
      - 'infrastructure/**'

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v2
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: us-west-2

      - name: Deploy infrastructure
        run: |
          cd infrastructure
          chmod +x deploy.sh
          ./deploy.sh dev us-west-2
```

### 5. Begin Data Collection

Your infrastructure is ready! Next steps:

1. ✅ AWS infrastructure deployed
2. ⏭️ Configure mobile apps with API endpoint
3. ⏭️ Test data collection on test devices
4. ⏭️ Recruit pilot participants
5. ⏭️ Monitor data quality and costs
6. ⏭️ Scale to full study cohort

---

## Additional Resources

### Documentation

- **Technical Details**: `infrastructure/DEPLOYMENT.md`
- **Testing Results**: `infrastructure/TESTING_RESULTS.md`
- **API Documentation**: `infrastructure/API_GATEWAY.md`
- **Project Overview**: `docs/PROJECT_BRIEF.md`

### AWS Documentation

- [CloudFormation User Guide](https://docs.aws.amazon.com/cloudformation/)
- [Lambda Developer Guide](https://docs.aws.amazon.com/lambda/)
- [DynamoDB Developer Guide](https://docs.aws.amazon.com/dynamodb/)
- [Cognito Developer Guide](https://docs.aws.amazon.com/cognito/)
- [API Gateway Developer Guide](https://docs.aws.amazon.com/apigateway/)

### Support

- **GitHub Issues**: [osrp/issues](https://github.com/open-sensor-research-platform/osrp/issues)
- **AWS Support**: Available if you have a support plan
- **Community**: Coming soon

---

## Appendix: Manual Deployment

If you prefer not to use the automated script, you can deploy manually:

### 1. Validate Template

```bash
aws cloudformation validate-template \
  --template-body file://cloudformation-master.yaml \
  --region us-west-2
```

### 2. Create Stack

```bash
aws cloudformation create-stack \
  --stack-name osrp-dev \
  --template-body file://cloudformation-master.yaml \
  --parameters \
    ParameterKey=Environment,ParameterValue=dev \
    ParameterKey=StudyName,ParameterValue=osrp \
  --capabilities CAPABILITY_NAMED_IAM \
  --region us-west-2 \
  --tags Key=Environment,Value=dev Key=Project,Value=OSRP
```

### 3. Wait for Completion

```bash
aws cloudformation wait stack-create-complete \
  --stack-name osrp-dev \
  --region us-west-2
```

### 4. Get Outputs

```bash
aws cloudformation describe-stacks \
  --stack-name osrp-dev \
  --region us-west-2 \
  --query 'Stacks[0].Outputs'
```

### 5. Deploy Lambda Code

```bash
cd lambda

# Package auth handler
zip auth_handler.zip auth_handler.py

aws lambda update-function-code \
  --function-name osrp-auth-dev \
  --zip-file fileb://auth_handler.zip \
  --region us-west-2

aws lambda wait function-updated \
  --function-name osrp-auth-dev \
  --region us-west-2

# Package data upload handler
zip data_upload_handler.zip data_upload_handler.py

aws lambda update-function-code \
  --function-name osrp-data-upload-dev \
  --zip-file fileb://data_upload_handler.zip \
  --region us-west-2

aws lambda wait function-updated \
  --function-name osrp-data-upload-dev \
  --region us-west-2
```

---

**Deployment Guide Version**: 0.2.0
**Last Updated**: January 16, 2026
**Status**: Tested and verified on AWS
**Related Issues**: #7, #8, #9
