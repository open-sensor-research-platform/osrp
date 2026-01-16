# OSRP Analysis Backend - SageMaker Studio + Marimo

This directory contains the analysis backend for OSRP (Open Sensing Research Platform), built on AWS SageMaker Studio with Marimo notebooks.

## Overview

The analysis backend provides:
- **Interactive Data Exploration**: Marimo reactive notebooks
- **Multi-Modal Analysis**: Combine behavioral, physiological, and environmental data
- **Machine Learning Pipeline**: From raw data to predictive models
- **Scalable Infrastructure**: AWS SageMaker Studio

## Directory Structure

```
analysis/
├── ANALYSIS_ARCHITECTURE.md       # Complete architecture documentation
├── infrastructure/
│   └── sagemaker-cloudformation.md # CloudFormation templates for SageMaker
├── notebooks/                      # Example Marimo notebooks
│   ├── daily_behavior_profile.py  # Daily participant overview
│   ├── multimodal_analysis.py     # Cross-modal correlation analysis
│   └── ml_pipeline_example.py     # End-to-end ML workflow
├── utils/
│   └── data_access.py             # Data access utilities
└── examples/                       # Additional examples and tutorials
```

## Quick Start

### 🚀 Recommended: Simple Setup (5 Minutes)

**Based on Scott Friedman's proven approach**: https://github.com/scttfrdmn/aws-marimo

This is the **easiest and fastest** way to get started. No CloudFormation, no complex configuration.

#### Option A: SageMaker Studio Lab (FREE!)

1. **Sign up** at https://studiolab.sagemaker.aws (no AWS account needed!)
2. **One command** in terminal:
   ```bash
   curl -fsSL https://raw.githubusercontent.com/scttfrdmn/aws-marimo/main/bootstrap.sh | bash
   ```
3. **Install analysis tools**:
   ```bash
   conda activate marimo-env
   pip install boto3 pandas numpy plotly scikit-learn pillow opencv-python-headless
   ```
4. **Start marimo**: `~/start-marimo.sh`
5. **Upload** the `analysis/` directory from this dev kit
6. **Open** notebooks and start analyzing!

📖 **See**: `SAGEMAKER_SETUP_SIMPLIFIED.md` for detailed guide
🎯 **See**: `QUICK_REFERENCE.md` for analysis patterns

#### Option B: SageMaker Studio (If you have it)

```bash
# In Studio terminal
conda create -n marimo-env python=3.11 -y
conda activate marimo-env
pip install marimo jupyter-server-proxy
pip install boto3 pandas numpy plotly scikit-learn pillow opencv-python-headless

# Create start script
cat > ~/start-marimo.sh << 'EOF'
#!/bin/bash
conda activate marimo-env
marimo edit --host 0.0.0.0 --port 8888
EOF
chmod +x ~/start-marimo.sh

# Start marimo
~/start-marimo.sh
```

Access via: `proxy/8888/` in Studio

### 🏢 Advanced: Production Deployment (30+ Minutes)

For teams needing persistent, automated setup with CloudFormation:

📖 **See**: `infrastructure/sagemaker-cloudformation.md`

This approach:
- Deploys via CloudFormation
- Uses lifecycle configurations
- Automatically installs marimo for all users
- Best for organizations and teams

**Most users should start with the Simple Setup above!**

## Example Notebooks

### 1. Daily Behavior Profile (`daily_behavior_profile.py`)

**Purpose**: Comprehensive view of one participant's complete day

**Features**:
- Screenshot timeline showing app usage
- Activity levels throughout the day
- Heart rate patterns
- Screen time analysis
- Multi-panel dashboard

**Use Cases**:
- Daily participant check-ins
- Data quality verification
- Individual case studies
- Participant reports

**How to Use**:
```python
# Open in Marimo
marimo edit daily_behavior_profile.py

# Select participant and date
# All visualizations update reactively
```

### 2. Multi-Modal Analysis (`multimodal_analysis.py`)

**Purpose**: Analyze relationships between different data streams

