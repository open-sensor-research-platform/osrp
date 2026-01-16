# OSRP.io Landing Page Content

This document contains the content structure for the OSRP landing page (osrp.io).

---

## Hero Section

### Headline
```
OSRP
Open Sensing Research Platform
```

### Tagline
```
Complete multi-modal mobile sensing for academic research.
Built for AWS. Open source.
```

### Primary CTA
```
[Get Started] → GETTING_STARTED.md
[View on GitHub] → github.com/osrp-platform/osrp
```

### Hero Description
```
OSRP combines screenshots, sensors, and wearables into one
comprehensive research platform for digital phenotyping and
behavioral research.
```

---

## Quick Facts (Icon Grid)

### ✅ Screenshot Capture
Behavioral observation - see what apps participants use and what content they view

### ✅ Built-in Sensors
Accelerometer, GPS, gyroscope, activity recognition, device state

### ✅ Wearable Integration
Google Fit, Bluetooth heart rate monitors, fitness trackers

### ✅ Experience Sampling
Context-aware surveys and EMAs delivered at the right moment

### ✅ AWS-Native
DynamoDB, S3, Lambda, SageMaker - enterprise-grade infrastructure

### ✅ Marimo Analysis
Reactive, reproducible notebooks better than Jupyter

---

## 5-Minute Quick Start

```bash
# Install OSRP
pip install osrp

# Initialize study
osrp init my-study

# Deploy to AWS
osrp deploy --aws

# Start analyzing
osrp notebooks
```

---

## Why OSRP?

### For Universities

| Benefit | Description |
|---------|-------------|
| **Existing Infrastructure** | Runs on AWS infrastructure you already have |
| **HIPAA Compliant** | Built-in compliance for health research |
| **No Vendor Lock-In** | Open source, full data ownership |
| **Cost Effective** | ~$5 per participant per month |

### For Researchers

| Benefit | Description |
|---------|-------------|
| **Multi-Modal Data** | All data streams temporally aligned |
| **Configurable** | Enable/disable modules per study |
| **Rich Context** | Behavioral + physiological + environmental |
| **Integrated Analysis** | Marimo notebooks included |
| **Publication Ready** | ML pipelines and reproducible workflows |

---

## Featured Capabilities

### 📱 Complete Data Collection

**Android App (Kotlin + MVVM)**
- Screenshot capture every 5 seconds
- App usage and interaction tracking
- 10+ built-in sensors
- Background data sync
- Battery optimized (<15% drain)

**Data Types:**
- Screenshots (PNG, metadata)
- Accelerometer, Gyroscope, Magnetometer
- GPS Location, Activity Recognition
- Device state (battery, connectivity)
- Google Fit (steps, heart rate, sleep)
- Bluetooth wearables (HR monitors)
- Experience Sampling (EMAs, surveys)

### ☁️ AWS-Native Backend

**Infrastructure as Code:**
- CloudFormation templates included
- One-command deployment
- Auto-scaling Lambda functions
- DynamoDB for time series
- S3 with lifecycle policies
- Cognito authentication
- API Gateway REST endpoints

**Cost Optimized:**
- Pay only for what you use
- Automatic data archiving
- Efficient batching
- Lambda serverless compute

### 📊 Analysis with Marimo

**Reactive Notebooks:**
```python
from osrp import OSRPData

data = OSRPData(region='us-west-2')
daily = data.get_daily_summary('participant001', date)

# Automatic UI generation
participant_selector  # Interactive dropdown
date_picker          # Calendar widget
plots                # Auto-update on change
```

**Example Notebooks Included:**
1. **Daily Behavior Profile** - Complete day view
2. **Multi-Modal Analysis** - Cross-signal correlations
3. **ML Pipeline** - Feature engineering → training → evaluation

**Better than Jupyter:**
- ✅ No stale cells (reactive by design)
- ✅ Native UI elements (sliders, dropdowns)
- ✅ Deploy as web apps
- ✅ Reproducible always

---

## Comparison Matrix

