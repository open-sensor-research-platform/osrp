# OSRP AWS Architecture

Visual overview of the OSRP AWS infrastructure.

**Version**: 0.2.0 (MVP)
**Last Updated**: January 16, 2026

---

## High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         Mobile Apps                              │
│                    (Android / iOS / Fire)                        │
└───────────────────────┬─────────────────────────────────────────┘
                        │
                        │ HTTPS
                        │
┌───────────────────────▼─────────────────────────────────────────┐
│                      API Gateway                                 │
│              (REST API + Cognito Authorizer)                     │
│                                                                   │
│  ┌──────────────────┐        ┌───────────────────────────────┐ │
│  │ Auth Endpoints   │        │ Data Endpoints                 │ │
│  │ - /auth/register │        │ - /data/sensor     (protected)│ │
│  │ - /auth/login    │        │ - /data/event      (protected)│ │
│  │ - /auth/refresh  │        │ - /data/device-state (protected)│ │
│  │                  │        │ - /data/presigned-url (protected)│ │
│  └──────────────────┘        └───────────────────────────────┘ │
└─────────┬──────────────────────────────┬───────────────────────┘
          │                              │
          │                              │ Validates ID Token
          │                              │
┌─────────▼────────────┐       ┌─────────▼─────────────────────┐
│  Lambda: Auth        │       │  Cognito Authorizer           │
│  (osrp-auth-dev)     │       │  (validates JWT tokens)       │
│                      │       └─────────┬─────────────────────┘
│  - User registration │                 │
│  - User login        │                 │
│  - Token refresh     │       ┌─────────▼─────────────────────┐
│                      │       │  Lambda: Data Upload          │
│  256 MB / 30s        │       │  (osrp-data-upload-dev)       │
└──────────┬───────────┘       │                               │
           │                   │  - Sensor data upload         │
           │                   │  - Event logging              │
           │                   │  - Device state storage       │
           │                   │  - Presigned URL generation   │
           │                   │                               │
           │                   │  512 MB / 30s                 │
           │                   └──────────┬────────────────────┘
           │                              │
           │                              │
┌──────────▼──────────┐       ┌───────────▼──────────────────────┐
│  Cognito User Pool  │       │  DynamoDB Tables                  │
│                     │       │                                   │
│  - Email auth       │       │  ┌─────────────────────────────┐ │
│  - Password policy  │       │  │ ParticipantStatus           │ │
│  - Email verify     │       │  │ - User enrollment           │ │
│  - Custom attrs:    │       │  │ - Study assignments         │ │
│    • studyCode      │       │  └─────────────────────────────┘ │
│    • participantId  │       │                                   │
│                     │       │  ┌─────────────────────────────┐ │
│  - Token expiry:    │       │  │ SensorTimeSeries            │ │
│    • Access: 1h     │       │  │ - Accelerometer data        │ │
│    • ID: 1h         │       │  │ - GPS data                  │ │
│    • Refresh: 30d   │       │  │ - Gyroscope data            │ │
└─────────────────────┘       │  │ - Heart rate data           │ │
                              │  │ - TTL: 90 days              │ │
                              │  └─────────────────────────────┘ │
                              │                                   │
                              │  ┌─────────────────────────────┐ │
                              │  │ EventLog                    │ │
                              │  │ - App events                │ │
                              │  │ - User interactions         │ │
                              │  │ - TTL: 90 days              │ │
                              │  └─────────────────────────────┘ │
                              │                                   │
                              │  ┌─────────────────────────────┐ │
                              │  │ DeviceState                 │ │
                              │  │ - Device info snapshots     │ │
                              │  │ - TTL: 90 days              │ │
                              │  └─────────────────────────────┘ │
                              └───────────────────────────────────┘
                                              │
                              ┌───────────────▼───────────────────┐
                              │  S3 Buckets                        │
                              │                                   │
                              │  ┌─────────────────────────────┐ │
                              │  │ osrp-data-{env}-{account}   │ │
                              │  │ - Screenshots               │ │
                              │  │ - Large files               │ │
                              │  │ - Lifecycle policies        │ │
                              │  │   • 30d → STANDARD_IA       │ │
                              │  │   • 90d → GLACIER           │ │
                              │  └─────────────────────────────┘ │
                              │                                   │
                              │  ┌─────────────────────────────┐ │
                              │  │ osrp-logs-{env}-{account}   │ │
                              │  │ - Access logs               │ │
                              │  │ - 90-day retention          │ │
                              │  └─────────────────────────────┘ │
                              └───────────────────────────────────┘
                                              │
                              ┌───────────────▼───────────────────┐
                              │  CloudWatch Logs                   │
                              │                                   │
                              │  - API Gateway logs               │
                              │  - Lambda logs (Auth)             │
                              │  - Lambda logs (Data Upload)      │
                              │  - 30-day retention               │
                              └───────────────────────────────────┘
