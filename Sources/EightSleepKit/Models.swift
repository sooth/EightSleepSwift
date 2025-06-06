import Foundation

// MARK: - Authentication Models

public struct Token {
    public let bearerToken: String
    public let expiration: Date
    public let userId: String
}

// MARK: - User Models

public struct EightUser {
    public let userId: String
    public let side: BedSide
    public var profile: UserProfile?
    public var trends: [TrendData] = []
    public var routines: [Routine] = []
    public var nextAlarm: Date?
    public var nextAlarmId: String?
    public var bedStateType: BedStateType?
    public var currentSideTemp: Double?
    public var targetHeatingTemp: Double?
}

public enum BedSide: String, CaseIterable {
    case solo = "solo"
    case left = "left"
    case right = "right"
}

public enum BedStateType: String {
    case off = "off"
    case smart = "smart"
}

public struct UserProfile: Codable {
    public let email: String?
    public let firstName: String?
    public let lastName: String?
}

// MARK: - Sleep Data Models

public struct TrendData: Codable {
    public let day: String
    public let score: Int?
    public let presenceStart: String?
    public let presenceEnd: String?
    public let sleepDuration: Int?
    public let presenceDuration: Int?
    public let lightDuration: Int?
    public let deepDuration: Int?
    public let remDuration: Int?
    public let tnt: Int?
    public let processing: Bool?
    public let sessions: [SleepSession]?
    public let sleepQualityScore: SleepQualityScore?
    public let sleepRoutineScore: SleepRoutineScore?
}

public struct SleepSession: Codable {
    public let stages: [SleepStage]?
    public let timeseries: SleepTimeseries?
}

public struct SleepStage: Codable {
    public let stage: String
    public let duration: Int?
}

public struct SleepTimeseries: Codable {
    public let heartRate: [[TimeseriesEntry]]?
    public let respiratoryRate: [[TimeseriesEntry]]?
    public let tempBedC: [[TimeseriesEntry]]?
    public let tempRoomC: [[TimeseriesEntry]]?
    
    private enum CodingKeys: String, CodingKey {
        case heartRate, respiratoryRate, tempBedC, tempRoomC
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Decode arrays that contain mixed types [String, Double]
        if let heartRateRaw = try? container.decode([[TimeseriesEntry]].self, forKey: .heartRate) {
            self.heartRate = heartRateRaw
        } else {
            self.heartRate = nil
        }
        
        if let respiratoryRateRaw = try? container.decode([[TimeseriesEntry]].self, forKey: .respiratoryRate) {
            self.respiratoryRate = respiratoryRateRaw
        } else {
            self.respiratoryRate = nil
        }
        
        if let tempBedCRaw = try? container.decode([[TimeseriesEntry]].self, forKey: .tempBedC) {
            self.tempBedC = tempBedCRaw
        } else {
            self.tempBedC = nil
        }
        
        if let tempRoomCRaw = try? container.decode([[TimeseriesEntry]].self, forKey: .tempRoomC) {
            self.tempRoomC = tempRoomCRaw
        } else {
            self.tempRoomC = nil
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        // For simplicity, we'll encode as [[Double]] when possible
        if let heartRate = heartRate {
            let values = heartRate.map { $0.compactMap { $0.doubleValue } }
            try container.encodeIfPresent(values, forKey: .heartRate)
        }
        
        if let respiratoryRate = respiratoryRate {
            let values = respiratoryRate.map { $0.compactMap { $0.doubleValue } }
            try container.encodeIfPresent(values, forKey: .respiratoryRate)
        }
        
        if let tempBedC = tempBedC {
            let values = tempBedC.map { $0.compactMap { $0.doubleValue } }
            try container.encodeIfPresent(values, forKey: .tempBedC)
        }
        
        if let tempRoomC = tempRoomC {
            let values = tempRoomC.map { $0.compactMap { $0.doubleValue } }
            try container.encodeIfPresent(values, forKey: .tempRoomC)
        }
    }
}

public enum TimeseriesEntry: Codable {
    case string(String)
    case double(Double)
    
    public var stringValue: String? {
        switch self {
        case .string(let value): return value
        case .double(let value): return String(value)
        }
    }
    
    public var doubleValue: Double? {
        switch self {
        case .string(let value): return Double(value)
        case .double(let value): return value
        }
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let stringValue = try? container.decode(String.self) {
            self = .string(stringValue)
        } else if let doubleValue = try? container.decode(Double.self) {
            self = .double(doubleValue)
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Value is neither String nor Double")
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let value):
            try container.encode(value)
        case .double(let value):
            try container.encode(value)
        }
    }
}

