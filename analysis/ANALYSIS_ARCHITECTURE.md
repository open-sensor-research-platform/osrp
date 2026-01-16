# Analysis Backend Architecture

## Overview
SageMaker Studio with Marimo notebooks provides an interactive, reproducible analysis environment for mobile sensing data.

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                     DATA COLLECTION LAYER                         │
├─────────────────────────────────────────────────────────────────┤
│  Android App → API Gateway → Lambda → DynamoDB + S3             │
│  - Screenshots in S3                                             │
│  - Sensor data in DynamoDB                                       │
│  - Events in DynamoDB                                            │
│  - Wearable data in DynamoDB                                     │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│                     ANALYSIS LAYER                                │
├─────────────────────────────────────────────────────────────────┤
│  SageMaker Studio                                                 │
│  ├── Marimo Notebooks                                            │
│  │   ├── Exploratory Analysis                                    │
│  │   ├── Time Series Analysis                                    │
│  │   ├── Computer Vision (screenshots)                           │
│  │   ├── Multi-Modal Fusion                                      │
│  │   └── Predictive Models                                       │
│  │                                                                │
│  ├── Python Libraries                                            │
│  │   ├── boto3 (AWS SDK)                                         │
│  │   ├── pandas, numpy                                           │
│  │   ├── plotly, altair (visualization)                          │
│  │   ├── scikit-learn, pytorch                                   │
│  │   └── PIL, opencv (image processing)                          │
│  │                                                                │
│  └── Data Access Layer                                           │
│      ├── DynamoDBReader                                          │
│      ├── S3ImageLoader                                           │
│      ├── DataAggregator                                          │
│      └── ContextJoiner                                           │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│                     OUTPUT LAYER                                  │
├─────────────────────────────────────────────────────────────────┤
│  - Interactive Dashboards (Marimo)                               │
│  - Statistical Reports                                            │
│  - ML Models (deployed to SageMaker Endpoints)                  │
│  - Exported Datasets (S3)                                        │
└─────────────────────────────────────────────────────────────────┘
```

## SageMaker Studio Setup

### Infrastructure Requirements

**CloudFormation Additions:**
```yaml
SageMakerExecutionRole:
  Type: AWS::IAM::Role
  Properties:
    AssumeRolePolicyDocument:
      Statement:
        - Effect: Allow
          Principal:
            Service: sagemaker.amazonaws.com
          Action: sts:AssumeRole
    ManagedPolicyArns:
      - arn:aws:iam::aws:policy/AmazonSageMakerFullAccess
    Policies:
      - PolicyName: DataAccess
        PolicyDocument:
          Statement:
            - Effect: Allow
              Action:
                - s3:GetObject
                - s3:ListBucket
              Resource:
                - !GetAtt DataBucket.Arn
                - !Sub '${DataBucket.Arn}/*'
            - Effect: Allow
              Action:
                - dynamodb:Query
                - dynamodb:Scan
                - dynamodb:GetItem
                - dynamodb:BatchGetItem
              Resource:
                - !GetAtt SensorTimeSeriesTable.Arn
                - !GetAtt EventLogTable.Arn
                - !GetAtt ScreenshotMetadataTable.Arn
                - !GetAtt EMAResponseTable.Arn
                - !GetAtt WearableDataTable.Arn

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
      KernelGatewayAppSettings:
        DefaultResourceSpec:
          InstanceType: ml.t3.medium
    VpcId: !Ref VPC
    SubnetIds:
      - !Ref PrivateSubnet1
      - !Ref PrivateSubnet2

SageMakerUserProfile:
  Type: AWS::SageMaker::UserProfile
  Properties:
    DomainId: !Ref SageMakerStudioDomain
    UserProfileName: researcher
    UserSettings:
      ExecutionRole: !GetAtt SageMakerExecutionRole.Arn
```

### Marimo Setup in SageMaker

**Lifecycle Configuration Script:**
```bash
#!/bin/bash
set -e

# Install Marimo
pip install marimo

# Install data science libraries
pip install boto3 pandas numpy plotly altair scikit-learn
pip install pillow opencv-python-headless
pip install seaborn matplotlib

# Clone analysis repository with example notebooks
cd /home/sagemaker-user
git clone <analysis-repo-url> mobile-sensing-analysis

# Create marimo app launcher
cat > /home/sagemaker-user/launch-marimo.sh << 'EOF'
#!/bin/bash
cd /home/sagemaker-user/mobile-sensing-analysis/notebooks
marimo edit --host 0.0.0.0 --port 8080
EOF

chmod +x /home/sagemaker-user/launch-marimo.sh

echo "Marimo setup complete!"
```

## Data Access Layer

### Python Utilities

**data_access.py:**
```python
import boto3
import pandas as pd
from typing import List, Dict, Optional
from datetime import datetime, timedelta
import io
from PIL import Image

