# CLAUDE.md - OSRP Development Guide

This document helps Claude (or any AI assistant) understand the OSRP project structure, development workflow, and conventions.

---

## Project Overview

**OSRP (Open Sensing Research Platform)** is a comprehensive, multi-modal mobile sensing platform for academic research. It combines:
- Screenshot capture (behavioral observation)
- Built-in sensors (accelerometer, GPS, activity)
- Wearable integration (Google Fit, Bluetooth HR monitors)
- Experience sampling (EMAs)
- AWS-native infrastructure (DynamoDB, S3, Lambda)
- Marimo analysis notebooks (reactive, reproducible)

**Primary Language**: Python 3.11+
**Package Manager**: `uv` (fast Python package installer and resolver)
**Target Platform**: AWS
**License**: Apache 2.0

---

## Critical Information

### ⚠️ Use `uv` for ALL Python Operations

This project uses **`uv`** instead of pip/virtualenv/poetry. Always use `uv` commands:

```bash
# ❌ DON'T USE
pip install package
python -m venv env
pip install -r requirements.txt

# ✅ USE INSTEAD
uv pip install package
uv venv
uv pip sync requirements.txt
```

### Project Names & Conventions

- **Package name**: `osrp` (lowercase, PyPI)
- **Class name**: `OSRPData` (PascalCase)
- **CLI command**: `osrp` (lowercase)
- **Bucket naming**: `osrp-{study}-{env}` (e.g., `osrp-depression-study-dev`)
- **Stack naming**: `osrp-{study}-{env}` (e.g., `osrp-depression-study-prod`)

### ⚠️ Never Use Old Names

The project was recently rebranded:
- ❌ `MobileSensingData` → ✅ `OSRPData`
- ❌ `mobile-sensing-platform` → ✅ `osrp`
- ❌ `mobile-sensing-data` (bucket) → ✅ `osrp-data`

Always use the new OSRP naming.

---

## Project Structure

```
osrp/
├── osrp/                          # Python package
│   ├── __init__.py               # Exports OSRPData, DataAggregator
│   ├── cli.py                    # CLI commands (osrp init, deploy, etc.)
│   └── analysis/                 # Analysis backend (to be moved here)
│
├── analysis/                      # Analysis tools (current location)
│   ├── utils/
│   │   └── data_access.py       # OSRPData class, DataAggregator
│   ├── notebooks/               # Marimo notebooks
│   │   ├── daily_behavior_profile.py
│   │   ├── multimodal_analysis.py
│   │   └── ml_pipeline_example.py
│   └── infrastructure/
│       └── sagemaker-cloudformation.md
│
├── docs/                         # Documentation
│   ├── PROJECT_BRIEF.md
│   ├── TECHNICAL_SPECIFICATION.md
│   ├── IMPLEMENTATION_PLAN.md
│   ├── TESTING_GUIDE.md
│   └── HARDWARE_RECOMMENDATIONS.md
│
├── infrastructure/               # AWS CloudFormation
│   ├── cloudformation-stack.yaml
│   ├── deploy.sh
│   └── README.md
│
├── templates/                    # Code templates
│   ├── android_module_template.kt
│   └── lambda_function_template.py
│
├── tests/                        # Test suite
│   ├── lambda/
│   ├── load/
│   └── validation/
│
├── android/                      # Android app templates
│   └── templates/
│
├── pyproject.toml               # Python project config (uv)
├── requirements.txt             # Core dependencies
├── setup.py                     # Package setup (backwards compat)
├── README.md                    # Main README
├── QUICK_START.md              # 15-min setup guide
├── LANDING_PAGE.md             # Website content
├── REBRAND_SUMMARY.md          # Rebrand changelog
├── TODO.md                     # Remaining tasks
└── CLAUDE.md                   # This file
```

---

## Development Setup

### 1. Install `uv`

```bash
# macOS/Linux
curl -LsSf https://astral.sh/uv/install.sh | sh

# Or with Homebrew
brew install uv

# Verify installation
uv --version
```

