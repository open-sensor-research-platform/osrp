# OSRP S3 Bucket Structure

## Overview

S3 buckets for OSRP data storage with automatic lifecycle management and cost optimization.

**CloudFormation Template**: `cloudformation-s3.yaml`
**Version**: 0.2.0 (MVP)

---

## Buckets

### 1. Data Bucket

**Name**: `osrp-data-{environment}-{account-id}`
**Purpose**: Primary data storage for sensor readings, files, and processed data

**Folder Structure**:
```
osrp-data-dev-123456789012/
├── raw/                     # Raw uploaded data
│   ├── sensor/              # Sensor data files (if batch uploaded)
│   │   ├── {userId}/
│   │   │   ├── {date}/
│   │   │   │   └── {timestamp}.json
│   ├── screenshots/         # Screenshots (future)
│   │   └── {userId}/
│   │       ├── {date}/
│   │       │   └── {timestamp}.png
│   └── audio/               # Audio recordings (future)
│       └── {userId}/
│           └── {date}/
│               └── {timestamp}.m4a
│
├── processed/               # Processed/aggregated data
│   ├── daily/               # Daily summaries
│   │   └── {userId}/
│   │       └── {date}.parquet
│   ├── features/            # Extracted features
│   │   └── {userId}/
│   │       └── {date}_features.parquet
│   └── ml/                  # ML model outputs
│       └── predictions/
│           └── {userId}/
│               └── {date}_predictions.json
│
├── exports/                 # Data exports for researchers
│   └── {studyId}/
│       └── {exportId}/
│           ├── participants.csv
│           ├── sensor_data.parquet
│           └── metadata.json
│
└── temp/                    # Temporary uploads (7-day TTL)
    └── {userId}/
        └── {uploadId}/
```

---

## Lifecycle Policies

### Raw Data (`raw/` prefix)

```yaml
Lifecycle:
  - Day 0-29:    STANDARD storage
  - Day 30-89:   STANDARD_IA (Infrequent Access)
  - Day 90+:     GLACIER (Archive)
```

**Rationale**: Raw sensor data is frequently accessed for 30 days during active analysis, then archived for long-term storage.

**Cost Impact**:
- STANDARD: $0.023/GB/month
- STANDARD_IA: $0.0125/GB/month
- GLACIER: $0.004/GB/month

**Example**: 1GB raw data over 1 year
- Month 1: $0.023 (STANDARD)
- Months 2-3: $0.025 (STANDARD_IA)
- Months 4-12: $0.036 (GLACIER)
- **Total**: $0.084 vs $0.276 without lifecycle

### Processed Data (`processed/` prefix)

```yaml
Lifecycle:
  - Current version: STANDARD storage (kept indefinitely)
  - Old versions:    STANDARD_IA after 30 days, deleted after 90 days
```

**Rationale**: Processed data is accessed frequently and regenerated if needed. Versioning protects against accidental overwrites.

### Temporary Data (`temp/` prefix)

```yaml
Lifecycle:
  - Day 0-6:     STANDARD storage
  - Day 7:       Deleted automatically
```

**Rationale**: Temporary upload staging area, cleaned up automatically to avoid costs.

### Incomplete Multipart Uploads

```yaml
Lifecycle:
  - Day 3:       Aborted automatically
```

**Rationale**: Failed uploads can leave orphaned parts consuming storage. Auto-cleanup after 3 days.

---

## Security

### Encryption

**At Rest**: AES-256 server-side encryption
```python
# Automatic encryption, no code needed
s3_client.put_object(
    Bucket=bucket_name,
    Key=key,
    Body=data
    # Encryption applied automatically
)
```

**In Transit**: HTTPS only (enforced by bucket policy)
```json
{
  "Effect": "Deny",
  "Principal": "*",
  "Action": "s3:*",
  "Condition": {
    "Bool": {
      "aws:SecureTransport": "false"
    }
  }
}
```

### Access Control

**Public Access**: Completely blocked
- Block public ACLs
- Block public bucket policies
- Ignore public ACLs
- Restrict public buckets

**Programmatic Access**: IAM roles only
- Lambda functions: Read/write via execution role
- Mobile apps: Presigned URLs only (no direct access)
- Researchers: Read-only via IAM user

---

## CORS Configuration

Allows mobile apps to upload directly using presigned URLs:

```yaml
CorsConfiguration:
  AllowedOrigins: ['*']
  AllowedMethods: [GET, PUT, POST, HEAD]
  AllowedHeaders: ['*']
  MaxAge: 3000  # 50 minutes
```

**Usage in Mobile App**:
```python
# 1. Get presigned URL from Lambda
response = requests.post(
    f'{api_endpoint}/data/presigned-url',
    headers={'Authorization': f'Bearer {token}'},
    json={
        'userId': user_id,
        'key': f'raw/sensor/{user_id}/{date}/{timestamp}.json',
        'contentType': 'application/json'
    }
)
presigned_url = response.json()['uploadUrl']

# 2. Upload directly to S3
requests.put(
    presigned_url,
    data=sensor_data,
    headers={'Content-Type': 'application/json'}
)
```

