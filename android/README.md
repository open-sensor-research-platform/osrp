# OSRP Android App

Android application for the Open Sensing Research Platform (OSRP).

**Version**: 0.1.0
**Status**: Project setup complete - ready for feature development

---

## Project Structure

```
android/
├── app/
│   ├── src/main/
│   │   ├── java/io/osrp/app/
│   │   │   ├── data/              # Data layer
│   │   │   │   ├── local/         # Local database (Room)
│   │   │   │   ├── remote/        # API services (Retrofit)
│   │   │   │   └── repository/    # Repository implementations
│   │   │   ├── ui/                # UI layer
│   │   │   │   ├── main/          # Main activity
│   │   │   │   ├── auth/          # Authentication screens
│   │   │   │   └── sensors/       # Sensor management screens
│   │   │   ├── util/              # Utility classes
│   │   │   └── OSRPApplication.kt # Application class
│   │   ├── res/                   # Resources
│   │   │   ├── layout/            # XML layouts
│   │   │   ├── values/            # Strings, colors, themes
│   │   │   └── drawable/          # Images and icons
│   │   └── AndroidManifest.xml
│   └── build.gradle.kts           # App module build config
├── gradle/                        # Gradle wrapper
├── build.gradle.kts               # Project build config
└── settings.gradle.kts            # Project settings
```

---

## Architecture

**MVVM (Model-View-ViewModel)** + **Repository Pattern**

```
┌─────────────┐
│     UI      │  Activities, Fragments, Composables
│  (View)     │
└──────┬──────┘
       │
┌──────▼──────────┐
│   ViewModel     │  Holds UI state, business logic
└──────┬──────────┘
       │
┌──────▼──────────┐
│   Repository    │  Single source of truth
└──────┬──────────┘
       │
   ┌───▼───┐
┌──▼───┐ ┌▼────┐
│ API  │ │ DB  │  Data sources
│Remote│ │Local│
└──────┘ └─────┘
```

### Key Components

1. **Data Layer**
   - `remote/`: Retrofit API interfaces and DTOs
   - `local/`: Room database entities and DAOs
   - `repository/`: Repository implementations

2. **UI Layer**
   - Activities and Fragments
   - ViewModels
   - View Binding / Jetpack Compose

3. **Domain Layer** (Future)
   - Use cases
   - Business logic

---

## Tech Stack

### Core
- **Language**: Kotlin 1.9.20
- **Min SDK**: 26 (Android 8.0) - Fire Tablet support
- **Target SDK**: 34 (Android 14)
- **Build Tool**: Gradle 8.2 with Kotlin DSL

### Architecture Components
- **Lifecycle**: ViewModel, LiveData, Lifecycle-aware components
- **Navigation**: Jetpack Navigation (to be added)
- **Data Binding**: View Binding enabled

### Networking
- **Retrofit** 2.9.0 - REST API client
- **OkHttp** 4.12.0 - HTTP client
- **Gson** 2.10.1 - JSON serialization

### Database
- **Room** 2.6.1 - Local SQLite database
- **KSP** - Kotlin Symbol Processing for Room

### Concurrency
- **Kotlin Coroutines** 1.7.3 - Async operations
- **Flow** - Reactive streams

### Background Processing
- **WorkManager** 2.9.0 - Scheduled tasks
- Foreground services for continuous data collection

### Authentication
- **AWS Amplify** 2.14.5 - Cognito integration
- Secure token storage

### Sensors & Location
- **Google Play Services Location** 21.1.0
- Built-in sensor APIs

### UI
- **Material 3** - Modern Material Design
- **Jetpack Compose** - Modern declarative UI (optional)
- **ConstraintLayout** - Flexible layouts

### Testing
- **JUnit** 4.13.2
- **Espresso** 3.5.1
- **Kotlin Coroutines Test** 1.7.3

---

## Setup Instructions

### Prerequisites

1. **Android Studio** Hedgehog (2023.1.1) or later
2. **JDK** 17 or later
3. **Android SDK** with API 34
4. **Git** for version control

### Initial Setup

1. **Clone the repository**
   ```bash
   git clone https://github.com/open-sensor-research-platform/osrp.git
   cd osrp/android
   ```

2. **Open in Android Studio**
   - File → Open → Select `android/` directory
   - Wait for Gradle sync to complete

3. **Configure AWS API endpoint**
   - Edit `app/src/main/java/io/osrp/app/data/remote/RetrofitClient.kt`
   - Update `BASE_URL` with your API Gateway endpoint from AWS deployment

4. **Sync Gradle**
   - Click "Sync Project with Gradle Files" in toolbar
   - Wait for dependencies to download

### Build and Run

```bash
# Build debug APK
./gradlew assembleDebug

# Install on connected device
./gradlew installDebug

# Run tests
./gradlew test
./gradlew connectedAndroidTest
```

---

## Development Workflow

### Creating a New Feature

1. Create feature branch
   ```bash
   git checkout -b feature/sensor-data-collection
   ```

2. Implement feature using MVVM pattern:
   - Add data models in `data/remote/` or `data/local/`
   - Create repository in `data/repository/`
   - Create ViewModel in `ui/{feature}/`
   - Create UI (Activity/Fragment) in `ui/{feature}/`

3. Add tests
   - Unit tests in `test/`
   - Instrumentation tests in `androidTest/`

4. Commit and push
   ```bash
   git add .
   git commit -m "Add sensor data collection"
   git push origin feature/sensor-data-collection
   ```

### Code Style