### 2. Clone and Set Up Project

```bash
# Clone repository
git clone https://github.com/osrp-platform/osrp.git
cd osrp

# Create virtual environment with uv
uv venv

# Activate environment
source .venv/bin/activate  # macOS/Linux
# .venv\Scripts\activate   # Windows

# Install dependencies
uv pip sync requirements.txt

# Install package in editable mode
uv pip install -e .

# Verify installation
osrp info
```

### 3. Install Development Dependencies

```bash
# Install dev dependencies
uv pip install pytest pytest-cov black flake8 mypy

# Install analysis dependencies
uv pip install marimo plotly scikit-learn torch opencv-python-headless
```

### 4. Configure AWS

```bash
# Install AWS CLI (if not already installed)
uv pip install awscli

# Configure credentials
aws configure
# Enter: Access Key ID, Secret Access Key, Region (us-west-2), Output (json)
```

---

## Python Package Management with `uv`

### Adding Dependencies

```bash
# Add a new dependency
uv pip install pandas

# Update requirements.txt
uv pip freeze > requirements.txt

# Or add directly to requirements.txt, then:
uv pip sync requirements.txt
```

### Updating Dependencies

```bash
# Update a specific package
uv pip install --upgrade boto3

# Update all packages
uv pip install --upgrade -r requirements.txt

# Sync to requirements.txt exactly
uv pip sync requirements.txt
```

### Creating Lock File

```bash
# Generate lock file for reproducible builds
uv pip compile requirements.txt -o requirements.lock

# Install from lock file
uv pip sync requirements.lock
```

---

## Common Tasks

### Running CLI Commands

```bash
# Create new study
osrp init my-study --template=comprehensive

# Deploy to AWS
cd my-study
osrp deploy --aws --region=us-west-2 --environment=dev

# Start Marimo notebooks
osrp notebooks

# Check deployment status
osrp status --region=us-west-2

# Show system info
osrp info
```

### Working with Data Access Layer

```python
from osrp import OSRPData, DataAggregator
from datetime import datetime

# Initialize
data = OSRPData(region='us-west-2')

# Get participants
participants = data.get_participant_list()

# Get daily summary
daily = data.get_daily_summary(
    user_id='participant001',
    date=datetime(2026, 1, 15)
)

# Access individual streams
screenshots = daily['screenshots']
heart_rate = daily['heart_rate']
activity = daily['activity']

# Align multi-modal data
aligned = data.align_multi_modal({
    'screenshots': screenshots,
    'hr': heart_rate,
    'activity': activity
}, freq='5min')

# Compute screen time
screen_sessions = data.compute_screen_time(screenshots)

# Activity summary
aggregator = DataAggregator()
activity_summary = aggregator.daily_activity_summary(
    daily['activity'],
    daily['steps']
)
```

### Running Marimo Notebooks

```bash
# Start Marimo server
cd analysis/notebooks
marimo edit daily_behavior_profile.py --port 8888

# Or use CLI
osrp notebooks --notebook daily_behavior_profile.py

# Run all cells (non-interactive)
marimo run daily_behavior_profile.py
```

### Testing

```bash
# Run all tests
pytest

# Run with coverage
pytest --cov=osrp --cov-report=html

# Run specific test file
pytest tests/test_data_access.py

# Run specific test
pytest tests/test_data_access.py::test_get_daily_summary
```

### Code Quality

```bash
# Format code with Black
black osrp/ analysis/ tests/

# Lint with flake8
flake8 osrp/ analysis/ --max-line-length=100

# Type check with mypy
mypy osrp/ --ignore-missing-imports

# Run all checks
black osrp/ && flake8 osrp/ && mypy osrp/ && pytest
```

---

## AWS Deployment

### Deploy Infrastructure

```bash
# From infrastructure directory
cd infrastructure

# Deploy development stack
./deploy.sh dev us-west-2

# Deploy production stack
./deploy.sh prod us-west-2

# Or use CLI
osrp deploy --aws --region=us-west-2 --environment=prod
```

