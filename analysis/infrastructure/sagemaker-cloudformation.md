# SageMaker Studio CloudFormation Extension

This file contains the CloudFormation resources to add SageMaker Studio
to your Mobile Sensing Platform deployment.

Add these resources to your main cloudformation-stack.yaml file.

```yaml
# ============================================================================
# SAGEMAKER STUDIO RESOURCES
# ============================================================================

  # Execution Role for SageMaker
  SageMakerExecutionRole:
    Type: AWS::IAM::Role
    Properties:
      RoleName: !Sub '${ProjectName}-${Environment}-sagemaker-role'
      AssumeRolePolicyDocument:
        Version: '2012-10-17'
        Statement:
          - Effect: Allow
            Principal:
              Service: 
                - sagemaker.amazonaws.com
            Action: 'sts:AssumeRole'
      ManagedPolicyArns:
        - arn:aws:iam::aws:policy/AmazonSageMakerFullAccess
      Policies:
        - PolicyName: DataAccess
          PolicyDocument:
            Version: '2012-10-17'
            Statement:
              # S3 Access
              - Effect: Allow
                Action:
                  - s3:GetObject
                  - s3:ListBucket
                  - s3:PutObject
                Resource:
                  - !GetAtt DataBucket.Arn
                  - !Sub '${DataBucket.Arn}/*'
              
              # DynamoDB Read Access
              - Effect: Allow
                Action:
                  - dynamodb:Query
                  - dynamodb:Scan
                  - dynamodb:GetItem
                  - dynamodb:BatchGetItem
                  - dynamodb:DescribeTable
                Resource:
                  - !GetAtt SensorTimeSeriesTable.Arn
                  - !Sub '${SensorTimeSeriesTable.Arn}/index/*'
                  - !GetAtt EventLogTable.Arn
                  - !Sub '${EventLogTable.Arn}/index/*'
                  - !GetAtt ScreenshotMetadataTable.Arn
                  - !Sub '${ScreenshotMetadataTable.Arn}/index/*'
                  - !GetAtt EMAResponseTable.Arn
                  - !Sub '${EMAResponseTable.Arn}/index/*'
                  - !GetAtt WearableDataTable.Arn
                  - !Sub '${WearableDataTable.Arn}/index/*'
                  - !GetAtt ParticipantStatusTable.Arn
                  - !Sub '${ParticipantStatusTable.Arn}/index/*'
              
              # CloudWatch Logs
              - Effect: Allow
                Action:
                  - logs:CreateLogGroup
                  - logs:CreateLogStream
                  - logs:PutLogEvents
                Resource: 'arn:aws:logs:*:*:*'

  # SageMaker Studio Domain
  SageMakerStudioDomain:
    Type: AWS::SageMaker::Domain
    Properties:
      DomainName: !Sub '${ProjectName}-${Environment}-studio'
      AuthMode: IAM
      DefaultUserSettings:
        ExecutionRole: !GetAtt SageMakerExecutionRole.Arn
        JupyterServerAppSettings:
          DefaultResourceSpec:
            InstanceType: ml.t3.medium
            SageMakerImageArn: !Sub 'arn:aws:sagemaker:${AWS::Region}:081325390199:image/datascience-1.0'
        KernelGatewayAppSettings:
          DefaultResourceSpec:
            InstanceType: ml.t3.medium
      SubnetIds:
        - !Ref PrivateSubnet1
        - !Ref PrivateSubnet2
      VpcId: !Ref VPC
      Tags:
        - Key: Environment
          Value: !Ref Environment
        - Key: Project
          Value: !Ref ProjectName

  # Default User Profile for Researchers
  ResearcherUserProfile:
    Type: AWS::SageMaker::UserProfile
    Properties:
      DomainId: !Ref SageMakerStudioDomain
      UserProfileName: researcher
      UserSettings:
        ExecutionRole: !GetAtt SageMakerExecutionRole.Arn
      Tags:
        - Key: Role
          Value: Researcher

  # Additional User Profiles (optional - add as needed)
  PrincipalInvestigatorProfile:
    Type: AWS::SageMaker::UserProfile
    Properties:
      DomainId: !Ref SageMakerStudioDomain
      UserProfileName: pi
      UserSettings:
        ExecutionRole: !GetAtt SageMakerExecutionRole.Arn
      Tags:
        - Key: Role
          Value: PI

  # Lifecycle Configuration for Marimo Setup
  MarimoLifecycleConfig:
    Type: AWS::SageMaker::StudioLifecycleConfig
    Properties:
      StudioLifecycleConfigName: !Sub '${ProjectName}-marimo-setup'
      StudioLifecycleConfigAppType: JupyterServer
      StudioLifecycleConfigContent:
        Fn::Base64: |
          #!/bin/bash
          set -e
          
          echo "Installing Marimo and dependencies..."
          
          # Install Marimo
          pip install marimo
          
          # Install data science libraries
          pip install boto3 pandas numpy plotly altair scikit-learn
          pip install pillow opencv-python-headless
          pip install seaborn matplotlib
          pip install scipy
          
          # Clone analysis repository
          cd /home/sagemaker-user
          if [ ! -d "mobile-sensing-analysis" ]; then
            git clone https://github.com/your-org/mobile-sensing-analysis.git
          fi
          
          # Create launcher script
          cat > /home/sagemaker-user/launch-marimo.sh << 'EOF'
          #!/bin/bash
          cd /home/sagemaker-user/mobile-sensing-analysis/notebooks
          marimo edit --host 0.0.0.0 --port 8080
          EOF
          
          chmod +x /home/sagemaker-user/launch-marimo.sh
          
          echo "Marimo setup complete!"

# ============================================================================
# OUTPUTS - Add to existing Outputs section
# ============================================================================

  SageMakerDomainId:
    Description: SageMaker Studio Domain ID
    Value: !Ref SageMakerStudioDomain
    Export:
      Name: !Sub '${ProjectName}-${Environment}-domain-id'

  SageMakerDomainUrl:
    Description: SageMaker Studio Domain URL
    Value: !Sub 'https://${SageMakerStudioDomain}.studio.${AWS::Region}.sagemaker.aws/jupyter/default/lab'

  SageMakerRoleArn:
    Description: SageMaker Execution Role ARN
    Value: !GetAtt SageMakerExecutionRole.Arn
    Export:
      Name: !Sub '${ProjectName}-${Environment}-sagemaker-role-arn'
```

