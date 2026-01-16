# OSRP Authentication Lambda Function

## Overview

AWS Lambda function for handling user authentication via Cognito.

**Handler File**: `lambda/auth_handler.py`
**CloudFormation Template**: `cloudformation-lambda-auth.yaml`
**Runtime**: Python 3.11
**Version**: 0.2.0 (MVP)

---

## Endpoints

### POST /auth/register

Register a new user with study-specific attributes.

**Request**:
```json
{
  "email": "participant@example.com",
  "password": "SecurePass123!",
  "studyCode": "depression_study_2026",
  "participantId": "P001"
}
```

**Response (200)**:
```json
{
  "message": "User registered successfully",
  "userSub": "550e8400-e29b-41d4-a716-446655440000",
  "userConfirmed": false,
  "email": "participant@example.com",
  "studyCode": "depression_study_2026",
  "participantId": "P001"
}
```

**Error Responses**:
- `400` - Invalid password or missing fields
- `409` - User already exists
- `500` - Internal server error

### POST /auth/login

Authenticate user and return tokens.

**Request**:
```json
{
  "email": "participant@example.com",
  "password": "SecurePass123!"
}
```

**Response (200)**:
```json
{
  "accessToken": "eyJraWQiOiI...",
  "idToken": "eyJraWQiOiJ...",
  "refreshToken": "eyJjdHkiOi...",
  "expiresIn": 3600,
  "tokenType": "Bearer"
}
```

**Error Responses**:
- `401` - Invalid email or password
- `403` - User email not verified
- `500` - Internal server error

### POST /auth/refresh

Refresh access and ID tokens.

**Request**:
```json
{
  "refreshToken": "eyJjdHkiOi..."
}
```

**Response (200)**:
```json
{
  "accessToken": "eyJraWQiOiI...",
  "idToken": "eyJraWQiOiJ...",
  "expiresIn": 3600,
  "tokenType": "Bearer"
}
```

**Error Responses**:
- `401` - Invalid or expired refresh token
- `500` - Internal server error

---

## Deployment

### Prerequisites

1. **Cognito Stack Deployed**:
   ```bash
   aws cloudformation describe-stacks \
     --stack-name osrp-cognito-dev \
     --region us-west-2
   ```

2. **AWS CLI Configured**:
   ```bash
   aws sts get-caller-identity
   ```

### Package Lambda Code

```bash
# From infrastructure directory
cd infrastructure/lambda

# Create deployment package
zip -r auth_handler.zip auth_handler.py

# Upload to S3 (if code is large)
aws s3 cp auth_handler.zip s3://osrp-deployment-us-west-2/lambda/auth_handler.zip
```

### Deploy CloudFormation Stack

```bash
# From infrastructure directory
cd infrastructure

# Validate template
aws cloudformation validate-template \
  --template-body file://cloudformation-lambda-auth.yaml

# Create stack
aws cloudformation create-stack \
  --stack-name osrp-lambda-auth-dev \
  --template-body file://cloudformation-lambda-auth.yaml \
  --parameters \
    ParameterKey=Environment,ParameterValue=dev \
    ParameterKey=StudyName,ParameterValue=osrp \
    ParameterKey=CognitoStackName,ParameterValue=osrp-cognito-dev \
  --capabilities CAPABILITY_NAMED_IAM \
  --region us-west-2

# Wait for completion
aws cloudformation wait stack-create-complete \
  --stack-name osrp-lambda-auth-dev \
  --region us-west-2

# Get outputs
aws cloudformation describe-stacks \
  --stack-name osrp-lambda-auth-dev \
  --region us-west-2 \
  --query 'Stacks[0].Outputs'
```

### Update Lambda Code

```bash
# From infrastructure/lambda directory
zip -r auth_handler.zip auth_handler.py

# Update function code
aws lambda update-function-code \
  --function-name osrp-auth-dev \
  --zip-file fileb://auth_handler.zip \
  --region us-west-2

# Wait for update
aws lambda wait function-updated \
  --function-name osrp-auth-dev \
  --region us-west-2
```

---

## Testing

### Unit Tests

```bash
# From project root
pytest tests/lambda/test_auth_handler.py -v

# With coverage
pytest tests/lambda/test_auth_handler.py --cov=auth_handler --cov-report=html
```