---

## Access Patterns

### 1. Mobile App Upload (via Presigned URL)

```python
# Lambda function generates presigned URL
import boto3
from datetime import datetime, timedelta

s3_client = boto3.client('s3')

def generate_presigned_url(bucket, key, expiration=3600):
    """Generate presigned URL for upload"""
    url = s3_client.generate_presigned_url(
        'put_object',
        Params={
            'Bucket': bucket,
            'Key': key,
            'ContentType': 'application/json'
        },
        ExpiresIn=expiration
    )
    return url

# Usage
url = generate_presigned_url(
    bucket='osrp-data-dev-123456789012',
    key=f'raw/sensor/{user_id}/{date}/{timestamp}.json',
    expiration=3600  # 1 hour
)
```

### 2. Lambda Function Write (Direct)

```python
import boto3
import json

s3_client = boto3.client('s3')

def store_processed_data(user_id, date, data):
    """Store processed daily summary"""
    key = f'processed/daily/{user_id}/{date}.json'

    s3_client.put_object(
        Bucket='osrp-data-dev-123456789012',
        Key=key,
        Body=json.dumps(data),
        ContentType='application/json',
        Metadata={
            'userId': user_id,
            'date': date,
            'processedAt': str(int(time.time()))
        }
    )

    return key
```

### 3. OSRPData Read (Analysis)

```python
import boto3
import pandas as pd

s3_client = boto3.client('s3')

def get_daily_summary(user_id, date):
    """Read processed daily summary"""
    key = f'processed/daily/{user_id}/{date}.parquet'

    try:
        response = s3_client.get_object(
            Bucket='osrp-data-dev-123456789012',
            Key=key
        )

        # Read Parquet data
        df = pd.read_parquet(response['Body'])
        return df

    except s3_client.exceptions.NoSuchKey:
        return None  # No data for this date
```

### 4. Export Data for Researcher

```python
def export_study_data(study_id, start_date, end_date):
    """Export all data for a study"""
    export_id = str(uuid.uuid4())
    export_prefix = f'exports/{study_id}/{export_id}/'

    # Collect data from DynamoDB and S3
    participants_df = get_participants(study_id)
    sensor_df = get_sensor_data(study_id, start_date, end_date)

    # Write to S3
    s3_client.put_object(
        Bucket='osrp-data-dev-123456789012',
        Key=f'{export_prefix}participants.csv',
        Body=participants_df.to_csv(index=False)
    )

    s3_client.put_object(
        Bucket='osrp-data-dev-123456789012',
        Key=f'{export_prefix}sensor_data.parquet',
        Body=sensor_df.to_parquet()
    )

    # Generate presigned download URLs
    urls = {
        'participants': generate_presigned_url(
            bucket='osrp-data-dev-123456789012',
            key=f'{export_prefix}participants.csv',
            expiration=86400  # 24 hours
        ),
        'sensor_data': generate_presigned_url(
            bucket='osrp-data-dev-123456789012',
            key=f'{export_prefix}sensor_data.parquet',
            expiration=86400
        )
    }

    return urls
```

---

## Logging

### Access Logs

All S3 access logged to separate logging bucket:

**Logging Bucket**: `osrp-logs-{environment}-{account-id}`
**Log Prefix**: `s3-access-logs/`

**Log Format**:
```
bucket owner [time] remote-ip requester request-id operation key
"request-uri" http-status error-code bytes-sent object-size total-time
turn-around-time "referer" "user-agent" version-id
```

**Example Log Entry**:
```
osrp-data-dev-123456789012 [16/Jan/2026:01:00:00 +0000] 203.0.113.0
arn:aws:sts::123456789012:assumed-role/osrp-lambda-role/osrp-upload
ABC123 REST.PUT.OBJECT raw/sensor/participant_001/2026-01-16/1705363200000.json
"PUT /raw/sensor/participant_001/2026-01-16/1705363200000.json HTTP/1.1"
200 - 1024 - 32 15 "-" "Boto3/1.28.0" -
```

---

## Cost Estimation

### MVP (10 participants, 30 days)

**Assumptions**:
- 1 sensor per participant at 5 Hz
- 100 bytes per reading
- 8 hours/day collection

**Calculations**:
- Readings/day: 5 Hz × 8 hours × 3600 s = 144,000
- Data/day/participant: 144,000 × 100 bytes = 14.4 MB
- Data/month/participant: 14.4 MB × 30 = 432 MB
- Total data/month (10 participants): 4.32 GB

**Storage Costs** (month 1):
- STANDARD: 4.32 GB × $0.023 = $0.10