**Features**:
- Temporal alignment of multiple signals
- Correlation heatmaps
- Time series comparison
- PCA dimensionality reduction
- Statistical hypothesis testing

**Use Cases**:
- Research question exploration
- Pattern identification
- Multi-modal feature extraction
- Cross-validation of sensors

**How to Use**:
```python
# Open in Marimo
marimo edit multimodal_analysis.py

# Select multiple participants and date range
# Choose alignment window (1min, 5min, etc.)
# Explore correlations interactively
```

### 3. ML Pipeline Example (`ml_pipeline_example.py`)

**Purpose**: Complete workflow from raw data to predictive model

**Features**:
- Feature engineering from time series
- Train/test split with cross-validation
- Multiple model types (Random Forest, Gradient Boosting)
- Performance evaluation (ROC-AUC, confusion matrix)
- Feature importance analysis

**Use Cases**:
- Stress detection
- Activity prediction
- Intervention timing
- Behavior classification

**How to Use**:
```python
# Open in Marimo
marimo edit ml_pipeline_example.py

# Select participants and date range
# Choose feature window and model type
# Model trains automatically
# View results and feature importance
```

## Data Access API

### `OSRPData` Class

```python
from osrp import OSRPData

# Initialize
data = OSRPData(region='us-west-2')

# Get sensor data
accel = data.get_sensor_data(
    user_id='user001',
    sensor_type='accelerometer',
    start_time=datetime(2026, 1, 1),
    end_time=datetime(2026, 1, 2)
)

# Get screenshots
screenshots = data.get_screenshots(
    user_id='user001',
    start_time=datetime(2026, 1, 1),
    end_time=datetime(2026, 1, 2),
    load_images=False  # Set True to download images
)

# Get complete daily summary
daily = data.get_daily_summary(
    user_id='user001',
    date=datetime(2026, 1, 1)
)
```

### Available Methods

- `get_sensor_data()` - Time series sensor data
- `get_screenshots()` - Screenshot metadata and images
- `get_events()` - Event log data
- `get_wearable_data()` - Wearable device data
- `get_ema_responses()` - Survey responses
- `get_daily_summary()` - All data for one day
- `get_participant_list()` - List of participants
- `compute_screen_time()` - Screen usage sessions
- `align_multi_modal()` - Temporal alignment

## Why Marimo?

### vs Jupyter Notebooks

**Reactivity**:
- ✅ Automatic re-execution when inputs change
- ✅ No stale cells
- ✅ Reproducible by design
- ❌ Jupyter: Manual re-run required

**Interactivity**:
- ✅ Native UI elements (sliders, dropdowns)
- ✅ Real-time visualization updates
- ✅ Better user experience for non-programmers
- ❌ Jupyter: Widgets less integrated

**Deployment**:
- ✅ Can run as standalone apps
- ✅ Easy to share with stakeholders
- ✅ Better for dashboards
- ❌ Jupyter: Primarily for notebook viewing

### Example: Reactive Updates

```python
import marimo as mo

# Create dropdown - UI element
user_id = mo.ui.dropdown(
    options=['user001', 'user002', 'user003'],
    value='user001',
    label='Select Participant'
)

# This cell automatically re-runs when dropdown changes!
data = get_data(user_id.value)
plot = create_visualization(data)

# Display
user_id  # Shows dropdown
plot     # Shows plot - updates when dropdown changes
```

## Creating New Notebooks

### 1. Basic Template

```python
import marimo as mo

app = mo.App()

@app.cell
def __():
    import marimo as mo
    import pandas as pd
    import plotly.graph_objects as go
    from osrp import OSRPData

    data_access = OSRPData()
    return mo, pd, go, data_access

@app.cell
def __(mo):
    # Your analysis code here
    result = mo.md("## My Analysis")
    result

if __name__ == "__main__":
    app.run()
```

### 2. Save and Run

```bash
# Save as my_analysis.py
marimo edit my_analysis.py
```

### 3. Share

```bash
# Export as HTML (static)
marimo export html my_analysis.py -o my_analysis.html

# Or run as web app
marimo run my_analysis.py --host 0.0.0.0 --port 8080
```

## Common Analysis Patterns