- Follow [Kotlin Coding Conventions](https://kotlinlang.org/docs/coding-conventions.html)
- Use meaningful variable names
- Add KDoc comments for public APIs
- Keep functions small and focused

---

## Testing

### Unit Tests

Location: `app/src/test/`

```bash
./gradlew test
```

Tests:
- ViewModels
- Repositories
- Utilities

### Instrumentation Tests

Location: `app/src/androidTest/`

```bash
./gradlew connectedAndroidTest
```

Tests:
- UI flows
- Database operations
- API integration

### Device Requirements for Testing

- **Fire Tablet** (primary target)
  - Fire HD 10 (11th Gen) or later
  - Fire OS 8 or later (Android 9+)

- **Google Pixel** (development/testing)
  - Pixel 6 or later
  - Android 12 or later

---

## Permissions

The app requires the following permissions:

### Network
- `INTERNET` - API communication
- `ACCESS_NETWORK_STATE` - Network status

### Location
- `ACCESS_FINE_LOCATION` - GPS data
- `ACCESS_COARSE_LOCATION` - Network location
- `ACCESS_BACKGROUND_LOCATION` - Background tracking

### Sensors
- `BODY_SENSORS` - Heart rate, step counter
- `ACTIVITY_RECOGNITION` - Activity detection

### Storage
- `READ_MEDIA_IMAGES` - Screenshot access (Android 13+)
- `READ_EXTERNAL_STORAGE` - File access (Android 12 and below)

### Background
- `FOREGROUND_SERVICE` - Long-running operations
- `FOREGROUND_SERVICE_DATA_SYNC` - Data sync service
- `FOREGROUND_SERVICE_LOCATION` - Location tracking service
- `RECEIVE_BOOT_COMPLETED` - Auto-start on boot

### Notifications
- `POST_NOTIFICATIONS` - User notifications (Android 13+)

All runtime permissions are requested at appropriate times with clear explanations to users.

---

## Configuration

### API Endpoint

Update in `RetrofitClient.kt`:
```kotlin
private const val BASE_URL = "https://your-api-id.execute-api.us-west-2.amazonaws.com/dev/"
```

### Build Variants

- **Debug**: Development builds with logging enabled
- **Release**: Production builds with ProGuard/R8 optimization

### Signing Configuration (Future)

Create `keystore.properties`:
```
storeFile=/path/to/keystore.jks
storePassword=your-store-password
keyAlias=your-key-alias
keyPassword=your-key-password
```

---

## Troubleshooting

### Gradle Sync Failed

**Issue**: Gradle sync fails after opening project

**Solutions**:
1. File → Invalidate Caches → Restart
2. Clean project: Build → Clean Project
3. Rebuild project: Build → Rebuild Project
4. Check internet connection for dependency downloads

### Build Errors

**Issue**: Build fails with dependency resolution errors

**Solutions**:
1. Update Android Studio to latest version
2. Update Android SDK tools
3. Clear Gradle cache:
   ```bash
   ./gradlew clean
   rm -rf ~/.gradle/caches
   ```

### Cannot Run on Device

**Issue**: App won't install on device

**Solutions**:
1. Enable USB Debugging on device
2. Check device is recognized: `adb devices`
3. Verify min SDK compatibility (device must be Android 8.0+)
4. Uninstall old version if exists

### Retrofit API Errors

**Issue**: Network requests failing with SSL errors

**Solutions**:
1. Verify API endpoint URL is correct
2. Check device has internet connection
3. Ensure AWS API Gateway is deployed and accessible
4. Check authentication tokens are valid

---

## Next Steps

### Immediate (v0.2.0)

- [ ] Implement authentication UI
- [ ] Add Cognito integration
- [ ] Create sensor data collection service
- [ ] Implement local database schema
- [ ] Add WorkManager background sync

### Short-term (v0.3.0)

- [ ] Screenshot capture module
- [ ] Accelerometer data collection
- [ ] GPS location tracking
- [ ] Heart rate monitoring (if available)
- [ ] Battery and device state monitoring

### Medium-term (v0.4.0)

- [ ] Settings screen
- [ ] Data sync status UI
- [ ] Study enrollment flow
- [ ] Notification system
- [ ] Offline queue management

### Long-term (v1.0.0)

- [ ] Experience sampling (EMA) surveys
- [ ] Wearable device integration
- [ ] Data visualization dashboard
- [ ] Multi-study support
- [ ] Advanced privacy controls

---

## Resources

### Documentation
- [Android Developer Guides](https://developer.android.com/guide)
- [Kotlin Documentation](https://kotlinlang.org/docs/home.html)
- [Material Design 3](https://m3.material.io/)
- [Jetpack Compose](https://developer.android.com/jetpack/compose)

### OSRP Documentation
- [Project Brief](../docs/PROJECT_BRIEF.md)
- [Technical Specification](../docs/TECHNICAL_SPECIFICATION.md)
- [AWS Deployment](../docs/AWS_DEPLOYMENT.md)

### Libraries
- [Retrofit](https://square.github.io/retrofit/)
- [Room](https://developer.android.com/training/data-storage/room)
- [Coroutines](https://kotlinlang.org/docs/coroutines-overview.html)
- [WorkManager](https://developer.android.com/topic/libraries/architecture/workmanager)
- [AWS Amplify Android](https://docs.amplify.aws/android/)

---

## Contributing

1. Create a feature branch
2. Make your changes
3. Add tests
4. Ensure all tests pass
5. Submit a pull request

---

## License

Apache 2.0 - See [LICENSE](../LICENSE) file

---

**Android Project Version**: 0.1.0
**OSRP Version**: 0.2.0 (MVP)
**Last Updated**: January 16, 2026
**Maintainer**: OSRP Contributors
