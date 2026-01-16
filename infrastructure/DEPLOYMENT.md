# OSRP AWS Deployment Guide

## Overview

Complete guide for deploying OSRP infrastructure to AWS using CloudFormation.

**Master Template**: `cloudformation-master.yaml`
**Deployment Script**: `deploy.sh`
**Version**: 0.2.0 (MVP)

---

## Prerequisites

### 1. AWS Account

- Active AWS account
- Administrator or PowerUser access
- Credit card on file (for charges beyond free tier)

### 2. AWS CLI

Install and configure AWS CLI:

```bash
# Install (macOS)
brew install awscli

# Install (Linux)
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# Configure credentials
aws configure
# AWS Access Key ID: <your-key>
# AWS Secret Access Key: <your-secret>
# Default region: us-west-2
# Default output format: json

# Verify
aws sts get-caller-identity
```

### 3. Required Tools

```bash
# jq (JSON processor)
brew install jq  # macOS
sudo apt install jq  # Linux

# zip
# Usually pre-installed, verify:
which zip
```

---

## Quick Start

### Deploy to Development

```bash
cd infrastructure
./deploy.sh dev us-west-2
```

This single command:
1. ✅ Validates CloudFormation template
2. ✅ Creates/updates stack
3. ✅ Deploys all AWS resources
4. ✅ Packages Lambda code
5. ✅ Updates Lambda functions
6. ✅ Outputs connection details

**Time**: ~5-10 minutes

---

## Resources Deployed

### DynamoDB Tables (4)

| Table | Purpose | Billing |
|-------|---------|---------|
| ParticipantStatus | User enrollment and tracking | Pay-per-request |
| SensorTimeSeries | Sensor data (accelerometer, etc.) | Pay-per-request |
| EventLog | App events and interactions | Pay-per-request |
| DeviceState | Device state snapshots | Pay-per-request |

**Features**:
- Global Secondary Indexes for querying
- Time-To-Live (90 days) on data tables
- Point-in-time recovery enabled
- Encryption at rest (AES-256)
- DynamoDB Streams enabled

### S3 Buckets (2)

| Bucket | Purpose | Features |
|--------|---------|----------|
| osrp-data-{env}-{account-id} | Data storage | Lifecycle policies, versioning, CORS |
| osrp-logs-{env}-{account-id} | Access logs | 90-day retention, encryption |

**Data Bucket Lifecycle**:
- Day 0-29: STANDARD storage
- Day 30-89: STANDARD_IA (Infrequent Access)
- Day 90+: GLACIER (Archive)

### Cognito (User Authentication)

- **User Pool**: Email-based authentication
- **User Pool Client**: Mobile app client
- **Identity Pool**: AWS credentials for mobile apps
- **Custom Attributes**: studyCode, participantId

**Features**:
- Strong password policy
- Email verification
- Optional MFA (software token)
- Token refresh (30 days)

### Lambda Functions (2)

| Function | Purpose | Memory | Timeout |
|----------|---------|--------|---------|
| osrp-auth-{env} | Authentication (register, login, refresh) | 256 MB | 30s |
| osrp-data-upload-{env} | Data upload (sensor, events, files) | 512 MB | 30s |

**Features**:
- Python 3.11 runtime
- CloudWatch logging (30-day retention)
- IAM roles with least privilege
- Environment variables configured

### API Gateway

- **REST API**: Regional endpoint
- **Endpoints**: 7 (3 auth + 4 data)
- **Authentication**: Cognito User Pool authorizer
- **Rate Limiting**: 10K req/sec, 5K burst
- **CORS**: Enabled for mobile apps

---

## Deployment Options

### Option 1: Automated Script (Recommended)

```bash
# Deploy to dev
./deploy.sh dev us-west-2

# Deploy to staging
./deploy.sh staging us-west-2

# Deploy to prod
./deploy.sh prod us-west-2

# Custom stack name
./deploy.sh dev us-west-2 my-custom-stack
```

### Option 2: Manual AWS CLI

```bash
# Validate template
aws cloudformation validate-template \
  --template-body file://cloudformation-master.yaml \
  --region us-west-2

# Deploy stack
aws cloudformation create-stack \
  --stack-name osrp-dev \
  --template-body file://cloudformation-master.yaml \
  --parameters \
    ParameterKey=Environment,ParameterValue=dev \
    ParameterKey=StudyName,ParameterValue=osrp \
  --capabilities CAPABILITY_NAMED_IAM \
  --region us-west-2

# Wait for completion
aws cloudformation wait stack-create-complete \
  --stack-name osrp-dev \
  --region us-west-2

# Package and deploy Lambda code
cd lambda
zip auth_handler.zip auth_handler.py
zip data_upload_handler.zip data_upload_handler.py

aws lambda update-function-code \
  --function-name osrp-auth-dev \
  --zip-file fileb://auth_handler.zip \
  --region us-west-2

aws lambda update-function-code \
  --function-name osrp-data-upload-dev \
  --zip-file fileb://data_upload_handler.zip \
  --region us-west-2
```