## Network Configuration

If you don't already have VPC resources, add these:

```yaml
  # VPC for SageMaker Studio
  VPC:
    Type: AWS::EC2::VPC
    Properties:
      CidrBlock: 10.0.0.0/16
      EnableDnsHostnames: true
      EnableDnsSupport: true
      Tags:
        - Key: Name
          Value: !Sub '${ProjectName}-${Environment}-vpc'

  # Private Subnets (SageMaker requires private subnets)
  PrivateSubnet1:
    Type: AWS::EC2::Subnet
    Properties:
      VpcId: !Ref VPC
      CidrBlock: 10.0.1.0/24
      AvailabilityZone: !Select [0, !GetAZs '']
      Tags:
        - Key: Name
          Value: !Sub '${ProjectName}-${Environment}-private-1'

  PrivateSubnet2:
    Type: AWS::EC2::Subnet
    Properties:
      VpcId: !Ref VPC
      CidrBlock: 10.0.2.0/24
      AvailabilityZone: !Select [1, !GetAZs '']
      Tags:
        - Key: Name
          Value: !Sub '${ProjectName}-${Environment}-private-2'

  # NAT Gateway for outbound internet access
  NatGatewayEIP:
    Type: AWS::EC2::EIP
    Properties:
      Domain: vpc

  NatGateway:
    Type: AWS::EC2::NatGateway
    Properties:
      AllocationId: !GetAtt NatGatewayEIP.AllocationId
      SubnetId: !Ref PublicSubnet1

  # Route Table for Private Subnets
  PrivateRouteTable:
    Type: AWS::EC2::RouteTable
    Properties:
      VpcId: !Ref VPC

  PrivateRoute:
    Type: AWS::EC2::Route
    Properties:
      RouteTableId: !Ref PrivateRouteTable
      DestinationCidrBlock: 0.0.0.0/0
      NatGatewayId: !Ref NatGateway

  PrivateSubnet1RouteTableAssociation:
    Type: AWS::EC2::SubnetRouteTableAssociation
    Properties:
      SubnetId: !Ref PrivateSubnet1
      RouteTableId: !Ref PrivateRouteTable

  PrivateSubnet2RouteTableAssociation:
    Type: AWS::EC2::SubnetRouteTableAssociation
    Properties:
      SubnetId: !Ref PrivateSubnet2
      RouteTableId: !Ref PrivateRouteTable
```

## Cost Estimates

**SageMaker Studio:**
- ml.t3.medium notebook: ~$0.05/hour (~$36/month if running 24/7)
- ml.t3.large notebook: ~$0.10/hour (~$72/month if running 24/7)
- EFS storage: ~$0.30/GB/month

**Best Practice:** Stop notebooks when not in use to minimize costs.

**Typical Usage:**
- 2-3 researchers, 20 hours/week each: ~$50-75/month
- Larger team (5-10 researchers): ~$200-400/month

## Deployment

```bash
# Deploy with SageMaker Studio
aws cloudformation deploy \
  --template-file cloudformation-stack-with-sagemaker.yaml \
  --stack-name mobile-sensing-dev \
  --parameter-overrides Environment=dev \
  --capabilities CAPABILITY_IAM \
  --region us-west-2
```

## Accessing SageMaker Studio

1. Navigate to SageMaker Console
2. Select "Domains" from left menu
3. Click on your domain
4. Click "Launch" → "Studio" for your user profile
5. Wait for environment to start
6. Access Marimo notebooks in `/home/sagemaker-user/mobile-sensing-analysis/`

## Running Marimo Notebooks

In SageMaker Studio terminal:

```bash
# Start Marimo server
cd /home/sagemaker-user/mobile-sensing-analysis/notebooks
marimo edit daily_behavior_profile.py

# Or use the launcher script
/home/sagemaker-user/launch-marimo.sh
```

Access at: `http://localhost:8080`
