import Foundation

public enum TemperatureUnit {
    case celsius
    case fahrenheit
}

public struct TemperatureConverter {
    
    public static func heatingLevelToTemp(_ rawValue: Int, unit: TemperatureUnit) -> Double? {
        let map = unit == .celsius ? Constants.rawToCelsiusMap : Constants.rawToFahrenheitMap
        
        // Direct match
        if let exactMatch = map[rawValue] {
            return Double(exactMatch)
        }
        
        // Interpolation for values between map entries
        let sortedKeys = map.keys.sorted()
        
        for i in 0..<sortedKeys.count - 1 {
            let lowerKey = sortedKeys[i]
            let upperKey = sortedKeys[i + 1]
            
            if rawValue > lowerKey && rawValue < upperKey {
                let lowerTemp = Double(map[lowerKey]!)
                let upperTemp = Double(map[upperKey]!)
                
                let ratio = Double(rawValue - lowerKey) / Double(upperKey - lowerKey)
                let interpolatedTemp = lowerTemp + (ratio * (upperTemp - lowerTemp))
                
                return interpolatedTemp
            }
        }
        
        // If value is outside range, return nil
        return nil
    }
    
    public static func tempToHeatingLevel(_ temp: Double, unit: TemperatureUnit) -> Int? {
        let map = unit == .celsius ? Constants.rawToCelsiusMap : Constants.rawToFahrenheitMap
        
        // Find exact match
        for (raw, mappedTemp) in map {
            if Double(mappedTemp) == temp {
                return raw
            }
        }
        
        // Find closest values for interpolation
        let sortedEntries = map.sorted { $0.value < $1.value }
        
        for i in 0..<sortedEntries.count - 1 {
            let lower = sortedEntries[i]
            let upper = sortedEntries[i + 1]
            
            if temp >= Double(lower.value) && temp <= Double(upper.value) {
                let ratio = (temp - Double(lower.value)) / (Double(upper.value) - Double(lower.value))
                let interpolatedRaw = Double(lower.key) + (ratio * Double(upper.key - lower.key))
                
                return Int(round(interpolatedRaw))
            }
        }
        
        // If temperature is outside range, return closest boundary
        if let first = sortedEntries.first, temp < Double(first.value) {
            return first.key
        }
        
        if let last = sortedEntries.last, temp > Double(last.value) {
            return last.key
        }
        
        return nil
    }
    
    public static func celsiusToFahrenheit(_ celsius: Double) -> Double {
        return (celsius * 9.0 / 5.0) + 32.0
    }
    
    public static func fahrenheitToCelsius(_ fahrenheit: Double) -> Double {
        return (fahrenheit - 32.0) * 5.0 / 9.0
    }
}