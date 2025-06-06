import Foundation
import EightSleepKit

// Version that accepts command line arguments for non-interactive environments

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

@main
struct EightSleepCLIArgs {
    static func main() async {
        let args = CommandLine.arguments
        
        guard args.count >= 3 else {
            print("Usage: eight-sleep-cli <email> <password>")
            print("Example: eight-sleep-cli user@example.com mypassword")
            exit(1)
        }
        
        let email = args[1]
        let password = args[2]
        
        print("Eight Sleep Data Viewer")
        print("======================\n")
        print("Connecting to Eight Sleep...\n")
        
        let client = EightSleepClient(
            email: email,
            password: password,
            timezone: TimeZone.current
        )
        
        do {
            try await client.start()
            try await client.updateUserData()
            
            print("✓ Connected successfully!\n")
            
            for (_, user) in client.users {
                print("═══════════════════════════════════════════════════")
                print("User: \(user.side.rawValue.capitalized) Side")
                print("═══════════════════════════════════════════════════")
                
                print("\n📊 CURRENT STATUS")
                print("─────────────────")
                print("In Bed: \(user.bedPresence ? "Yes" : "No")")
                print("Bed State: \(user.bedStateType?.rawValue.capitalized ?? "Unknown")")
                print("Current Temp: \(user.currentSideTemp?.rounded() ?? 0)°C")
                
                print("\n🌙 LAST NIGHT'S SLEEP")
                print("────────────────────")
                
                if let lastDate = user.lastSessionDate {
                    print("Date: \(formatDate(lastDate))")
                    print("Sleep Score: \(user.lastSleepScore ?? 0)/100")
                    
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
                    
                    print("\nPhysiological Metrics:")
                    print("  • Heart Rate: \(Int(user.lastHeartRate ?? 0)) bpm")
                    print("  • Respiratory Rate: \(user.lastRespiratoryRate?.rounded() ?? 0) brpm")
                    print("  • Toss & Turns: \(user.lastTossAndTurns ?? 0)")
                    
                    print("\nEnvironmental:")
                    print("  • Bed Temperature: \(user.lastBedTemp?.rounded() ?? 0)°C")
                    print("  • Room Temperature: \(user.lastRoomTemp?.rounded() ?? 0)°C")
                } else {
                    print("No sleep data available for last night")
                }
                
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
                
                if let nextAlarm = user.nextAlarm {
                    print("\n⏰ NEXT ALARM")
                    print("────────────")
                    print("Time: \(formatDate(nextAlarm))")
                    print("Enabled: \(user.getAlarmEnabled(alarmId: nil) ? "Yes" : "No")")
                }
                
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