**Request Costs**:
- PUT requests: 10 participants × 144 uploads/day × 30 days = 43,200
- Cost: 43,200 × $0.005/1000 = $0.22

**Total Month 1**: $0.32

**With Lifecycle** (month 3):
- 1.44 GB STANDARD (current): $0.03
- 1.44 GB STANDARD_IA (30-90 days): $0.02
- 1.44 GB GLACIER (90+ days): $0.01
- **Total**: $0.06 (81% savings)

### Production (100 participants, 1 year)

**Data**: 43.2 GB/month = 518.4 GB/year

**Without Lifecycle**:
- Storage: 518.4 GB × $0.023 = $11.92/month = $143/year

**With Lifecycle**:
- Average: ~$0.012/GB/month = $6.22/month = $75/year
- **Savings**: $68/year (47% reduction)

---

## CloudFormation Deployment

### Deploy S3 Stack

```bash
# Validate template
aws cloudformation validate-template \
  --template-body file://infrastructure/cloudformation-s3.yaml

# Deploy
aws cloudformation create-stack \
  --stack-name osrp-s3-dev \
  --template-body file://infrastructure/cloudformation-s3.yaml \
  --parameters \
    ParameterKey=Environment,ParameterValue=dev \
    ParameterKey=StudyName,ParameterValue=osrp \
  --region us-west-2

# Check status
aws cloudformation describe-stacks \
  --stack-name osrp-s3-dev \
  --region us-west-2

# Get bucket names
aws cloudformation describe-stacks \
  --stack-name osrp-s3-dev \
  --region us-west-2 \
  --query 'Stacks[0].Outputs'
```

### Test Bucket

```bash
# List buckets
aws s3 ls | grep osrp

# Test upload
echo "test data" > test.txt
aws s3 cp test.txt s3://osrp-data-dev-123456789012/temp/test.txt

# Test download
aws s3 cp s3://osrp-data-dev-123456789012/temp/test.txt downloaded.txt

# Test encryption (check metadata)
aws s3api head-object \
  --bucket osrp-data-dev-123456789012 \
  --key temp/test.txt

# Cleanup
aws s3 rm s3://osrp-data-dev-123456789012/temp/test.txt
rm test.txt downloaded.txt
```

---

## Best Practices

### 1. Use Prefixes Consistently

```python
# Good: Organized by prefix
raw/sensor/{userId}/{date}/{timestamp}.json
processed/daily/{userId}/{date}.parquet

# Bad: Flat structure
{userId}_{date}_{timestamp}_sensor.json
```

### 2. Include Metadata

```python
s3_client.put_object(
    Bucket=bucket,
    Key=key,
    Body=data,
    Metadata={
        'userId': user_id,
        'sensorType': 'accelerometer',
        'collectedAt': timestamp,
        'platform': 'android'
    }
)
```

### 3. Use Presigned URLs for Mobile Uploads

```python
# Don't: Give mobile apps IAM credentials
# Do: Generate presigned URLs in Lambda
url = s3_client.generate_presigned_url('put_object', ...)
```

### 4. Batch Small Files

```python
# Don't: 1 file per sensor reading (high request costs)
# Do: Batch 100 readings into one file
```

### 5. Use Parquet for Processed Data

```python
# Don't: JSON for large datasets (slow, large)
# Do: Parquet for columnar data (fast, compressed)
df.to_parquet(f's3://{bucket}/{key}')
```

---

## Troubleshooting

### Issue: Access Denied

**Cause**: IAM role lacks permissions
**Fix**: Add S3 permissions to Lambda execution role

```json
{
  "Effect": "Allow",
  "Action": [
    "s3:GetObject",
    "s3:PutObject"
  ],
  "Resource": "arn:aws:s3:::osrp-data-dev-*/*"
}
```

### Issue: Slow Uploads

**Cause**: Large files without multipart
**Fix**: Use multipart upload for files >100MB

```python
config = boto3.s3.transfer.TransferConfig(
    multipart_threshold=100 * 1024 * 1024,  # 100 MB
    max_concurrency=10
)
s3_client.upload_file(filename, bucket, key, Config=config)
```

### Issue: High Costs

**Cause**: No lifecycle policies
**Fix**: Verify lifecycle rules are active

```bash
aws s3api get-bucket-lifecycle-configuration \
  --bucket osrp-data-dev-123456789012
```

---

## Next Steps

1. ✅ S3 bucket structure designed
2. ✅ CloudFormation template created
3. ✅ Documentation complete
4. ⏭️ Deploy to AWS dev environment (Issue #8)
5. ⏭️ Test upload/download
6. ⏭️ Configure Lambda access (Issues #4, #5)

---

**Bucket Version**: 0.2.0 (MVP)
**Last Updated**: January 16, 2026
**Related Issues**: #2, #4, #5, #8
