# OSRP Development Setup

## Overview

This guide covers setting up your development environment for building OSRP on macOS with the devices you have available.

---

## Your Setup

- **Development Machine**: MacBook (macOS)
- **Test Devices**:
  - Fire Tablet (Android-based, for initial testing)
  - iPhone (iOS, limited data collection capabilities)

---

## Android Development on macOS

### 1. Install Android Studio

```bash
# Option 1: Download from website
# Visit: https://developer.android.com/studio
# Download Android Studio for macOS (Apple Silicon or Intel)

# Option 2: Using Homebrew
brew install --cask android-studio
```

**First Launch**:
1. Open Android Studio
2. Follow setup wizard
3. Install Android SDK
4. Install Android SDK Platform-Tools
5. Install Android Emulator (optional)

### 2. Install Required SDKs

In Android Studio:
1. Go to **Settings** → **Languages & Frameworks** → **Android SDK**
2. Install these SDK platforms:
   - Android 8.0 (Oreo) - API 26 (minimum)
   - Android 14 - API 34 (target)
3. Switch to **SDK Tools** tab
4. Install:
   - Android SDK Build-Tools
   - Android Emulator
   - Android SDK Platform-Tools
   - Google Play Services (for eventual Google Fit integration)

### 3. Set Up Environment Variables

Add to your `~/.zshrc` or `~/.bash_profile`:

```bash
# Android SDK
export ANDROID_HOME=$HOME/Library/Android/sdk
export PATH=$PATH:$ANDROID_HOME/emulator
export PATH=$PATH:$ANDROID_HOME/platform-tools
export PATH=$PATH:$ANDROID_HOME/tools
export PATH=$PATH:$ANDROID_HOME/tools/bin

# Reload shell
source ~/.zshrc  # or source ~/.bash_profile
```

### 4. Verify Installation

```bash
# Check Android SDK
adb version

# Should show: Android Debug Bridge version X.X.X

# Check Java (bundled with Android Studio)
which java
```

---

## Fire Tablet Setup for Development

### About Fire OS

Fire OS is Amazon's customized version of Android:
- **Pros**: Can run Android apps, has sensors, good for initial testing
- **Cons**: No Google Play Services, some features may work differently

### Enable Developer Mode

1. **Settings** → **Device Options** → **About Fire Tablet**
2. Tap **Serial Number** 7 times (enables Developer Options)
3. Go back to **Device Options** → **Developer Options**
4. Enable:
   - **USB debugging**
   - **Stay awake** (keeps screen on while charging)
   - **Install via USB** (allows sideloading)

### Connect to macOS

```bash
# Connect Fire Tablet via USB

# Check if device is recognized
adb devices

# Should show:
# List of devices attached
# XXXXXXXXXXXXX   device

# If not recognized:
# 1. Install/update drivers
# 2. Try different USB cable
# 3. Revoke and re-authorize USB debugging on tablet
```

### Install APK on Fire Tablet

```bash
# Build APK in Android Studio
# Build → Build Bundle(s) / APK(s) → Build APK(s)

# Install on Fire Tablet
adb install -r app/build/outputs/apk/debug/app-debug.apk

# View logs
adb logcat | grep OSRP
```

### Fire Tablet Limitations

**Will Work:**
- ✅ Screenshots (core OSRP feature)
- ✅ App usage tracking
- ✅ Built-in sensors (accelerometer, gyroscope, etc.)
- ✅ Location (GPS)
- ✅ Device state monitoring
- ✅ Battery monitoring

**Won't Work (initially):**
- ❌ Google Fit (no Google Play Services)
- ❌ Some wearable integrations
- ⚠️ Bluetooth HR monitors (may work but test required)

**Workaround**: Focus on core features first (screenshots, sensors, app usage). Add Google Fit support later when you get an Android phone.

---

## iOS Development (Limited)

### What iOS Can Collect

Due to iOS privacy restrictions, OSRP on iOS will be very limited:

**Possible:**
- ✅ HealthKit data (steps, heart rate, sleep - if user grants permission)
- ✅ Screen time data (via Screen Time API - limited)
- ✅ Motion sensors (accelerometer, gyroscope - with permission)
- ✅ Location (with permission)
- ✅ Experience sampling (surveys/EMAs)