class MobileSensingData:
    """
    Unified data access layer for mobile sensing data
    """
    
    def __init__(self, region: str = 'us-west-2'):
        self.dynamodb = boto3.resource('dynamodb', region_name=region)
        self.s3 = boto3.client('s3', region_name=region)
        self.region = region
        
    def get_sensor_data(
        self, 
        user_id: str, 
        sensor_type: str,
        start_time: datetime,
        end_time: datetime
    ) -> pd.DataFrame:
        """
        Retrieve sensor time series data
        
        Args:
            user_id: Participant ID
            sensor_type: Type of sensor (accelerometer, gyroscope, etc.)
            start_time: Start timestamp
            end_time: End timestamp
            
        Returns:
            DataFrame with sensor readings
        """
        table = self.dynamodb.Table('SensorTimeSeries')
        
        response = table.query(
            KeyConditionExpression='userIdSensorType = :pk AND #ts BETWEEN :start AND :end',
            ExpressionAttributeNames={'#ts': 'timestamp'},
            ExpressionAttributeValues={
                ':pk': f"{user_id}#{sensor_type}",
                ':start': int(start_time.timestamp() * 1000),
                ':end': int(end_time.timestamp() * 1000)
            }
        )
        
        return pd.DataFrame(response['Items'])
    
    def get_screenshots(
        self,
        user_id: str,
        start_time: datetime,
        end_time: datetime,
        load_images: bool = False
    ) -> pd.DataFrame:
        """
        Retrieve screenshot metadata (and optionally images)
        
        Args:
            user_id: Participant ID
            start_time: Start timestamp
            end_time: End timestamp
            load_images: If True, download actual images
            
        Returns:
            DataFrame with screenshot metadata and optional image data
        """
        table = self.dynamodb.Table('ScreenshotMetadata')
        
        response = table.query(
            KeyConditionExpression='userId = :uid AND #ts BETWEEN :start AND :end',
            ExpressionAttributeNames={'#ts': 'timestamp'},
            ExpressionAttributeValues={
                ':uid': user_id,
                ':start': int(start_time.timestamp() * 1000),
                ':end': int(end_time.timestamp() * 1000)
            }
        )
        
        df = pd.DataFrame(response['Items'])
        
        if load_images and not df.empty:
            df['image'] = df.apply(
                lambda row: self._load_image(row['s3Bucket'], row['s3Key']),
                axis=1
            )
        
        return df
    
    def get_events(
        self,
        user_id: str,
        start_time: datetime,
        end_time: datetime,
        event_type: Optional[str] = None
    ) -> pd.DataFrame:
        """
        Retrieve event log data
        """
        table = self.dynamodb.Table('EventLog')
        
        key_condition = 'userId = :uid AND timestampEventType BETWEEN :start AND :end'
        expression_values = {
            ':uid': user_id,
            ':start': f"{int(start_time.timestamp() * 1000)}#",
            ':end': f"{int(end_time.timestamp() * 1000)}#~"
        }
        
        response = table.query(
            KeyConditionExpression=key_condition,
            ExpressionAttributeValues=expression_values
        )
        
        df = pd.DataFrame(response['Items'])
        
        if event_type and not df.empty:
            df = df[df['eventType'] == event_type]
        
        return df
    
    def get_wearable_data(
        self,
        user_id: str,
        source: str,
        start_time: datetime,
        end_time: datetime
    ) -> pd.DataFrame:
        """
        Retrieve wearable device data
        """
        table = self.dynamodb.Table('WearableData')
        
        response = table.query(
            KeyConditionExpression='userIdSource = :pk AND #ts BETWEEN :start AND :end',
            ExpressionAttributeNames={'#ts': 'timestamp'},
            ExpressionAttributeValues={
                ':pk': f"{user_id}#{source}",
                ':start': int(start_time.timestamp() * 1000),
                ':end': int(end_time.timestamp() * 1000)
            }
        )
        
        return pd.DataFrame(response['Items'])
    
    def get_ema_responses(
        self,
        user_id: str,
        start_time: datetime,
        end_time: datetime
    ) -> pd.DataFrame:
        """
        Retrieve EMA survey responses
        """
        table = self.dynamodb.Table('EMAResponse')
        
        response = table.query(
            KeyConditionExpression='userId = :uid AND timestampSurveyId BETWEEN :start AND :end',
            ExpressionAttributeValues={
                ':uid': user_id,
                ':start': f"{int(start_time.timestamp() * 1000)}#",
                ':end': f"{int(end_time.timestamp() * 1000)}#~"
            }
        )
        
        return pd.DataFrame(response['Items'])
    
    def get_daily_summary(
        self,
        user_id: str,
        date: datetime
    ) -> Dict:
        """
        Get comprehensive daily summary for a participant
        
        Returns all data types for a single day
        """
        start = date.replace(hour=0, minute=0, second=0, microsecond=0)
        end = start + timedelta(days=1)
        
        return {
            'screenshots': self.get_screenshots(user_id, start, end),
            'accelerometer': self.get_sensor_data(user_id, 'accelerometer', start, end),
            'location': self.get_sensor_data(user_id, 'location', start, end),
            'activity': self.get_sensor_data(user_id, 'activity', start, end),
            'events': self.get_events(user_id, start, end),
            'heart_rate': self.get_wearable_data(user_id, 'polar_h10', start, end),
            'ema_responses': self.get_ema_responses(user_id, start, end)
        }
    
    def _load_image(self, bucket: str, key: str) -> Image.Image:
        """Load image from S3"""
        try:
            response = self.s3.get_object(Bucket=bucket, Key=key)
            image_data = response['Body'].read()
            return Image.open(io.BytesIO(image_data))
        except Exception as e:
            print(f"Error loading image {key}: {e}")
            return None
