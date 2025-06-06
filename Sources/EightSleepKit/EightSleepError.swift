import Foundation

public enum EightSleepError: LocalizedError {
    case notAuthenticated
    case authenticationFailed(statusCode: Int)
    case tokenExpired
    case invalidResponse
    case invalidURL
    case apiError(statusCode: Int, data: Data?)
    case decodingError(Error)
    case invalidSide(String)
    case noNextAlarm
    case deviceNotFound
    case userNotFound
    
    public var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "Not authenticated. Please login first."
        case .authenticationFailed(let statusCode):
            return "Authentication failed with status code: \(statusCode)"
        case .tokenExpired:
            return "Authentication token expired. Please login again."
        case .invalidResponse:
            return "Invalid response from server"
        case .invalidURL:
            return "Invalid URL"
        case .apiError(let statusCode, _):
            return "API request failed with status code: \(statusCode)"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .invalidSide(let side):
            return "Invalid bed side: \(side). Must be 'solo', 'left', or 'right'"
        case .noNextAlarm:
            return "No next alarm found"
        case .deviceNotFound:
            return "No Eight Sleep device found"
        case .userNotFound:
            return "User not found"
        }
    }
}