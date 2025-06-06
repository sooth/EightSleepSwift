#!/usr/bin/swift

import Foundation

// Direct test of Eight Sleep authentication

let email = "test@example.com"  // Replace with your email
let password = "testpassword"   // Replace with your password

print("Testing Eight Sleep Authentication")
print("==================================")
print("Email: \(email)")
print("Password: \(String(repeating: "*", count: password.count))")
print()

let url = URL(string: "https://auth-api.8slp.net/v1/tokens")!
var request = URLRequest(url: url)
request.httpMethod = "POST"
request.setValue("application/json", forHTTPHeaderField: "Content-Type")
request.setValue("gzip", forHTTPHeaderField: "Accept-Encoding")
request.setValue("application/json", forHTTPHeaderField: "Accept")

let body: [String: Any] = [
    "client_id": "0894c7f33bb94800a03f1f4df13a4f38",
    "client_secret": "f0954a3ed5763ba3d06834c73731a32f15f168f47d4f164751275def86db0c76",
    "grant_type": "password",
    "username": email,
    "password": password
]

do {
    let jsonData = try JSONSerialization.data(withJSONObject: body)
    request.httpBody = jsonData
    
    print("Request body:")
    if let jsonString = String(data: jsonData, encoding: .utf8) {
        print(jsonString)
    }
    print()
    
    let semaphore = DispatchSemaphore(value: 0)
    var responseData: Data?
    var urlResponse: URLResponse?
    var error: Error?
    
    let task = URLSession.shared.dataTask(with: request) { data, response, err in
        responseData = data
        urlResponse = response
        error = err
        semaphore.signal()
    }
    
    task.resume()
    semaphore.wait()
    
    if let error = error {
        print("Network error: \(error)")
        exit(1)
    }
    
    if let httpResponse = urlResponse as? HTTPURLResponse {
        print("Status Code: \(httpResponse.statusCode)")
        print("Headers: \(httpResponse.allHeaderFields)")
        print()
    }
    
    if let data = responseData, let jsonString = String(data: data, encoding: .utf8) {
        print("Response:")
        print(jsonString)
        print()
        
        // Try to decode
        struct AuthResponse: Codable {
            let access_token: String
            let expires_in: Double
            let userId: String
        }
        
        do {
            let decoder = JSONDecoder()
            let authResponse = try decoder.decode(AuthResponse.self, from: data)
            print("✅ Success!")
            print("User ID: \(authResponse.userId)")
            print("Token: \(String(authResponse.access_token.prefix(20)))...")
            print("Expires in: \(authResponse.expires_in) seconds")
        } catch {
            print("❌ Decoding failed: \(error)")
            
            // Try to see what fields are actually present
            if let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                print("\nActual fields in response:")
                for (key, value) in dict {
                    print("  \(key): \(type(of: value))")
                }
            }
        }
    }
    
} catch {
    print("Error: \(error)")
}