### Pattern 1: Daily Aggregations

```python
# Load full day
daily_data = data_access.get_daily_summary(user_id, date)

# Compute aggregates
screen_time = data_access.compute_screen_time(daily_data['screenshots'])
activity_summary = aggregator.daily_activity_summary(
    daily_data['activity'],
    daily_data['steps']
)
```

### Pattern 2: Multi-Day Trends

```python
# Loop through dates
results = []
for date in date_range:
    daily = data_access.get_daily_summary(user_id, date)
    summary = {
        'date': date,
        'total_steps': daily['steps']['steps'].sum(),
        'screen_time': len(daily['screenshots']) * 5 / 60  # minutes
    }
    results.append(summary)

trends_df = pd.DataFrame(results)
```

### Pattern 3: Feature Engineering

```python
# Extract features for ML
from utils.data_access import DataAggregator

aggregator = DataAggregator()

features = aggregator.context_features(
    sensor_data={
        'accelerometer': accel_df,
        'location': location_df,
        'activity': activity_df
    },
    window='5min'
)
```

## Troubleshooting

### Issue: "No module named 'marimo'"

```bash
# Install in SageMaker Studio
pip install marimo
```

### Issue: "Access Denied" reading DynamoDB

Check that SageMaker execution role has read permissions:
```yaml
- Effect: Allow
  Action:
    - dynamodb:Query
    - dynamodb:Scan
    - dynamodb:GetItem
  Resource: arn:aws:dynamodb:*:*:table/SensorTimeSeries
```

### Issue: Empty DataFrames

- Verify data exists for selected time range
- Check participant ID is correct
- Ensure date/time in correct timezone

### Issue: Marimo won't start

```bash
# Check port availability
netstat -tuln | grep 8080

# Try different port
marimo edit notebook.py --port 8081
```

## Performance Tips

1. **Limit Time Ranges**: Start with 1 day, expand as needed
2. **Sample Participants**: Use 5-10 participants for development
3. **Cache Results**: Use `@functools.lru_cache` for expensive operations
4. **Downsample Sensors**: Aggregate high-frequency data (e.g., 100Hz → 1Hz)
5. **Lazy Loading**: Don't load images unless needed

## Cost Optimization

### SageMaker Studio Costs

**Stop instances when not in use:**
```bash
# From AWS CLI
aws sagemaker delete-app \
  --domain-id <domain-id> \
  --user-profile-name researcher \
  --app-type JupyterServer \
  --app-name default
```

**Use appropriate instance sizes:**
- Development: ml.t3.medium ($0.05/hr)
- Heavy computation: ml.c5.xlarge ($0.20/hr)
- ML training: ml.m5.2xlarge ($0.46/hr)

**Storage:**
- Keep only active notebooks in EFS
- Archive old analyses to S3
- Set up lifecycle policies

## Security

### Data Access

- Read-only access to production data by default
- Separate dev/staging environments for testing
- Audit logging enabled via CloudTrail

### Best Practices

1. **De-identification**: Remove PII in analysis notebooks
2. **Access Control**: IAM roles per researcher/team
3. **Data Export**: Secure S3 buckets for results
4. **Compliance**: Follow institutional IRB requirements

## Next Steps

1. **Run Example Notebooks**: Start with daily_behavior_profile.py
2. **Customize for Your Study**: Modify notebooks for your research questions
3. **Create New Analyses**: Use templates to build new notebooks
4. **Deploy Models**: Use SageMaker endpoints for predictions
5. **Build Dashboards**: Create Marimo apps for stakeholders

## Resources

- **Marimo Documentation**: https://docs.marimo.io
- **SageMaker Studio Guide**: https://docs.aws.amazon.com/sagemaker/
- **Plotly for Python**: https://plotly.com/python/
- **Pandas User Guide**: https://pandas.pydata.org/docs/

## Support

- Check ANALYSIS_ARCHITECTURE.md for detailed architecture
- See infrastructure/ for deployment guides
- Review utils/data_access.py for API documentation
- Consult example notebooks for usage patterns

Happy analyzing! 🎉
