import Foundation

public class EightSleepClient {
    private let apiClient: APIClient
    private let email: String
    private let password: String
    private let timezone: TimeZone
    private let clientId: String?
    private let clientSecret: String?
    
    private var deviceIds: [String] = []
    private var isPod: Bool = false
    private var hasBase: Bool = false
    private var deviceData: DeviceData?
    
    public private(set) var users: [String: EightUser] = [:]
    
    public var deviceId: String? {
        deviceIds.first
    }
    
    public init(
        email: String,
        password: String,
        timezone: TimeZone,
        clientId: String? = nil,
        clientSecret: String? = nil,
        session: URLSession = .shared
    ) {
        self.email = email
        self.password = password
        self.timezone = timezone
        self.clientId = clientId
        self.clientSecret = clientSecret
        self.apiClient = APIClient(session: session)
    }
    
    public func start() async throws {
        // Authenticate
        do {
            _ = try await apiClient.authenticate(
                email: email,
                password: password,
                clientId: clientId,
                clientSecret: clientSecret
            )
        } catch {
            print("DEBUG: Authentication failed with error: \(error)")
            throw error
        }
        
        // Fetch device list
        try await fetchDeviceList()
        
        // Assign users
        try await assignUsers()
    }
    
    public func refreshToken() async throws {
        _ = try await apiClient.authenticate(
            email: email,
            password: password,
            clientId: clientId,
            clientSecret: clientSecret
        )
    }
    
    private func fetchDeviceList() async throws {
        let url = "\(Constants.clientAPIURL)/users/me"
        let response: UserMeResponse = try await apiClient.apiRequest("GET", url)
        
        deviceIds = response.user.devices
        isPod = response.user.features.contains("cooling")
        hasBase = response.user.features.contains("elevation")
    }
    
    private func assignUsers() async throws {
        guard let deviceId = deviceIds.first else {
            throw EightSleepError.deviceNotFound
        }
        
        let url = "\(Constants.clientAPIURL)/devices/\(deviceId)?filter=leftUserId,rightUserId,awaySides"
        let response: DeviceResponse = try await apiClient.apiRequest("GET", url)
        
        // Get all user IDs including away users
        var userIds = Set<String>()
        if let leftUserId = response.result.leftUserId {
            userIds.insert(leftUserId)
        }
        if let rightUserId = response.result.rightUserId {
            userIds.insert(rightUserId)
        }
        if let awaySides = response.result.awaySides {
            awaySides.values.forEach { userIds.insert($0) }
        }
        
        // Create users for each unique ID
        for userId in userIds {
            let userUrl = "\(Constants.clientAPIURL)/users/\(userId)"
            let userResponse: UserResponse = try await apiClient.apiRequest("GET", userUrl)
            
            if let sideString = userResponse.user.currentDevice?.side,
               let side = BedSide(rawValue: sideString) {
                let user = EightUser(userId: userId, side: side)
                users[userId] = user
            }
        }
    }
    
    public func updateUserData() async throws {
        for userId in users.keys {
            try await updateUser(userId: userId)
        }
    }
    
    public func updateUser(userId: String) async throws {
        guard var user = users[userId] else {
            throw EightSleepError.userNotFound
        }
        
        // Update profile
        try await updateUserProfile(for: &user)
        
        // Update trends
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = Constants.dateFormat
        
        let now = Date()
        let start = Calendar.current.date(byAdding: .day, value: -1, to: now)!
        let end = Calendar.current.date(byAdding: .day, value: 1, to: now)!
        
        try await updateTrendData(
            for: &user,
            startDate: dateFormatter.string(from: start),
            endDate: dateFormatter.string(from: end)
        )
        
        // Update routines
        try await updateRoutinesData(for: &user)
        
        // Update temperature data
        try await updateTemperatureData(for: &user)
        
        // Store updated user
        users[userId] = user
    }
    
    private func updateUserProfile(for user: inout EightUser) async throws {
        let url = "\(Constants.clientAPIURL)/users/\(user.userId)"
        struct ProfileResponse: Codable {
            let user: UserProfile
        }
        let response: ProfileResponse = try await apiClient.apiRequest("GET", url)
        user.profile = response.user
    }
    