```

---

## Request Flow

### Authentication Flow

```
Mobile App                API Gateway          Lambda (Auth)         Cognito
    │                         │                      │                  │
    │  POST /auth/login       │                      │                  │
    ├────────────────────────>│                      │                  │
    │                         │                      │                  │
    │                         │  Invoke Lambda       │                  │
    │                         ├─────────────────────>│                  │
    │                         │                      │                  │
    │                         │                      │  InitiateAuth    │
    │                         │                      ├─────────────────>│
    │                         │                      │                  │
    │                         │                      │  Tokens          │
    │                         │                      │<─────────────────┤
    │                         │                      │                  │
    │                         │  Return tokens       │                  │
    │                         │<─────────────────────┤                  │
    │                         │                      │                  │
    │  { accessToken,         │                      │                  │
    │    idToken,             │                      │                  │
    │    refreshToken }       │                      │                  │
    │<────────────────────────┤                      │                  │
    │                         │                      │                  │
```

### Data Upload Flow (with Authorization)

```
Mobile App          API Gateway       Cognito Auth       Lambda (Data)    DynamoDB
    │                   │                  │                   │              │
    │  POST /data/sensor│                  │                   │              │
    │  Authorization:   │                  │                   │              │
    │  Bearer {idToken} │                  │                   │              │
    ├──────────────────>│                  │                   │              │
    │                   │                  │                   │              │
    │                   │  Validate token  │                   │              │
    │                   ├─────────────────>│                   │              │
    │                   │                  │                   │              │
    │                   │  Token valid     │                   │              │
    │                   │  + User claims   │                   │              │
    │                   │<─────────────────┤                   │              │
    │                   │                  │                   │              │
    │                   │  Invoke Lambda   │                   │              │
    │                   │  + User context  │                   │              │
    │                   ├──────────────────┴──────────────────>│              │
    │                   │                                      │              │
    │                   │                                      │  PutItem     │
    │                   │                                      ├─────────────>│
    │                   │                                      │              │
    │                   │                                      │  Success     │
    │                   │                                      │<─────────────┤
    │                   │                                      │              │
    │                   │  Success response                    │              │
    │                   │<─────────────────────────────────────┤              │
    │                   │                                      │              │
    │  { message: "...",│                                      │              │
    │    count: 1 }     │                                      │              │
    │<──────────────────┤                                      │              │
    │                   │                                      │              │
```

---

## Data Storage Structure

### DynamoDB Table Schemas

#### ParticipantStatus

```
Partition Key: userId (S)
Sort Key: studyCode (S)

Attributes:
- userId: String (UUID)
- studyCode: String
- enrollmentDate: Number (timestamp)
- status: String (enrolled, active, withdrawn, completed)
- participantId: String (custom participant ID)
- deviceInfo: Map
- lastSyncTime: Number (timestamp)
```

#### SensorTimeSeries

```
Partition Key: userIdSensorType (S) - e.g., "user123#accelerometer"
Sort Key: timestamp (N)

Attributes:
- userIdSensorType: String (composite key)
- timestamp: Number (milliseconds since epoch)
- sensorType: String (accelerometer, gyroscope, gps, heart_rate)
- data: Map (sensor-specific data)
- accuracy: Number
- groupCode: String (studyCode)
- expirationTime: Number (TTL, 90 days from creation)

GSI: groupCode-timestamp-index
- Allows querying by study across all users
```

#### EventLog

```
Partition Key: userId (S)
Sort Key: timestamp (N)

Attributes:
- userId: String (UUID)
- timestamp: Number (milliseconds since epoch)
- eventType: String (app_launch, screen_capture, etc.)
- groupCode: String (studyCode)
- metadata: Map (event-specific data)
- expirationTime: Number (TTL, 90 days from creation)

GSI: groupCode-timestamp-index
```

#### DeviceState

```
Partition Key: userId (S)
Sort Key: timestamp (N)

Attributes:
- userId: String (UUID)
- timestamp: Number (milliseconds since epoch)
- deviceInfo: Map
- batteryLevel: Number
- storageAvailable: Number
- networkType: String
- groupCode: String (studyCode)
- expirationTime: Number (TTL, 90 days from creation)
```

### S3 Bucket Structure

```
osrp-data-{env}-{account}/
├── raw/
│   ├── screenshots/
│   │   ├── {userId}/
│   │   │   ├── {timestamp}-{hash}.png
│   │   │   ├── {timestamp}-{hash}.png
│   │   │   └── ...
│   ├── audio/
│   │   └── {userId}/
│   │       └── {timestamp}-{hash}.mp3
│   └── files/
│       └── {userId}/
│           └── {filename}
├── processed/
│   └── (future: processed data)
└── exports/
    └── (future: data exports for researchers)