### Integration Testing

#### Test Registration

```bash
# Get Lambda function name
FUNCTION_NAME=$(aws cloudformation describe-stacks \
  --stack-name osrp-lambda-auth-dev \
  --region us-west-2 \
  --query 'Stacks[0].Outputs[?OutputKey==`AuthLambdaFunctionName`].OutputValue' \
  --output text)

# Invoke Lambda
aws lambda invoke \
  --function-name $FUNCTION_NAME \
  --payload '{
    "httpMethod": "POST",
    "path": "/auth/register",
    "body": "{\"email\":\"test@example.com\",\"password\":\"SecurePass123!\",\"studyCode\":\"test_study\",\"participantId\":\"TEST001\"}"
  }' \
  --region us-west-2 \
  response.json

# View response
cat response.json | jq .
```

#### Test Login

```bash
aws lambda invoke \
  --function-name $FUNCTION_NAME \
  --payload '{
    "httpMethod": "POST",
    "path": "/auth/login",
    "body": "{\"email\":\"test@example.com\",\"password\":\"SecurePass123!\"}"
  }' \
  --region us-west-2 \
  response.json

cat response.json | jq .
```

#### Test Refresh

```bash
# Extract refresh token from login response
REFRESH_TOKEN=$(cat response.json | jq -r '.body' | jq -r '.refreshToken')

aws lambda invoke \
  --function-name $FUNCTION_NAME \
  --payload "{
    \"httpMethod\": \"POST\",
    \"path\": \"/auth/refresh\",
    \"body\": \"{\\\"refreshToken\\\":\\\"$REFRESH_TOKEN\\\"}\"
  }" \
  --region us-west-2 \
  response.json

cat response.json | jq .
```

### API Gateway Testing (After Issue #6)

```bash
# Get API endpoint
API_ENDPOINT=$(aws cloudformation describe-stacks \
  --stack-name osrp-api-gateway-dev \
  --region us-west-2 \
  --query 'Stacks[0].Outputs[?OutputKey==`ApiEndpoint`].OutputValue' \
  --output text)

# Test registration
curl -X POST $API_ENDPOINT/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "SecurePass123!",
    "studyCode": "test_study",
    "participantId": "TEST001"
  }' | jq .

# Test login
curl -X POST $API_ENDPOINT/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "SecurePass123!"
  }' | jq .
```

---

## CloudWatch Logs

### View Logs

```bash
# Get log group name
LOG_GROUP="/aws/lambda/osrp-auth-dev"

# View recent logs
aws logs tail $LOG_GROUP \
  --follow \
  --region us-west-2

# Search logs
aws logs filter-log-events \
  --log-group-name $LOG_GROUP \
  --filter-pattern "ERROR" \
  --region us-west-2
```

### Log Format

```
[INFO] 2026-01-16T12:00:00.000Z request-id Authenticating user: test@example.com
[INFO] 2026-01-16T12:00:01.000Z request-id User authenticated successfully: test@example.com
```

---

## Error Handling

### Client Errors (4xx)

| Code | Error | Description |
|------|-------|-------------|
| 400 | Invalid JSON | Request body not valid JSON |
| 400 | Invalid password | Password doesn't meet requirements |
| 400 | Missing field | Required field missing from request |
| 401 | Invalid credentials | Email or password incorrect |
| 401 | Invalid token | Refresh token invalid or expired |
| 403 | Not verified | User email not verified |
| 404 | Not found | Invalid endpoint |
| 409 | User exists | Email already registered |

### Server Errors (5xx)

| Code | Error | Description |
|------|-------|-------------|
| 500 | Internal error | Unexpected server error |

### Error Response Format

```json
{
  "error": "Error message here"
}
```

---

## Security

### Token Storage

**DO NOT**:
- Log tokens
- Store tokens in plaintext
- Send tokens in URL parameters
- Store tokens in local storage (web)

**DO**:
- Store in secure storage (Keychain/Keystore)
- Clear tokens on logout
- Validate tokens before use
- Refresh tokens proactively

### Password Requirements

