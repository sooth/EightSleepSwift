import Foundation

public extension EightUser {
    
    // MARK: - Current Session Properties
    
    var currentSessionDate: Date? {
        guard let trend = trends.last,
              let dateString = trend.presenceStart else { return nil }
        return parseDate(dateString)
    }
    
    var currentSessionProcessing: Bool {
        trends.last?.processing ?? false
    }
    
    var currentSleepStage: String? {
        guard let currentTrend = trends.last,
              let sessions = currentTrend.sessions,
              let currentSession = sessions.last,
              let stages = currentSession.stages,
              !stages.isEmpty else { return nil }
        
        // API always has an awake state last while processing
        if currentSessionProcessing && stages.count >= 2 {
            return stages[stages.count - 2].stage
        } else {
            return stages.last?.stage
        }
    }
    
    var currentSleepScore: Int? {
        trends.last?.score
    }
    
    var currentSleepBreakdown: [String: Int]? {
        guard let trend = trends.last else { return nil }
        
        var breakdown: [String: Int] = [:]
        
        if let light = trend.lightDuration { breakdown["light"] = light }
        if let deep = trend.deepDuration { breakdown["deep"] = deep }
        if let rem = trend.remDuration { breakdown["rem"] = rem }
        
        if let presence = trend.presenceDuration,
           let sleep = trend.sleepDuration {
            breakdown["awake"] = presence - sleep
        }
        
        return breakdown.isEmpty ? nil : breakdown
    }
    
    var currentHeartRate: Double? {
        guard let trend = trends.last,
              let sessions = trend.sessions,
              let session = sessions.last,
              let timeseries = session.timeseries,
              let heartRateData = timeseries.heartRate,
              let lastEntry = heartRateData.last,
              lastEntry.count >= 2 else { return nil }
        
        return lastEntry[1].doubleValue
    }
    
    var currentRoomTemp: Double? {
        guard let trend = trends.last,
              let sessions = trend.sessions,
              let session = sessions.last,
              let timeseries = session.timeseries,
              let tempData = timeseries.tempRoomC,
              let lastEntry = tempData.last,
              lastEntry.count >= 2 else { return nil }
        
        return lastEntry[1].doubleValue
    }
    
    var currentTossAndTurns: Int? {
        trends.last?.tnt
    }
    
    var currentRespiratoryRate: Double? {
        trends.last?.sleepQualityScore?.respiratoryRate?.current
    }
    
    var currentHRV: Double? {
        trends.last?.sleepQualityScore?.hrv?.current
    }
    
    var timeSlept: Int? {
        trends.last?.sleepDuration
    }
    
    // MARK: - Last Session Properties
    
    var lastSessionDate: Date? {
        guard trends.count >= 2,
              let dateString = trends[trends.count - 2].presenceStart else { return nil }
        return parseDate(dateString)
    }
    
    var lastSleepScore: Int? {
        guard trends.count >= 2 else { return nil }
        return trends[trends.count - 2].score
    }
    
    var lastSleepBreakdown: [String: Int]? {
        guard trends.count >= 2 else { return nil }
        let trend = trends[trends.count - 2]
        
        var breakdown: [String: Int] = [:]
        
        if let light = trend.lightDuration { breakdown["light"] = light }
        if let deep = trend.deepDuration { breakdown["deep"] = deep }
        if let rem = trend.remDuration { breakdown["rem"] = rem }
        
        if let presence = trend.presenceDuration,
           let sleep = trend.sleepDuration {
            breakdown["awake"] = presence - sleep
        }
        
        return breakdown.isEmpty ? nil : breakdown
    }
    
    var lastBedTemp: Double? {
        guard trends.count >= 2 else { return nil }
        return trends[trends.count - 2].sleepQualityScore?.tempBedC?.average
    }
    
    var lastRoomTemp: Double? {
        guard trends.count >= 2 else { return nil }
        return trends[trends.count - 2].sleepQualityScore?.tempRoomC?.average
    }
    
    var lastTossAndTurns: Int? {
        guard trends.count >= 2 else { return nil }
        return trends[trends.count - 2].tnt
    }
    
    var lastHeartRate: Double? {
        guard trends.count >= 2 else { return nil }
        return trends[trends.count - 2].sleepQualityScore?.heartRate?.average
    }
    
    var lastRespiratoryRate: Double? {
        guard trends.count >= 2 else { return nil }
        return trends[trends.count - 2].sleepQualityScore?.respiratoryRate?.average
    }
    
    // MARK: - Bed Presence
    
    var bedPresence: Bool {
        guard let trend = trends.last,
              let sessions = trend.sessions,
              let session = sessions.last,
              let timeseries = session.timeseries,
              let heartRateData = timeseries.heartRate,
              let lastEntry = heartRateData.last,
              lastEntry.count >= 1,
              let timeString = lastEntry[0].stringValue else { return false }
        
        let heartRateTime = parseDate(timeString) ?? Date.distantPast
        let timeDifference = Date().timeIntervalSince(heartRateTime)
        
        // Consider present if last heart rate was within 10 minutes
        return timeDifference < 600
    }
    
    // MARK: - Alarm Methods
    
    func getAlarmEnabled(alarmId: String?) -> Bool {
        let checkNextAlarm = alarmId == nil
        let id = alarmId ?? nextAlarmId
        
        guard let id = id else { return false }
        
        for routine in routines {
            // Check override alarms first
            if let override = routine.override {
                for alarm in override.alarms {
                    if alarm.alarmId == id {
                        return checkNextAlarm ? alarm.enabled : !alarm.disabledIndividually
                    }
                }
            }
            
            // Check regular alarms
            for alarm in routine.alarms {
                if alarm.alarmId == id {
                    return checkNextAlarm ? alarm.enabled : !alarm.disabledIndividually
                }
            }
        }
        
        return false
    }
    
    // MARK: - Helper Methods
    
    private func parseDate(_ dateString: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        
        if let date = formatter.date(from: dateString) {
            return date
        }
        
        // Try without milliseconds
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        if let date = formatter.date(from: dateString) {
            return date
        }
        
        // Try with Z suffix
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        return formatter.date(from: dateString)
    }
}