```

## Example Analysis Notebooks

### 1. Daily Digital Behavior Profile

**Purpose:** Visualize one participant's complete day

**Analyses:**
- Screenshot timeline (app usage over time)
- Activity levels throughout day
- Heart rate patterns
- Screen time vs physical activity
- Context-aware insights

### 2. Screen Time vs Physical Activity

**Purpose:** Correlation analysis between digital and physical behavior

**Analyses:**
- Sedentary screen time detection
- Activity type classification
- Temporal patterns
- Individual differences

### 3. App Usage Clustering

**Purpose:** Identify behavioral patterns in app usage

**Analyses:**
- K-means clustering of usage patterns
- Time-of-day preferences
- App category analysis
- Session duration distributions

### 4. Context-Aware Behavior Prediction

**Purpose:** Build predictive models for interventions

**Analyses:**
- Feature engineering from multi-modal data
- Random forest classification
- Model evaluation
- Feature importance

### 5. Multi-Modal Dashboard

**Purpose:** Interactive exploration of all data streams

**Analyses:**
- Real-time data selection
- Synchronized visualizations
- Export capabilities
- Researcher annotations

## Marimo Advantages

### vs Jupyter Notebooks

**Reactivity:**
- Automatic re-execution when inputs change
- No stale cells
- Reproducible by design

**Interactivity:**
- Native UI elements (sliders, dropdowns)
- Real-time visualization updates
- Better user experience

**Deployment:**
- Can run as apps (not just notebooks)
- Easy to share with non-technical users
- Better for research dashboards

**Example:**
```python
import marimo as mo

# Interactive participant selector
user_id = mo.ui.dropdown(
    options=['user001', 'user002', 'user003'],
    value='user001',
    label='Select Participant'
)

# Date range selector
date_range = mo.ui.date_range(
    start='2026-01-01',
    end='2026-01-31',
    label='Date Range'
)

# Automatically updates when inputs change
data = get_data(user_id.value, date_range.value)
plot = create_visualization(data)

mo.md(f"## Analysis for {user_id.value}")
plot
```

## Deployment Workflow

### For Researchers

1. **Access SageMaker Studio**
   - Log in via AWS Console
   - Launch Studio
   - Open Marimo notebook

2. **Load Data**
   - Use MobileSensingData class
   - Specify participant and date range
   - Data loads automatically

3. **Explore & Analyze**
   - Interactive visualizations
   - Statistical analyses
   - ML models

4. **Export Results**
   - Save figures
   - Export processed data
   - Generate reports

### For Developers

1. **Create New Analysis**
   - Use example notebooks as templates
   - Add new data access methods
   - Create visualizations

2. **Test Locally** (optional)
   - Run Marimo locally with AWS credentials
   - Iterate quickly

3. **Deploy to SageMaker**
   - Commit to Git
   - Pull in SageMaker Studio
   - Share with research team

## Cost Optimization

### SageMaker Studio Costs

**Notebook Instances:**
- ml.t3.medium: $0.05/hour (~$36/month if always on)
- ml.t3.large: $0.10/hour (~$72/month if always on)

**Best Practices:**
- Stop notebooks when not in use
- Use lifecycle configs to auto-stop
- Use spot instances for training jobs

**Storage:**
- EFS for notebooks: ~$0.30/GB/month
- Keep only active analysis files

**Data Transfer:**
- S3 → SageMaker: Free (same region)
- DynamoDB → SageMaker: Free (API calls only)

**Typical Costs:**
- Small team (2-3 researchers): $50-100/month
- Medium team (5-10 researchers): $200-400/month

## Security Considerations

### IAM Permissions

**Principle of Least Privilege:**
- Read-only access to data by default
- Write access only for processed outputs
- No ability to modify raw collected data

**Data Privacy:**
- De-identification in analysis notebooks
- No PII in exported datasets
- Secure S3 bucket policies

**Audit Logging:**
- CloudTrail logs all API calls
- SageMaker logging enabled
- Regular access reviews

## Future Enhancements

### Advanced Analytics

1. **Real-time Analysis**
   - Stream processing with Kinesis
   - Real-time dashboards
   - Immediate feedback to participants

2. **ML Pipeline**
   - Automated feature extraction
   - Model training pipeline
   - A/B testing framework

3. **Collaborative Features**
   - Shared notebooks
   - Annotation tools
   - Research team workspace

4. **Advanced Visualizations**
   - 3D activity timelines
   - Network graphs (social interactions)
   - Geospatial analysis

## Next Steps

1. Deploy SageMaker Studio domain
2. Install Marimo and dependencies
3. Load example notebooks
4. Test with sample data
5. Create custom analyses for your research