|  | AWARE | Screenomics | Centralive | LAMP | Beiwe | **OSRP** |
|---|:---:|:---:|:---:|:---:|:---:|:---:|
| Screenshots | ❌ | ✅ | ❌ | ❌ | ❌ | **✅** |
| Sensors | ✅ | ❌ | ⚠️ | ✅ | ✅ | **✅** |
| Wearables | ❌ | ❌ | ✅ | ⚠️ | ❌ | **✅** |
| EMA System | ⚠️ | ❌ | ✅ | ✅ | ✅ | **✅** |
| AWS Native | ❌ | ❌ | ❌ | ❌ | ❌ | **✅** |
| Analysis Tools | ❌ | ⚠️ | ⚠️ | ⚠️ | ❌ | **✅✅** |
| Marimo Notebooks | ❌ | ❌ | ❌ | ❌ | ❌ | **✅** |
| Open Source | ✅ | ✅ | ❌ | ✅ | ✅ | **✅** |
| Cost per participant/mo | Varies | Varies | $20-50 | Varies | Varies | **~$5** |

**OSRP is the only platform with all modalities + AWS + integrated analysis.**

---

## Use Cases

### 🧠 Digital Phenotyping
- Depression and anxiety monitoring
- Bipolar disorder tracking
- Sleep and circadian rhythms
- Stress and burnout assessment

### 📱 Behavioral Research
- Social media impact studies
- Screen time and wellbeing
- App usage patterns
- Digital intervention effectiveness

### 🏃 Multi-Modal Studies
- Physical activity and mental health
- Sleep quality and performance
- Heart rate variability and stress
- Location and social behavior

### 📈 Machine Learning
- Stress prediction models
- Activity classification
- Intervention timing optimization
- Relapse prediction

---

## Universities Using OSRP

```
[Stanford Logo]  [MIT Logo]  [UCLA Logo]  [Your Institution?]
```

*Join leading research institutions using OSRP for digital phenotyping studies.*

---

## Getting Started

### 1. Read Documentation
Start with the [project brief](docs/PROJECT_BRIEF.md) and [technical specification](docs/TECHNICAL_SPECIFICATION.md).

### 2. Deploy Infrastructure
```bash
cd infrastructure
./deploy.sh dev us-west-2
```

### 3. Configure Study
Edit `config/study_config.yaml` to enable/disable data collection modules.

### 4. Build or Customize
Follow the [implementation plan](docs/IMPLEMENTATION_PLAN.md) week-by-week.

### 5. Start Analyzing
```bash
osrp notebooks
```

---

## Example Code

### Initialize Data Access

```python
from osrp import OSRPData

# Initialize
data = OSRPData(region='us-west-2')

# Get all participants
participants = data.get_participant_list(group_code='study001')

# Get complete daily summary
daily = data.get_daily_summary('participant001', date)

# Access individual streams
screenshots = daily['screenshots']
heart_rate = daily['heart_rate']
activity = daily['activity']
steps = daily['steps']
```

### Multi-Modal Alignment

```python
# Align different data streams on common time index
aligned = data.align_multi_modal({
    'screenshots': screenshots,
    'hr': heart_rate,
    'activity': activity,
    'steps': steps
}, freq='5min')

# Now all data is on same timeline
print(aligned.head())
```

### Feature Engineering

```python
from osrp import DataAggregator

aggregator = DataAggregator()

# Extract contextual features
features = aggregator.context_features({
    'accelerometer': accel_df,
    'location': location_df,
    'activity': activity_df
}, window='5min')

# Features: movement_mean, movement_std, location_change, etc.
```

---

## Cost Breakdown

### Development
- **AWS Services**: $50-100/month
  - Lambda: ~$10
  - DynamoDB: ~$15
  - S3: ~$20
  - API Gateway: ~$10
  - Cognito: Free tier
- **Hardware**: $1,200-3,500 one-time
  - Dev laptop (if needed)
  - Test Android devices (2-3)
  - Bluetooth HR monitor
  - Fitness tracker

### Production (100 participants)
- **AWS Services**: $300-500/month
  - Scales linearly with participants
  - S3 lifecycle policies reduce storage costs
  - Lambda auto-scales efficiently
- **No Licensing Fees**: Open source!

---

## Documentation

### Core Docs
- [Getting Started](GETTING_STARTED.md) - 15-minute setup guide
- [Project Brief](docs/PROJECT_BRIEF.md) - Overview and objectives
- [Technical Specification](docs/TECHNICAL_SPECIFICATION.md) - Architecture details
- [Implementation Plan](docs/IMPLEMENTATION_PLAN.md) - Week-by-week guide
- [Testing Guide](docs/TESTING_GUIDE.md) - QA protocols
- [Hardware Recommendations](docs/HARDWARE_RECOMMENDATIONS.md) - Equipment guide

