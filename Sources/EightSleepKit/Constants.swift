import Foundation

enum Constants {
    static let clientAPIURL = "https://client-api.8slp.net/v1"
    static let appAPIURL = "https://app-api.8slp.net/"
    static let authURL = "https://auth-api.8slp.net/v1/tokens"
    
    static let knownClientId = "0894c7f33bb94800a03f1f4df13a4f38"
    static let knownClientSecret = "f0954a3ed5763ba3d06834c73731a32f15f168f47d4f164751275def86db0c76"
    
    static let tokenTimeBufferSeconds: TimeInterval = 120
    static let defaultTimeout: TimeInterval = 240
    
    static let dateFormat = "yyyy-MM-dd"
    static let dateTimeISOFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
    
    static let possibleSleepStages = ["bedTimeLevel", "initialSleepLevel", "finalSleepLevel"]
    
    static let minTempC = 13
    static let maxTempC = 44
    static let minTempF = 55
    static let maxTempF = 110
    
    static let rawToCelsiusMap: [Int: Int] = [
        -100: 13,
        -97: 14,
        -94: 15,
        -91: 16,
        -83: 17,
        -75: 18,
        -67: 19,
        -58: 20,
        -50: 21,
        -42: 22,
        -33: 23,
        -25: 24,
        -17: 25,
        -8: 26,
        0: 27,
        6: 28,
        11: 29,
        17: 30,
        22: 31,
        28: 32,
        33: 33,
        39: 34,
        44: 35,
        50: 36,
        56: 37,
        61: 38,
        67: 39,
        72: 40,
        78: 41,
        83: 42,
        89: 43,
        100: 44
    ]
    
    static let rawToFahrenheitMap: [Int: Int] = [
        -100: 55,
        -99: 56,
        -97: 57,
        -95: 58,
        -94: 59,
        -92: 60,
        -90: 61,
        -86: 62,
        -81: 63,
        -77: 64,
        -72: 65,
        -68: 66,
        -63: 67,
        -58: 68,
        -54: 69,
        -49: 70,
        -44: 71,
        -40: 72,
        -35: 73,
        -31: 74,
        -26: 75,
        -21: 76,
        -18: 77,
        -17: 77,
        -12: 78,
        -7: 79,
        -3: 80,
        1: 81,
        4: 82,
        7: 83,
        10: 84,
        14: 85,
        16: 86,
        17: 86,
        20: 87,
        23: 88,
        26: 89,
        29: 90,
        32: 91,
        35: 92,
        38: 93,
        41: 94,
        44: 95,
        48: 96,
        51: 97,
        54: 98,
        57: 99,
        60: 100,
        63: 101,
        66: 102,
        69: 103,
        72: 104,
        75: 105,
        78: 106,
        80: 107,
        81: 107,
        85: 108,
        88: 109,
        92: 110,
        100: 111
    ]
}