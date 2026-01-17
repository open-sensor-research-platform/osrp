# OSRP Data Access Guide

Complete guide to accessing and analyzing data collected by the Open Sensing Research Platform.

---

## Table of Contents

- [Introduction](#introduction)
- [Installation and Setup](#installation-and-setup)
- [Connecting to AWS](#connecting-to-aws)
- [Using OSRPData](#using-osrpdata)
  - [Basic Usage](#basic-usage)
  - [Common Queries](#common-queries)
  - [Data Aggregation](#data-aggregation)
- [Using Marimo Notebooks](#using-marimo-notebooks)
- [Performance Tips](#performance-tips)
- [Troubleshooting](#troubleshooting)
- [API Reference](#api-reference)

---

## Introduction

The OSRP data access layer provides a clean Python API for retrieving and analyzing data collected from iOS and Android devices. Data is stored in AWS DynamoDB and accessed through the `OSRPData` class.

### What Data is Available?

**Android**:
- Accelerometer data (5 Hz sampling)
- Device events (app lifecycle, etc.)
- Device state (battery, storage, network)

**iOS**:
- Step count (daily)
- Heart rate (individual samples)
- Active energy burned (daily)

All data includes:
- User ID
- Timestamps
- Upload metadata
- Data type and values

---

## Installation and Setup

### Prerequisites

- **Python**: 3.11 or later
- **uv**: Fast Python package manager
- **AWS Account**: With deployed OSRP infrastructure
- **AWS Credentials**: Configured with appropriate permissions

### Install uv

```bash
# macOS/Linux
curl -LsSf https://astral.sh/uv/install.sh | sh

# Or with Homebrew
brew install uv

# Verify installation
uv --version
```

### Install OSRP Package

```bash
# Clone repository
git clone https://github.com/open-sensor-research-platform/osrp.git
cd osrp

# Create virtual environment
uv venv

# Activate environment
source .venv/bin/activate  # macOS/Linux
# .venv\Scripts\activate   # Windows

# Install dependencies
uv pip sync requirements.txt

# Install OSRP in editable mode
uv pip install -e .

# Verify installation
python -c "from osrp import OSRPData; print('OSRP installed successfully!')"
```

---

## Connecting to AWS

### Configure AWS Credentials

The OSRPData class uses boto3 to connect to AWS. Configure your credentials:

**Option 1: AWS CLI (Recommended)**

```bash
aws configure
```

Enter your:
- AWS Access Key ID
- AWS Secret Access Key
- Default region (e.g., `us-west-2`)
- Default output format (`json`)

**Option 2: Environment Variables**

```bash
export AWS_ACCESS_KEY_ID=your_access_key
export AWS_SECRET_ACCESS_KEY=your_secret_key
export AWS_DEFAULT_REGION=us-west-2
```

**Option 3: AWS Credentials File**

Create `~/.aws/credentials`:

```ini
[default]
aws_access_key_id = your_access_key
aws_secret_access_key = your_secret_key
```

And `~/.aws/config`:

```ini
[default]
region = us-west-2
output = json
```

### Test Connection

```python
from osrp import OSRPData

# Initialize with your region
data = OSRPData(region='us-west-2')

# Test connection by listing participants
participants = data.get_participant_list()
print(f"Found {len(participants)} participants")
```

---

## Using OSRPData

### Basic Usage

```python
from osrp import OSRPData
from datetime import datetime, timedelta

# Initialize
data = OSRPData(region='us-west-2')

# Get list of all participants
participants = data.get_participant_list()
print(f"Participants: {participants}")

# Get data for specific participant
user_id = participants[0]
today = datetime.now()

# Get today's summary
daily_summary = data.get_daily_summary(
    user_id=user_id,
    date=today
)

print(f"Steps today: {daily_summary['steps']}")
print(f"Heart rate samples: {len(daily_summary['heart_rate'])}")
```

### Common Queries

#### Get Step Count Data

```python
# Single day
steps_today = data.get_steps(
    user_id='user@example.com',
    start_date=datetime(2026, 1, 16),
    end_date=datetime(2026, 1, 16)
)

# Date range
start = datetime(2026, 1, 1)
end = datetime(2026, 1, 16)
steps_month = data.get_steps(
    user_id='user@example.com',
    start_date=start,
    end_date=end
)

print(f"Total steps in range: {steps_month['value'].sum()}")
print(f"Average daily steps: {steps_month['value'].mean()}")
```

#### Get Heart Rate Data

```python
# Get heart rate samples for today
hr_data = data.get_heart_rate(
    user_id='user@example.com',
    start_date=datetime(2026, 1, 16),
    end_date=datetime(2026, 1, 16)
)

# Analyze
print(f"Samples: {len(hr_data)}")
print(f"Min HR: {hr_data['value'].min()} bpm")
print(f"Max HR: {hr_data['value'].max()} bpm")
print(f"Avg HR: {hr_data['value'].mean():.1f} bpm")
```

#### Get Accelerometer Data (Android)

```python
# Get accelerometer data
accel_data = data.get_accelerometer(
    user_id='user@example.com',
    start_date=datetime(2026, 1, 16, 10, 0),
    end_date=datetime(2026, 1, 16, 11, 0)
)

# Data includes x, y, z components
print(f"Samples: {len(accel_data)}")
print(accel_data[['timestamp', 'x', 'y', 'z']].head())
```

#### Get Active Energy

```python
# Get active energy burned
energy_data = data.get_active_energy(
    user_id='user@example.com',
    start_date=datetime(2026, 1, 1),
    end_date=datetime(2026, 1, 16)
)

print(f"Total calories burned: {energy_data['value'].sum():.0f} kcal")
```

### Data Aggregation

```python
from osrp import OSRPData, DataAggregator

data = OSRPData(region='us-west-2')
aggregator = DataAggregator()

# Get daily data
daily = data.get_daily_summary(
    user_id='user@example.com',
    date=datetime(2026, 1, 16)
)

# Aggregate activity
activity_summary = aggregator.daily_activity_summary(
    activity_data=daily['activity'],
    steps_data=daily['steps']
)

print(activity_summary)
# Output:
# {
#     'total_steps': 10000,
#     'active_minutes': 120,
#     'sedentary_minutes': 600,
#     'calories_burned': 450
# }
```

#### Multi-Modal Data Alignment

```python
# Get different data types
screenshots = data.get_screenshots(user_id, date)
heart_rate = data.get_heart_rate(user_id, date)
activity = data.get_activity(user_id, date)

# Align to common time grid (5-minute intervals)
aligned = data.align_multi_modal({
    'screenshots': screenshots,
    'heart_rate': heart_rate,
    'activity': activity
}, freq='5min')

# Now all data is aligned to the same timestamps
print(aligned.head())
```

#### Screen Time Analysis

```python
# Get screenshot data
screenshots = data.get_screenshots(
    user_id='user@example.com',
    start_date=datetime(2026, 1, 16),
    end_date=datetime(2026, 1, 16)
)

# Compute screen time sessions
sessions = data.compute_screen_time(screenshots)

print(f"Screen sessions today: {len(sessions)}")
print(f"Total screen time: {sessions['duration_minutes'].sum():.0f} min")
print(f"Avg session length: {sessions['duration_minutes'].mean():.1f} min")
```

---

## Using Marimo Notebooks

Marimo provides reactive, reproducible analysis notebooks for OSRP data.

### Available Notebooks

Located in `analysis/notebooks/`:

1. **daily_behavior_profile.py**: Daily activity and behavior analysis
2. **multimodal_analysis.py**: Multi-modal data correlation
3. **ml_pipeline_example.py**: Machine learning pipeline examples

### Starting Marimo

```bash
# Install Marimo (if not already installed)
uv pip install marimo plotly scikit-learn

# Navigate to notebooks directory
cd analysis/notebooks

# Start Marimo server
marimo edit daily_behavior_profile.py --port 8888

# Or use OSRP CLI
osrp notebooks
```

### Using the Daily Behavior Profile Notebook

```python
import marimo

__generated_with = "0.9.14"
app = marimo.App()

@app.cell
def __():
    import marimo as mo
    from osrp import OSRPData
    from datetime import datetime

    # Initialize data access
    data_access = OSRPData(region='us-west-2')

    # Get participants
    participants = data_access.get_participant_list()

    # Interactive participant selector
    user_selector = mo.ui.dropdown(
        options=participants,
        value=participants[0] if participants else None,
        label='Select Participant'
    )

    return mo, data_access, user_selector

@app.cell
def __(data_access, user_selector):
    # Get selected user's data
    user_id = user_selector.value

    if user_id:
        daily_data = data_access.get_daily_summary(
            user_id=user_id,
            date=datetime.now()
        )

        # Display results
        print(f"Steps: {daily_data['steps']}")
        print(f"Active Energy: {daily_data['active_energy']} kcal")

    return daily_data
```

### Creating Custom Notebooks

```python
# Create new notebook
marimo edit my_analysis.py

# Basic structure
import marimo

__generated_with = "0.9.14"
app = marimo.App()

@app.cell
def __():
    import marimo as mo
    import pandas as pd
    import plotly.graph_objects as go
    from osrp import OSRPData

    data = OSRPData(region='us-west-2')

    return mo, pd, go, data

@app.cell
def __(data):
    # Your analysis code here
    participants = data.get_participant_list()

    # Interactive UI elements
    user_dropdown = mo.ui.dropdown(
        options=participants,
        label="Select User"
    )

    user_dropdown
    return user_dropdown, participants

if __name__ == "__main__":
    app.run()
```

---

## Performance Tips

### 1. Use Date Range Filtering

Always filter by date to reduce data transfer:

```python
# Good: Narrow date range
data.get_heart_rate(
    user_id='user@example.com',
    start_date=datetime(2026, 1, 16),
    end_date=datetime(2026, 1, 16)
)

# Avoid: Retrieving all data
data.get_heart_rate(user_id='user@example.com')  # Too broad!
```

### 2. Batch Requests for Multiple Users

```python
# Efficient: Batch process
all_data = []
for user in participants:
    user_data = data.get_daily_summary(user, date)
    all_data.append(user_data)
```

### 3. Cache Intermediate Results

```python
import pickle

# Save expensive query results
results = data.get_accelerometer(user_id, start, end)
with open('accel_cache.pkl', 'wb') as f:
    pickle.dump(results, f)

# Load cached results
with open('accel_cache.pkl', 'rb') as f:
    results = pickle.load(f)
```

### 4. Use Pandas Efficiently

```python
# Good: Vectorized operations
df['magnitude'] = np.sqrt(df['x']**2 + df['y']**2 + df['z']**2)

# Avoid: Row iteration
for idx, row in df.iterrows():  # Slow!
    df.at[idx, 'magnitude'] = np.sqrt(row['x']**2 + row['y']**2 + row['z']**2)
```

### 5. Limit Data Type Queries

```python
# Good: Query only what you need
steps = data.get_steps(user_id, date)

# Avoid: Getting all data types when you only need one
daily = data.get_daily_summary(user_id, date)  # Returns everything
steps = daily['steps']  # Wasteful if you only need steps
```

---

## Troubleshooting

### Connection Issues

**Error**: `NoCredentialsError: Unable to locate credentials`

**Solution**: Configure AWS credentials (see [Connecting to AWS](#connecting-to-aws))

```bash
aws configure
```

---

**Error**: `EndpointConnectionError: Could not connect to the endpoint URL`

**Solution**: Check your region and network connection

```python
# Verify region matches your deployment
data = OSRPData(region='us-west-2')  # Use correct region

# Test AWS connection
import boto3
dynamodb = boto3.resource('dynamodb', region_name='us-west-2')
tables = list(dynamodb.tables.all())
print(f"Tables: {[t.name for t in tables]}")
```

---

### Data Not Found

**Error**: `ResourceNotFoundException: Requested resource not found`

**Solution**: Verify table names and deployment

```python
# List available tables
import boto3
dynamodb = boto3.client('dynamodb', region_name='us-west-2')
response = dynamodb.list_tables()
print(f"Available tables: {response['TableNames']}")
```

---

**Error**: Empty results returned

**Solution**: Check date range and user ID

```python
# Verify participant exists
participants = data.get_participant_list()
print(f"Participants: {participants}")

# Check if data exists for date
daily = data.get_daily_summary(user_id, date)
if not daily:
    print(f"No data for {user_id} on {date}")
```

---

### Performance Issues

**Issue**: Queries are slow

**Solution**:
1. Use narrower date ranges
2. Add GSI indexes to DynamoDB tables
3. Enable DynamoDB on-demand billing for variable workloads
4. Cache frequently accessed data

```python
# Use date filtering
data.get_heart_rate(
    user_id='user@example.com',
    start_date=datetime(2026, 1, 16, 10, 0),
    end_date=datetime(2026, 1, 16, 11, 0)  # 1-hour window
)
```

---

### Import Errors

**Error**: `ModuleNotFoundError: No module named 'osrp'`

**Solution**: Install package in editable mode

```bash
cd /path/to/osrp
uv pip install -e .
```

---

**Error**: `ImportError: cannot import name 'OSRPData'`

**Solution**: Reinstall package

```bash
uv pip install -e . --force-reinstall
```

---

## API Reference

### OSRPData

Main class for accessing OSRP data.

#### Constructor

```python
OSRPData(region: str = 'us-west-2')
```

**Parameters**:
- `region` (str): AWS region where data is stored

**Example**:
```python
data = OSRPData(region='us-west-2')
```

---

#### Methods

##### get_participant_list()

Get list of all participant IDs.

```python
def get_participant_list() -> List[str]
```

**Returns**: List of participant email addresses/IDs

**Example**:
```python
participants = data.get_participant_list()
# ['user1@example.com', 'user2@example.com']
```

---

##### get_daily_summary()

Get complete daily summary for a participant.

```python
def get_daily_summary(
    user_id: str,
    date: datetime
) -> Dict[str, pd.DataFrame]
```

**Parameters**:
- `user_id` (str): Participant ID
- `date` (datetime): Date to retrieve

**Returns**: Dictionary with keys:
- `steps`: Step count data
- `heart_rate`: Heart rate samples
- `active_energy`: Active energy burned
- `activity`: Activity data (if available)
- `screenshots`: Screenshot data (if available)

**Example**:
```python
summary = data.get_daily_summary(
    user_id='user@example.com',
    date=datetime(2026, 1, 16)
)
```

---

##### get_steps()

Get step count data.

```python
def get_steps(
    user_id: str,
    start_date: datetime,
    end_date: datetime
) -> pd.DataFrame
```

**Parameters**:
- `user_id` (str): Participant ID
- `start_date` (datetime): Start of date range
- `end_date` (datetime): End of date range

**Returns**: DataFrame with columns:
- `timestamp`: Datetime index
- `value`: Step count
- `unit`: 'count'

**Example**:
```python
steps = data.get_steps(
    user_id='user@example.com',
    start_date=datetime(2026, 1, 1),
    end_date=datetime(2026, 1, 16)
)
```

---

##### get_heart_rate()

Get heart rate samples.

```python
def get_heart_rate(
    user_id: str,
    start_date: datetime,
    end_date: datetime
) -> pd.DataFrame
```

**Parameters**:
- `user_id` (str): Participant ID
- `start_date` (datetime): Start of date range
- `end_date` (datetime): End of date range

**Returns**: DataFrame with columns:
- `timestamp`: Datetime index
- `value`: Heart rate in bpm
- `unit`: 'bpm'

**Example**:
```python
hr = data.get_heart_rate(
    user_id='user@example.com',
    start_date=datetime(2026, 1, 16),
    end_date=datetime(2026, 1, 16)
)
```

---

##### get_accelerometer()

Get accelerometer data (Android only).

```python
def get_accelerometer(
    user_id: str,
    start_date: datetime,
    end_date: datetime
) -> pd.DataFrame
```

**Parameters**:
- `user_id` (str): Participant ID
- `start_date` (datetime): Start of date range
- `end_date` (datetime): End of date range

**Returns**: DataFrame with columns:
- `timestamp`: Datetime index
- `x`: X-axis acceleration (m/s²)
- `y`: Y-axis acceleration (m/s²)
- `z`: Z-axis acceleration (m/s²)
- `accuracy`: Sensor accuracy

**Example**:
```python
accel = data.get_accelerometer(
    user_id='user@example.com',
    start_date=datetime(2026, 1, 16, 10, 0),
    end_date=datetime(2026, 1, 16, 11, 0)
)
```

---

##### align_multi_modal()

Align multiple data streams to common time grid.

```python
def align_multi_modal(
    data_dict: Dict[str, pd.DataFrame],
    freq: str = '5min'
) -> pd.DataFrame
```

**Parameters**:
- `data_dict` (dict): Dictionary of DataFrames to align
- `freq` (str): Resampling frequency (pandas frequency string)

**Returns**: DataFrame with aligned data streams

**Example**:
```python
aligned = data.align_multi_modal({
    'steps': steps_df,
    'heart_rate': hr_df,
    'activity': activity_df
}, freq='5min')
```

---

### DataAggregator

Helper class for data aggregation.

#### daily_activity_summary()

Compute daily activity summary.

```python
def daily_activity_summary(
    activity_data: pd.DataFrame,
    steps_data: pd.DataFrame
) -> Dict[str, float]
```

**Parameters**:
- `activity_data` (DataFrame): Activity data
- `steps_data` (DataFrame): Steps data

**Returns**: Dictionary with keys:
- `total_steps`: Total step count
- `active_minutes`: Minutes of activity
- `sedentary_minutes`: Minutes of inactivity
- `calories_burned`: Estimated calories

**Example**:
```python
from osrp import DataAggregator

aggregator = DataAggregator()
summary = aggregator.daily_activity_summary(
    activity_data=daily['activity'],
    steps_data=daily['steps']
)
```

---

## Next Steps

- **Deploy Infrastructure**: See [infrastructure/DEPLOYMENT.md](../infrastructure/DEPLOYMENT.md)
- **Test Data Collection**: Start collecting data with Android/iOS apps
- **Run Notebooks**: Explore data with Marimo notebooks
- **Build Custom Analysis**: Create your own analysis pipelines

---

## Support

- **Issues**: https://github.com/open-sensor-research-platform/osrp/issues
- **Documentation**: https://github.com/open-sensor-research-platform/osrp/tree/main/docs
- **Examples**: See `analysis/notebooks/` for working examples

---

**Last Updated**: January 2026
**Version**: 0.1.0