**Not Possible:**
- ❌ Screenshots (iOS doesn't allow apps to capture screen)
- ❌ App usage details (very limited API)
- ❌ Detailed interaction tracking
- ❌ Background data collection (heavily restricted)

### iOS Development Setup

If you want to explore iOS:

```bash
# Xcode (required for iOS development)
# Install from App Store (free)

# iOS requires:
# - Swift or Objective-C
# - Different architecture than Android
# - Separate 16-week implementation plan
```

**Recommendation**: Focus on Android first. iOS can be v0.3.0 or later.

---

## Recommended Development Workflow

### Phase 1: Mac + Fire Tablet (Now)

1. **Develop on macOS**
   - Install Android Studio
   - Write code in Kotlin
   - Use Android Emulator for quick testing

2. **Test on Fire Tablet**
   - Basic functionality testing
   - Screenshot capture (critical feature)
   - Sensor data collection
   - App usage tracking

3. **Skip Google Fit for now**
   - Can add later when you get Android phone
   - Focus on core OSRP features

### Phase 2: Get Android Phone (Later)

Once you secure an Android phone:

1. **Test Google Fit integration**
2. **Test on real Android device** (better than Fire OS)
3. **Test all wearable features**
4. **Production testing**

### Phase 3: iOS Exploration (Future)

If there's interest:
1. Build limited iOS version
2. HealthKit integration
3. Basic sensor collection
4. No screenshots (iOS limitation)

---

## Project Structure for Android

```
osrp/
├── android/                    # Android app
│   ├── app/
│   │   ├── src/
│   │   │   ├── main/
│   │   │   │   ├── kotlin/
│   │   │   │   │   └── io/osrp/app/
│   │   │   │   │       ├── MainActivity.kt
│   │   │   │   │       ├── modules/
│   │   │   │   │       │   ├── screenshot/
│   │   │   │   │       │   ├── sensors/
│   │   │   │   │       │   ├── appusage/
│   │   │   │   │       │   └── wearables/
│   │   │   │   │       ├── data/
│   │   │   │   │       └── ui/
│   │   │   │   ├── res/
│   │   │   │   └── AndroidManifest.xml
│   │   │   └── build.gradle
│   │   └── build.gradle
│   └── gradle/
```

---

## Quick Start: First Android App

### 1. Create New Project

1. Open Android Studio
2. **File** → **New** → **New Project**
3. Select **Empty Activity**
4. Configure:
   - Name: `OSRP`
   - Package name: `io.osrp.app`
   - Save location: `/Users/scttfrdmn/src/osrp/osrp/android`
   - Language: **Kotlin**
   - Minimum SDK: **API 26 (Android 8.0)**
   - Build configuration language: **Kotlin DSL**

### 2. Connect Fire Tablet

```bash
# Enable USB debugging on Fire Tablet (see above)

# Connect via USB
adb devices

# Should show your device
```

### 3. Run Hello World

1. Click **Run** button (green play icon)
2. Select your Fire Tablet as target
3. App will install and launch

### 4. View Logs

```bash
adb logcat | grep OSRP
```

---

## Testing Without Physical Devices

### Android Emulator

Android Studio includes emulators:

1. **Tools** → **Device Manager**
2. **Create Device**
3. Choose hardware (e.g., Pixel 6)
4. Download system image (API 34 recommended)
5. Launch emulator

**Limitations:**
- Emulator sensors are simulated
- No real sensor data
- Good for UI testing
- Bad for sensor/data collection testing

**Recommendation**: Use emulator for UI work, Fire Tablet for real testing.

---

## Kotlin Crash Course for OSRP

If you're new to Kotlin:

```kotlin
// Basic OSRP module structure
class ScreenshotModule(private val context: Context) {

    private var isCapturing = false

    fun startCapture() {
        if (isCapturing) return

        isCapturing = true
        // Screenshot capture logic
    }

    fun stopCapture() {
        isCapturing = false
    }

    private fun captureScreen() {
        // Implementation
    }
}

// Use in Activity
class MainActivity : AppCompatActivity() {

    private lateinit var screenshotModule: ScreenshotModule

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)

        screenshotModule = ScreenshotModule(this)
        screenshotModule.startCapture()
    }
}
```

---

## Development Tools

### Recommended

- **Android Studio**: Primary IDE
- **Kotlin**: Primary language
- **Git**: Version control (already using)
- **Postman**: Test AWS API endpoints
- **Charles Proxy**: Debug network traffic

### Optional

- **Scrcpy**: Mirror Fire Tablet screen to Mac
  ```bash
  brew install scrcpy
  scrcpy
  ```

- **Vysor**: Alternative screen mirror (Chrome extension)

---

## Cost Considerations

### Current Setup (Free)
- ✅ Android Studio: Free
- ✅ macOS development: Already have
- ✅ Fire Tablet: Already have
- ✅ Android Emulator: Free

### Future Needs
- 📱 Android phone: $100-300 (for production testing)
  - Recommended: Pixel 6a or similar (good sensor quality)
  - Used/refurbished is fine
  - Unlocked device preferred

- 💻 AWS costs: ~$50-100/month during development
  - Can use AWS Free Tier initially

---

## Next Steps

1. **Install Android Studio** on your Mac
2. **Enable Developer Mode** on Fire Tablet
3. **Connect and verify** Fire Tablet with `adb devices`
4. **Create initial Android project** following structure above
5. **Follow implementation plan** (docs/IMPLEMENTATION_PLAN.md)
   - Week 1: AWS infrastructure (can do on Mac)
   - Week 2: Android project structure
   - Week 3: Screenshot module (critical to test on Fire Tablet)
   - Week 4+: Continue building features

---

## Troubleshooting

### Fire Tablet not recognized

```bash
# Check USB cable (try different one)
# Revoke USB debugging authorization on tablet
# Settings → Developer Options → Revoke USB debugging authorizations
# Then reconnect and re-authorize

# Check ADB
adb kill-server
adb start-server
adb devices
```

### Android Studio slow on Mac

```bash
# Increase memory allocation
# Android Studio → Settings → Appearance & Behavior → System Settings → Memory Settings
# Set IDE heap size to 4096 MB (if you have 16GB+ RAM)
```

### Fire OS compatibility issues

If something doesn't work on Fire OS:
1. Test on Android Emulator
2. Document the issue
3. Note it as Fire OS limitation
4. Will work on real Android phones

---

## Resources

- **Android Developer Docs**: https://developer.android.com/
- **Kotlin Documentation**: https://kotlinlang.org/docs/home.html
- **Fire OS Documentation**: https://developer.amazon.com/docs/fire-tablets/ft-intro.html
- **OSRP Implementation Plan**: docs/IMPLEMENTATION_PLAN.md

---

**Ready to start?** Install Android Studio and create your first OSRP Android project!
