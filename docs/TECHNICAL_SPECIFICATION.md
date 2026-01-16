# OSRP Technical Specification

**OSRP (Open Sensing Research Platform)** - Complete multi-modal mobile sensing for academic research.

This document provides the complete technical architecture for OSRP, including data models, API specifications, security protocols, and performance requirements.

**Version**: 0.1.0
**Last Updated**: January 15, 2026
**Copyright**: 2026 Scott Friedman and OSRP Contributors
**License**: Apache 2.0

## System Architecture

### Components
1. **Android Application** (Kotlin/Java)
   - Data collection modules
   - Local storage and batching
   - Upload management
   - User interface

2. **AWS Backend**
   - API Gateway (REST endpoints)
   - Lambda (serverless processing)
   - DynamoDB (metadata, events, sensor data)
   - S3 (screenshots, bulk data)
   - Cognito (authentication)
   - CloudWatch (monitoring)

3. **Analysis Backend** (v0.1.0 - ✅ Available)
   - OSRPData class for unified data access
   - Marimo reactive notebooks
   - SageMaker Studio integration
   - DataAggregator for feature extraction

4. **Researcher Dashboard** (Optional - Planned for v0.2.0)
   - Web application for study management
   - Participant monitoring
   - Data export tools

### Technology Stack

**Android App:**
- Language: Kotlin 1.9+
- Min SDK: 26 (Android 8.0)
- Target SDK: 34 (Android 14)
- Architecture: MVVM with Repository pattern
- Key Libraries:
  - Retrofit 2.9+ (networking)
  - Room 2.6+ (local database)
  - Coroutines + Flow (async)
  - WorkManager 2.9+ (background tasks)
  - AWS SDK for Android 2.70+
  - Google Fit API
  - Play Services Location

**AWS Infrastructure:**
- IaC: CloudFormation
- Compute: Lambda (Python 3.11)
- Storage: S3 + DynamoDB
- Auth: Cognito
- API: API Gateway REST
- Monitoring: CloudWatch

**Analysis Tools (Python):**
- Language: Python 3.11+
- Package Manager: uv (fast package installer)
- Data Access: OSRPData class
- Notebooks: Marimo (reactive notebooks)
- Libraries: pandas, numpy, plotly, scikit-learn

**Development Tools:**
- Android Studio Hedgehog+
- AWS CLI v2
- uv (Python package manager)
- Git
- Docker (for local testing)
- Marimo (notebook development)

## Data Model

### DynamoDB Tables

**StudyConfiguration**
```
PK: groupCode (String)
Attributes:
  - studyName: String
  - description: String
  - enabledModules: Map<String, Boolean>
  - samplingRates: Map<String, Number>
  - uploadPolicy: String (wifi_only, always, scheduled)
  - emaSchedules: List<Object>
  - createdAt: Number
  - updatedAt: Number
```

**ParticipantStatus**
```
PK: userId (String)
Attributes:
  - groupCode: String
  - email: String (Cognito)
  - enrolledAt: Number
  - lastSeenTimestamp: Number
  - deviceInfo: Map (model, osVersion, appVersion)
  - dataCollectionStatus: String
  - screenshotCount: Number
  - lastScreenshotTime: Number
  - lastSensorUpload: String
  - batteryOptimizationEnabled: Boolean
  
GSI: groupCode-lastSeen-index (for monitoring)
```

**SensorTimeSeries**
```
PK: userIdSensorType (String) e.g., "user123#accelerometer"
SK: timestamp (Number)
Attributes:
  - groupCode: String
  - data: Map (sensor-specific values)
  - accuracy: Number
  - expirationTime: Number (TTL)
  
GSI: groupCode-timestamp-index
```

**EventLog**
```
PK: userId (String)
SK: timestampEventType (String) e.g., "1705334400000#app_launch"
Attributes:
  - groupCode: String
  - eventType: String
  - eventData: Map
  - context: Map (location, activity, battery, etc.)
  
GSI: groupCode-eventType-index
```

**ScreenshotMetadata**
```
PK: userId (String)
SK: timestamp (Number)
Attributes:
  - groupCode: String
  - s3Key: String
  - s3Bucket: String
  - fileSize: Number
  - appName: String
  - appCategory: String
  - activityType: String (sitting, walking, etc.)
  - location: Map (lat, lon) - if enabled
  - batteryLevel: Number
  - context: Map (other contextual data)
  
GSI: groupCode-timestamp-index
```

