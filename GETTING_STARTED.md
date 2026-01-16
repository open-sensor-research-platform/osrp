# Getting Started with OSRP

**OSRP (Open Sensing Research Platform)** - Complete multi-modal mobile sensing for academic research.

This guide helps you get started with OSRP, whether you want to:
1. **Use the analysis tools** (Python package + Marimo notebooks)
2. **Deploy the full system** (Android app + AWS infrastructure + analysis)
3. **Develop and contribute** to OSRP

---

## Table of Contents

- [Quick Start: Analysis Only (5 minutes)](#quick-start-analysis-only)
- [Full System Setup (30+ minutes)](#full-system-setup)
- [Development Setup](#development-setup)
- [Common Tasks](#common-tasks)
- [Troubleshooting](#troubleshooting)
- [Next Steps](#next-steps)

---

## Quick Start: Analysis Only

**Goal**: Install OSRP package and start analyzing existing data.

**Time**: 5 minutes
**Prerequisites**: Python 3.11+

### Step 1: Install uv (Fast Package Manager)

```bash
# macOS/Linux
curl -LsSf https://astral.sh/uv/install.sh | sh

# Or with Homebrew
brew install uv

# Verify
uv --version
```

### Step 2: Install OSRP

```bash
# Navigate to OSRP directory
cd /path/to/osrp

# Create virtual environment
uv venv

# Activate environment
source .venv/bin/activate  # macOS/Linux
# .venv\Scripts\activate   # Windows

# Install OSRP in editable mode
uv pip install -e .

# Verify installation
osrp --version  # Should show: osrp, version 0.1.0
osrp info       # Show system information
```

### Step 3: Start Analyzing

```bash
# Start Marimo notebooks
osrp notebooks

# Or open specific notebook
cd analysis/notebooks
marimo edit daily_behavior_profile.py
```

### Step 4: Use Python API

```python
from osrp import OSRPData
from datetime import datetime

# Initialize
data = OSRPData(region='us-west-2')

# Get participants
participants = data.get_participant_list()

# Get daily summary
daily = data.get_daily_summary('participant001', datetime(2026, 1, 15))

# Access individual data streams
screenshots = daily['screenshots']
heart_rate = daily['heart_rate']
activity = daily['activity']
steps = daily['steps']

# Align multi-modal data
aligned = data.align_multi_modal({
    'screenshots': screenshots,
    'hr': heart_rate,
    'activity': activity
}, freq='5min')
```

**✓ You're ready to analyze OSRP data!**

See [QUICK_START.md](QUICK_START.md) for a more detailed 15-minute tutorial.

---

## Full System Setup

**Goal**: Deploy complete OSRP system (Android app + AWS + analysis).

**Time**: 30+ minutes
**Prerequisites**:
- AWS account with admin access
- Android Studio Hedgehog+
- Python 3.11+
- Git

### Overview

The full OSRP system consists of:
1. **Android App** - Data collection (screenshots, sensors, wearables)
2. **AWS Backend** - Storage and processing (DynamoDB, S3, Lambda)
3. **Analysis Environment** - Data access and notebooks (Python + Marimo)

### Phase 1: Python Package (5 minutes)

```bash
# 1. Install uv
curl -LsSf https://astral.sh/uv/install.sh | sh

# 2. Clone/navigate to OSRP
cd osrp

# 3. Create environment
uv venv
source .venv/bin/activate

# 4. Install package
uv pip install -e .

# 5. Verify
osrp info
```

### Phase 2: AWS Infrastructure (10 minutes)

```bash
# 1. Configure AWS credentials
aws configure
# Enter: Access Key ID, Secret Access Key, Region (us-west-2)

# 2. Initialize a study
osrp init my-study --template=comprehensive
cd my-study

# 3. Review configuration
cat config/study_config.yaml
# Edit if needed (enable/disable modules, sampling rates, etc.)

# 4. Deploy to AWS
osrp deploy --aws --region=us-west-2 --environment=dev

# 5. Verify deployment
osrp status --region=us-west-2

# 6. Note the outputs (you'll need these for Android app)
# - API Endpoint
# - User Pool ID
# - Client ID
# - Data Bucket Name
```

**Expected AWS Resources Created**:
- DynamoDB tables (SensorTimeSeries, EventLog, ScreenshotMetadata, etc.)
- S3 bucket with lifecycle policies
- Lambda functions (presigned URLs, data processing)
- API Gateway REST endpoints
- Cognito user pool
- CloudWatch monitoring

**Cost**: ~$50-100/month during development

### Phase 3: Android App (Weeks 1-16)

See [docs/IMPLEMENTATION_PLAN.md](docs/IMPLEMENTATION_PLAN.md) for the complete 16-week plan.

**Quick overview**:

```bash
# Week 1: AWS infrastructure ✓ (already done via osrp deploy)
# Week 2: Android project structure
# Week 3: Screenshot module
# Week 4: App usage tracking
# Weeks 5-8: Sensor modules
# Weeks 9-12: Wearables and EMA
# Weeks 13-16: Testing and production prep
```

**Android app development is beyond this quick start guide.** Follow the implementation plan for step-by-step instructions.

### Phase 4: Analysis Environment (Already Complete!)

The OSRP Python package includes everything you need:

```bash
# Start analyzing
osrp notebooks

# Or use Python API directly
python
>>> from osrp import OSRPData
>>> data = OSRPData(region='us-west-2')
>>> participants = data.get_participant_list()
```

---

## Development Setup

**For contributors and developers working on OSRP itself.**

### Prerequisites

- Python 3.11+
- uv (package manager)
- Git
- AWS CLI v2
- Android Studio (for Android development)

### Setup Development Environment

```bash
# 1. Clone repository
git clone https://github.com/osrp-platform/osrp.git
cd osrp

# 2. Create virtual environment
uv venv
source .venv/bin/activate

# 3. Install dev dependencies
uv pip install -e .
uv pip install pytest pytest-cov black flake8 mypy

# 4. Install analysis dependencies
uv pip install marimo plotly scikit-learn torch opencv-python-headless

# 5. Verify installation
osrp info
pytest  # Run tests

# 6. Set up pre-commit hooks (optional)
pip install pre-commit
pre-commit install
```

### Development Workflow

```bash
# Format code
black osrp/ analysis/ tests/

# Lint
flake8 osrp/ analysis/ --max-line-length=100

# Type check
mypy osrp/ --ignore-missing-imports

# Run tests
pytest

# Run tests with coverage
pytest --cov=osrp --cov-report=html

# Test CLI
osrp info
osrp init test-study
```

### Project Structure

```
osrp/
├── osrp/                          # Python package
│   ├── __init__.py               # Exports OSRPData
│   ├── cli.py                    # CLI commands
│   └── analysis/
│       └── utils/
│           └── data_access.py    # OSRPData, DataAggregator
├── analysis/                      # Analysis tools
│   ├── notebooks/                # Marimo notebooks
│   └── infrastructure/           # SageMaker setup
├── docs/                          # Documentation
├── infrastructure/                # CloudFormation templates
├── templates/                     # Code templates
├── tests/                         # Test suite
├── pyproject.toml                # Project config
├── requirements.txt              # Core dependencies
└── README.md                     # Main README
```

---

## Common Tasks

### Initialize a New Study

```bash
osrp init depression-study --template=comprehensive
cd depression-study

# Templates available:
# - basic: Screenshots + sensors only
# - ema: + Experience sampling
# - wearables: + Wearable integration
# - comprehensive: Everything (default)
```

### Deploy to AWS

```bash
# Development environment
osrp deploy --aws --region=us-west-2 --environment=dev

# Staging environment
osrp deploy --aws --region=us-west-2 --environment=staging

# Production environment
osrp deploy --aws --region=us-west-2 --environment=prod
```

### Check Deployment Status

```bash
# Check OSRP stacks
osrp status --region=us-west-2

# Check specific stack
aws cloudformation describe-stacks \
  --stack-name osrp-my-study-dev \
  --region=us-west-2
```

### Start Analysis Notebooks

```bash
# Start Marimo with all notebooks
osrp notebooks

# Start specific notebook
osrp notebooks --notebook daily_behavior_profile.py

# Use custom port
osrp notebooks --port 8080
```

### Access Data

```python
from osrp import OSRPData, DataAggregator
from datetime import datetime

# Initialize
data = OSRPData(region='us-west-2')

# Get participant list
participants = data.get_participant_list(group_code='study001')

# Get sensor data
accel = data.get_sensor_data(
    user_id='participant001',
    sensor_type='accelerometer',
    start_time=datetime(2026, 1, 1),
    end_time=datetime(2026, 1, 2)
)

# Get screenshots
screenshots = data.get_screenshots(
    user_id='participant001',
    start_time=datetime(2026, 1, 1),
    end_time=datetime(2026, 1, 2),
    load_images=False  # Set True to download actual images
)

# Get daily summary (all data types)
daily = data.get_daily_summary(
    user_id='participant001',
    date=datetime(2026, 1, 15)
)

# Compute screen time
screen_sessions = data.compute_screen_time(daily['screenshots'])

# Align multi-modal data
aligned = data.align_multi_modal({
    'screenshots': daily['screenshots'],
    'hr': daily['heart_rate'],
    'activity': daily['activity']
}, freq='5min')
```

### Update Dependencies

```bash
# Add new package
uv pip install scipy

# Update requirements.txt
uv pip freeze > requirements.txt

# Install from requirements.txt
uv pip sync requirements.txt

# Update single package
uv pip install --upgrade boto3
```

---

## Troubleshooting

### uv not found

```bash
# Install uv
curl -LsSf https://astral.sh/uv/install.sh | sh

# Add to PATH (if needed)
export PATH="$HOME/.cargo/bin:$PATH"
echo 'export PATH="$HOME/.cargo/bin:$PATH"' >> ~/.bashrc  # or ~/.zshrc
```

### ModuleNotFoundError: No module named 'osrp'

```bash
# Ensure you're in the right directory
cd /path/to/osrp

# Activate virtual environment
source .venv/bin/activate

# Install in editable mode
uv pip install -e .
```

### AWS credentials not configured

```bash
# Configure AWS CLI
aws configure

# Or set environment variables
export AWS_ACCESS_KEY_ID=your_key_id
export AWS_SECRET_ACCESS_KEY=your_secret_key
export AWS_DEFAULT_REGION=us-west-2
```

### osrp deploy fails

```bash
# Validate CloudFormation template
aws cloudformation validate-template \
  --template-body file://infrastructure/cloudformation-stack.yaml

# Check AWS permissions
aws sts get-caller-identity

# Ensure you have AdministratorAccess or equivalent
```

### Marimo notebooks won't start

```bash
# Install marimo
uv pip install marimo

# Try specific port
osrp notebooks --port 8080

# Or run directly
marimo edit analysis/notebooks/daily_behavior_profile.py
```

### Empty DataFrames in notebooks

Common causes:
1. **No data collected yet** - Ensure Android app is running and collecting data
2. **Wrong participant ID** - Check participant list with `data.get_participant_list()`
3. **Wrong date range** - Verify data exists for selected dates
4. **AWS credentials issue** - Ensure SageMaker/notebook has proper IAM role

---

## Next Steps

### For Researchers

1. ✓ **Install package** (`uv pip install -e .`)
2. ✓ **Deploy AWS infrastructure** (`osrp deploy --aws`)
3. → **Build Android app** (see [IMPLEMENTATION_PLAN.md](docs/IMPLEMENTATION_PLAN.md))
4. → **Pilot test** (5-10 participants, 1 week)
5. → **Full study** (analyze with Marimo notebooks)

### For Developers

1. ✓ **Set up development environment**
2. → **Read architecture docs** ([TECHNICAL_SPECIFICATION.md](docs/TECHNICAL_SPECIFICATION.md))
3. → **Follow implementation plan** ([IMPLEMENTATION_PLAN.md](docs/IMPLEMENTATION_PLAN.md))
4. → **Write tests** (pytest)
5. → **Contribute** (GitHub pull requests)

### For System Administrators

1. ✓ **Review AWS infrastructure** ([infrastructure/README.md](infrastructure/README.md))
2. → **Security audit** (IAM roles, encryption, compliance)
3. → **Cost optimization** (S3 lifecycle, Reserved Capacity)
4. → **Monitoring setup** (CloudWatch alarms, SNS notifications)
5. → **Backup strategy** (DynamoDB Point-in-Time Recovery)

---

## Documentation

- **README.md** - Main project overview
- **QUICK_START.md** - 15-minute setup guide
- **CLAUDE.md** - Development guide for AI assistants
- **docs/PROJECT_BRIEF.md** - Project overview and objectives
- **docs/TECHNICAL_SPECIFICATION.md** - Complete architecture
- **docs/IMPLEMENTATION_PLAN.md** - Week-by-week development plan
- **docs/TESTING_GUIDE.md** - Testing strategies
- **analysis/README.md** - Analysis backend guide

---

## Support

- **GitHub**: https://github.com/osrp-platform/osrp
- **Documentation**: https://docs.osrp.io (coming soon)
- **Website**: https://osrp.io (coming soon)
- **Issues**: https://github.com/osrp-platform/osrp/issues

---

## License

Apache License 2.0

Copyright 2026 Scott Friedman and OSRP Contributors

---

**Last Updated**: January 15, 2026
**Version**: 0.1.0
**Status**: Active Development

Welcome to OSRP! 🎉
