import SwiftUI
import EightSleepKit

// Example iOS/tvOS app showing how to use EightSleepKit

struct ContentView: View {
    @State private var client: EightSleepClient?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var sleepData: SleepData?
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    if isLoading {
                        ProgressView("Loading...")
                            .padding()
                    } else if let sleepData = sleepData {
                        SleepDataView(data: sleepData)
                    } else if let error = errorMessage {
                        Text(error)
                            .foregroundColor(.red)
                            .padding()
                    } else {
                        Button("Connect to Eight Sleep") {
                            Task {
                                await connectToEightSleep()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
                .padding()
            }
            .navigationTitle("Eight Sleep")
        }
    }
    
    func connectToEightSleep() async {
        isLoading = true
        errorMessage = nil
        
        // In a real app, get these from secure storage or user input
        let email = "your@email.com"
        let password = "yourpassword"
        
        client = EightSleepClient(
            email: email,
            password: password,
            timezone: TimeZone.current
        )
        
        do {
            try await client?.start()
            try await client?.updateUserData()
            
            // Get first user's data
            if let user = client?.users.values.first {
                sleepData = SleepData(
                    side: user.side.rawValue,
                    currentScore: user.currentSleepScore,
                    lastScore: user.lastSleepScore,
                    currentStage: user.currentSleepStage,
                    heartRate: user.currentHeartRate,
                    roomTemp: user.currentRoomTemp,
                    bedPresence: user.bedPresence,
                    lastBreakdown: user.lastSleepBreakdown
                )
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
}

struct SleepData {
    let side: String
    let currentScore: Int?
    let lastScore: Int?
    let currentStage: String?
    let heartRate: Double?
    let roomTemp: Double?
    let bedPresence: Bool
    let lastBreakdown: [String: Int]?
}

struct SleepDataView: View {
    let data: SleepData
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("\(data.side.capitalized) Side")
                .font(.title2)
                .bold()
            
            GroupBox("Current Status") {
                VStack(alignment: .leading, spacing: 8) {
                    Label("In Bed", systemImage: data.bedPresence ? "checkmark.circle.fill" : "xmark.circle")
                        .foregroundColor(data.bedPresence ? .green : .gray)
                    
                    if let stage = data.currentStage {
                        Label("Sleep Stage: \(stage)", systemImage: "moon.fill")
                    }
                    
                    if let hr = data.heartRate {
                        Label("Heart Rate: \(Int(hr)) bpm", systemImage: "heart.fill")
                    }
                    
                    if let temp = data.roomTemp {
                        Label("Room Temp: \(Int(temp))°C", systemImage: "thermometer")
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            if let lastScore = data.lastScore {
                GroupBox("Last Night") {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Sleep Score")
                            Spacer()
                            Text("\(lastScore)/100")
                                .font(.title3)
                                .bold()
                                .foregroundColor(scoreColor(lastScore))
                        }
                        
                        if let breakdown = data.lastBreakdown {
                            Divider()
                            ForEach(breakdown.sorted(by: { $0.key < $1.key }), id: \.key) { stage, seconds in
                                HStack {
                                    Text(stage.capitalized)
                                    Spacer()
                                    Text(formatDuration(seconds))
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
    }
    
    func scoreColor(_ score: Int) -> Color {
        switch score {
        case 90...100: return .green
        case 70..<90: return .yellow
        default: return .orange
        }
    }
    
    func formatDuration(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        return "\(hours)h \(minutes)m"
    }
}

// MARK: - tvOS Specific Adjustments

#if os(tvOS)
extension ContentView {
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 30) {
                    if isLoading {
                        ProgressView("Loading...")
                            .scaleEffect(1.5)
                            .padding()
                    } else if let sleepData = sleepData {
                        SleepDataView(data: sleepData)
                            .padding(.horizontal, 80)
                    } else if let error = errorMessage {
                        Text(error)
                            .foregroundColor(.red)
                            .padding()
                            .font(.title3)
                    } else {
                        Button("Connect to Eight Sleep") {
                            Task {
                                await connectToEightSleep()
                            }
                        }
                        .padding(.horizontal, 60)
                        .padding(.vertical, 20)
                    }
                }
                .padding(.vertical, 60)
            }
            .navigationTitle("Eight Sleep")
        }
    }
}
#endif