**EMAResponse**
```
PK: userId (String)
SK: timestampSurveyId (String)
Attributes:
  - groupCode: String
  - surveyId: String
  - triggerType: String (scheduled, random, context)
  - triggeredAt: Number
  - respondedAt: Number
  - responses: Map<String, Any>
  - context: Map
  
GSI: groupCode-timestamp-index
```

**WearableData**
```
PK: userIdSource (String) e.g., "user123#googlefit"
SK: timestamp (Number)
Attributes:
  - groupCode: String
  - dataType: String (steps, heartRate, sleep, etc.)
  - values: Map
  - source: String
  - expirationTime: Number (TTL)
  
GSI: groupCode-timestamp-index
```

### S3 Structure
```
bucket-name/
├── screenshots/
│   ├── {userId}/
│   │   ├── {timestamp}_{sequence}.png
│   │   └── {timestamp}_{sequence}.png
├── audio/ (optional future)
│   └── {userId}/
│       └── {timestamp}.m4a
├── processed/
│   ├── aggregated/
│   └── ml-features/
└── exports/
    └── {studyId}/
        └── {timestamp}/
```

## API Endpoints

### Authentication
```
POST /auth/register
POST /auth/login
POST /auth/refresh
```

### Configuration
```
GET /config/{groupCode}
```

### Data Upload
```
POST /upload/presigned-url
  Body: { userId, filename, contentType }
  Returns: { uploadUrl, key }

POST /events
  Body: { userId, eventType, eventData, context }

POST /sensor-batch
  Body: { userId, sensorType, readings[] }

POST /wearable-sync
  Body: { userId, source, dataType, values[] }
```

### EMA
```
GET /ema/pending/{userId}
POST /ema/response
  Body: { userId, surveyId, responses, context }
```

### Monitoring (Researcher)
```
GET /participants/status?groupCode={code}
GET /participants/{userId}/summary
```

## Android App Architecture

### Module Structure
```
com.mobilesensing.app/
├── core/
│   ├── auth/
│   │   ├── AuthManager.kt
│   │   └── CognitoClient.kt
│   ├── network/
│   │   ├── ApiService.kt
│   │   ├── S3Uploader.kt
│   │   └── RetrofitBuilder.kt
│   ├── database/
│   │   ├── AppDatabase.kt
│   │   ├── dao/
│   │   └── entities/
│   ├── config/
│   │   ├── StudyConfig.kt
│   │   └── ModuleController.kt
│   └── repository/
│       └── DataRepository.kt
│
├── modules/
│   ├── screenshot/
│   │   ├── ScreenCaptureService.kt
│   │   ├── MediaProjectionManager.kt
│   │   └── ScreenshotProcessor.kt
│   ├── appusage/
│   │   └── AppUsageTracker.kt
│   ├── interaction/
│   │   └── AccessibilityTracker.kt
│   ├── sensors/
│   │   ├── AccelerometerModule.kt
│   │   ├── GyroscopeModule.kt
│   │   ├── LocationModule.kt
│   │   ├── ActivityRecognitionModule.kt
│   │   └── BaseSensorModule.kt
│   ├── wearables/
│   │   ├── GoogleFitModule.kt
│   │   ├── BluetoothHRModule.kt
│   │   └── WearableConnector.kt
│   ├── device/
│   │   ├── BatteryMonitor.kt
│   │   ├── ConnectivityMonitor.kt
│   │   └── DeviceStateCollector.kt
│   └── ema/
│       ├── SurveyEngine.kt
│       ├── TriggerDetector.kt
│       └── NotificationManager.kt
│
├── data/
│   ├── upload/
│   │   ├── UploadManager.kt
│   │   ├── BatchUploader.kt
│   │   └── RetryHandler.kt
│   └── models/
│       ├── SensorReading.kt
│       ├── Event.kt
│       └── Context.kt
│
└── ui/
    ├── MainActivity.kt
    ├── onboarding/
    ├── dashboard/
    └── settings/
```

### Key Interfaces

**BaseSensorModule**
```kotlin
interface BaseSensorModule {
    val sensorType: String
    val samplingRate: Long
    
    fun initialize(context: Context)
    fun startCollection()
    fun stopCollection()
    fun onSensorChanged(values: FloatArray, timestamp: Long)
    fun cleanup()
}
```

