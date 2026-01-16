# OSRP iOS App

iOS application for the Open Sensing Research Platform (OSRP).

## Overview

The OSRP iOS app collects health and sensor data from iOS devices for academic research studies. It features:

- **HealthKit Integration**: Collects health data (steps, heart rate, activity, etc.)
- **AWS Cognito Authentication**: Secure user authentication
- **Local Data Storage**: Core Data for offline data persistence
- **Automatic Upload**: Background upload to AWS infrastructure
- **Real-time Dashboard**: Status monitoring and control interface

## Requirements

- **Xcode**: 15.0 or later
- **iOS**: 15.0 or later
- **Swift**: 5.9 or later
- **Device**: iPhone or iPad with HealthKit support

## Project Structure

```
ios/OSRP/OSRP/
├── OSRPApp.swift              # App entry point
├── Info.plist                 # App configuration and permissions
├── Views/
│   ├── ContentView.swift      # Placeholder view
│   ├── LoginView.swift        # Login screen
│   └── MainView.swift         # Main dashboard
├── ViewModels/
│   ├── AuthViewModel.swift    # Authentication state management
│   └── StatusViewModel.swift  # Dashboard state management
├── Services/
│   ├── AuthService.swift      # Cognito authentication
│   ├── DataService.swift      # HealthKit data collection
│   └── UploadService.swift    # AWS upload service
├── Models/                    # Data models (to be added)
└── Utilities/                 # Helper utilities (to be added)
```

## Architecture

The iOS app follows the **MVVM (Model-View-ViewModel)** architecture pattern:

- **Models**: Data structures and Core Data entities
- **Views**: SwiftUI views for the user interface
- **ViewModels**: Business logic and state management (using `@Published` and Combine)
- **Services**: API and data access layer

## Setup

### 1. Clone Repository

```bash
git clone https://github.com/open-sensor-research-platform/osrp.git
cd osrp/ios
```

### 2. Open in Xcode

```bash
open OSRP/OSRP.xcodeproj
```

Or double-click `OSRP.xcodeproj` in Finder.

### 3. Configure Bundle Identifier

1. Select the project in Xcode
2. Select the "OSRP" target
3. Go to "Signing & Capabilities"
4. Set your Team
5. Update Bundle Identifier: `io.osrp.app` (or your own)

### 4. Add HealthKit Capability

1. Select the project in Xcode
2. Select the "OSRP" target
3. Go to "Signing & Capabilities"
4. Click "+ Capability"
5. Add "HealthKit"

### 5. Install Dependencies

The project uses Swift Package Manager for dependencies. Xcode should automatically resolve packages, but you can manually resolve if needed:

1. File → Packages → Resolve Package Versions
2. Wait for AWS SDK to download

Or via command line:
```bash
xcodebuild -resolvePackageDependencies
```

### 6. Build and Run

1. Select a target device or simulator
2. Press `Cmd+R` to build and run
3. Or click the "Play" button in Xcode toolbar

## Configuration

### AWS Configuration

Create a `Config.swift` file in the project to store AWS configuration:

```swift
// Services/Config.swift
struct AWSConfig {
    static let region = "us-west-2"
    static let userPoolId = "your-user-pool-id"
    static let clientId = "your-client-id"
    static let apiEndpoint = "https://your-api.execute-api.us-west-2.amazonaws.com/prod"
}
```

**Note**: Do not commit this file if it contains sensitive information. Add it to `.gitignore`.

### HealthKit Permissions

The app requests the following HealthKit permissions (configured in `Info.plist`):

- Steps
- Heart Rate
- Activity (walking, running, cycling, etc.)
- Sleep Analysis

Permissions are requested at runtime when the user starts data collection.

## Development

### Running on Simulator

```bash
# List available simulators
xcrun simctl list devices

# Boot a simulator
xcrun simctl boot "iPhone 15 Pro"

# Build and run
xcodebuild -scheme OSRP -destination 'platform=iOS Simulator,name=iPhone 15 Pro'
```

**Note**: HealthKit is not available in the iOS Simulator. You must use a physical device to test HealthKit functionality.

### Running on Device

1. Connect your iPhone or iPad
2. Trust your computer on the device
3. Select your device in Xcode
4. Enable Developer Mode on device (Settings → Privacy & Security → Developer Mode)
5. Press `Cmd+R` to build and run

### Code Style

- **Formatting**: Follow Swift API Design Guidelines
- **SwiftUI**: Use declarative syntax with proper state management
- **Async/Await**: Use Swift concurrency for asynchronous operations
- **Documentation**: Add doc comments for public APIs

```swift
/// Brief description
///
/// Detailed description if needed.
///
/// - Parameters:
///   - parameter1: Description
///   - parameter2: Description
/// - Returns: Description
/// - Throws: Description of errors
func exampleFunction(parameter1: String, parameter2: Int) async throws -> String {
    // Implementation
}
```

## Testing

### Unit Tests

Run unit tests from Xcode:
1. Press `Cmd+U`
2. Or: Product → Test

Or via command line:
```bash
xcodebuild test -scheme OSRP -destination 'platform=iOS Simulator,name=iPhone 15 Pro'
```

### UI Tests

Run UI tests:
```bash
xcodebuild test -scheme OSRPUITests -destination 'platform=iOS Simulator,name=iPhone 15 Pro'
```

## Deployment

### TestFlight

1. Archive the app: Product → Archive
2. Validate the archive
3. Distribute to TestFlight
4. Add internal/external testers
5. Submit for review (external testers only)

### App Store

1. Archive the app: Product → Archive
2. Validate the archive
3. Distribute to App Store Connect
4. Fill out App Store information
5. Submit for review

## Troubleshooting

### Common Issues

**Issue**: "Unable to resolve package dependencies"
```bash
# Solution: Clean and reset packages
rm -rf ~/Library/Developer/Xcode/DerivedData
xcodebuild -resolvePackageDependencies
```

**Issue**: "Code signing error"
```
Solution:
1. Select project in Xcode
2. Go to Signing & Capabilities
3. Select your Team
4. Enable "Automatically manage signing"
```

**Issue**: "HealthKit not available"
```
HealthKit is not available in the iOS Simulator.
Use a physical iPhone or iPad with iOS 15.0+.
```

**Issue**: "Module 'OSRP' not found"
```bash
# Solution: Clean build folder
Cmd+Shift+K (Clean Build Folder)
Cmd+B (Build)
```

## Next Steps

### Immediate (MVP)
- [ ] Issue #18: Implement AWS Cognito authentication
- [ ] Issue #19: Implement HealthKit data collection
- [ ] Issue #20: Implement data upload to AWS
- [ ] Issue #21: Add Core Data for local storage
- [ ] Issue #22: Test end-to-end on physical device

### Future Enhancements
- [ ] Settings screen
- [ ] Data visualization
- [ ] Background data collection
- [ ] Push notifications
- [ ] Multiple study support
- [ ] Export data locally

## Resources

- [Swift Documentation](https://swift.org/documentation/)
- [SwiftUI Tutorials](https://developer.apple.com/tutorials/swiftui)
- [HealthKit Documentation](https://developer.apple.com/documentation/healthkit)
- [AWS SDK for Swift](https://github.com/awslabs/aws-sdk-swift)
- [Cognito Documentation](https://docs.aws.amazon.com/cognito/)

## License

Apache 2.0 - See LICENSE file for details

## Contact

For questions or issues, please open an issue on GitHub:
https://github.com/open-sensor-research-platform/osrp/issues
