# Changelog

All notable changes to OSRP (Open Sensing Research Platform) will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Planned
- iOS support (limited - no screenshots due to platform restrictions)
- Real-time interventions and just-in-time adaptive interventions (JITAIs)
- Advanced ML pipelines with AutoML support
- Researcher web dashboard for study management
- Multi-study management interface
- Enhanced security features and audit logging

## [0.1.0] - 2026-01-15

### Added
- Initial release of OSRP (Open Sensing Research Platform)
- Core data collection framework for multi-modal mobile sensing
- `OSRPData` class for unified data access to DynamoDB and S3
- `DataAggregator` class for higher-level data aggregations and feature extraction
- CLI tool with commands:
  - `osrp init` - Initialize new study
  - `osrp deploy` - Deploy AWS infrastructure
  - `osrp notebooks` - Start Marimo analysis notebooks
  - `osrp status` - Check deployment status
  - `osrp info` - Display system information
- Python package structure with proper imports
- Three example Marimo notebooks:
  - `daily_behavior_profile.py` - Daily participant overview with screenshots, activity, heart rate
  - `multimodal_analysis.py` - Cross-modal correlation analysis
  - `ml_pipeline_example.py` - End-to-end ML workflow from raw data to model
- Data access methods:
  - `get_sensor_data()` - Time series sensor data (accelerometer, gyroscope, GPS, etc.)
  - `get_screenshots()` - Screenshot metadata and images
  - `get_events()` - Event log data
  - `get_wearable_data()` - Wearable device data (Google Fit, Bluetooth HR)
  - `get_ema_responses()` - Experience sampling method (EMA) survey responses
  - `get_daily_summary()` - Complete daily summary for a participant
  - `get_participant_list()` - List of participants
  - `compute_screen_time()` - Screen usage sessions from screenshots
  - `align_multi_modal()` - Temporal alignment of multiple data streams
- AWS CloudFormation templates for infrastructure deployment:
  - DynamoDB tables (SensorTimeSeries, EventLog, ScreenshotMetadata, EMAResponse, WearableData)
  - S3 buckets with lifecycle policies
  - Lambda functions for data processing
  - API Gateway REST endpoints
  - Cognito user pools for authentication
- Android app templates and module structure (Kotlin, MVVM architecture)
- Comprehensive documentation:
  - PROJECT_BRIEF.md - Project overview and objectives
  - TECHNICAL_SPECIFICATION.md - Complete architecture details
  - IMPLEMENTATION_PLAN.md - Week-by-week development guide
  - TESTING_GUIDE.md - Testing strategies and protocols
  - HARDWARE_RECOMMENDATIONS.md - Development hardware guide
  - QUICK_START.md - 15-minute setup guide
  - CLAUDE.md - AI assistant development guide
  - LANDING_PAGE.md - Website content for osrp.io
- Development tools:
  - `pyproject.toml` configuration for modern Python tooling
  - Black code formatting configuration
  - pytest testing framework setup
  - mypy type checking configuration
- `uv` package manager integration for fast dependency management
- Apache 2.0 license

### Changed
- Rebranded from "Mobile Sensing Platform" to "OSRP (Open Sensing Research Platform)"
- Renamed `MobileSensingData` class to `OSRPData`
- Updated all import paths to use new OSRP naming
- Bucket naming convention: `mobile-sensing-data` → `osrp-data-{study-id}`
- Stack naming convention: `mobile-sensing-{env}` → `osrp-{study}-{env}`

### Technical Details
- **Language**: Python 3.11+
- **Package Manager**: uv (fast Python package installer)
- **AWS Services**: DynamoDB, S3, Lambda, API Gateway, Cognito, SageMaker
- **Analysis Framework**: Marimo (reactive notebooks)
- **Android**: Kotlin 1.9+, Min SDK 26, Target SDK 34, MVVM architecture
- **Dependencies**: boto3, pandas, numpy, plotly, pillow, click, rich

### Known Limitations
- Android-only (iOS support planned for v0.2.0)
- AWS-only deployment (multi-cloud support planned for future)
- No real-time interventions yet (planned for v0.2.0)
- Researcher dashboard not yet implemented (planned for v0.2.0)

## [0.0.1] - 2026-01-01

### Added
- Initial project setup
- Basic project structure
- Proof of concept for data collection modules

---

## Version History

- **0.1.0** (2026-01-15) - Initial public release
- **0.0.1** (2026-01-01) - Internal proof of concept

---

## Semantic Versioning

OSRP follows [Semantic Versioning 2.0.0](https://semver.org/spec/v2.0.0.html):

- **MAJOR** version (X.0.0) - Incompatible API changes
- **MINOR** version (0.X.0) - New functionality in a backward compatible manner
- **PATCH** version (0.0.X) - Backward compatible bug fixes

---

## Types of Changes

- **Added** - New features
- **Changed** - Changes in existing functionality
- **Deprecated** - Soon-to-be removed features
- **Removed** - Removed features
- **Fixed** - Bug fixes
- **Security** - Security vulnerability fixes

---

## Contributing

For information about contributing to OSRP, see CONTRIBUTING.md (coming soon).

To report bugs or request features, please open an issue at:
https://github.com/osrp-platform/osrp/issues

---

**Copyright 2026 Scott Friedman and OSRP Contributors**

Licensed under the Apache License, Version 2.0
