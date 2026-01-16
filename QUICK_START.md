# OSRP Quick Start Guide

Get up and running with OSRP in 15 minutes.

---

## Prerequisites

- AWS account with admin access
- Python 3.11+
- AWS CLI v2 installed and configured
- Android Studio (for app development)

---

## Step 1: Install OSRP (2 minutes)

```bash
# Install from pip
pip install osrp

# Verify installation
osrp info
```

---

## Step 2: Initialize Your Study (3 minutes)

```bash
# Create a new study
osrp init depression-study --template=comprehensive

# Navigate to study directory
cd depression-study

# Review configuration
cat config/study_config.yaml
```

**Edit configuration** to customize data collection:
```yaml
# config/study_config.yaml
modules:
  screenshots: true        # Behavioral observation
  sensors: true           # Motion, location, activity
  wearables: true         # Google Fit, Bluetooth HR
  ema: true               # Experience sampling

sampling:
  screenshot_interval: 5  # Every 5 seconds
  sensor_frequency: 1     # 1 Hz (once per second)
```

---

## Step 3: Deploy to AWS (5 minutes)

```bash
# Configure AWS credentials (if not already done)
aws configure
# Enter: Access Key ID, Secret Access Key, Region (us-west-2), Output (json)

# Deploy infrastructure
osrp deploy --aws --region=us-west-2 --environment=dev

# This creates:
# - DynamoDB tables for data storage
# - S3 buckets for screenshots
# - Lambda functions for data processing
# - API Gateway endpoints
# - Cognito user pool for authentication
# - SageMaker Studio (optional)
```

**Expected output:**
```
✓ Deployment successful!

Stack Outputs:
- ApiEndpoint: https://abc123.execute-api.us-west-2.amazonaws.com/dev
- UserPoolId: us-west-2_ABC123
- DataBucket: osrp-depression-study-dev
```

Save these values - you'll need them for Android app configuration.

---

## Step 4: Set Up Analysis Environment (3 minutes)

### Option A: SageMaker Studio Lab (FREE, no AWS account needed)

```bash
# 1. Sign up at https://studiolab.sagemaker.aws

# 2. In Studio Lab terminal, run:
curl -fsSL https://raw.githubusercontent.com/scttfrdmn/aws-marimo/main/bootstrap.sh | bash

# 3. Install OSRP
conda activate marimo-env
pip install osrp

# 4. Clone your study
git clone <your-repo> depression-study
cd depression-study

# 5. Start analyzing
osrp notebooks
```

### Option B: Local Jupyter/Marimo

```bash
# Install marimo
pip install marimo

# Start notebooks
osrp notebooks
# Opens http://localhost:8888
```

---

## Step 5: Configure Android App (Separate task)

The Android app needs to be built separately. See `docs/IMPLEMENTATION_PLAN.md` for details.

**Quick configuration:**
```kotlin
// app/src/main/res/values/aws_config.xml
<resources>
    <string name="cognito_user_pool_id">us-west-2_ABC123</string>
    <string name="cognito_client_id">YOUR_CLIENT_ID</string>
    <string name="api_endpoint">https://abc123.execute-api.us-west-2.amazonaws.com/dev</string>
    <string name="s3_bucket">osrp-depression-study-dev</string>
    <string name="aws_region">us-west-2</string>
</resources>
```

---

## Step 6: Start Collecting Data

1. **Install app** on test device
2. **Register participant** via app
3. **Grant permissions** (accessibility, location, etc.)
4. **Start collection** from app settings
5. **Monitor** via AWS CloudWatch or `osrp status`

---

## Step 7: Analyze Data (2 minutes)

```bash
# Start Marimo notebooks
osrp notebooks
```

**In the notebook:**
```python
from osrp import OSRPData
from datetime import datetime

# Initialize
data = OSRPData(region='us-west-2')

# Get participants
participants = data.get_participant_list()
print(f"Found {len(participants)} participants")

# Get daily summary for first participant
daily = data.get_daily_summary(
    user_id=participants[0],
    date=datetime(2026, 1, 15)
)

# Explore data
print(f"Screenshots: {len(daily['screenshots'])}")
print(f"Heart rate readings: {len(daily['heart_rate'])}")
print(f"Steps: {daily['steps']['steps'].sum()}")
```

---

## Common Commands

### Study Management
```bash
osrp init <study-name>           # Create new study
osrp deploy --aws                # Deploy infrastructure
osrp status                      # Check deployment status
osrp info                        # Show system info
```

