# Mobile Sensing Analysis - Quick Reference

## 🚀 5-Minute Setup (Easiest)

### Step 1: Get SageMaker Studio Lab (Free!)
1. Go to https://studiolab.sagemaker.aws
2. Sign up (no credit card required)
3. Launch environment

### Step 2: One-Command Install
```bash
# This installs marimo + jupyter-server-proxy
curl -fsSL https://raw.githubusercontent.com/scttfrdmn/aws-marimo/main/bootstrap.sh | bash
```

### Step 3: Install Mobile Sensing Tools
```bash
conda activate marimo-env
pip install boto3 pandas numpy plotly scikit-learn pillow opencv-python-headless
```

### Step 4: Copy Analysis Files
```bash
cd ~
# Upload the analysis/ directory from this dev kit
# Or git clone your analysis repo
```

### Step 5: Start Marimo
```bash
~/start-marimo.sh
```

### Step 6: Open Notebook
- Click proxy link in terminal
- Navigate to your notebook
- Start analyzing!

## 📊 Sample Analysis Session

```python
import marimo as mo
import sys
sys.path.append('/home/studio-lab-user/analysis/utils')
from data_access import MobileSensingData

# Connect to your data
data = MobileSensingData(region='us-west-2')

# Interactive controls
user_id = mo.ui.dropdown(
    options=data.get_participant_list(),
    label='Select Participant'
)

date = mo.ui.date(value='2026-01-15', label='Date')

# Load data (auto-updates when inputs change!)
daily = data.get_daily_summary(user_id.value, date.value)

# Display
mo.md(f"""
## Analysis for {user_id.value}
**Date:** {date.value}
**Screenshots:** {len(daily['screenshots'])}
**Total Steps:** {daily['steps']['steps'].sum():.0f}
""")
```

## 📁 File Organization

```
/home/studio-lab-user/  (or /home/sagemaker-user/)
├── aws-marimo/                 # Scott's marimo setup (auto-created)
├── start-marimo.sh             # Launch script (auto-created)
├── mobile-sensing-analysis/    # Your analysis files
│   ├── notebooks/
│   │   ├── daily_behavior_profile.py
│   │   ├── multimodal_analysis.py
│   │   └── ml_pipeline_example.py
│   └── utils/
│       └── data_access.py
└── .conda/envs/marimo-env/     # Isolated Python environment
```

## 🔑 AWS Configuration

### In SageMaker Studio Lab
You'll need to configure AWS credentials:

```bash
# Option 1: Environment variables
export AWS_ACCESS_KEY_ID=your_key
export AWS_SECRET_ACCESS_KEY=your_secret
export AWS_DEFAULT_REGION=us-west-2

# Option 2: AWS CLI configuration
aws configure
```

### In SageMaker Studio
Credentials are automatic! The Studio execution role is used.

```python
# Just works - no configuration needed
import boto3
dynamodb = boto3.resource('dynamodb')
```

## 🎯 Common Tasks

### Load One Day of Data
```python
from datetime import datetime
from data_access import MobileSensingData

data = MobileSensingData()
daily = data.get_daily_summary('user001', datetime(2026, 1, 15))

# Access specific streams
screenshots = daily['screenshots']
heart_rate = daily['heart_rate']
steps = daily['steps']
```

### Compare Multiple Days
```python
from datetime import datetime, timedelta
import pandas as pd

results = []
start = datetime(2026, 1, 1)

for i in range(7):
    date = start + timedelta(days=i)
    daily = data.get_daily_summary('user001', date)
    results.append({
        'date': date,
        'screenshots': len(daily['screenshots']),
        'steps': daily['steps']['steps'].sum()
    })

trends = pd.DataFrame(results)
```

### Multi-Modal Alignment
```python
# Align different data streams to common time base
aligned = data.align_multi_modal(
    {
        'screen': screenshots,
        'movement': accelerometer,
        'hr': heart_rate
    },
    freq='5min',
    method='ffill'
)

# Now everything is on same time index
correlation = aligned.corr()
```

### Screen Time Analysis
```python
# Compute screen usage sessions
sessions = data.compute_screen_time(
    screenshots,
    threshold_seconds=60  # Max gap between screenshots
)

# Total screen time
total_minutes = sessions['duration_minutes'].sum()

# Top apps
top_apps = sessions.groupby('appName')['duration_minutes'].sum().sort_values(ascending=False)
```

## 🎨 Visualization Patterns

### Timeline Plot
```python
import plotly.graph_objects as go

fig = go.Figure()
fig.add_trace(go.Scatter(
    x=screenshots.index,
    y=[1] * len(screenshots),
    mode='markers',
    marker=dict(size=10),
    text=screenshots['appName'],
    hovertemplate='%{text}<br>%{x}<extra></extra>'
))
fig.update_layout(
    title='App Usage Timeline',
    xaxis_title='Time',
    height=200
)
fig
```

