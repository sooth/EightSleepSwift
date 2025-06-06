import Foundation

class APIClient {
    private let session: URLSession
    private var token: Token?
    
    init(session: URLSession = .shared) {
        self.session = session
    }
    
    func setToken(_ token: Token) {
        self.token = token
    }
    
    func authenticate(email: String, password: String, clientId: String? = nil, clientSecret: String? = nil) async throws -> Token {
        let url = URL(string: Constants.authURL)!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("keep-alive", forHTTPHeaderField: "Connection")
        request.setValue("okhttp/4.9.3", forHTTPHeaderField: "User-Agent")
        request.setValue("gzip", forHTTPHeaderField: "Accept-Encoding")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        let body: [String: Any] = [
            "client_id": clientId ?? Constants.knownClientId,
            "client_secret": clientSecret ?? Constants.knownClientSecret,
            "grant_type": "password",
            "username": email,
            "password": password
        ]
        
        print("DEBUG: Authenticating with email: \(email)")
        print("DEBUG: Password length: \(password.count)")
        print("DEBUG: Client ID: \(clientId ?? Constants.knownClientId)")
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw EightSleepError.invalidResponse
        }
        
        print("DEBUG: Response status code: \(httpResponse.statusCode)")
        
        guard httpResponse.statusCode == 200 else {
            // Log error response for debugging
            if let errorString = String(data: data, encoding: .utf8) {
                print("DEBUG: Auth error response body:")
                print(errorString)
            }
            throw EightSleepError.authenticationFailed(statusCode: httpResponse.statusCode)
        }
        
        // First, let's see what we got
        print("DEBUG: Got 200 response, attempting to decode...")
        if let jsonString = String(data: data, encoding: .utf8) {
            print("DEBUG: Success response body:")
            print(jsonString)
        }
        
        do {
            let authResponse = try JSONDecoder().decode(AuthResponse.self, from: data)
            
            let expiration = Date().addingTimeInterval(authResponse.expires_in)
            let token = Token(
                bearerToken: authResponse.access_token,
                expiration: expiration,
                userId: authResponse.userId
            )
            
            self.token = token
            return token
        } catch {
            // Log the response for debugging
            print("DEBUG: Failed to decode auth response")
            if let jsonString = String(data: data, encoding: .utf8) {
                print("DEBUG: Raw response body:")
                print(jsonString)
            }
            print("DEBUG: Decoding error: \(error)")
            
            // Try to decode as dictionary to see structure
            if let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                print("DEBUG: Response fields:")
                for (key, value) in dict {
                    print("  \(key): \(type(of: value))")
                }
            }
            
            throw EightSleepError.decodingError(error)
        }
    }
    
    func apiRequest<T: Decodable>(_ method: String, _ url: String, params: [String: String]? = nil, body: [String: Any]? = nil) async throws -> T {
        guard let token = token else {
            throw EightSleepError.notAuthenticated
        }
        
        // Check if token needs refresh
        if Date() > token.expiration.addingTimeInterval(-Constants.tokenTimeBufferSeconds) {
            throw EightSleepError.tokenExpired
        }
        
        guard let url = URL(string: url) else {
            throw EightSleepError.invalidURL
        }
        
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        if let params = params {
            components?.queryItems = params.map { URLQueryItem(name: $0.key, value: $0.value) }
        }
        
        guard let finalURL = components?.url else {
            throw EightSleepError.invalidURL
        }
        
        print("DEBUG: API Request: \(method) \(finalURL.absoluteString)")
        
        var request = URLRequest(url: finalURL)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("keep-alive", forHTTPHeaderField: "Connection")
        request.setValue("okhttp/4.9.3", forHTTPHeaderField: "User-Agent")
        request.setValue("Bearer \(token.bearerToken)", forHTTPHeaderField: "Authorization")
        request.setValue("gzip", forHTTPHeaderField: "Accept-Encoding")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        if let body = body {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            if let bodyString = String(data: request.httpBody!, encoding: .utf8) {
                print("DEBUG: Request body: \(bodyString)")
            }
        }
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw EightSleepError.invalidResponse
        }
        
        print("DEBUG: API Response status: \(httpResponse.statusCode)")
        
        if httpResponse.statusCode == 401 {
            throw EightSleepError.tokenExpired
        }
        
        guard 200..<300 ~= httpResponse.statusCode else {
            if let errorString = String(data: data, encoding: .utf8) {
                print("DEBUG: Error response: \(errorString)")
            }
            throw EightSleepError.apiError(statusCode: httpResponse.statusCode, data: data)
        }
        
        // Log successful response
        if let responseString = String(data: data, encoding: .utf8) {
            print("DEBUG: Success response: \(responseString)")
        }
        
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            print("DEBUG: Failed to decode response as \(T.self): \(error)")
            throw error
        }
    }
    
    func apiRequestRaw(_ method: String, _ url: String, params: [String: String]? = nil, body: [String: Any]? = nil) async throws {
        guard let token = token else {
            throw EightSleepError.notAuthenticated
        }
        
        // Check if token needs refresh
        if Date() > token.expiration.addingTimeInterval(-Constants.tokenTimeBufferSeconds) {
            throw EightSleepError.tokenExpired
        }
        
        guard let url = URL(string: url) else {
            throw EightSleepError.invalidURL
        }
        
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        if let params = params {
            components?.queryItems = params.map { URLQueryItem(name: $0.key, value: $0.value) }
        }
        
        guard let finalURL = components?.url else {
            throw EightSleepError.invalidURL
        }
        
        print("DEBUG: API Request Raw: \(method) \(finalURL.absoluteString)")
        
        var request = URLRequest(url: finalURL)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("keep-alive", forHTTPHeaderField: "Connection")
        request.setValue("okhttp/4.9.3", forHTTPHeaderField: "User-Agent")
        request.setValue("Bearer \(token.bearerToken)", forHTTPHeaderField: "Authorization")
        request.setValue("gzip", forHTTPHeaderField: "Accept-Encoding")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        if let body = body {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            if let bodyString = String(data: request.httpBody!, encoding: .utf8) {
                print("DEBUG: Request body: \(bodyString)")
            }
        }
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw EightSleepError.invalidResponse
        }
        
        print("DEBUG: API Response Raw status: \(httpResponse.statusCode)")
        
        if httpResponse.statusCode == 401 {
            throw EightSleepError.tokenExpired
        }
        
        guard 200..<300 ~= httpResponse.statusCode else {
            if let errorString = String(data: data, encoding: .utf8) {
                print("DEBUG: Error response: \(errorString)")
            }
            throw EightSleepError.apiError(statusCode: httpResponse.statusCode, data: data)
        }
    }
}