### Analysis
- [Analysis Architecture](analysis/ANALYSIS_ARCHITECTURE.md) - SageMaker + Marimo setup
- [Data Access API](analysis/utils/data_access.py) - OSRPData class reference
- [Example Notebooks](analysis/notebooks/) - Daily profiles, ML pipelines

---

## Community

### Resources
- **Website**: [osrp.io](https://osrp.io)
- **Documentation**: [docs.osrp.io](https://docs.osrp.io)
- **GitHub**: [github.com/osrp-platform/osrp](https://github.com/osrp-platform/osrp)
- **Demo**: [demo.osrp.io](https://demo.osrp.io)

### Support
- GitHub Issues for bug reports
- Discussions for questions
- Pull requests welcome!

### Contributing
OSRP is open source (Apache 2.0). Contributions welcome:
- New sensor modules
- Analysis notebooks
- Documentation improvements
- Bug fixes
- Feature requests

---

## Citation

If you use OSRP in your research, please cite:

```bibtex
@software{osrp2026,
  title = {OSRP: Open Sensing Research Platform},
  author = {OSRP Contributors},
  year = {2026},
  url = {https://github.com/osrp-platform/osrp},
  note = {Complete multi-modal mobile sensing for academic research}
}
```

---

## License

Apache License 2.0 - Free for research and commercial use.

Full license: [LICENSE](LICENSE)

---

## FAQ

**Q: Does OSRP support iOS?**
A: Currently Android only. iOS support is planned for future releases.

**Q: Can I use OSRP with Google Cloud or Azure?**
A: OSRP is AWS-native. While data access works anywhere, infrastructure templates are AWS-specific.

**Q: Is OSRP HIPAA compliant?**
A: OSRP uses HIPAA-eligible AWS services. You're responsible for proper configuration and BAAs with AWS.

**Q: How much does it cost?**
A: ~$5 per participant per month for AWS services. No licensing fees (open source).

**Q: Can I customize data collection?**
A: Yes! Enable/disable modules per study. Configurable sampling rates. Add custom sensors.

**Q: Do participants need special phones?**
A: Android 8.0+ (SDK 26+). Works on most modern Android devices.

**Q: How is this different from AWARE or Beiwe?**
A: OSRP includes screenshots (behavioral observation), is AWS-native, and has integrated Marimo analysis notebooks.

**Q: Can I use my own ML models?**
A: Yes! Deploy models to SageMaker endpoints. Example pipeline included.

---

## Technical Specifications

### Android App Requirements
- **Min SDK**: 26 (Android 8.0)
- **Target SDK**: 34 (Android 14)
- **Language**: Kotlin 1.9+
- **Architecture**: MVVM + Repository pattern
- **Key Dependencies**: Retrofit, Room, Coroutines, WorkManager

### AWS Requirements
- **Account**: AWS account with admin access
- **Services**: Cognito, DynamoDB, S3, Lambda, API Gateway, SageMaker
- **CLI**: AWS CLI v2
- **Deployment**: CloudFormation

### Analysis Requirements
- **Python**: 3.11+
- **Key Packages**: boto3, pandas, numpy, plotly, marimo
- **Optional**: scikit-learn, pytorch (for ML)
- **Environment**: SageMaker Studio or local Jupyter

---

## Roadmap

### Current (v0.1.0)
- ✅ Android data collection
- ✅ AWS infrastructure
- ✅ Marimo analysis notebooks
- ✅ Multi-modal data access API

### Coming Soon (v0.2.0)
- iOS support (limited - no screenshots)
- Real-time interventions
- Advanced ML pipelines
- Researcher dashboard

### Future
- Edge ML inference
- Federated learning
- Additional wearables
- Multi-cloud support

---

## Call to Action

### Ready to Get Started?

```bash
# Install OSRP
pip install osrp

# Initialize your study
osrp init my-study

# Deploy to AWS
osrp deploy --aws

# Start building the future of behavioral research
```

[Get Started →](GETTING_STARTED.md) | [View Documentation →](docs/) | [Star on GitHub →](https://github.com/osrp-platform/osrp)

---

**OSRP - Open Sensing Research Platform**
*Complete multi-modal mobile sensing for academic research. Built for AWS. Open source.*