### Multi-Panel Dashboard
```python
from plotly.subplots import make_subplots

fig = make_subplots(
    rows=3, cols=1,
    subplot_titles=('Movement', 'Heart Rate', 'Steps'),
    vertical_spacing=0.1
)

# Movement
fig.add_trace(
    go.Scatter(x=accel.index, y=accel['magnitude']),
    row=1, col=1
)

# Heart Rate
fig.add_trace(
    go.Scatter(x=hr.index, y=hr['heartRate']),
    row=2, col=1
)

# Steps (hourly)
hourly = steps.resample('1H')['steps'].sum()
fig.add_trace(
    go.Bar(x=hourly.index, y=hourly.values),
    row=3, col=1
)

fig.update_layout(height=800, showlegend=False)
fig
```

### Correlation Heatmap
```python
import plotly.express as px

# Compute correlation matrix
corr = aligned.corr()

fig = px.imshow(
    corr,
    text_auto='.2f',
    aspect='auto',
    title='Cross-Modal Correlations'
)
fig
```

## 🔬 Analysis Workflows

### Workflow 1: Daily Participant Check
1. Select participant from dropdown
2. Select date
3. View dashboard with all streams
4. Export any interesting findings

### Workflow 2: Multi-Day Trends
1. Select participant
2. Select date range
3. Compute daily aggregates
4. Plot trends over time
5. Identify patterns

### Workflow 3: Population Analysis
1. Select multiple participants
2. Compute features for each
3. Aggregate across population
4. Compare distributions
5. Statistical testing

### Workflow 4: ML Pipeline
1. Extract features from time windows
2. Prepare training data with labels
3. Train/test split
4. Train model
5. Evaluate performance
6. Analyze feature importance

## 💡 Marimo Tips

### Reactive Updates
```python
# This is the key difference from Jupyter!
# When slider changes, EVERYTHING downstream auto-updates

slider = mo.ui.slider(0, 100, value=50)
filtered = data[data['value'] > slider.value]  # Auto-updates!
plot = create_plot(filtered)                   # Auto-updates!

# Display
mo.vstack([slider, plot])
```

### UI Elements
```python
import marimo as mo

# Dropdown
dropdown = mo.ui.dropdown(['A', 'B', 'C'], value='A')

# Slider
slider = mo.ui.slider(0, 100, value=50)

# Date picker
date = mo.ui.date(value='2026-01-15')

# Multi-select
multi = mo.ui.multiselect(['X', 'Y', 'Z'])

# Checkbox
check = mo.ui.checkbox(label='Include outliers')

# Text input
text = mo.ui.text(placeholder='Enter user ID')

# Use their values
result = process(dropdown.value, slider.value, date.value)
```

### Layout
```python
# Vertical stack
mo.vstack([element1, element2, element3])

# Horizontal stack
mo.hstack([element1, element2], justify='space-between')

# Markdown
mo.md("""
## My Analysis
This is **bold** and this is *italic*
""")

# Tables
mo.ui.table(dataframe)
```

## 🐛 Debugging

### Print Debugging
```python
# Works in marimo
print(f"User ID: {user_id.value}")
print(f"Data shape: {daily['screenshots'].shape}")
```

### Inspect Data
```python
# Quick inspection
mo.ui.table(df.head())

# Or just display
df.head()
```

### Check Reactivity
```python
# Add this to see when cells execute
import time
print(f"Cell executed at {time.time()}")
```

## 📊 Performance Tips

1. **Limit Time Ranges**: Start with 1 day, expand as needed
2. **Sample Data**: Use `.sample(n=1000)` for large datasets
3. **Cache Results**: Use `@functools.lru_cache` for expensive ops
4. **Downsample**: Aggregate high-frequency data
5. **Lazy Loading**: Don't load images unless displaying

## 🔗 Quick Links

- **Your Analysis Files**: `/analysis/notebooks/`
- **Data Access API**: `/analysis/utils/data_access.py`
- **Scott's Marimo Guide**: https://github.com/scttfrdmn/aws-marimo
- **Marimo Docs**: https://docs.marimo.io
- **SageMaker Studio Lab**: https://studiolab.sagemaker.aws

## 🎯 Next Steps

1. ✅ Set up marimo (5 minutes)
2. ✅ Try example notebook
3. ✅ Load your own data
4. ✅ Create custom analysis
5. ✅ Share with team

**Need help?** 
- Check `analysis/README.md` for detailed guide
- See `SAGEMAKER_SETUP_SIMPLIFIED.md` for setup details
- Review example notebooks in `notebooks/`