### Check Deployment Status

```bash
# List stacks
aws cloudformation list-stacks \
  --region us-west-2 \
  --stack-status-filter CREATE_COMPLETE UPDATE_COMPLETE

# Describe specific stack
aws cloudformation describe-stacks \
  --stack-name osrp-my-study-dev \
  --region us-west-2

# Or use CLI
osrp status --region=us-west-2
```

### View Stack Outputs

```bash
# Get outputs (API endpoint, user pool, etc.)
aws cloudformation describe-stacks \
  --stack-name osrp-my-study-dev \
  --region us-west-2 \
  --query 'Stacks[0].Outputs'
```

---

## Code Conventions

### Python Style

- **Formatting**: Black (line length: 100)
- **Imports**: isort (with Black-compatible settings)
- **Docstrings**: Google style
- **Type hints**: Use for all public functions

```python
from typing import List, Dict, Optional
from datetime import datetime
import pandas as pd

def get_sensor_data(
    user_id: str,
    sensor_type: str,
    start_time: datetime,
    end_time: datetime
) -> pd.DataFrame:
    """
    Retrieve sensor time series data.

    Args:
        user_id: Participant ID
        sensor_type: Type of sensor (accelerometer, gyroscope, location, etc.)
        start_time: Start timestamp
        end_time: End timestamp

    Returns:
        DataFrame with sensor readings and datetime index
    """
    pass
```

### Class Naming

- **Public classes**: `OSRPData`, `DataAggregator` (PascalCase)
- **Private classes**: `_InternalHelper` (underscore prefix)
- **Constants**: `MAX_RETRIES`, `DEFAULT_REGION` (UPPER_SNAKE_CASE)

### Function Naming

- **Public functions**: `get_daily_summary()`, `align_multi_modal()` (snake_case)
- **Private functions**: `_load_image()`, `_compute_hash()` (underscore prefix)

### File Naming

- **Python modules**: `data_access.py`, `cli.py` (snake_case)
- **Documentation**: `README.md`, `QUICK_START.md` (UPPER_CASE)
- **Notebooks**: `daily_behavior_profile.py`, `multimodal_analysis.py` (snake_case)

---

## Important Files

### Core Python Files

| File | Purpose | Key Classes/Functions |
|------|---------|----------------------|
| `osrp/__init__.py` | Package entry point | Exports `OSRPData`, `DataAggregator` |
| `osrp/cli.py` | CLI implementation | `init()`, `deploy()`, `notebooks()` |
| `analysis/utils/data_access.py` | Data access layer | `OSRPData`, `DataAggregator` |

### Configuration Files

| File | Purpose | Format |
|------|---------|--------|
| `pyproject.toml` | Python project config | TOML (uv, Black, pytest) |
| `requirements.txt` | Core dependencies | Text (one package per line) |
| `setup.py` | Package setup | Python (setuptools) |

### Documentation Files

| File | Purpose | Audience |
|------|---------|----------|
| `README.md` | Main project README | Everyone |
| `QUICK_START.md` | 15-minute setup guide | New users |
| `GETTING_STARTED.md` | Detailed setup | Developers |
| `CLAUDE.md` | AI assistant guide | Claude/AI |
| `LANDING_PAGE.md` | Website content | Marketing |
| `TODO.md` | Remaining tasks | Contributors |
| `REBRAND_SUMMARY.md` | Rebrand changelog | Maintainers |

### AWS Infrastructure

| File | Purpose |
|------|---------|
| `infrastructure/cloudformation-stack.yaml` | Complete AWS infrastructure |
| `infrastructure/deploy.sh` | Deployment script |
| `infrastructure/README.md` | Infrastructure documentation |

---

## Working with Marimo Notebooks

### Structure

Marimo notebooks are Python files with special decorators:

```python
import marimo

__generated_with = "0.9.14"
app = marimo.App()

@app.cell
def __():
    import marimo as mo
    import pandas as pd
    from osrp import OSRPData

    data_access = OSRPData(region='us-west-2')
    return mo, pd, data_access

@app.cell
def __(mo, data_access):
    participants = data_access.get_participant_list()

    user_selector = mo.ui.dropdown(
        options=participants,
        value=participants[0] if participants else None,
        label='Select Participant'
    )

    user_selector
    return user_selector, participants

if __name__ == "__main__":
    app.run()
```

### Key Principles

1. **Reactive by design**: Cells auto-rerun when dependencies change
2. **No cell order**: Dependencies determine execution order
3. **UI elements**: Use `mo.ui.*` for interactive controls
4. **Return values**: Return variables to make them available to other cells

### Running Notebooks

```bash
# Interactive editing
marimo edit daily_behavior_profile.py

# Run as app
marimo run daily_behavior_profile.py

# Export to HTML
marimo export html daily_behavior_profile.py -o output.html
```

---

## Testing Guidelines

### Test Structure

```
tests/
├── __init__.py
├── test_data_access.py       # OSRPData tests
├── test_cli.py                # CLI tests
├── test_aggregator.py         # DataAggregator tests
├── lambda/
│   └── test_handlers.py       # Lambda function tests
└── fixtures/
    └── sample_data.py         # Test data fixtures
```

### Writing Tests

```python
import pytest
from datetime import datetime
from osrp import OSRPData

@pytest.fixture
def data_access():
    """Create OSRPData instance for testing."""
    return OSRPData(region='us-west-2')

def test_get_participant_list(data_access):
    """Test getting participant list."""
    participants = data_access.get_participant_list()
    assert isinstance(participants, list)

def test_get_daily_summary(data_access):
    """Test getting daily summary."""
    daily = data_access.get_daily_summary(
        user_id='test_user_001',
        date=datetime(2026, 1, 15)
    )

    assert 'screenshots' in daily
    assert 'heart_rate' in daily
    assert 'activity' in daily
```

### Running Tests

```bash
# All tests
pytest

# Specific file
pytest tests/test_data_access.py

# Specific test
pytest tests/test_data_access.py::test_get_daily_summary

# With coverage
pytest --cov=osrp --cov-report=html

# Verbose
pytest -v

# Stop on first failure
pytest -x
```

---

## Deployment Checklist

### Pre-Deployment

- [ ] All tests passing: `pytest`
- [ ] Code formatted: `black osrp/`
- [ ] Linting clean: `flake8 osrp/`
- [ ] Type checking: `mypy osrp/`
- [ ] Documentation updated
- [ ] Version bumped in `osrp/__init__.py`

### AWS Deployment

```bash
# 1. Test CloudFormation template
aws cloudformation validate-template \
  --template-body file://infrastructure/cloudformation-stack.yaml

# 2. Deploy to dev environment
osrp deploy --aws --region=us-west-2 --environment=dev

# 3. Verify deployment
osrp status --region=us-west-2

# 4. Run integration tests
pytest tests/integration/

# 5. Deploy to production
osrp deploy --aws --region=us-west-2 --environment=prod
```

### Package Release

```bash
# 1. Update version
# Edit osrp/__init__.py: __version__ = "0.1.0"

# 2. Update CHANGELOG.md
# Add release notes

# 3. Build package
uv pip install build
python -m build

# 4. Test on TestPyPI
uv pip install twine
twine upload --repository testpypi dist/*

# 5. Test installation
uv pip install --index-url https://test.pypi.org/simple/ osrp

# 6. Upload to PyPI
twine upload dist/*

# 7. Tag release
git tag -a v0.1.0 -m "Release v0.1.0"
git push origin v0.1.0
```

---

## Troubleshooting

### Common Issues

**Issue**: `ModuleNotFoundError: No module named 'osrp'`
```bash
# Solution: Install in editable mode
uv pip install -e .
```

**Issue**: `ImportError: cannot import name 'OSRPData'`
```bash
# Solution: Check __init__.py exports, reinstall
uv pip install -e . --force-reinstall
```