- Minimum 8 characters
- At least one uppercase letter (A-Z)
- At least one lowercase letter (a-z)
- At least one number (0-9)
- At least one special character (!@#$%^&*)

### Rate Limiting

Consider adding API Gateway throttling:
- Burst limit: 100 requests/second
- Rate limit: 1000 requests/second

---

## Monitoring

### CloudWatch Metrics

Key metrics to monitor:
- `Invocations` - Total Lambda invocations
- `Errors` - Function errors
- `Duration` - Execution time
- `Throttles` - Throttled invocations

### Custom Metrics (Future)

Log custom metrics:
```python
import boto3
cloudwatch = boto3.client('cloudwatch')

cloudwatch.put_metric_data(
    Namespace='OSRP/Auth',
    MetricData=[
        {
            'MetricName': 'SuccessfulLogins',
            'Value': 1,
            'Unit': 'Count',
            'Dimensions': [
                {'Name': 'Environment', 'Value': 'dev'}
            ]
        }
    ]
)
```

### Alarms

Create CloudWatch alarms:

```bash
# High error rate alarm
aws cloudwatch put-metric-alarm \
  --alarm-name osrp-auth-errors-dev \
  --alarm-description "Auth Lambda error rate too high" \
  --metric-name Errors \
  --namespace AWS/Lambda \
  --statistic Sum \
  --period 300 \
  --evaluation-periods 1 \
  --threshold 10 \
  --comparison-operator GreaterThanThreshold \
  --dimensions Name=FunctionName,Value=osrp-auth-dev \
  --region us-west-2
```

---

## Troubleshooting

### Issue: Lambda timeout

**Symptoms**: 502 Bad Gateway, CloudWatch shows timeout
**Cause**: Lambda execution time > 30 seconds
**Fix**:
1. Check Cognito latency
2. Increase Lambda timeout (max 15 minutes)
3. Check network connectivity

### Issue: Invalid user pool ID

**Symptoms**: ResourceNotFoundException
**Cause**: Environment variable not set or incorrect
**Fix**:
```bash
aws lambda update-function-configuration \
  --function-name osrp-auth-dev \
  --environment Variables={USER_POOL_ID=us-west-2_ABC123,CLIENT_ID=abc123xyz} \
  --region us-west-2
```

### Issue: Permission denied

**Symptoms**: AccessDeniedException
**Cause**: Lambda role lacks Cognito permissions
**Fix**: Update IAM role policy (see CloudFormation template)

### Issue: Cold start latency

**Symptoms**: First request takes >1 second
**Cause**: Lambda cold start
**Solution**: Consider provisioned concurrency for production

---

## Performance

### Benchmarks

Expected performance (warm Lambda):
- Registration: 200-400ms
- Login: 150-300ms
- Refresh: 100-200ms

### Optimization Tips

1. **Reuse connections**: boto3 client created once
2. **Minimize dependencies**: Only import what's needed
3. **Use provisioned concurrency**: For production workloads
4. **Monitor CloudWatch**: Identify slow operations

---

## Cost Estimation

### Lambda Pricing

**Free Tier** (per month):
- 1M requests - FREE
- 400,000 GB-seconds compute - FREE

**Beyond Free Tier**:
- $0.20 per 1M requests
- $0.0000166667 per GB-second

### MVP Cost (10 participants)

**Assumptions**:
- 100 auth requests/day
- 256 MB memory, 200ms average duration

**Calculations**:
- Requests: 3,000/month = **FREE** (within free tier)
- Compute: 3,000 × 0.256 GB × 0.2s = 153.6 GB-seconds = **FREE**

**Total**: $0/month

### Production Cost (100 participants)

**Assumptions**:
- 1,000 auth requests/day
- 256 MB memory, 200ms average duration

**Calculations**:
- Requests: 30,000/month = **FREE**
- Compute: 30,000 × 0.256 GB × 0.2s = 1,536 GB-seconds = **FREE**

**Total**: $0/month (still within free tier)

---

## Next Steps

1. ✅ Lambda function implemented
2. ✅ Unit tests created
3. ✅ CloudFormation template created
4. ✅ Documentation complete
5. ⏭️ Deploy to AWS dev environment (Issue #8)
6. ⏭️ Test authentication flow
7. ⏭️ Integrate with API Gateway (Issue #6)
8. ⏭️ Integrate with mobile apps (Issues #11, #18)

---

**Lambda Version**: 0.2.0 (MVP)
**Last Updated**: January 16, 2026
**Related Issues**: #4, #6, #8, #11, #18