osrp-logs-{env}-{account}/
└── access-logs/
    └── {date}/
        └── {timestamp}-{hash}.log
```

---

## Security Architecture

### Authentication & Authorization

```
┌─────────────────────────────────────────────────────────────┐
│                    Security Layers                           │
└─────────────────────────────────────────────────────────────┘

1. Transport Security
   ├── HTTPS enforced by API Gateway
   ├── TLS 1.2+ required
   └── Certificate managed by AWS

2. Authentication (Cognito)
   ├── Email + password
   ├── Password requirements:
   │   ├── Min 8 characters
   │   ├── Uppercase letter
   │   ├── Lowercase letter
   │   ├── Number
   │   └── Special character
   ├── Email verification required
   └── Account lockout after 5 failed attempts

3. Authorization (API Gateway)
   ├── Cognito User Pool Authorizer
   ├── Validates ID token (not access token)
   ├── Token signature verification
   ├── Token expiration check
   └── User context passed to Lambda

4. Data Isolation
   ├── User ID embedded in DynamoDB keys
   ├── S3 paths include user ID
   ├── Lambda validates user owns requested data
   └── Cross-user access prevented

5. Encryption
   ├── In transit: HTTPS/TLS
   ├── At rest: AES-256
   │   ├── DynamoDB: AWS managed keys
   │   ├── S3: AWS managed keys
   │   └── CloudWatch: Default encryption
   └── Cognito: User data encrypted

6. IAM Roles (Least Privilege)
   ├── Lambda Auth Role:
   │   └── cognito-idp:InitiateAuth
   │       cognito-idp:AdminCreateUser
   │       logs:CreateLogStream, PutLogEvents
   │
   └── Lambda Data Upload Role:
       └── dynamodb:PutItem, Query, Scan
           s3:PutObject, GetObject
           logs:CreateLogStream, PutLogEvents
```

### Token Usage

```
After successful login, user receives:

1. Access Token
   - Purpose: AWS service access (not used by OSRP currently)
   - Lifetime: 1 hour
   - Scope: aws.cognito.signin.user.admin

2. ID Token ⭐ (USE THIS FOR API CALLS)
   - Purpose: API authentication
   - Lifetime: 1 hour
   - Contains: user claims (email, studyCode, participantId)
   - Validated by: API Gateway Cognito Authorizer

3. Refresh Token
   - Purpose: Obtain new access/ID tokens
   - Lifetime: 30 days
   - Used with: /auth/refresh endpoint
```

---

## Scalability & Performance

### Current Limits

| Component | Limit | Notes |
|-----------|-------|-------|
| API Gateway | 10,000 req/sec | Burst: 5,000 |
| Lambda (Auth) | 1,000 concurrent | Can be increased |
| Lambda (Data) | 1,000 concurrent | Can be increased |
| DynamoDB | Unlimited | Pay-per-request |
| S3 | Unlimited | 3,500 PUT/s, 5,500 GET/s per prefix |
| Cognito | 50 req/sec (User Pool) | Can be increased |

### Performance Metrics (Tested)

| Operation | Latency | Notes |
|-----------|---------|-------|
| Login | ~1.5s | Includes Cognito auth |
| Sensor upload | ~200ms | DynamoDB write |
| Event log | ~150ms | DynamoDB write |
| Presigned URL | ~50ms | S3 URL generation |
| Lambda cold start | ~500ms | First invocation |
| Lambda warm | ~2-90ms | Subsequent invocations |

### Optimization Strategies

1. **Batching**: Upload sensor data in batches of 10-100 readings
2. **Caching**: Cache ID tokens until expiration
3. **Compression**: Compress data before upload
4. **Offline queue**: Queue data locally, upload when connected
5. **Presigned URLs**: Use for large files (> 1MB) instead of Lambda

---

## Monitoring & Observability

### CloudWatch Metrics

```
┌─────────────────────────────────────────┐
│          CloudWatch Metrics              │
└─────────────────────────────────────────┘

API Gateway:
├── Count (total requests)
├── 4XXError (client errors)
├── 5XXError (server errors)
├── Latency (response time)
└── IntegrationLatency (Lambda execution time)

Lambda:
├── Invocations (function calls)
├── Errors (failed executions)
├── Duration (execution time)
├── Throttles (rate limiting)
└── ConcurrentExecutions (active instances)

DynamoDB:
├── ConsumedReadCapacityUnits
├── ConsumedWriteCapacityUnits
├── UserErrors (client errors)
└── SystemErrors (AWS errors)