### Option 3: AWS Console

1. Navigate to CloudFormation console
2. Click "Create stack"
3. Upload `cloudformation-master.yaml`
4. Enter parameters (Environment: dev, StudyName: osrp)
5. Acknowledge IAM resource creation
6. Click "Create stack"
7. Wait 5-10 minutes for completion
8. Manually deploy Lambda code via AWS CLI or Lambda console

---

## Post-Deployment

### 1. Get Stack Outputs

```bash
aws cloudformation describe-stacks \
  --stack-name osrp-dev \
  --region us-west-2 \
  --query 'Stacks[0].Outputs'
```

**Key Outputs**:
- `ApiEndpoint`: API Gateway URL
- `UserPoolId`: Cognito User Pool ID
- `UserPoolClientId`: Cognito Client ID
- `DataBucketName`: S3 bucket name
- Lambda function names

### 2. Save Configuration

```bash
# Save to .env file
export API_ENDPOINT=$(aws cloudformation describe-stacks \
  --stack-name osrp-dev \
  --region us-west-2 \
  --query 'Stacks[0].Outputs[?OutputKey==`ApiEndpoint`].OutputValue' \
  --output text)

echo "API_ENDPOINT=$API_ENDPOINT" > .env
echo "USER_POOL_ID=<user-pool-id>" >> .env
echo "USER_POOL_CLIENT_ID=<client-id>" >> .env
```

### 3. Create Test User

```bash
aws cognito-idp admin-create-user \
  --user-pool-id <user-pool-id> \
  --username test@example.com \
  --user-attributes \
    Name=email,Value=test@example.com \
    Name=email_verified,Value=true \
    Name=custom:studyCode,Value=test_study \
    Name=custom:participantId,Value=TEST001 \
  --temporary-password TempPass123! \
  --region us-west-2

# Set permanent password
aws cognito-idp admin-set-user-password \
  --user-pool-id <user-pool-id> \
  --username test@example.com \
  --password SecurePass123! \
  --permanent \
  --region us-west-2
```

### 4. Test API

```bash
# Test login
curl -X POST $API_ENDPOINT/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "SecurePass123!"
  }' | jq .

# Save access token
export ACCESS_TOKEN=$(curl -s -X POST $API_ENDPOINT/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"SecurePass123!"}' \
  | jq -r '.accessToken')

# Test sensor upload
curl -X POST $API_ENDPOINT/data/sensor \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "sensorType": "accelerometer",
    "readings": [
      {"timestamp": 1705334400123, "data": {"x": 0.234, "y": -9.812, "z": 0.156}, "accuracy": 3}
    ],
    "studyCode": "test_study"
  }' | jq .
```

---

## Updating the Stack

### Update Infrastructure

```bash
# Make changes to cloudformation-master.yaml

# Update stack
./deploy.sh dev us-west-2
```

CloudFormation will:
- ✅ Detect changes
- ✅ Show change set
- ✅ Update only modified resources
- ✅ Rollback on failure

### Update Lambda Code Only

```bash
cd lambda

# Package code
zip auth_handler.zip auth_handler.py

# Deploy
aws lambda update-function-code \
  --function-name osrp-auth-dev \
  --zip-file fileb://auth_handler.zip \
  --region us-west-2
```

### Update Lambda Environment Variables

```bash
aws lambda update-function-configuration \
  --function-name osrp-auth-dev \
  --environment Variables={USER_POOL_ID=xyz,CLIENT_ID=abc} \
  --region us-west-2
```

---

## Monitoring

### CloudWatch Dashboards

Create custom dashboard:

```bash
aws cloudwatch put-dashboard \
  --dashboard-name osrp-dev \
  --dashboard-body file://dashboard.json \
  --region us-west-2
```

### Key Metrics to Monitor

**API Gateway**:
- `Count` - Total requests
- `4XXError` - Client errors
- `5XXError` - Server errors
- `Latency` - Response time

**Lambda**:
- `Invocations` - Function calls
- `Errors` - Failed executions
- `Duration` - Execution time
- `Throttles` - Rate limiting

**DynamoDB**:
- `ConsumedReadCapacityUnits` - Read usage
- `ConsumedWriteCapacityUnits` - Write usage
- `UserErrors` - Client errors

### View Logs

```bash
# API Gateway logs
aws logs tail /aws/apigateway/osrp-api-dev --follow --region us-west-2

# Lambda logs
aws logs tail /aws/lambda/osrp-auth-dev --follow --region us-west-2
aws logs tail /aws/lambda/osrp-data-upload-dev --follow --region us-west-2
```

---

## Cost Management

### Free Tier (First 12 Months)

- **Lambda**: 1M requests/month, 400K GB-seconds
- **API Gateway**: 1M requests/month
- **DynamoDB**: 25 GB storage, 25 WCU, 25 RCU
- **S3**: 5 GB storage, 20K GET, 2K PUT
- **Cognito**: 50K MAU

### MVP Cost Estimate (10 Participants)