public struct SleepQualityScore: Codable {
    public let total: Int?
    public let sleepDurationSeconds: ScoreDetail?
    public let hrv: HRVDetail?
    public let respiratoryRate: RespiratoryDetail?
    public let heartRate: HeartRateDetail?
    public let tempBedC: TempDetail?
    public let tempRoomC: TempDetail?
}

public struct SleepRoutineScore: Codable {
    public let total: Int?
    public let latencyAsleepSeconds: ScoreDetail?
    public let latencyOutSeconds: ScoreDetail?
    public let wakeupConsistency: ScoreDetail?
}

public struct ScoreDetail: Codable {
    public let score: Int?
}

public struct HRVDetail: Codable {
    public let current: Double?
    public let average: Double?
}

public struct RespiratoryDetail: Codable {
    public let current: Double?
    public let average: Double?
}

public struct HeartRateDetail: Codable {
    public let current: Double?
    public let average: Double?
}

public struct TempDetail: Codable {
    public let average: Double?
}

// MARK: - Device Models

public struct DeviceData: Codable {
    public let leftHeatingLevel: Int?
    public let rightHeatingLevel: Int?
    public let leftTargetHeatingLevel: Int?
    public let rightTargetHeatingLevel: Int?
    public let leftNowHeating: Bool?
    public let rightNowHeating: Bool?
    public let leftHeatingDuration: Int?
    public let rightHeatingDuration: Int?
    public let needsPriming: Bool?
    public let priming: Bool?
    public let hasWater: Bool?
    public let lastPrime: String?
}

// MARK: - Routine Models

public struct Routine: Codable {
    public let id: String
    public let enabled: Bool
    public let alarms: [Alarm]
    public let `override`: RoutineOverride?
}

public struct RoutineOverride: Codable {
    public let routineEnabled: Bool
    public let alarms: [Alarm]
}

public struct Alarm: Codable {
    public let alarmId: String
    public let enabled: Bool
    public let disabledIndividually: Bool
    public let time: String?
    public let settings: AlarmSettings?
}

public struct AlarmSettings: Codable {
    public let volume: Int?
    public let duration: Int?
    public let thermal: Bool?
}

// MARK: - Base Models (for adjustable bases)

public struct BaseData: Codable {
    public let left: BaseDataSide?
    public let right: BaseDataSide?
}

public struct BaseDataSide: Codable {
    public let preset: BasePreset?
    public let leg: BaseAngle?
    public let torso: BaseAngle?
    public let inSnoreMitigation: Bool?
}

public struct BasePreset: Codable {
    public let name: String
}

public struct BaseAngle: Codable {
    public let currentAngle: Int
}

// MARK: - API Response Models

public struct AuthResponse: Codable {
    public let access_token: String
    public let token_type: String
    public let expires_in: Double
    public let refresh_token: String
    public let userId: String
    
    private enum CodingKeys: String, CodingKey {
        case access_token
        case token_type
        case expires_in
        case refresh_token
        case userId
    }
}

public struct UserMeResponse: Codable {
    public let user: UserMeData
}

public struct UserMeData: Codable {
    public let devices: [String]
    public let features: [String]
}

public struct DeviceResponse: Codable {
    public let result: DeviceResult
}

public struct DeviceResult: Codable {
    public let leftUserId: String?
    public let rightUserId: String?
    public let awaySides: [String: String]?
}

public struct UserResponse: Codable {
    public let user: UserData
}

public struct UserData: Codable {
    public let currentDevice: CurrentDevice?
}

public struct CurrentDevice: Codable {
    public let side: String
}

public struct TrendsResponse: Codable {
    public let days: [TrendData]
}

public struct RoutinesResponse: Codable {
    public let settings: RoutineSettings
    public let state: RoutineState
}

public struct RoutineSettings: Codable {
    public let routines: [Routine]
}

public struct RoutineState: Codable {
    public let nextAlarm: NextAlarm?
    public let upcomingRoutineId: String?
}

public struct NextAlarm: Codable {
    public let nextTimestamp: String?
    public let alarmId: String
}

public struct TemperatureResponse: Codable {
    public let currentLevel: Int
    public let currentDeviceLevel: Int
    public let currentState: TemperatureState
    public let smart: SmartTemperature?
}

public struct TemperatureState: Codable {
    public let type: String
}

public struct SmartTemperature: Codable {
    public let bedTimeLevel: Int?
    public let initialSleepLevel: Int?
    public let finalSleepLevel: Int?
}