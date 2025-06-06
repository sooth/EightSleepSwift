# Eight Sleep Swift Library - Usage Guide

## Running the CLI Tool

The Eight Sleep CLI tool requires valid Eight Sleep account credentials to work. Since the tool prompts for credentials interactively, it needs to be run in a proper terminal environment.

### Interactive Mode (Recommended)

1. Open Terminal on macOS
2. Navigate to the EightSleepSwift directory:
   ```bash
   cd /path/to/EightSleepSwift
   ```

3. Run the CLI:
   ```bash
   ./run-cli.sh
   ```
   
4. Enter your Eight Sleep email when prompted
5. Enter your Eight Sleep password when prompted (it will be hidden)

### Command Line Arguments Mode

For scripting or automation:

```bash
./.build/release/eight-sleep-cli-args your@email.com yourpassword
```

## Troubleshooting

If you get authentication errors:

1. **Verify your credentials**: Make sure you're using the same email and password you use to log into the Eight Sleep app

2. **Check your account**: Ensure your Eight Sleep account is active and you have a device registered

3. **Network issues**: The API requires an internet connection

## Integration in iOS/tvOS Apps

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
            print("Sleep Score: \(user.currentSleepScore ?? 0)")
        }
    } catch {
        print("Error: \(error)")
    }
}
```

## API Requirements

The Eight Sleep API requires:
- Valid Eight Sleep account credentials
- Active Eight Sleep device (Pod, Pod Pro, etc.)
- Internet connection
- Proper headers (handled by the library)

The library uses the same authentication method as the official Eight Sleep mobile app.