**Monthly**:
- Lambda: FREE (within free tier)
- API Gateway: FREE (within free tier)
- DynamoDB: FREE (within free tier)
- S3: $0.10 (4 GB storage)
- Cognito: FREE (within free tier)
- **Total**: ~$0.10/month

### Production Cost Estimate (100 Participants)

**Monthly**:
- Lambda: $0.50 (300K requests)
- API Gateway: $1.05 (300K requests)
- DynamoDB: $0.38 (writes) + $0.10 (storage) = $0.48
- S3: $6.22 (with lifecycle policies)
- Cognito: FREE (within free tier)
- **Total**: ~$8/month

### Cost Optimization

1. **Use lifecycle policies**: 81% S3 cost savings
2. **Enable TTL**: Auto-delete old DynamoDB data
3. **Batch requests**: Reduce API call count
4. **Monitor usage**: Set billing alarms

```bash
# Set billing alarm ($10/month)
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

## Rollback

### Automatic Rollback

CloudFormation automatically rolls back on failure:
- Template validation errors
- Resource creation failures
- Permission issues

### Manual Rollback

```bash
# Rollback to previous stack state
aws cloudformation cancel-update-stack \
  --stack-name osrp-dev \
  --region us-west-2

# Delete and recreate stack
aws cloudformation delete-stack \
  --stack-name osrp-dev \
  --region us-west-2

aws cloudformation wait stack-delete-complete \
  --stack-name osrp-dev \
  --region us-west-2

# Redeploy
./deploy.sh dev us-west-2
```

---

## Troubleshooting

### Issue: Stack creation failed

**Check Events**:
```bash
aws cloudformation describe-stack-events \
  --stack-name osrp-dev \
  --region us-west-2 \
  --max-items 20
```

**Common Causes**:
- Bucket name already taken
- Insufficient IAM permissions
- Invalid parameter values
- Resource limits exceeded

### Issue: Lambda function not updating

**Check Function Status**:
```bash
aws lambda get-function \
  --function-name osrp-auth-dev \
  --region us-west-2
```

**Verify Code**:
```bash
# Download deployed code
aws lambda get-function \
  --function-name osrp-auth-dev \
  --region us-west-2 \
  --query 'Code.Location' \
  --output text | xargs curl -o deployed.zip
```

### Issue: API Gateway 403 errors

**Check Authorizer**:
```bash
aws apigateway get-authorizers \
  --rest-api-id <api-id> \
  --region us-west-2
```

**Test Token**:
```bash
# Verify token is valid
jwt decode $ACCESS_TOKEN
```

### Issue: High costs

**Check Cost Explorer**:
```bash
aws ce get-cost-and-usage \
  --time-period Start=2026-01-01,End=2026-01-31 \
  --granularity MONTHLY \
  --metrics BlendedCost \
  --region us-east-1
```

**Identify Top Services**:
- API Gateway request count
- Lambda invocations
- DynamoDB consumed capacity
- S3 storage and requests

---

## Cleanup

### Delete Stack

```bash
# Delete all resources
aws cloudformation delete-stack \
  --stack-name osrp-dev \
  --region us-west-2

# Wait for deletion
aws cloudformation wait stack-delete-complete \
  --stack-name osrp-dev \
  --region us-west-2
```

**Note**: This deletes:
- ✅ All DynamoDB tables (data is lost)
- ✅ All S3 buckets (if empty)
- ✅ All Lambda functions
- ✅ API Gateway
- ✅ Cognito User Pool (users are lost)

**S3 Buckets**: If buckets have data, you must empty them first:

```bash
# Empty data bucket
aws s3 rm s3://osrp-data-dev-123456789012 --recursive

# Empty logging bucket
aws s3 rm s3://osrp-logs-dev-123456789012 --recursive

# Then delete stack
aws cloudformation delete-stack --stack-name osrp-dev --region us-west-2
```

---

## Multi-Environment Setup

### Deploy All Environments

```bash
# Development
./deploy.sh dev us-west-2

# Staging
./deploy.sh staging us-west-2

# Production
./deploy.sh prod us-west-2
```

### Environment Differences

| Feature | Dev | Staging | Prod |
|---------|-----|---------|------|
| Deletion Protection | ❌ Off | ❌ Off | ✅ On |
| Point-in-time Recovery | ✅ On | ✅ On | ✅ On |
| API Rate Limit | 10K/sec | 10K/sec | 20K/sec* |
| Backup Retention | 7 days | 30 days | 90 days* |

*Requires manual configuration changes to template

---

## CI/CD Integration

### GitHub Actions

```yaml
name: Deploy OSRP Infrastructure

on:
  push:
    branches:
      - main

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

---

## Next Steps

1. ✅ Infrastructure deployed
2. ✅ Test users created
3. ✅ API endpoints tested
4. ⏭️ Deploy mobile apps (Issues #11, #18)
5. ⏭️ Set up monitoring dashboard
6. ⏭️ Configure backup strategy
7. ⏭️ Plan production migration

---

**Deployment Version**: 0.2.0 (MVP)
**Last Updated**: January 16, 2026
**Related Issues**: #7, #8, #9