### Analysis
```bash
osrp notebooks                   # Start Marimo notebooks
osrp notebooks --notebook daily_behavior_profile.py  # Open specific notebook
osrp notebooks --port 8080       # Use custom port
```

---

## Example: Daily Participant Report

```python
from osrp import OSRPData, DataAggregator
from datetime import datetime
import plotly.express as px

# Initialize
data = OSRPData(region='us-west-2')
aggregator = DataAggregator()

# Get data
user_id = 'participant001'
date = datetime(2026, 1, 15)
daily = data.get_daily_summary(user_id, date)

# Compute screen time
screen_sessions = data.compute_screen_time(daily['screenshots'])
total_screen_minutes = screen_sessions['duration_minutes'].sum()

# Activity summary
activity_summary = aggregator.daily_activity_summary(
    daily['activity'],
    daily['steps']
)

# Visualize
fig = px.line(
    daily['heart_rate'],
    y='heartRate',
    title=f'Heart Rate for {user_id} on {date.date()}'
)
fig.show()

# Print summary
print(f"""
Daily Summary for {user_id}:
- Screen time: {total_screen_minutes/60:.1f} hours
- Total steps: {activity_summary['total_steps']}
- Screenshots captured: {len(daily['screenshots'])}
""")
```

---

## Troubleshooting

### "AWS CLI not found"
```bash
pip install awscli
aws configure
```

### "Permission denied" on deployment
```bash
# Ensure your AWS user has AdministratorAccess or equivalent
# Check: AWS Console → IAM → Users → Your User → Permissions
```

### "No module named 'osrp'"
```bash
pip install osrp
# Or install in editable mode for development:
cd osrp
pip install -e .
```

### "Marimo not found"
```bash
pip install marimo
# Or install with analysis extras:
pip install osrp[analysis]
```

### Empty DataFrames in notebooks
- Verify data collection is running (check Android app)
- Check participant ID is correct
- Verify date range has data
- Check AWS CloudWatch logs for errors

---

## Next Steps

### For Researchers
1. ✅ **Read documentation**: `docs/PROJECT_BRIEF.md`
2. ✅ **Explore notebooks**: `analysis/notebooks/`
3. ✅ **Customize study**: Edit `config/study_config.yaml`
4. ✅ **Pilot test**: 3-5 participants for 1 week

### For Developers
1. ✅ **Review architecture**: `docs/TECHNICAL_SPECIFICATION.md`
2. ✅ **Follow plan**: `docs/IMPLEMENTATION_PLAN.md`
3. ✅ **Build Android app**: Week-by-week guide
4. ✅ **Test thoroughly**: `docs/TESTING_GUIDE.md`

### For Universities
1. ✅ **Cost analysis**: See `README.md` cost section
2. ✅ **Security review**: HIPAA compliance check
3. ✅ **IRB submission**: Use template language
4. ✅ **Infrastructure audit**: AWS Well-Architected review

---

## Getting Help

- **Documentation**: [docs.osrp.io](https://docs.osrp.io)
- **GitHub Issues**: [github.com/osrp-platform/osrp/issues](https://github.com/osrp-platform/osrp/issues)
- **Email**: contact@osrp.io
- **Community**: GitHub Discussions

---

## What You've Built

After completing this guide, you have:

✅ A configured OSRP study
✅ AWS infrastructure deployed (DynamoDB, S3, Lambda, Cognito, API Gateway)
✅ Analysis environment ready (Marimo notebooks)
✅ Data access tools (OSRPData class)
✅ Example notebooks for visualization and ML

**Total time invested**: ~15 minutes
**Infrastructure cost**: ~$10-20/month (development)
**Ready for**: Pilot testing with real participants

---

## Pro Tips

### Cost Optimization
```bash
# Stop SageMaker instances when not in use
aws sagemaker delete-app --domain-id <id> --user-profile-name researcher

# Enable S3 lifecycle policies (auto-archive old data)
# Already configured in CloudFormation template
```

### Performance
```python
# Batch requests for better performance
participants = data.get_participant_list()

# Use date ranges wisely
# Start with 1 day, expand as needed
daily = data.get_daily_summary(user_id, date)
```

### Security
```yaml
# Use environment-specific stacks
osrp deploy --aws --environment=dev      # Development
osrp deploy --aws --environment=staging  # Testing
osrp deploy --aws --environment=prod     # Production

# Never commit AWS credentials to git
# Use AWS IAM roles instead
```

---

**You're ready to start collecting multi-modal mobile sensing data with OSRP!**

For detailed implementation guidance, see [GETTING_STARTED.md](GETTING_STARTED.md).