Cognito:
├── SignInSuccesses
├── SignInThrottles
├── TokenRefreshSuccesses
└── UserAuthentication
```

### CloudWatch Logs

```
Log Groups:
├── /aws/apigateway/osrp-api-dev
│   ├── Request/response logs
│   ├── Authorization failures
│   └── Integration errors
│
├── /aws/lambda/osrp-auth-dev
│   ├── Authentication attempts
│   ├── User registrations
│   └── Token refreshes
│
└── /aws/lambda/osrp-data-upload-dev
    ├── Data uploads
    ├── S3 operations
    └── DynamoDB operations

Retention: 30 days
Log Level: INFO
```

---

## Disaster Recovery

### Backup Strategy

1. **DynamoDB**
   - Point-in-time recovery enabled
   - Can restore to any point in last 35 days
   - Automated backups

2. **S3**
   - Versioning enabled
   - Can restore previous versions
   - Cross-region replication (optional)

3. **Cognito**
   - No automated backups
   - Export users before major changes
   - Document configuration

### Recovery Procedures

#### Recover Deleted DynamoDB Data

```bash
# Restore to specific timestamp
aws dynamodb restore-table-to-point-in-time \
  --source-table-name osrp-SensorTimeSeries-dev \
  --target-table-name osrp-SensorTimeSeries-dev-restored \
  --restore-date-time 2026-01-15T12:00:00Z \
  --region us-west-2
```

#### Recover Deleted S3 Objects

```bash
# List versions
aws s3api list-object-versions \
  --bucket osrp-data-dev-123456789012 \
  --prefix raw/screenshots/user123/

# Restore specific version
aws s3api copy-object \
  --bucket osrp-data-dev-123456789012 \
  --copy-source osrp-data-dev-123456789012/path/to/file?versionId=xyz \
  --key path/to/file
```

---

## Cost Breakdown (Detailed)

### MVP (10 Participants) - Monthly

```
Service          Usage                      Cost
─────────────────────────────────────────────────
Lambda           30K requests               FREE (< 1M)
                 5 GB-seconds               FREE (< 400K)

API Gateway      30K requests               FREE (< 1M)

DynamoDB         100K writes                FREE (pay-per-request)
                 50K reads                  FREE
                 1 GB storage               FREE (< 25 GB)

S3               2 GB storage               $0.05
                 10K PUT                    $0.01
                 100K GET                   $0.04

Cognito          10 MAU                     FREE (< 50K)

CloudWatch       1 GB logs                  $0.01
                 10 metrics                 FREE

Data Transfer    1 GB out                   FREE (< 100 GB)
─────────────────────────────────────────────────
TOTAL                                       ~$0.11/month
```

### Production (100 Participants) - Monthly

```
Service          Usage                      Cost
─────────────────────────────────────────────────
Lambda           300K requests              $0.40
                 50 GB-seconds              $0.10

API Gateway      300K requests              $1.05

DynamoDB         1M writes @ $1.25/M        $1.25
                 500K reads @ $0.25/M       $0.13
                 10 GB storage @ $0.25/GB   $2.50

S3               20 GB @ $0.023/GB          $0.46
                 (with lifecycle)
                 100K PUT @ $0.005/1K       $0.50
                 1M GET @ $0.0004/1K        $0.40

Cognito          100 MAU                    FREE (< 50K)

CloudWatch       10 GB logs @ $0.50/GB      $0.50
                 100 metrics @ $0.30/metric $0.30

Data Transfer    10 GB out @ $0.09/GB       $0.90
─────────────────────────────────────────────────
TOTAL                                       ~$8.49/month
```

---

## Appendix: Resource Names

### Naming Convention

```
Format: {studyName}-{resourceType}-{environment}

Examples:
- osrp-ParticipantStatus-dev
- osrp-auth-dev
- osrp-data-dev-942542972736
```

### Complete Resource List

```
DynamoDB Tables:
├── osrp-ParticipantStatus-{env}
├── osrp-SensorTimeSeries-{env}
├── osrp-EventLog-{env}
└── osrp-DeviceState-{env}

S3 Buckets:
├── osrp-data-{env}-{account-id}
└── osrp-logs-{env}-{account-id}

Lambda Functions:
├── osrp-auth-{env}
└── osrp-data-upload-{env}

IAM Roles:
├── osrp-auth-lambda-role-{env}
└── osrp-data-upload-lambda-role-{env}

API Gateway:
└── osrp-api-{env}

Cognito:
├── osrp-user-pool-{env}
├── osrp-user-pool-client-{env}
└── osrp-identity-pool-{env}

CloudWatch Log Groups:
├── /aws/lambda/osrp-auth-{env}
├── /aws/lambda/osrp-data-upload-{env}
└── /aws/apigateway/osrp-api-{env}
```

---

**Architecture Version**: 0.2.0 (MVP)
**Last Updated**: January 16, 2026
**Related Documents**: AWS_DEPLOYMENT.md, TECHNICAL_SPECIFICATION.md
