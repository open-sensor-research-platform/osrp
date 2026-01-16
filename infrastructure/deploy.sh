#!/bin/bash
#
# OSRP AWS Infrastructure Deployment Script
# Deploys complete OSRP infrastructure to AWS
#
# Usage: ./deploy.sh <environment> <region> [stack-name]
#

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Parse arguments
ENVIRONMENT=${1:-dev}
REGION=${2:-us-west-2}
STACK_NAME=${3:-osrp-${ENVIRONMENT}}

# Validate environment
if [[ ! "$ENVIRONMENT" =~ ^(dev|staging|prod)$ ]]; then
    echo -e "${RED}Error: Invalid environment. Must be dev, staging, or prod${NC}"
    exit 1
fi

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}OSRP Infrastructure Deployment${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo "Environment: $ENVIRONMENT"
echo "Region: $REGION"
echo "Stack Name: $STACK_NAME"
echo ""

# Check AWS credentials
echo -e "${YELLOW}Checking AWS credentials...${NC}"
if ! aws sts get-caller-identity --region $REGION > /dev/null 2>&1; then
    echo -e "${RED}Error: AWS credentials not configured${NC}"
    echo "Run: aws configure"
    exit 1
fi
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
echo -e "${GREEN}✓ AWS credentials valid (Account: $ACCOUNT_ID)${NC}"
echo ""

# Validate CloudFormation template
echo -e "${YELLOW}Validating CloudFormation template...${NC}"
if ! aws cloudformation validate-template \
    --template-body file://cloudformation-master.yaml \
    --region $REGION > /dev/null 2>&1; then
    echo -e "${RED}Error: CloudFormation template validation failed${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Template is valid${NC}"
echo ""

# Check if stack exists
STACK_EXISTS=$(aws cloudformation describe-stacks \
    --stack-name $STACK_NAME \
    --region $REGION 2>&1 || true)

if echo "$STACK_EXISTS" | grep -q "does not exist"; then
    ACTION="create-stack"
    echo -e "${YELLOW}Creating new stack: $STACK_NAME${NC}"
else
    ACTION="update-stack"
    echo -e "${YELLOW}Updating existing stack: $STACK_NAME${NC}"
fi
echo ""

# Deploy stack
echo -e "${YELLOW}Deploying CloudFormation stack...${NC}"
if [ "$ACTION" == "create-stack" ]; then
    aws cloudformation create-stack \
        --stack-name $STACK_NAME \
        --template-body file://cloudformation-master.yaml \
        --parameters \
            ParameterKey=Environment,ParameterValue=$ENVIRONMENT \
            ParameterKey=StudyName,ParameterValue=osrp \
        --capabilities CAPABILITY_NAMED_IAM \
        --region $REGION \
        --tags Key=Environment,Value=$ENVIRONMENT Key=Project,Value=OSRP

    echo "Waiting for stack creation to complete..."
    aws cloudformation wait stack-create-complete \
        --stack-name $STACK_NAME \
        --region $REGION
else
    # Try to update stack
    if aws cloudformation update-stack \
        --stack-name $STACK_NAME \
        --template-body file://cloudformation-master.yaml \
        --parameters \
            ParameterKey=Environment,ParameterValue=$ENVIRONMENT \
            ParameterKey=StudyName,ParameterValue=osrp \
        --capabilities CAPABILITY_NAMED_IAM \
        --region $REGION 2>&1 | grep -q "No updates are to be performed"; then
        echo -e "${YELLOW}No updates needed${NC}"
    else
        echo "Waiting for stack update to complete..."
        aws cloudformation wait stack-update-complete \
            --stack-name $STACK_NAME \
            --region $REGION
    fi
fi
echo -e "${GREEN}✓ Stack deployed successfully${NC}"
echo ""

# Get stack outputs
echo -e "${YELLOW}Retrieving stack outputs...${NC}"
OUTPUTS=$(aws cloudformation describe-stacks \
    --stack-name $STACK_NAME \
    --region $REGION \
    --query 'Stacks[0].Outputs')

API_ENDPOINT=$(echo $OUTPUTS | jq -r '.[] | select(.OutputKey=="ApiEndpoint") | .OutputValue')
USER_POOL_ID=$(echo $OUTPUTS | jq -r '.[] | select(.OutputKey=="UserPoolId") | .OutputValue')
USER_POOL_CLIENT_ID=$(echo $OUTPUTS | jq -r '.[] | select(.OutputKey=="UserPoolClientId") | .OutputValue')
AUTH_LAMBDA=$(echo $OUTPUTS | jq -r '.[] | select(.OutputKey=="AuthLambdaFunctionName") | .OutputValue')
DATA_LAMBDA=$(echo $OUTPUTS | jq -r '.[] | select(.OutputKey=="DataUploadLambdaFunctionName") | .OutputValue')

echo -e "${GREEN}✓ Outputs retrieved${NC}"
echo ""

# Package Lambda functions
echo -e "${YELLOW}Packaging Lambda functions...${NC}"
cd lambda

# Auth Lambda
if [ -f "auth_handler.py" ]; then
    echo "Packaging auth_handler.py..."
    zip -q auth_handler.zip auth_handler.py
    echo -e "${GREEN}✓ auth_handler.zip created${NC}"
else
    echo -e "${YELLOW}Warning: auth_handler.py not found${NC}"
fi

# Data Upload Lambda
if [ -f "data_upload_handler.py" ]; then
    echo "Packaging data_upload_handler.py..."
    zip -q data_upload_handler.zip data_upload_handler.py
    echo -e "${GREEN}✓ data_upload_handler.zip created${NC}"
else
    echo -e "${YELLOW}Warning: data_upload_handler.py not found${NC}"
fi

cd ..
echo ""

# Deploy Lambda code
echo -e "${YELLOW}Deploying Lambda functions...${NC}"

if [ -f "lambda/auth_handler.zip" ]; then
    echo "Updating Auth Lambda function..."
    aws lambda update-function-code \
        --function-name $AUTH_LAMBDA \
        --zip-file fileb://lambda/auth_handler.zip \
        --region $REGION > /dev/null

    echo "Waiting for Auth Lambda update..."
    aws lambda wait function-updated \
        --function-name $AUTH_LAMBDA \
        --region $REGION

    echo -e "${GREEN}✓ Auth Lambda deployed${NC}"
fi

if [ -f "lambda/data_upload_handler.zip" ]; then
    echo "Updating Data Upload Lambda function..."
    aws lambda update-function-code \
        --function-name $DATA_LAMBDA \
        --zip-file fileb://lambda/data_upload_handler.zip \
        --region $REGION > /dev/null

    echo "Waiting for Data Upload Lambda update..."
    aws lambda wait function-updated \
        --function-name $DATA_LAMBDA \
        --region $REGION

    echo -e "${GREEN}✓ Data Upload Lambda deployed${NC}"
fi

# Cleanup zip files
rm -f lambda/*.zip
echo ""

# Display summary
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Deployment Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${BLUE}API Endpoint:${NC}"
echo "  $API_ENDPOINT"
echo ""
echo -e "${BLUE}Cognito User Pool:${NC}"
echo "  Pool ID: $USER_POOL_ID"
echo "  Client ID: $USER_POOL_CLIENT_ID"
echo ""
echo -e "${BLUE}Lambda Functions:${NC}"
echo "  Auth: $AUTH_LAMBDA"
echo "  Data Upload: $DATA_LAMBDA"
echo ""
echo -e "${BLUE}Next Steps:${NC}"
echo "  1. Create a test user:"
echo "     aws cognito-idp admin-create-user \\"
echo "       --user-pool-id $USER_POOL_ID \\"
echo "       --username test@example.com \\"
echo "       --user-attributes Name=email,Value=test@example.com Name=email_verified,Value=true \\"
echo "       --temporary-password TempPass123! \\"
echo "       --region $REGION"
echo ""
echo "  2. Test authentication:"
echo "     curl -X POST $API_ENDPOINT/auth/login \\"
echo "       -H 'Content-Type: application/json' \\"
echo "       -d '{\"email\":\"test@example.com\",\"password\":\"YourPassword123!\"}'"
echo ""
echo "  3. Save credentials to .env file:"
echo "     echo 'API_ENDPOINT=$API_ENDPOINT' > .env"
echo "     echo 'USER_POOL_ID=$USER_POOL_ID' >> .env"
echo "     echo 'USER_POOL_CLIENT_ID=$USER_POOL_CLIENT_ID' >> .env"
echo ""
echo -e "${GREEN}Documentation: infrastructure/DEPLOYMENT.md${NC}"
echo ""
