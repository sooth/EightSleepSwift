# EightSleepKit

A Swift library for interacting with Eight Sleep smart mattresses, compatible with iOS, tvOS, macOS, and watchOS.

## Features

- 🔐 OAuth2 authentication with Eight Sleep API
- 📊 Comprehensive sleep data retrieval (scores, stages, metrics)
- 🌡️ Temperature control (-100 to +100 heating/cooling levels)
- ❤️ Real-time physiological data (heart rate, HRV, respiratory rate)
- ⏰ Alarm and routine management
- 🛏️ Multi-user support (left/right/solo sides)
- 📱 Platform support: iOS 13+, tvOS 13+, macOS 10.15+, watchOS 6+

## Installation

### Swift Package Manager

Add the following to your `Package.swift` file:

```swift
dependencies: [
    .package(url: "https://github.com/yourusername/EightSleepKit.git", from: "1.0.0")
]
```

Or in Xcode:
1. File → Add Package Dependencies
2. Enter the repository URL
3. Click Add Package

## Quick Start

```swift
import EightSleepKit

// Create client
let client = EightSleepClient(
    email: "your@email.com",
    password: "yourpassword",
    timezone: TimeZone.current
)

// Connect and fetch data
Task {
    do {
        try await client.start()
        try await client.updateUserData()
        
        // Access sleep data
        for (_, user) in client.users {
            print("Side: \(user.side.rawValue)")
            print("Sleep Score: \(user.currentSleepScore ?? 0)")
            print("In Bed: \(user.bedPresence)")
        }
    } catch {
        print("Error: \(error)")
    }
}
```

## Usage Examples

### Current Sleep Session

```swift
if let user = client.users.values.first {
    // Real-time metrics
    print("Current Status:")
    print("- In bed: \(user.bedPresence)")
    print("- Sleep stage: \(user.currentSleepStage ?? "awake")")
    print("- Heart rate: \(user.currentHeartRate ?? 0) bpm")
    print("- HRV: \(user.currentHRV ?? 0)")
    print("- Respiratory rate: \(user.currentRespiratoryRate ?? 0) brpm")
    print("- Room temp: \(user.currentRoomTemp ?? 0)°C")
    
    // Sleep breakdown
    if let breakdown = user.currentSleepBreakdown {
        print("\nSleep Stages:")
        print("- Light: \(breakdown["light"] ?? 0) seconds")
        print("- Deep: \(breakdown["deep"] ?? 0) seconds")
        print("- REM: \(breakdown["rem"] ?? 0) seconds")
        print("- Awake: \(breakdown["awake"] ?? 0) seconds")
    }
}
```

### Historical Data

```swift
if let user = client.users.values.first {
    // Last night's summary
    print("Last Night:")
    print("- Score: \(user.lastSleepScore ?? 0)/100")
    print("- Duration: \(user.timeSlept ?? 0) seconds")
    print("- Average heart rate: \(user.lastHeartRate ?? 0) bpm")
    print("- Average bed temp: \(user.lastBedTemp ?? 0)°C")
    print("- Toss & turns: \(user.lastTossAndTurns ?? 0)")
    
    // Weekly trends
    print("\nWeekly Scores:")
    for trend in user.trends.suffix(7) {
        if let score = trend.score {
            print("- \(trend.day): \(score)/100")
        }
    }
}
```

### Temperature Control

```swift
// Set temperature (-100 = max cooling, +100 = max heating)
try await client.setHeatingLevel(for: userId, level: 20)

// Set temperature with duration
try await client.setHeatingLevel(for: userId, level: -30, duration: 3600) // 1 hour

// Turn off temperature control
try await client.turnOffSide(for: userId)

// Set away mode
try await client.setAwayMode(for: userId, action: "start") // or "end"
```

### Device Information

```swift
// Update device data
try await client.updateDeviceData()

if let deviceData = client.deviceData {
    print("Device Status:")
    print("- Needs priming: \(deviceData.needsPriming ?? false)")
    print("- Has water: \(deviceData.hasWater ?? true)")
    print("- Left heating: \(deviceData.leftHeatingLevel ?? 0)")
    print("- Right heating: \(deviceData.rightHeatingLevel ?? 0)")
}
```

## Command Line Tools

The package includes two CLI tools for testing:

### Interactive CLI
```bash
./run-cli.sh
# Enter email and password when prompted
```

### Command Line Arguments
```bash
./.build/release/eight-sleep-cli-args your@email.com yourpassword
```

Both tools display comprehensive sleep data including scores, physiological metrics, and environmental data.

## API Structure

### Main Classes

- **`EightSleepClient`**: Main entry point for API interaction
- **`EightUser`**: User-specific data and metrics
- **`APIClient`**: Handles network requests and authentication

### Key Data Models

- **`TrendData`**: Daily sleep session data with detailed metrics
- **`SleepSession`**: Individual sleep session with stages and timeseries
- **`SleepTimeseries`**: Time-based data (heart rate, temperature, etc.)
- **`DeviceData`**: Current device state and settings
- **`Routine`**: Alarm and sleep routine configuration

## Error Handling

```swift
enum EightSleepError: LocalizedError {
    case notAuthenticated
    case authenticationFailed(statusCode: Int)
    case tokenExpired
    case deviceNotFound
    case userNotFound
    // ... more cases
}
```

Handle errors appropriately:

```swift
do {
    try await client.start()
} catch EightSleepError.authenticationFailed(let code) {
    if code == 401 {
        print("Invalid credentials")
    } else {
        print("Auth failed: \(code)")
    }
} catch EightSleepError.deviceNotFound {
    print("No Eight Sleep device on account")
} catch {
    print("Unexpected error: \(error)")
}
```

## Temperature Utilities

```swift
// Convert between heating levels and temperatures
let celsius = TemperatureConverter.heatingLevelToTemp(50, unit: .celsius)
let level = TemperatureConverter.tempToHeatingLevel(25.0, unit: .celsius)

// Convert between units
let fahrenheit = TemperatureConverter.celsiusToFahrenheit(celsius)
```

## Requirements

- Swift 5.7+
- iOS 13.0+ / tvOS 13.0+ / macOS 10.15+ / watchOS 6.0+
- Eight Sleep account with active device

## Notes

- All timestamps are converted to the timezone specified during client initialization
- Temperature levels range from -100 (maximum cooling) to +100 (maximum heating)
- The API uses OAuth2 with hardcoded client credentials (same as official app)
- Sleep data is typically updated every 5 minutes during active sessions

## Credits

This library is a Swift port of the [pyEight](https://github.com/lukas-clarke/pyEight) Python library, maintaining API compatibility with the Eight Sleep service.