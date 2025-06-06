import Foundation
import EightSleepKit

// MARK: - CLI Input Helpers

func readInput(prompt: String, isSecure: Bool = false) -> String {
    print(prompt, terminator: ": ")
    fflush(stdout)  // Force flush the output
    
    if isSecure {
        // Disable echo for password input
        let handle = FileHandle.standardInput
        var oldTermios = termios()
        tcgetattr(handle.fileDescriptor, &oldTermios)
        
        var newTermios = oldTermios
        newTermios.c_lflag &= ~tcflag_t(ECHO)
        tcsetattr(handle.fileDescriptor, TCSANOW, &newTermios)
        
        guard let input = readLine()?.trimmingCharacters(in: .whitespacesAndNewlines) else {
            // Re-enable echo before returning
            tcsetattr(handle.fileDescriptor, TCSANOW, &oldTermios)
            print() // New line after password
            return ""
        }
        
        // Re-enable echo
        tcsetattr(handle.fileDescriptor, TCSANOW, &oldTermios)
        print() // New line after password
        
        return input
    }
    
    guard let input = readLine()?.trimmingCharacters(in: .whitespacesAndNewlines) else {
        return ""
    }
    
    return input
}

func formatDuration(_ seconds: Int?) -> String {
    guard let seconds = seconds else { return "N/A" }
    let hours = seconds / 3600
    let minutes = (seconds % 3600) / 60
    return "\(hours)h \(minutes)m"
}

func formatDate(_ date: Date?) -> String {
    guard let date = date else { return "N/A" }
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .short
    return formatter.string(from: date)
}

// MARK: - Main Program

@main
struct EightSleepCLI {
    static func main() async {
        print("Eight Sleep Data Viewer")
        print("======================\n")
        
        // Get credentials
        let email = readInput(prompt: "Email")
        print("DEBUG: Read email: '\(email)' (length: \(email.count))")
        
        let password = readInput(prompt: "Password", isSecure: true)
        print("DEBUG: Read password: '\(String(repeating: "*", count: password.count))' (length: \(password.count))")
        
        print("\nConnecting to Eight Sleep...\n")
        
        // Create client
        let client = EightSleepClient(
            email: email,
            password: password,
            timezone: TimeZone.current
        )
        
        do {
            // Authenticate and fetch data
            try await client.start()
            try await client.updateUserData()
            
            print("✓ Connected successfully!\n")
            
            // Display data for each user
            for (_, user) in client.users {
                print("═══════════════════════════════════════════════════")
                print("User: \(user.side.rawValue.capitalized) Side")
                print("═══════════════════════════════════════════════════")
                
                // Current Status
                print("\n📊 CURRENT STATUS")
                print("─────────────────")
                print("In Bed: \(user.bedPresence ? "Yes" : "No")")
                print("Bed State: \(user.bedStateType?.rawValue.capitalized ?? "Unknown")")
                print("Current Temp: \(user.currentSideTemp?.rounded() ?? 0)°C")
                
                // Last Night's Sleep
                print("\n🌙 LAST NIGHT'S SLEEP")
                print("────────────────────")
                
                if let lastDate = user.lastSessionDate {
                    print("Date: \(formatDate(lastDate))")
                    print("Sleep Score: \(user.lastSleepScore ?? 0)/100")
                    
                    // Sleep Breakdown
                    if let breakdown = user.lastSleepBreakdown {
                        print("\nSleep Stages:")
                        if let light = breakdown["light"] {
                            print("  • Light Sleep: \(formatDuration(light))")
                        }
                        if let deep = breakdown["deep"] {
                            print("  • Deep Sleep: \(formatDuration(deep))")
                        }
                        if let rem = breakdown["rem"] {
                            print("  • REM Sleep: \(formatDuration(rem))")
                        }
                        if let awake = breakdown["awake"] {
                            print("  • Awake Time: \(formatDuration(awake))")
                        }
                    }
                    
                    // Physiological Metrics
                    print("\nPhysiological Metrics:")
                    print("  • Heart Rate: \(Int(user.lastHeartRate ?? 0)) bpm")
                    print("  • Respiratory Rate: \(user.lastRespiratoryRate?.rounded() ?? 0) brpm")
                    print("  • Toss & Turns: \(user.lastTossAndTurns ?? 0)")
                    
                    // Environmental Data
                    print("\nEnvironmental:")
                    print("  • Bed Temperature: \(user.lastBedTemp?.rounded() ?? 0)°C")
                    print("  • Room Temperature: \(user.lastRoomTemp?.rounded() ?? 0)°C")
                } else {
                    print("No sleep data available for last night")
                }
                
                // Current Session (if in bed)
                if user.currentSessionProcessing || user.bedPresence {
                    print("\n💤 CURRENT SESSION")
                    print("─────────────────")
                    print("Status: \(user.currentSessionProcessing ? "Processing" : "Active")")
                    print("Sleep Stage: \(user.currentSleepStage ?? "Unknown")")
                    print("Current Score: \(user.currentSleepScore ?? 0)/100")
                    print("Time Slept: \(formatDuration(user.timeSlept))")
                    print("Heart Rate: \(Int(user.currentHeartRate ?? 0)) bpm")
                    print("Room Temp: \(user.currentRoomTemp?.rounded() ?? 0)°C")
                }
                
                // Alarms
                if let nextAlarm = user.nextAlarm {
                    print("\n⏰ NEXT ALARM")
                    print("────────────")
                    print("Time: \(formatDate(nextAlarm))")
                    print("Enabled: \(user.getAlarmEnabled(alarmId: nil) ? "Yes" : "No")")
                }
                
                // Sleep Trends
                print("\n📈 RECENT SLEEP SCORES")
                print("─────────────────────")
                let recentTrends = user.trends.suffix(7)
                for trend in recentTrends {
                    if let score = trend.score {
                        print("\(trend.day): \(score)/100")
                    }
                }
                
                print("\n")
            }
            
        } catch EightSleepError.authenticationFailed(let statusCode) {
            print("❌ Authentication failed (status: \(statusCode))")
            print("   Please check your email and password.")
        } catch EightSleepError.deviceNotFound {
            print("❌ No Eight Sleep device found on your account")
        } catch {
            print("❌ Error: \(error.localizedDescription)")
        }
    }
}