    private func updateTrendData(for user: inout EightUser, startDate: String, endDate: String) async throws {
        let url = "\(Constants.clientAPIURL)/users/\(user.userId)/trends"
        let params = [
            "tz": timezone.identifier,
            "from": startDate,
            "to": endDate,
            "include-main": "false",
            "include-all-sessions": "true",
            "model-version": "v2"
        ]
        
        let response: TrendsResponse = try await apiClient.apiRequest("GET", url, params: params)
        user.trends = response.days
    }
    
    private func updateRoutinesData(for user: inout EightUser) async throws {
        let url = "\(Constants.appAPIURL)v2/users/\(user.userId)/routines"
        let response: RoutinesResponse = try await apiClient.apiRequest("GET", url)
        
        user.routines = response.settings.routines
        
        if let nextTimestamp = response.state.nextAlarm?.nextTimestamp {
            user.nextAlarm = parseDate(nextTimestamp)
            user.nextAlarmId = response.state.nextAlarm?.alarmId
        } else {
            user.nextAlarm = nil
            user.nextAlarmId = nil
            
            // Check for upcoming disabled alarms
            if let upcomingRoutineId = response.state.upcomingRoutineId,
               let routine = user.routines.first(where: { $0.id == upcomingRoutineId }) {
                if let override = routine.override, let firstAlarm = override.alarms.first {
                    user.nextAlarmId = firstAlarm.alarmId
                } else if let firstAlarm = routine.alarms.first {
                    user.nextAlarmId = firstAlarm.alarmId
                }
            }
        }
    }
    
    private func updateTemperatureData(for user: inout EightUser) async throws {
        let url = "\(Constants.appAPIURL)v1/users/\(user.userId)/temperature"
        let response: TemperatureResponse = try await apiClient.apiRequest("GET", url)
        
        user.bedStateType = BedStateType(rawValue: response.currentState.type)
        user.currentSideTemp = TemperatureConverter.heatingLevelToTemp(response.currentDeviceLevel, unit: .celsius)
    }
    
    public func updateDeviceData() async throws {
        guard let deviceId = deviceId else {
            throw EightSleepError.deviceNotFound
        }
        
        let url = "\(Constants.clientAPIURL)/devices/\(deviceId)"
        struct DeviceDataResponse: Codable {
            let result: DeviceData
        }
        let response: DeviceDataResponse = try await apiClient.apiRequest("GET", url)
        self.deviceData = response.result
    }
    
    // MARK: - User Actions
    
    public func setHeatingLevel(for userId: String, level: Int, duration: Int = 0) async throws {
        guard users[userId] != nil else {
            throw EightSleepError.userNotFound
        }
        
        let url = "\(Constants.appAPIURL)v1/users/\(userId)/temperature"
        
        // Clamp values
        let clampedLevel = max(-100, min(100, level))
        
        // Turn on side first
        try await turnOnSide(for: userId)
        
        // Set heating level
        let levelData = ["currentLevel": clampedLevel]
        try await apiClient.apiRequestRaw("PUT", url, body: levelData)
        
        // Set duration if specified
        if duration > 0 {
            let durationData = ["timeBased": ["level": clampedLevel, "durationSeconds": duration]]
            try await apiClient.apiRequestRaw("PUT", url, body: durationData)
        }
    }
    
    public func turnOnSide(for userId: String) async throws {
        let url = "\(Constants.appAPIURL)v1/users/\(userId)/temperature"
        let data = ["currentState": ["type": "smart"]]
        try await apiClient.apiRequestRaw("PUT", url, body: data)
    }
    
    public func turnOffSide(for userId: String) async throws {
        let url = "\(Constants.appAPIURL)v1/users/\(userId)/temperature"
        let data = ["currentState": ["type": "off"]]
        try await apiClient.apiRequestRaw("PUT", url, body: data)
    }
    
    public func setAwayMode(for userId: String, action: String) async throws {
        guard action == "start" || action == "end" else {
            throw EightSleepError.apiError(statusCode: 400, data: nil)
        }
        
        let url = "\(Constants.appAPIURL)v1/users/\(userId)/away-mode"
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
        dateFormatter.timeZone = TimeZone(identifier: "UTC")
        
        let date = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let dateString = dateFormatter.string(from: date)
        
        let data = ["awayPeriod": [action: dateString]]
        try await apiClient.apiRequestRaw("PUT", url, body: data)
    }
    
    // MARK: - Helper Methods
    
    private func parseDate(_ dateString: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        
        if let date = formatter.date(from: dateString) {
            return date
        }
        
        // Try ISO8601 format
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        return formatter.date(from: dateString)
    }
}