**UploadPolicy**
```kotlin
sealed class UploadPolicy {
    object WifiOnly : UploadPolicy()
    object Always : UploadPolicy()
    data class Scheduled(val intervalMinutes: Int) : UploadPolicy()
}
```

**ModuleConfiguration**
```kotlin
data class ModuleConfiguration(
    val screenshot: ScreenshotConfig,
    val appUsage: AppUsageConfig,
    val sensors: SensorConfig,
    val wearables: WearableConfig,
    val ema: EMAConfig
)
```

## Security & Privacy

### Data Protection
- All data encrypted in transit (TLS 1.3)
- S3 encryption at rest (AES-256)
- DynamoDB encryption enabled
- Cognito MFA optional but recommended
- Screenshot local encryption before upload

### Privacy Controls
- Explicit consent for each data type
- Ability to pause/resume collection
- Ability to view collected data
- Data deletion on request
- No PII in logs or analytics

### Compliance
- Uses HIPAA-eligible AWS services (requires proper configuration)
- IRB-ready consent flows
- Data retention policies configurable
- Audit logging enabled
- GDPR-compatible data export

## Python Package (OSRP)

### Package Structure

```
osrp/
├── __init__.py           # Package entry, exports OSRPData
├── cli.py                # CLI commands
└── analysis/
    ├── __init__.py
    └── utils/
        ├── __init__.py
        └── data_access.py  # OSRPData, DataAggregator classes
```

### OSRPData Class

**Purpose**: Unified data access layer for OSRP data in DynamoDB and S3

**Key Methods**:
```python
from osrp import OSRPData

data = OSRPData(region='us-west-2')

# Data access methods
data.get_sensor_data(user_id, sensor_type, start_time, end_time)
data.get_screenshots(user_id, start_time, end_time, load_images=False)
data.get_events(user_id, start_time, end_time, event_type=None)
data.get_wearable_data(user_id, source, start_time, end_time)
data.get_ema_responses(user_id, start_time, end_time, survey_id=None)
data.get_daily_summary(user_id, date)  # All data for one day
data.get_participant_list(group_code=None)

# Analysis helpers
data.compute_screen_time(screenshots_df, threshold_seconds=60)
data.align_multi_modal(dataframes, freq='1min', method='ffill')
```

### DataAggregator Class

**Purpose**: Higher-level aggregations and feature extraction

**Key Methods**:
```python
from osrp import DataAggregator

aggregator = DataAggregator()

# Aggregation methods
aggregator.daily_activity_summary(activity_df, steps_df)
aggregator.app_usage_summary(screenshots_df)
aggregator.context_features(sensor_data, window='5min')
```

### CLI Tool

**Installation**:
```bash
uv pip install osrp
```

**Commands**:
```bash
osrp init <study-name>           # Initialize new study
osrp deploy --aws --region=...   # Deploy infrastructure
osrp notebooks                   # Start Marimo notebooks
osrp status                      # Check deployment status
osrp info                        # Show system information
osrp --version                   # Show version
```

### Marimo Notebooks

**Included Notebooks**:
1. `daily_behavior_profile.py` - Complete daily participant overview
2. `multimodal_analysis.py` - Cross-modal correlation analysis
3. `ml_pipeline_example.py` - End-to-end ML workflow

**Usage**:
```bash
# Start interactive editing
marimo edit daily_behavior_profile.py

# Run as app
marimo run daily_behavior_profile.py

# Export to HTML
marimo export html daily_behavior_profile.py -o output.html
```

## Performance Requirements

### Android App
- Battery drain: <15% per day with full collection
- Memory usage: <150MB average
- Storage: Efficient local caching, automatic cleanup
- Network: Batch uploads, retry logic, exponential backoff
- Crash rate: <0.1%

### AWS Backend
- API latency: <500ms p95
- Upload success rate: >99%
- Data durability: 99.999999999% (S3)
- Concurrent participants: 1000+ per deployment
- Cost: <$5 per participant per month

### Data Collection
- Screenshot capture: <100ms
- Sensor sampling: Configurable (1Hz - 100Hz)
- Data upload latency: <5 minutes (WiFi)
- Context capture: <50ms
