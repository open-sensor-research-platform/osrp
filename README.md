# OSRP - Open Sensing Research Platform

**Complete multi-modal mobile sensing for academic research. Built for AWS. Open source.**

[![License](https://img.shields.io/badge/license-Apache%202.0-blue.svg)](LICENSE)
[![AWS](https://img.shields.io/badge/AWS-Native-orange.svg)](https://aws.amazon.com/)
[![Python](https://img.shields.io/badge/python-3.11+-blue.svg)](https://www.python.org/)

---

## What is OSRP?

OSRP combines screenshots, sensors, and wearables into one comprehensive research platform for digital phenotyping and behavioral research.

### Key Features

✅ **Screenshot Capture** - Behavioral observation (what apps, what content)
✅ **Built-in Sensors** - Accelerometer, GPS, gyroscope, activity recognition
✅ **Wearable Integration** - Google Fit, Bluetooth heart rate monitors
✅ **Experience Sampling** - Context-aware surveys and EMAs
✅ **AWS-Native Infrastructure** - DynamoDB, S3, Lambda, SageMaker
✅ **Marimo Analysis Notebooks** - Reactive, reproducible data analysis
✅ **Open Source** - No licensing fees, full customization

### Why OSRP?

**For Universities:**
- Runs on existing AWS infrastructure
- HIPAA-compliant out of the box
- No vendor lock-in
- Uses AWS agreements you already have
- ~$5 per participant per month

**For Researchers:**
- Multi-modal data temporally aligned
- Configurable for different study designs
- Rich contextual data capture
- Integrated analysis environment (Marimo)
- Publication-ready ML pipelines

---

## Quick Start (5 Minutes)

### Installation

```bash
# Install OSRP Python package
pip install osrp

# Initialize a new study
osrp init my-study --template=ema

# Deploy to AWS
osrp deploy --aws --region=us-west-2

# Start analyzing data
osrp notebooks
```

### What's Included

```
osrp/
├── README.md                          # This file
├── GETTING_STARTED.md                 # Detailed setup guide
├── docs/
│   ├── PROJECT_BRIEF.md              # Project overview
│   ├── TECHNICAL_SPECIFICATION.md    # Complete architecture
│   ├── IMPLEMENTATION_PLAN.md        # Week-by-week development
│   ├── TESTING_GUIDE.md              # Testing protocols
│   └── HARDWARE_RECOMMENDATIONS.md   # Development hardware
├── templates/
│   ├── android_module_template.kt    # Android module templates
│   └── lambda_function_template.py   # Lambda function templates
├── infrastructure/
│   ├── cloudformation-stack.yaml     # AWS infrastructure as code
│   ├── deploy.sh                     # Deployment script
│   └── README.md                     # Infrastructure docs
├── tests/
│   ├── lambda/                       # Lambda tests
│   ├── load/                         # Load testing
│   └── validation/                   # Data validation
├── android/
│   └── templates/                    # Android app templates
└── analysis/                          # ⭐ Analysis Backend
    ├── README.md                     # Analysis guide
    ├── ANALYSIS_ARCHITECTURE.md      # Architecture docs
    ├── infrastructure/
    │   └── sagemaker-cloudformation.md
    ├── notebooks/                    # Marimo notebooks
    │   ├── daily_behavior_profile.py
    │   ├── multimodal_analysis.py
    │   └── ml_pipeline_example.py
    └── utils/
        └── data_access.py            # OSRPData class
```

---

## Analysis with Marimo

OSRP includes powerful analysis tools with reactive Marimo notebooks:

```python
from osrp import OSRPData

# Initialize
data = OSRPData(region='us-west-2')

# Get complete daily summary
daily = data.get_daily_summary('participant001', date)

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

### Example Notebooks Included

1. **Daily Behavior Profile** - Complete participant day view with screenshots, activity, heart rate
2. **Multi-Modal Analysis** - Correlation analysis across behavioral/physiological signals
3. **ML Pipeline** - End-to-end: feature engineering → model training → evaluation

---

## Development Phases

### Phase 1: Foundation (Weeks 1-4)
- AWS infrastructure setup
- Android project structure
- Screenshot module
- App usage & interaction tracking

### Phase 2: Sensor Collection (Weeks 5-8)
- Built-in sensors (accelerometer, GPS, etc.)
- Device state monitoring
- Data pipeline optimization
- Configuration system

### Phase 3: Wearables & EMA (Weeks 9-12)
- Google Fit integration
- Bluetooth wearables
- Experience sampling method (EMA)
- Context-aware triggers

### Phase 4: Testing & Deployment (Weeks 13-16)
- Comprehensive testing
- Documentation
- Pilot study
- Production preparation

### Phase 5: Analysis Backend (Parallel)
- SageMaker Studio deployment
- Marimo notebook environment
- Data access layer (OSRPData)
- Example analysis workflows
- ML pipeline templates

---

## Technology Stack

**Android App:**
- Kotlin 1.9+
- Min SDK 26, Target SDK 34
- MVVM Architecture
- Retrofit, Room, Coroutines, WorkManager
- AWS Android SDK

**AWS Backend:**
- CloudFormation (Infrastructure as Code)
- Lambda (Python 3.11)
- DynamoDB (NoSQL database)
- S3 (Object storage)
- Cognito (Authentication)
- API Gateway (REST API)
- SageMaker (Analysis environment)

**Analysis Tools:**
- Marimo (Reactive notebooks)
- Pandas, NumPy (Data manipulation)
- Plotly (Visualization)
- scikit-learn, PyTorch (Machine learning)
- PIL, OpenCV (Image processing)

---

## OSRP vs Other Platforms

|  | AWARE | Screenomics | Centralive | LAMP | Beiwe | **OSRP** |
|---|---|---|---|---|---|---|
| Screenshots | ❌ | ✅ | ❌ | ❌ | ❌ | **✅** |
| Sensors | ✅ | ❌ | ⚠️ | ✅ | ✅ | **✅** |
| Wearables | ❌ | ❌ | ✅ | ⚠️ | ❌ | **✅** |
| EMA System | ⚠️ | ❌ | ✅ | ✅ | ✅ | **✅** |
| AWS Native | ❌ | ❌ | ❌ | ❌ | ❌ | **✅** |
| Analysis Tools | ❌ | ⚠️ | ⚠️ | ⚠️ | ❌ | **✅✅** |
| Marimo Notebooks | ❌ | ❌ | ❌ | ❌ | ❌ | **✅** |
| Open Source | ✅ | ✅ | ❌ | ✅ | ✅ | **✅** |

**OSRP is the only platform with all modalities + AWS + integrated analysis.**

---

## Cost Estimates

**Development:**
- AWS: ~$50-100/month during development
- Hardware: $1,200-3,500 (see HARDWARE_RECOMMENDATIONS.md)

**Production (per 100 participants):**
- AWS: ~$300-500/month
- Scales linearly with participant count
- No per-participant licensing fees

---

## Use Cases

### Digital Phenotyping
- Depression and anxiety research
- Bipolar disorder monitoring
- Sleep and circadian rhythm studies
- Stress and burnout assessment

### Behavioral Research
- Social media impact studies
- Screen time and wellbeing
- App usage patterns
- Digital intervention effectiveness

### Multi-Modal Studies
- Physical activity and mental health
- Sleep quality and performance
- Heart rate variability and stress
- Location and social behavior

---

## Prerequisites

**For Development:**
- MacBook Pro or Linux workstation (16GB+ RAM)
- Android Studio Hedgehog or later
- AWS account with admin access
- AWS CLI v2 installed
- Git

**For Testing:**
- Android devices (recommended: Pixel 8, Galaxy S23)
- Bluetooth heart rate monitor (e.g., Polar H10)
- Fitness tracker with Google Fit support
- Test AWS account separate from production

---

## Getting Started

1. **Read Documentation**: Start with `docs/PROJECT_BRIEF.md`
2. **Set Up AWS**: Deploy infrastructure with `infrastructure/deploy.sh`
3. **Order Hardware**: See `docs/HARDWARE_RECOMMENDATIONS.md`
4. **Follow Plan**: Week-by-week guide in `docs/IMPLEMENTATION_PLAN.md`
5. **Build with Claude Code**: Use templates and specifications

---

## Community & Support

- **Website**: [osrp.io](https://osrp.io)
- **Documentation**: [docs.osrp.io](https://docs.osrp.io)
- **GitHub**: [github.com/osrp-platform/osrp](https://github.com/osrp-platform/osrp)
- **Demo**: [demo.osrp.io](https://demo.osrp.io)

---

## License

Apache License 2.0 - See LICENSE for details

---

## Citation

If you use OSRP in your research, please cite:

```bibtex
@software{osrp2026,
  title = {OSRP: Open Sensing Research Platform},
  author = {OSRP Contributors},
  year = {2026},
  url = {https://github.com/osrp-platform/osrp}
}
```

---

## Acknowledgments

OSRP builds on research from:
- Stanford Screenomics (screenshot capture methodology)
- AWARE Framework (sensor collection patterns)
- AWS architecture best practices
- Marimo (reactive notebook framework)

---

**Ready to start? Read [GETTING_STARTED.md](GETTING_STARTED.md) for detailed setup instructions.**