**Issue**: Marimo notebooks can't find `osrp` module
```bash
# Solution: Install osrp in same environment as marimo
uv pip install -e .
uv pip install marimo
```

**Issue**: AWS credentials not found
```bash
# Solution: Configure AWS CLI
aws configure
# Or set environment variables:
export AWS_ACCESS_KEY_ID=your_key_id
export AWS_SECRET_ACCESS_KEY=your_secret_key
export AWS_DEFAULT_REGION=us-west-2
```

**Issue**: `uv` command not found
```bash
# Solution: Install uv
curl -LsSf https://astral.sh/uv/install.sh | sh
# Add to PATH if needed
export PATH="$HOME/.cargo/bin:$PATH"
```

---

## Git Workflow

### Branch Naming

- `main` - Production-ready code
- `develop` - Development branch
- `feature/feature-name` - New features
- `bugfix/bug-description` - Bug fixes
- `docs/description` - Documentation updates

### Commit Messages

Follow conventional commits:

```bash
# Format: <type>(<scope>): <subject>

feat(cli): add osrp init command
fix(data): resolve timezone handling in get_daily_summary
docs(readme): update installation instructions
test(data): add tests for align_multi_modal
refactor(cli): simplify deploy command logic
```

Types: `feat`, `fix`, `docs`, `test`, `refactor`, `style`, `chore`

### Pull Request Checklist

- [ ] Tests pass: `pytest`
- [ ] Code formatted: `black osrp/`
- [ ] Linting clean: `flake8 osrp/`
- [ ] Documentation updated
- [ ] CHANGELOG.md updated
- [ ] Descriptive PR title
- [ ] Linked to issue (if applicable)

---

## Resources

### Documentation
- **Main README**: `README.md`
- **Quick Start**: `QUICK_START.md`
- **API Reference**: `analysis/utils/data_access.py` (docstrings)
- **Architecture**: `docs/TECHNICAL_SPECIFICATION.md`

### External Links
- **uv Documentation**: https://github.com/astral-sh/uv
- **Marimo Documentation**: https://docs.marimo.io
- **AWS CloudFormation**: https://docs.aws.amazon.com/cloudformation/
- **Boto3 Documentation**: https://boto3.amazonaws.com/v1/documentation/api/latest/index.html

### Community
- **GitHub**: https://github.com/osrp-platform/osrp
- **Documentation**: https://docs.osrp.io (coming soon)
- **Website**: https://osrp.io (coming soon)

---

## Quick Reference

### Essential Commands

```bash
# Setup
uv venv && source .venv/bin/activate
uv pip sync requirements.txt
uv pip install -e .

# Development
osrp info
osrp init my-study
osrp deploy --aws
osrp notebooks

# Testing
pytest
black osrp/
flake8 osrp/

# Package Management
uv pip install package-name
uv pip freeze > requirements.txt
uv pip sync requirements.txt
```

### Key Imports

```python
# Data access
from osrp import OSRPData, DataAggregator

# Marimo (in notebooks)
import marimo as mo

# AWS
import boto3

# Data science
import pandas as pd
import numpy as np
import plotly.graph_objects as go
```

---

## Notes for Claude

### When Making Changes

1. **Always use `uv`** for Python package operations
2. **Maintain naming conventions** (OSRPData, osrp, etc.)
3. **Update documentation** when changing APIs
4. **Add tests** for new functionality
5. **Format code** with Black before committing
6. **Check imports** work correctly after changes

### When Creating New Files

1. **Add docstrings** to all modules, classes, functions
2. **Include type hints** for function parameters
3. **Follow existing structure** and conventions
4. **Update relevant README** files
5. **Add to TODO.md** if incomplete

### When Debugging

1. **Check virtual environment** is activated
2. **Verify package installed** with `uv pip list`
3. **Test imports** with `python -c "from osrp import OSRPData"`
4. **Check AWS credentials** with `aws sts get-caller-identity`
5. **View logs** in CloudWatch if AWS-related

---

**Last Updated**: January 2026
**Version**: 0.1.0
**Maintainer**: OSRP Contributors
