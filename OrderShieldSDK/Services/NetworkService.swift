
import Foundation

class NetworkService {
    static let shared = NetworkService()
    
    private let baseURL = "https://ordershield-api.projectbeta.biz/api/sdk"
    private var apiKey: String?
    
    private init() {}
    
    func configure(apiKey: String) {
        self.apiKey = apiKey
    }
    
    // MARK: - cURL Logging Helper
    private func logCurlCommand(for request: URLRequest, endpoint: String) {
        guard let url = request.url else { return }
        
        var curlCommand = "curl -X '\(request.httpMethod ?? "GET")' \\\n"
        curlCommand += "  '\(url.absoluteString)' \\\n"
        
        // Add headers (excluding Content-Type for multipart as it will be set by curl)
        if let headers = request.allHTTPHeaderFields {
            for (key, value) in headers {
                if key.lowercased() == "content-type" && value.contains("multipart/form-data") {
                    // Skip Content-Type for multipart, curl will set it with boundary
                    continue
                }
                curlCommand += "  -H '\(key): \(value)' \\\n"
            }
        }
        
        // Add body for POST/PUT requests
        if let httpBody = request.httpBody, !httpBody.isEmpty {
            if let contentType = request.value(forHTTPHeaderField: "Content-Type"),
               contentType.contains("multipart/form-data") {
                // Extract boundary
                let boundary = contentType.components(separatedBy: "boundary=").last ?? ""
                
                // Parse multipart body to extract fields
                if let bodyString = String(data: httpBody, encoding: .utf8) {
                    let parts = bodyString.components(separatedBy: "--\(boundary)")
                    for part in parts {
                        if part.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || part.contains("--") {
                            continue
                        }
                        
                        let lines = part.components(separatedBy: "\r\n")
                        var fieldName: String?
                        var fieldValue: String?
                        var isFile = false
                        var fileName: String?
                        
                        for (index, line) in lines.enumerated() {
                            if line.contains("Content-Disposition: form-data") {
                                // Extract field name
                                if let nameRange = line.range(of: "name=\"") {
                                    let afterName = line[nameRange.upperBound...]
                                    if let endRange = afterName.range(of: "\"") {
                                        fieldName = String(afterName[..<endRange.lowerBound])
                                    }
                                }
                                
                                // Check if it's a file
                                if line.contains("filename=") {
                                    isFile = true
                                    if let fileRange = line.range(of: "filename=\"") {
                                        let afterFile = line[fileRange.upperBound...]
                                        if let endRange = afterFile.range(of: "\"") {
                                            fileName = String(afterFile[..<endRange.lowerBound])
                                        }
                                    }
                                }
                            } else if line.isEmpty && index > 0 && fieldName != nil {
                                // Next non-empty line after empty line is the value
                                if index + 1 < lines.count {
                                    let value = lines[index + 1]
                                    if !value.contains("--") && !value.isEmpty {
                                        fieldValue = value
                                    }
                                }
                            }
                        }
                        
                        if let name = fieldName {
                            if isFile, let file = fileName {
                                curlCommand += "  -F '\(name)=@/path/to/\(file)' \\\n"
                            } else if let value = fieldValue {
                                curlCommand += "  -F '\(name)=\(value)' \\\n"
                            }
                        }
                    }
                }
            } else {
                // For JSON, pretty print the body
                if let jsonObject = try? JSONSerialization.jsonObject(with: httpBody),
                   let jsonData = try? JSONSerialization.data(withJSONObject: jsonObject, options: .prettyPrinted),
                   let jsonString = String(data: jsonData, encoding: .utf8) {
                    // Format JSON for curl command
                    let escapedJson = jsonString
                        .replacingOccurrences(of: "'", with: "'\\''")
                        .replacingOccurrences(of: "\n", with: " ")
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                    curlCommand += "  -d '\(escapedJson)'"
                } else if let bodyString = String(data: httpBody, encoding: .utf8) {
                    curlCommand += "  -d '\(bodyString)'"
                }
            }
        }
        
        print("\n📡 [OrderShieldSDK] API Call: \(endpoint)")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print(curlCommand)
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
    }
    
    // MARK: - Device Registration
    func registerDevice(_ request: DeviceRegistrationRequest) async throws -> DeviceRegistrationResponse {
        guard let apiKey = apiKey else {
            throw NetworkError.missingAPIKey
        }
        
        let url = URL(string: "\(baseURL)/register-device")!
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "accept")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue(apiKey, forHTTPHeaderField: "X-API-KEY")
        
        let encoder = JSONEncoder()
        urlRequest.httpBody = try encoder.encode(request)
        
        logCurlCommand(for: urlRequest, endpoint: "register-device")
        
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.invalidResponse
        }
        
        let decoder = JSONDecoder()
        return try decoder.decode(DeviceRegistrationResponse.self, from: data)
    }
    
    // MARK: - Verification Settings
    func fetchVerificationSettings() async throws -> VerificationSettingsResponse {
        guard let apiKey = apiKey else {
            throw NetworkError.missingAPIKey
        }
        
        let url = URL(string: "\(baseURL)/verification-settings")!
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "GET"
        urlRequest.setValue("application/json", forHTTPHeaderField: "accept")
        urlRequest.setValue(apiKey, forHTTPHeaderField: "X-API-KEY")
        
        logCurlCommand(for: urlRequest, endpoint: "verification-settings")
        
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.invalidResponse
        }
        
        let decoder = JSONDecoder()
        return try decoder.decode(VerificationSettingsResponse.self, from: data)
    }
    
    // MARK: - Start Verification
    func startVerification(_ request: StartVerificationRequest) async throws -> StartVerificationResponse {
        guard let apiKey = apiKey else {
            throw NetworkError.missingAPIKey
        }
        
        let url = URL(string: "\(baseURL)/verification/start")!
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "accept")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue(apiKey, forHTTPHeaderField: "X-API-KEY")
        
        let encoder = JSONEncoder()
        urlRequest.httpBody = try encoder.encode(request)
        
        logCurlCommand(for: urlRequest, endpoint: "verification/start")
        
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.invalidResponse
        }
        
        let decoder = JSONDecoder()
        return try decoder.decode(StartVerificationResponse.self, from: data)
    }
    
    // MARK: - Selfie Verification
    func submitSelfie(
        customerId: String,
        sessionToken: String,
        imageData: Data,
        imageFormat: String = "jpeg"
    ) async throws -> SelfieVerificationResponse {
        guard let apiKey = apiKey else {
            throw NetworkError.missingAPIKey
        }
        
        let url = URL(string: "\(baseURL)/verification/selfie")!
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue(apiKey, forHTTPHeaderField: "X-API-KEY")
        
        let boundary = UUID().uuidString
        urlRequest.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        // Add customer_id
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"customer_id\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(customerId)\r\n".data(using: .utf8)!)
        
        // Add session_token
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"session_token\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(sessionToken)\r\n".data(using: .utf8)!)
        
        // Add image_format
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"image_format\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(imageFormat)\r\n".data(using: .utf8)!)
        
        // Add selfie_image
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"selfie_image\"; filename=\"selfie.\(imageFormat)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/\(imageFormat)\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n".data(using: .utf8)!)
        
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        urlRequest.httpBody = body
        
        logCurlCommand(for: urlRequest, endpoint: "verification/selfie")
        
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        
        // Log raw response for debugging
        if let responseString = String(data: data, encoding: .utf8) {
            print("📡 [OrderShieldSDK] Selfie Verification Response: \(responseString)")
        }
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        let decoder = JSONDecoder()
        
        // Try to decode the response
        do {
            let responseModel = try decoder.decode(SelfieVerificationResponse.self, from: data)
            
            // Log response details
            print("📡 [OrderShieldSDK] Selfie Verification - statusCode: \(responseModel.statusCode), status: '\(responseModel.status)', message: '\(responseModel.message)'")
            
            // Check if message indicates success
            let messageLowercased = responseModel.message.lowercased()
            let isSuccessMessage = messageLowercased.contains("success") || 
                                   messageLowercased.contains("successfully") ||
                                   messageLowercased.contains("data fetched successfully") ||
                                   messageLowercased.contains("data created successfully")
            
            // Check if message indicates already submitted/completed (should be treated as success)
            let isAlreadySubmittedMessage = messageLowercased.contains("already been submitted") ||
                                           messageLowercased.contains("already submitted") ||
                                           messageLowercased.contains("already completed") ||
                                           messageLowercased.contains("has already been")
            
            // Check statusCode and status - both must be success, OR statusCode is 200 with success message
            // OR if selfie is already submitted (400 status but already submitted message)
            if (responseModel.statusCode == 200 && responseModel.status == "success") || 
               (responseModel.statusCode == 200 && isSuccessMessage) ||
               (isAlreadySubmittedMessage && responseModel.statusCode == 400) {
                if isAlreadySubmittedMessage {
                    print("✅ [OrderShieldSDK] Selfie already submitted - treating as success - statusCode: \(responseModel.statusCode), status: '\(responseModel.status)', message: '\(responseModel.message)'")
                } else {
                    print("✅ [OrderShieldSDK] Selfie verification successful - statusCode: \(responseModel.statusCode), status: '\(responseModel.status)', message: '\(responseModel.message)'")
                }
                
                // Try to extract the actual StepCompletionData from the response if available
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let dataDict = json["data"] as? [String: Any],
                   let stepCompleted = dataDict["step_completed"] as? String,
                   let sessionDict = dataDict["verification_session"] as? [String: Any] {
                    let sessionId = sessionDict["session_id"] as? String ?? ""
                    let stepsCompleted = sessionDict["steps_completed"] as? [String] ?? []
                    let stepsRemaining = sessionDict["steps_remaining"] as? [String] ?? []
                    let stepsOptional = sessionDict["steps_optional"] as? [String] ?? []
                    let isComplete = sessionDict["is_complete"] as? Bool ?? false
                    let completedAt = sessionDict["completed_at"] as? String
                    
                    print("📡 [OrderShieldSDK] Using actual session data from response - sessionId: \(sessionId), stepsCompleted: \(stepsCompleted), stepsRemaining: \(stepsRemaining)")
                    
                    // Return response with extracted data
                    return SelfieVerificationResponse(
                        status: responseModel.status,
                        message: responseModel.message,
                        data: StepCompletionData(
                            stepCompleted: stepCompleted,
                            verificationSession: VerificationSession(
                                sessionId: sessionId,
                                stepsCompleted: stepsCompleted,
                                stepsRemaining: stepsRemaining,
                                stepsOptional: stepsOptional,
                                isComplete: isComplete,
                                completedAt: completedAt
                            )
                        ),
                        statusCode: responseModel.statusCode
                    )
                }
                
                // Fallback to responseModel.data if available
                if let stepData = responseModel.data {
                    return responseModel
                }
                
                // Return response even if data is nil (for backward compatibility)
                return responseModel
            } else {
                // API returned error status - use the message from API
                let errorMessage = responseModel.message.isEmpty ? "Selfie verification failed" : responseModel.message
                print("❌ [OrderShieldSDK] Selfie verification failed - statusCode: \(responseModel.statusCode), status: '\(responseModel.status)', message: '\(errorMessage)'")
                throw NSError(
                    domain: "OrderShieldSDK",
                    code: responseModel.statusCode,
                    userInfo: [NSLocalizedDescriptionKey: errorMessage]
                )
            }
        } catch let error as NSError {
            // If it's already an NSError with our domain, re-throw it
            if error.domain == "OrderShieldSDK" {
                print("❌ [OrderShieldSDK] Selfie verification error: \(error.localizedDescription)")
                throw error
            }
            
            // If decoding fails, try to extract error message from response
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                print("📡 [OrderShieldSDK] Decoding failed, trying to parse JSON: \(json)")
                if let message = json["message"] as? String,
                   let statusCode = json["statusCode"] as? Int,
                   let status = json["status"] as? String {
                    // Check if message indicates success
                    let messageLowercased = message.lowercased()
                    let isSuccessMessage = messageLowercased.contains("success") || 
                                           messageLowercased.contains("successfully") ||
                                           messageLowercased.contains("data fetched successfully") ||
                                           messageLowercased.contains("data created successfully")
                    
                    // Check if message indicates already submitted/completed (should be treated as success)
                    let isAlreadySubmittedMessage = messageLowercased.contains("already been submitted") ||
                                                   messageLowercased.contains("already submitted") ||
                                                   messageLowercased.contains("already completed") ||
                                                   messageLowercased.contains("has already been")
                    
                    // Check if it's actually a success response
                    // OR if selfie is already submitted (400 status but already submitted message)
                    if (statusCode == 200 && status == "success") || 
                       (statusCode == 200 && isSuccessMessage) ||
                       (isAlreadySubmittedMessage && statusCode == 400) {
                        if isAlreadySubmittedMessage {
                            print("✅ [OrderShieldSDK] Selfie already submitted - treating as success (parsed from JSON) - statusCode: \(statusCode), status: '\(status)', message: '\(message)'")
                        } else {
                            print("✅ [OrderShieldSDK] Selfie verification successful (parsed from JSON) - statusCode: \(statusCode), status: '\(status)', message: '\(message)'")
                        }
                        
                        // Try to extract the actual StepCompletionData from response if available
                        if let dataDict = json["data"] as? [String: Any],
                           let stepCompleted = dataDict["step_completed"] as? String,
                           let sessionDict = dataDict["verification_session"] as? [String: Any] {
                            let sessionId = sessionDict["session_id"] as? String ?? ""
                            let stepsCompleted = sessionDict["steps_completed"] as? [String] ?? []
                            let stepsRemaining = sessionDict["steps_remaining"] as? [String] ?? []
                            let stepsOptional = sessionDict["steps_optional"] as? [String] ?? []
                            let isComplete = sessionDict["is_complete"] as? Bool ?? false
                            let completedAt = sessionDict["completed_at"] as? String
                            
                            return SelfieVerificationResponse(
                                status: status,
                                message: message,
                                data: StepCompletionData(
                                    stepCompleted: stepCompleted,
                                    verificationSession: VerificationSession(
                                        sessionId: sessionId,
                                        stepsCompleted: stepsCompleted,
                                        stepsRemaining: stepsRemaining,
                                        stepsOptional: stepsOptional,
                                        isComplete: isComplete,
                                        completedAt: completedAt
                                    )
                                ),
                                statusCode: statusCode
                            )
                        }
                        
                        // Fallback to basic response if structure is different
                        return SelfieVerificationResponse(
                            status: status,
                            message: message,
                            data: nil,
                            statusCode: statusCode
                        )
                    } else {
                        print("❌ [OrderShieldSDK] Selfie verification failed - statusCode: \(statusCode), status: '\(status)', message: '\(message)'")
                        throw NSError(
                            domain: "OrderShieldSDK",
                            code: statusCode,
                            userInfo: [NSLocalizedDescriptionKey: message]
                        )
                    }
                }
            }
            
            // If HTTP status is not 200-299, throw invalid response
            if !(200...299).contains(httpResponse.statusCode) {
                print("❌ [OrderShieldSDK] Selfie verification HTTP error - statusCode: \(httpResponse.statusCode)")
                throw NetworkError.invalidResponse
            }
            
            // If we can't extract message, throw original error
            print("❌ [OrderShieldSDK] Selfie verification decoding error: \(error.localizedDescription)")
            throw error
        }
    }
    
    // MARK: - Email Verification
    func sendEmailCode(_ request: EmailSendCodeRequest) async throws -> StepCompletionData {
        guard let apiKey = apiKey else {
            throw NetworkError.missingAPIKey
        }
        
        let url = URL(string: "\(baseURL)/verification/email/send-code")!
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "accept")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue(apiKey, forHTTPHeaderField: "X-API-KEY")
        
        let encoder = JSONEncoder()
        urlRequest.httpBody = try encoder.encode(request)
        
        logCurlCommand(for: urlRequest, endpoint: "verification/email/send-code")
        
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        let decoder = JSONDecoder()
        
        // Log raw response for debugging
        if let responseString = String(data: data, encoding: .utf8) {
            print("📡 [OrderShieldSDK] Email Send Code Response: \(responseString)")
        }
        
        // Try to decode the response
        do {
            let responseModel = try decoder.decode(EmailSendCodeResponse.self, from: data)
            
            // Log response details
            print("📡 [OrderShieldSDK] Email Send Code - statusCode: \(responseModel.statusCode), status: '\(responseModel.status)', message: '\(responseModel.message)'")
            
            // Check if message indicates success (even if status field is different)
            let messageLowercased = responseModel.message.lowercased()
            let isSuccessMessage = messageLowercased.contains("success") || 
                                   messageLowercased.contains("successfully") ||
                                   messageLowercased.contains("data fetched successfully") ||
                                   messageLowercased.contains("data created successfully")
            
            // Check statusCode and status - both must be success, OR statusCode is 200 with success message
            if (responseModel.statusCode == 200 && responseModel.status == "success") || 
               (responseModel.statusCode == 200 && isSuccessMessage) {
                print("✅ [OrderShieldSDK] Email code sent successfully - statusCode: \(responseModel.statusCode), status: '\(responseModel.status)', message: '\(responseModel.message)'")
                // Return a dummy StepCompletionData since email send-code doesn't return session data
                // This maintains compatibility with the existing flow
                return StepCompletionData(
                    stepCompleted: "email",
                    verificationSession: VerificationSession(
                        sessionId: "",
                        stepsCompleted: ["email"],
                        stepsRemaining: [],
                        stepsOptional: [],
                        isComplete: false,
                        completedAt: nil
                    )
                )
            } else {
                // API returned error status - use the message from API
                let errorMessage = responseModel.message.isEmpty ? "Failed to send email code" : responseModel.message
                print("❌ [OrderShieldSDK] Email send code failed - statusCode: \(responseModel.statusCode), status: '\(responseModel.status)', message: '\(errorMessage)'")
                throw NSError(
                    domain: "OrderShieldSDK",
                    code: responseModel.statusCode,
                    userInfo: [NSLocalizedDescriptionKey: errorMessage]
                )
            }
        } catch let error as NSError {
            // If it's already an NSError with our domain, re-throw it
            if error.domain == "OrderShieldSDK" {
                print("❌ [OrderShieldSDK] Email send code error: \(error.localizedDescription)")
                throw error
            }
            
            // If decoding fails, try to extract error message from response
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                print("📡 [OrderShieldSDK] Decoding failed, trying to parse JSON: \(json)")
                if let message = json["message"] as? String,
                   let statusCode = json["statusCode"] as? Int,
                   let status = json["status"] as? String {
                    // Check if message indicates success
                    let messageLowercased = message.lowercased()
                    let isSuccessMessage = messageLowercased.contains("success") || 
                                           messageLowercased.contains("successfully") ||
                                           messageLowercased.contains("data fetched successfully") ||
                                           messageLowercased.contains("data created successfully")
                    
                    // Check if it's actually a success response
                    if (statusCode == 200 && status == "success") || 
                       (statusCode == 200 && isSuccessMessage) {
                        print("✅ [OrderShieldSDK] Email code sent successfully (parsed from JSON) - statusCode: \(statusCode), status: '\(status)', message: '\(message)'")
                        return StepCompletionData(
                            stepCompleted: "email",
                            verificationSession: VerificationSession(
                                sessionId: "",
                                stepsCompleted: ["email"],
                                stepsRemaining: [],
                                stepsOptional: [],
                                isComplete: false,
                                completedAt: nil
                            )
                        )
                    } else {
                        print("❌ [OrderShieldSDK] Email send code failed - statusCode: \(statusCode), status: '\(status)', message: '\(message)'")
                        throw NSError(
                            domain: "OrderShieldSDK",
                            code: statusCode,
                            userInfo: [NSLocalizedDescriptionKey: message]
                        )
                    }
                }
            }
            
            // If we can't extract message, throw original error
            print("❌ [OrderShieldSDK] Email send code decoding error: \(error.localizedDescription)")
            throw error
        }
    }
    
    func verifyEmailCode(_ request: EmailVerifyCodeRequest) async throws -> StepCompletionData {
        guard let apiKey = apiKey else {
            throw NetworkError.missingAPIKey
        }
        
        let url = URL(string: "\(baseURL)/verification/email/verify-code")!
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "accept")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue(apiKey, forHTTPHeaderField: "X-API-KEY")
        
        let encoder = JSONEncoder()
        urlRequest.httpBody = try encoder.encode(request)
        
        logCurlCommand(for: urlRequest, endpoint: "verification/email/verify-code")
        
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        let decoder = JSONDecoder()
        
        // Log raw response for debugging
        if let responseString = String(data: data, encoding: .utf8) {
            print("📡 [OrderShieldSDK] Email Verify Code Response: \(responseString)")
        }
        
        // Try to decode the response
        do {
            let responseModel = try decoder.decode(EmailVerifyCodeResponse.self, from: data)
            
            // Log response details
            print("📡 [OrderShieldSDK] Email Verify Code - statusCode: \(responseModel.statusCode), status: '\(responseModel.status)', message: '\(responseModel.message)'")
            
            // Check if message indicates success (even if status field is different)
            let messageLowercased = responseModel.message.lowercased()
            let isSuccessMessage = messageLowercased.contains("success") || 
                                   messageLowercased.contains("successfully") ||
                                   messageLowercased.contains("data fetched successfully") ||
                                   messageLowercased.contains("data created successfully")
            
            // Check statusCode and status - both must be success, OR statusCode is 200 with success message
            if (responseModel.statusCode == 200 && responseModel.status == "success") || 
               (responseModel.statusCode == 200 && isSuccessMessage) {
                print("✅ [OrderShieldSDK] Email verification successful - statusCode: \(responseModel.statusCode), status: '\(responseModel.status)', message: '\(responseModel.message)'")
                // Return a dummy StepCompletionData since email verify-code doesn't return session data
                return StepCompletionData(
                    stepCompleted: "email",
                    verificationSession: VerificationSession(
                        sessionId: "",
                        stepsCompleted: ["email"],
                        stepsRemaining: [],
                        stepsOptional: [],
                        isComplete: false,
                        completedAt: nil
                    )
                )
            } else {
                // API returned error status - use the message from API
                let errorMessage = responseModel.message.isEmpty ? "Email verification failed" : responseModel.message
                print("❌ [OrderShieldSDK] Email verification failed - statusCode: \(responseModel.statusCode), status: '\(responseModel.status)', message: '\(errorMessage)'")
                throw NSError(
                    domain: "OrderShieldSDK",
                    code: responseModel.statusCode,
                    userInfo: [NSLocalizedDescriptionKey: errorMessage]
                )
            }
        } catch let error as NSError {
            // If it's already an NSError with our domain, re-throw it
            if error.domain == "OrderShieldSDK" {
                print("❌ [OrderShieldSDK] Email verification error: \(error.localizedDescription)")
                throw error
            }
            
            // If decoding fails, try to extract error message from response
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                print("📡 [OrderShieldSDK] Decoding failed, trying to parse JSON: \(json)")
                if let message = json["message"] as? String,
                   let statusCode = json["statusCode"] as? Int,
                   let status = json["status"] as? String {
                    // Check if message indicates success
                    let messageLowercased = message.lowercased()
                    let isSuccessMessage = messageLowercased.contains("success") || 
                                           messageLowercased.contains("successfully") ||
                                           messageLowercased.contains("data fetched successfully") ||
                                           messageLowercased.contains("data created successfully")
                    
                    // Check if it's actually a success response
                    if (statusCode == 200 && status == "success") || 
                       (statusCode == 200 && isSuccessMessage) {
                        print("✅ [OrderShieldSDK] Email verification successful (parsed from JSON) - statusCode: \(statusCode), status: '\(status)', message: '\(message)'")
                        return StepCompletionData(
                            stepCompleted: "email",
                            verificationSession: VerificationSession(
                                sessionId: "",
                                stepsCompleted: ["email"],
                                stepsRemaining: [],
                                stepsOptional: [],
                                isComplete: false,
                                completedAt: nil
                            )
                        )
                    } else {
                        print("❌ [OrderShieldSDK] Email verification failed - statusCode: \(statusCode), status: '\(status)', message: '\(message)'")
                        throw NSError(
                            domain: "OrderShieldSDK",
                            code: statusCode,
                            userInfo: [NSLocalizedDescriptionKey: message]
                        )
                    }
                }
            }
            
            // If we can't extract message, throw original error
            print("❌ [OrderShieldSDK] Email verification decoding error: \(error.localizedDescription)")
            throw error
        }
    }
    
    // MARK: - Phone Verification
    func sendPhoneCode(_ request: PhoneSendCodeRequest) async throws -> StepCompletionData {
        guard let apiKey = apiKey else {
            throw NetworkError.missingAPIKey
        }
        
        let url = URL(string: "\(baseURL)/verification/phone/send-code")!
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "accept")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue(apiKey, forHTTPHeaderField: "X-API-KEY")
        
        let encoder = JSONEncoder()
        urlRequest.httpBody = try encoder.encode(request)
        
        logCurlCommand(for: urlRequest, endpoint: "verification/phone/send-code")
        
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        let decoder = JSONDecoder()
        
        // Log raw response for debugging
        if let responseString = String(data: data, encoding: .utf8) {
            print("📡 [OrderShieldSDK] Phone Send Code Response: \(responseString)")
        }
        
        // Try to decode the response
        do {
            let responseModel = try decoder.decode(PhoneSendCodeResponse.self, from: data)
            
            // Log response details
            print("📡 [OrderShieldSDK] Phone Send Code - statusCode: \(responseModel.statusCode), status: '\(responseModel.status)', message: '\(responseModel.message)'")
            
            // Check if message indicates success (even if status field is different)
            let messageLowercased = responseModel.message.lowercased()
            let isSuccessMessage = messageLowercased.contains("success") || 
                                   messageLowercased.contains("successfully") ||
                                   messageLowercased.contains("data fetched successfully") ||
                                   messageLowercased.contains("data created successfully")
            
            // Check statusCode and status - both must be success, OR statusCode is 200 with success message
            if (responseModel.statusCode == 200 && responseModel.status == "success") || 
               (responseModel.statusCode == 200 && isSuccessMessage) {
                print("✅ [OrderShieldSDK] Phone code sent successfully - statusCode: \(responseModel.statusCode), status: '\(responseModel.status)', message: '\(responseModel.message)'")
                // Return a dummy StepCompletionData since phone send-code doesn't return session data
                return StepCompletionData(
                    stepCompleted: "sms",
                    verificationSession: VerificationSession(
                        sessionId: "",
                        stepsCompleted: ["sms"],
                        stepsRemaining: [],
                        stepsOptional: [],
                        isComplete: false,
                        completedAt: nil
                    )
                )
            } else {
                // API returned error status - use the message from API
                let errorMessage = responseModel.message.isEmpty ? "Failed to send phone code" : responseModel.message
                print("❌ [OrderShieldSDK] Phone send code failed - statusCode: \(responseModel.statusCode), status: '\(responseModel.status)', message: '\(errorMessage)'")
                throw NSError(
                    domain: "OrderShieldSDK",
                    code: responseModel.statusCode,
                    userInfo: [NSLocalizedDescriptionKey: errorMessage]
                )
            }
        } catch let error as NSError {
            // If it's already an NSError with our domain, re-throw it
            if error.domain == "OrderShieldSDK" {
                print("❌ [OrderShieldSDK] Phone send code error: \(error.localizedDescription)")
                throw error
            }
            
            // If decoding fails, try to extract error message from response
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                print("📡 [OrderShieldSDK] Decoding failed, trying to parse JSON: \(json)")
                if let message = json["message"] as? String,
                   let statusCode = json["statusCode"] as? Int,
                   let status = json["status"] as? String {
                    // Check if message indicates success
                    let messageLowercased = message.lowercased()
                    let isSuccessMessage = messageLowercased.contains("success") || 
                                           messageLowercased.contains("successfully") ||
                                           messageLowercased.contains("data fetched successfully") ||
                                           messageLowercased.contains("data created successfully")
                    
                    // Check if it's actually a success response
                    if (statusCode == 200 && status == "success") || 
                       (statusCode == 200 && isSuccessMessage) {
                        print("✅ [OrderShieldSDK] Phone code sent successfully (parsed from JSON) - statusCode: \(statusCode), status: '\(status)', message: '\(message)'")
                        return StepCompletionData(
                            stepCompleted: "sms",
                            verificationSession: VerificationSession(
                                sessionId: "",
                                stepsCompleted: ["sms"],
                                stepsRemaining: [],
                                stepsOptional: [],
                                isComplete: false,
                                completedAt: nil
                            )
                        )
                    } else {
                        print("❌ [OrderShieldSDK] Phone send code failed - statusCode: \(statusCode), status: '\(status)', message: '\(message)'")
                        throw NSError(
                            domain: "OrderShieldSDK",
                            code: statusCode,
                            userInfo: [NSLocalizedDescriptionKey: message]
                        )
                    }
                }
            }
            
            // If we can't extract message, throw original error
            print("❌ [OrderShieldSDK] Phone send code decoding error: \(error.localizedDescription)")
            throw error
        }
    }
    
    func verifyPhoneCode(_ request: PhoneVerifyCodeRequest) async throws -> StepCompletionData {
        guard let apiKey = apiKey else {
            throw NetworkError.missingAPIKey
        }
        
        let url = URL(string: "\(baseURL)/verification/phone/verify-code")!
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "accept")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue(apiKey, forHTTPHeaderField: "X-API-KEY")
        
        let encoder = JSONEncoder()
        urlRequest.httpBody = try encoder.encode(request)
        
        logCurlCommand(for: urlRequest, endpoint: "verification/phone/verify-code")
        
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        let decoder = JSONDecoder()
        
        // Log raw response for debugging
        if let responseString = String(data: data, encoding: .utf8) {
            print("📡 [OrderShieldSDK] Phone Verify Code Response: \(responseString)")
        }
        
        // Try to decode the response
        do {
            let responseModel = try decoder.decode(PhoneVerifyCodeResponse.self, from: data)
            
            // Log response details
            print("📡 [OrderShieldSDK] Phone Verify Code - statusCode: \(responseModel.statusCode), status: '\(responseModel.status)', message: '\(responseModel.message)'")
            
            // Check if message indicates success (even if status field is different)
            let messageLowercased = responseModel.message.lowercased()
            let isSuccessMessage = messageLowercased.contains("success") || 
                                   messageLowercased.contains("successfully") ||
                                   messageLowercased.contains("data fetched successfully") ||
                                   messageLowercased.contains("data created successfully")
            
            // Check statusCode and status - both must be success, OR statusCode is 200 with success message
            if (responseModel.statusCode == 200 && responseModel.status == "success") || 
               (responseModel.statusCode == 200 && isSuccessMessage) {
                print("✅ [OrderShieldSDK] Phone verification successful - statusCode: \(responseModel.statusCode), status: '\(responseModel.status)', message: '\(responseModel.message)'")
                
                // Try to extract the actual StepCompletionData from the response if available
                // The API response contains full session data, not just a success flag
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let dataDict = json["data"] as? [String: Any],
                   let stepCompleted = dataDict["step_completed"] as? String,
                   let sessionDict = dataDict["verification_session"] as? [String: Any] {
                    let sessionId = sessionDict["session_id"] as? String ?? ""
                    let stepsCompleted = sessionDict["steps_completed"] as? [String] ?? []
                    let stepsRemaining = sessionDict["steps_remaining"] as? [String] ?? []
                    let stepsOptional = sessionDict["steps_optional"] as? [String] ?? []
                    let isComplete = sessionDict["is_complete"] as? Bool ?? false
                    let completedAt = sessionDict["completed_at"] as? String
                    
                    print("📡 [OrderShieldSDK] Using actual session data from response - sessionId: \(sessionId), stepsCompleted: \(stepsCompleted), stepsRemaining: \(stepsRemaining)")
                    
                    return StepCompletionData(
                        stepCompleted: stepCompleted,
                        verificationSession: VerificationSession(
                            sessionId: sessionId,
                            stepsCompleted: stepsCompleted,
                            stepsRemaining: stepsRemaining,
                            stepsOptional: stepsOptional,
                            isComplete: isComplete,
                            completedAt: completedAt
                        )
                    )
                }
                
                // Fallback to dummy StepCompletionData if structure is different
                return StepCompletionData(
                    stepCompleted: "sms",
                    verificationSession: VerificationSession(
                        sessionId: "",
                        stepsCompleted: ["sms"],
                        stepsRemaining: [],
                        stepsOptional: [],
                        isComplete: false,
                        completedAt: nil
                    )
                )
            } else {
                // API returned error status - use the message from API
                let errorMessage = responseModel.message.isEmpty ? "Phone verification failed" : responseModel.message
                print("❌ [OrderShieldSDK] Phone verification failed - statusCode: \(responseModel.statusCode), status: '\(responseModel.status)', message: '\(errorMessage)'")
                throw NSError(
                    domain: "OrderShieldSDK",
                    code: responseModel.statusCode,
                    userInfo: [NSLocalizedDescriptionKey: errorMessage]
                )
            }
        } catch let error as NSError {
            // If it's already an NSError with our domain, re-throw it
            if error.domain == "OrderShieldSDK" {
                print("❌ [OrderShieldSDK] Phone verification error: \(error.localizedDescription)")
                throw error
            }
            
            // If decoding fails, try to extract error message from response
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                print("📡 [OrderShieldSDK] Decoding failed, trying to parse JSON: \(json)")
                if let message = json["message"] as? String,
                   let statusCode = json["statusCode"] as? Int,
                   let status = json["status"] as? String {
                    // Check if message indicates success
                    let messageLowercased = message.lowercased()
                    let isSuccessMessage = messageLowercased.contains("success") || 
                                           messageLowercased.contains("successfully") ||
                                           messageLowercased.contains("data fetched successfully") ||
                                           messageLowercased.contains("data created successfully")
                    
                    // Check if it's actually a success response
                    if (statusCode == 200 && status == "success") || 
                       (statusCode == 200 && isSuccessMessage) {
                        print("✅ [OrderShieldSDK] Phone verification successful (parsed from JSON) - statusCode: \(statusCode), status: '\(status)', message: '\(message)'")
                        
                        // Try to extract the actual StepCompletionData from response if available
                        if let dataDict = json["data"] as? [String: Any],
                           let stepCompleted = dataDict["step_completed"] as? String,
                           let sessionDict = dataDict["verification_session"] as? [String: Any] {
                            let sessionId = sessionDict["session_id"] as? String ?? ""
                            let stepsCompleted = sessionDict["steps_completed"] as? [String] ?? []
                            let stepsRemaining = sessionDict["steps_remaining"] as? [String] ?? []
                            let stepsOptional = sessionDict["steps_optional"] as? [String] ?? []
                            let isComplete = sessionDict["is_complete"] as? Bool ?? false
                            let completedAt = sessionDict["completed_at"] as? String
                            
                            return StepCompletionData(
                                stepCompleted: stepCompleted,
                                verificationSession: VerificationSession(
                                    sessionId: sessionId,
                                    stepsCompleted: stepsCompleted,
                                    stepsRemaining: stepsRemaining,
                                    stepsOptional: stepsOptional,
                                    isComplete: isComplete,
                                    completedAt: completedAt
                                )
                            )
                        }
                        
                        // Fallback to dummy data if structure is different
                        return StepCompletionData(
                            stepCompleted: "sms",
                            verificationSession: VerificationSession(
                                sessionId: "",
                                stepsCompleted: ["sms"],
                                stepsRemaining: [],
                                stepsOptional: [],
                                isComplete: false,
                                completedAt: nil
                            )
                        )
                    } else {
                        print("❌ [OrderShieldSDK] Phone verification failed - statusCode: \(statusCode), status: '\(status)', message: '\(message)'")
                        throw NSError(
                            domain: "OrderShieldSDK",
                            code: statusCode,
                            userInfo: [NSLocalizedDescriptionKey: message]
                        )
                    }
                }
            }
            
            // If we can't extract message, throw original error
            print("❌ [OrderShieldSDK] Phone verification decoding error: \(error.localizedDescription)")
            throw error
        }
    }
    
    // MARK: - Terms Verification
    func submitTerms(_ request: TermsVerificationRequest) async throws -> StepCompletionData {
        guard let apiKey = apiKey else {
            throw NetworkError.missingAPIKey
        }
        
        let url = URL(string: "\(baseURL)/verification/terms")!
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "accept")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue(apiKey, forHTTPHeaderField: "X-API-KEY")
        
        let encoder = JSONEncoder()
        urlRequest.httpBody = try encoder.encode(request)
        
        logCurlCommand(for: urlRequest, endpoint: "verification/terms")
        
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        
        // Log raw response for debugging
        if let responseString = String(data: data, encoding: .utf8) {
            print("📡 [OrderShieldSDK] Terms Verification Response: \(responseString)")
        }
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        let decoder = JSONDecoder()
        
        // Try to decode the response
        do {
            let responseModel = try decoder.decode(SelfieVerificationResponse.self, from: data)
            
            // Log response details
            print("📡 [OrderShieldSDK] Terms Verification - statusCode: \(responseModel.statusCode), status: '\(responseModel.status)', message: '\(responseModel.message)'")
            
            // Check if message indicates success
            let messageLowercased = responseModel.message.lowercased()
            let isSuccessMessage = messageLowercased.contains("success") || 
                                   messageLowercased.contains("successfully") ||
                                   messageLowercased.contains("data fetched successfully") ||
                                   messageLowercased.contains("data created successfully")
            
            // Check if message indicates already accepted/completed (should be treated as success)
            let isAlreadyAcceptedMessage = messageLowercased.contains("already been accepted") ||
                                          messageLowercased.contains("already accepted") ||
                                          messageLowercased.contains("already completed") ||
                                          messageLowercased.contains("has already been")
            
            // Check statusCode and status - both must be success, OR statusCode is 200 with success message
            // OR if terms are already accepted (400 status but already accepted message)
            if (responseModel.statusCode == 200 && responseModel.status == "success") || 
               (responseModel.statusCode == 200 && isSuccessMessage) ||
               (isAlreadyAcceptedMessage && responseModel.statusCode == 400) {
                if isAlreadyAcceptedMessage {
                    print("✅ [OrderShieldSDK] Terms already accepted - treating as success - statusCode: \(responseModel.statusCode), status: '\(responseModel.status)', message: '\(responseModel.message)'")
                } else {
                    print("✅ [OrderShieldSDK] Terms verification successful - statusCode: \(responseModel.statusCode), status: '\(responseModel.status)', message: '\(responseModel.message)'")
                }
                
                // Try to extract the actual StepCompletionData from the response if available
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let dataDict = json["data"] as? [String: Any],
                   let stepCompleted = dataDict["step_completed"] as? String,
                   let sessionDict = dataDict["verification_session"] as? [String: Any] {
                    let sessionId = sessionDict["session_id"] as? String ?? ""
                    let stepsCompleted = sessionDict["steps_completed"] as? [String] ?? []
                    let stepsRemaining = sessionDict["steps_remaining"] as? [String] ?? []
                    let stepsOptional = sessionDict["steps_optional"] as? [String] ?? []
                    let isComplete = sessionDict["is_complete"] as? Bool ?? false
                    let completedAt = sessionDict["completed_at"] as? String
                    
                    print("📡 [OrderShieldSDK] Using actual session data from response - sessionId: \(sessionId), stepsCompleted: \(stepsCompleted), stepsRemaining: \(stepsRemaining)")
                    
                    return StepCompletionData(
                        stepCompleted: stepCompleted,
                        verificationSession: VerificationSession(
                            sessionId: sessionId,
                            stepsCompleted: stepsCompleted,
                            stepsRemaining: stepsRemaining,
                            stepsOptional: stepsOptional,
                            isComplete: isComplete,
                            completedAt: completedAt
                        )
                    )
                }
                
                // Fallback to responseModel.data if available
                if let stepData = responseModel.data {
                    return stepData
                }
                
                // Fallback to dummy data if structure is different
                return StepCompletionData(
                    stepCompleted: "terms",
                    verificationSession: VerificationSession(
                        sessionId: "",
                        stepsCompleted: ["terms"],
                        stepsRemaining: [],
                        stepsOptional: [],
                        isComplete: false,
                        completedAt: nil
                    )
                )
            } else {
                // API returned error status - use the message from API
                let errorMessage = responseModel.message.isEmpty ? "Terms verification failed" : responseModel.message
                print("❌ [OrderShieldSDK] Terms verification failed - statusCode: \(responseModel.statusCode), status: '\(responseModel.status)', message: '\(errorMessage)'")
                throw NSError(
                    domain: "OrderShieldSDK",
                    code: responseModel.statusCode,
                    userInfo: [NSLocalizedDescriptionKey: errorMessage]
                )
            }
        } catch let error as NSError {
            // If it's already an NSError with our domain, re-throw it
            if error.domain == "OrderShieldSDK" {
                print("❌ [OrderShieldSDK] Terms verification error: \(error.localizedDescription)")
                throw error
            }
            
            // If decoding fails, try to extract error message from response
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                print("📡 [OrderShieldSDK] Decoding failed, trying to parse JSON: \(json)")
                if let message = json["message"] as? String,
                   let statusCode = json["statusCode"] as? Int,
                   let status = json["status"] as? String {
                    // Check if message indicates success
                    let messageLowercased = message.lowercased()
                    let isSuccessMessage = messageLowercased.contains("success") || 
                                           messageLowercased.contains("successfully") ||
                                           messageLowercased.contains("data fetched successfully") ||
                                           messageLowercased.contains("data created successfully")
                    
                    // Check if message indicates already accepted/completed (should be treated as success)
                    let isAlreadyAcceptedMessage = messageLowercased.contains("already been accepted") ||
                                                  messageLowercased.contains("already accepted") ||
                                                  messageLowercased.contains("already completed") ||
                                                  messageLowercased.contains("has already been")
                    
                    // Check if it's actually a success response
                    // OR if terms are already accepted (400 status but already accepted message)
                    if (statusCode == 200 && status == "success") || 
                       (statusCode == 200 && isSuccessMessage) ||
                       (isAlreadyAcceptedMessage && statusCode == 400) {
                        if isAlreadyAcceptedMessage {
                            print("✅ [OrderShieldSDK] Terms already accepted - treating as success (parsed from JSON) - statusCode: \(statusCode), status: '\(status)', message: '\(message)'")
                        } else {
                            print("✅ [OrderShieldSDK] Terms verification successful (parsed from JSON) - statusCode: \(statusCode), status: '\(status)', message: '\(message)'")
                        }
                        
                        // Try to extract the actual StepCompletionData from response if available
                        if let dataDict = json["data"] as? [String: Any],
                           let stepCompleted = dataDict["step_completed"] as? String,
                           let sessionDict = dataDict["verification_session"] as? [String: Any] {
                            let sessionId = sessionDict["session_id"] as? String ?? ""
                            let stepsCompleted = sessionDict["steps_completed"] as? [String] ?? []
                            let stepsRemaining = sessionDict["steps_remaining"] as? [String] ?? []
                            let stepsOptional = sessionDict["steps_optional"] as? [String] ?? []
                            let isComplete = sessionDict["is_complete"] as? Bool ?? false
                            let completedAt = sessionDict["completed_at"] as? String
                            
                            return StepCompletionData(
                                stepCompleted: stepCompleted,
                                verificationSession: VerificationSession(
                                    sessionId: sessionId,
                                    stepsCompleted: stepsCompleted,
                                    stepsRemaining: stepsRemaining,
                                    stepsOptional: stepsOptional,
                                    isComplete: isComplete,
                                    completedAt: completedAt
                                )
                            )
                        }
                        
                        // Fallback to dummy data if structure is different
                        return StepCompletionData(
                            stepCompleted: "terms",
                            verificationSession: VerificationSession(
                                sessionId: "",
                                stepsCompleted: ["terms"],
                                stepsRemaining: [],
                                stepsOptional: [],
                                isComplete: false,
                                completedAt: nil
                            )
                        )
                    } else {
                        print("❌ [OrderShieldSDK] Terms verification failed - statusCode: \(statusCode), status: '\(status)', message: '\(message)'")
                        throw NSError(
                            domain: "OrderShieldSDK",
                            code: statusCode,
                            userInfo: [NSLocalizedDescriptionKey: message]
                        )
                    }
                }
            }
            
            // If HTTP status is not 200-299, throw invalid response
            if !(200...299).contains(httpResponse.statusCode) {
                print("❌ [OrderShieldSDK] Terms verification HTTP error - statusCode: \(httpResponse.statusCode)")
                throw NetworkError.invalidResponse
            }
            
            // If we can't extract message, throw original error
            print("❌ [OrderShieldSDK] Terms verification decoding error: \(error.localizedDescription)")
            throw error
        }
    }
    
    // MARK: - User Info Verification
    func submitUserInfo(_ request: UserInfoVerificationRequest) async throws -> StepCompletionData {
        guard let apiKey = apiKey else {
            throw NetworkError.missingAPIKey
        }
        
        let url = URL(string: "\(baseURL)/verification/user-info")!
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "accept")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue(apiKey, forHTTPHeaderField: "X-API-KEY")
        
        let encoder = JSONEncoder()
        urlRequest.httpBody = try encoder.encode(request)
        
        logCurlCommand(for: urlRequest, endpoint: "verification/user-info")
        
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        
        // Log raw response for debugging
        if let responseString = String(data: data, encoding: .utf8) {
            print("📡 [OrderShieldSDK] User Info Verification Response: \(responseString)")
        }
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        let decoder = JSONDecoder()
        
        // Try to decode the response
        do {
            let responseModel = try decoder.decode(SelfieVerificationResponse.self, from: data)
            
            // Log response details
            print("📡 [OrderShieldSDK] User Info Verification - statusCode: \(responseModel.statusCode), status: '\(responseModel.status)', message: '\(responseModel.message)'")
            
            // Check if message indicates success
            let messageLowercased = responseModel.message.lowercased()
            let isSuccessMessage = messageLowercased.contains("success") || 
                                   messageLowercased.contains("successfully") ||
                                   messageLowercased.contains("data fetched successfully") ||
                                   messageLowercased.contains("data created successfully")
            
            // Check statusCode and status - both must be success, OR statusCode is 200 with success message
            if (responseModel.statusCode == 200 && responseModel.status == "success") || 
               (responseModel.statusCode == 200 && isSuccessMessage) {
                print("✅ [OrderShieldSDK] User Info verification successful - statusCode: \(responseModel.statusCode), status: '\(responseModel.status)', message: '\(responseModel.message)'")
                
                // Try to extract the actual StepCompletionData from the response if available
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let dataDict = json["data"] as? [String: Any],
                   let stepCompleted = dataDict["step_completed"] as? String,
                   let sessionDict = dataDict["verification_session"] as? [String: Any] {
                    let sessionId = sessionDict["session_id"] as? String ?? ""
                    let stepsCompleted = sessionDict["steps_completed"] as? [String] ?? []
                    let stepsRemaining = sessionDict["steps_remaining"] as? [String] ?? []
                    let stepsOptional = sessionDict["steps_optional"] as? [String] ?? []
                    let isComplete = sessionDict["is_complete"] as? Bool ?? false
                    let completedAt = sessionDict["completed_at"] as? String
                    
                    print("📡 [OrderShieldSDK] Using actual session data from response - sessionId: \(sessionId), stepsCompleted: \(stepsCompleted), stepsRemaining: \(stepsRemaining)")
                    
                    return StepCompletionData(
                        stepCompleted: stepCompleted,
                        verificationSession: VerificationSession(
                            sessionId: sessionId,
                            stepsCompleted: stepsCompleted,
                            stepsRemaining: stepsRemaining,
                            stepsOptional: stepsOptional,
                            isComplete: isComplete,
                            completedAt: completedAt
                        )
                    )
                }
                
                // Fallback to responseModel.data if available
                if let stepData = responseModel.data {
                    return stepData
                }
                
                // Fallback to dummy data if structure is different
                return StepCompletionData(
                    stepCompleted: "userInfo",
                    verificationSession: VerificationSession(
                        sessionId: "",
                        stepsCompleted: ["userInfo"],
                        stepsRemaining: [],
                        stepsOptional: [],
                        isComplete: false,
                        completedAt: nil
                    )
                )
            } else {
                // API returned error status - use the message from API
                let errorMessage = responseModel.message.isEmpty ? "User Info verification failed" : responseModel.message
                print("❌ [OrderShieldSDK] User Info verification failed - statusCode: \(responseModel.statusCode), status: '\(responseModel.status)', message: '\(errorMessage)'")
                throw NSError(
                    domain: "OrderShieldSDK",
                    code: responseModel.statusCode,
                    userInfo: [NSLocalizedDescriptionKey: errorMessage]
                )
            }
        } catch let error as NSError {
            // If it's already an NSError with our domain, re-throw it
            if error.domain == "OrderShieldSDK" {
                print("❌ [OrderShieldSDK] User Info verification error: \(error.localizedDescription)")
                throw error
            }
            
            // If decoding fails, try to extract error message from response
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                print("📡 [OrderShieldSDK] Decoding failed, trying to parse JSON: \(json)")
                if let message = json["message"] as? String,
                   let statusCode = json["statusCode"] as? Int,
                   let status = json["status"] as? String {
                    // Check if message indicates success
                    let messageLowercased = message.lowercased()
                    let isSuccessMessage = messageLowercased.contains("success") || 
                                           messageLowercased.contains("successfully") ||
                                           messageLowercased.contains("data fetched successfully") ||
                                           messageLowercased.contains("data created successfully")
                    
                    // Check if it's actually a success response
                    if (statusCode == 200 && status == "success") || 
                       (statusCode == 200 && isSuccessMessage) {
                        print("✅ [OrderShieldSDK] User Info verification successful (parsed from JSON) - statusCode: \(statusCode), status: '\(status)', message: '\(message)'")
                        
                        // Try to extract the actual StepCompletionData from response if available
                        if let dataDict = json["data"] as? [String: Any],
                           let stepCompleted = dataDict["step_completed"] as? String,
                           let sessionDict = dataDict["verification_session"] as? [String: Any] {
                            let sessionId = sessionDict["session_id"] as? String ?? ""
                            let stepsCompleted = sessionDict["steps_completed"] as? [String] ?? []
                            let stepsRemaining = sessionDict["steps_remaining"] as? [String] ?? []
                            let stepsOptional = sessionDict["steps_optional"] as? [String] ?? []
                            let isComplete = sessionDict["is_complete"] as? Bool ?? false
                            let completedAt = sessionDict["completed_at"] as? String
                            
                            return StepCompletionData(
                                stepCompleted: stepCompleted,
                                verificationSession: VerificationSession(
                                    sessionId: sessionId,
                                    stepsCompleted: stepsCompleted,
                                    stepsRemaining: stepsRemaining,
                                    stepsOptional: stepsOptional,
                                    isComplete: isComplete,
                                    completedAt: completedAt
                                )
                            )
                        }
                        
                        // Fallback to dummy data if structure is different
                        return StepCompletionData(
                            stepCompleted: "userInfo",
                            verificationSession: VerificationSession(
                                sessionId: "",
                                stepsCompleted: ["userInfo"],
                                stepsRemaining: [],
                                stepsOptional: [],
                                isComplete: false,
                                completedAt: nil
                            )
                        )
                    } else {
                        print("❌ [OrderShieldSDK] User Info verification failed - statusCode: \(statusCode), status: '\(status)', message: '\(message)'")
                        throw NSError(
                            domain: "OrderShieldSDK",
                            code: statusCode,
                            userInfo: [NSLocalizedDescriptionKey: message]
                        )
                    }
                }
            }
            
            // If HTTP status is not 200-299, throw invalid response
            if !(200...299).contains(httpResponse.statusCode) {
                print("❌ [OrderShieldSDK] User Info verification HTTP error - statusCode: \(httpResponse.statusCode)")
                throw NetworkError.invalidResponse
            }
            
            // If we can't extract message, throw original error
            print("❌ [OrderShieldSDK] User Info verification decoding error: \(error.localizedDescription)")
            throw error
        }
    }
    
    // MARK: - Signature Verification (Multipart)
    func submitSignature(
        customerId: String,
        sessionToken: String,
        imageData: Data,
        imageFormat: String = "png"
    ) async throws -> StepCompletionData {
        guard let apiKey = apiKey else {
            throw NetworkError.missingAPIKey
        }
        
        let url = URL(string: "\(baseURL)/verification/signature")!
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue(apiKey, forHTTPHeaderField: "X-API-KEY")
        
        let boundary = UUID().uuidString
        urlRequest.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        // Add customer_id
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"customer_id\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(customerId)\r\n".data(using: .utf8)!)
        
        // Add session_token
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"session_token\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(sessionToken)\r\n".data(using: .utf8)!)
        
        // Add image_format
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"image_format\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(imageFormat)\r\n".data(using: .utf8)!)
        
        // Add signature_image
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"signature_image\"; filename=\"signature.\(imageFormat)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/\(imageFormat)\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n".data(using: .utf8)!)
        
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        urlRequest.httpBody = body
        
        logCurlCommand(for: urlRequest, endpoint: "verification/signature")
        
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        
        // Log raw response for debugging
        if let responseString = String(data: data, encoding: .utf8) {
            print("📡 [OrderShieldSDK] Signature Verification Response: \(responseString)")
        }
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        let decoder = JSONDecoder()
        
        // Try to decode the response
        do {
            let responseModel = try decoder.decode(SelfieVerificationResponse.self, from: data)
            
            // Log response details
            print("📡 [OrderShieldSDK] Signature Verification - statusCode: \(responseModel.statusCode), status: '\(responseModel.status)', message: '\(responseModel.message)'")
            
            // Check if message indicates success
            let messageLowercased = responseModel.message.lowercased()
            let isSuccessMessage = messageLowercased.contains("success") || 
                                   messageLowercased.contains("successfully") ||
                                   messageLowercased.contains("data fetched successfully") ||
                                   messageLowercased.contains("data created successfully")
            
            // Check if message indicates already submitted/completed (should be treated as success)
            let isAlreadySubmittedMessage = messageLowercased.contains("already been submitted") ||
                                           messageLowercased.contains("already submitted") ||
                                           messageLowercased.contains("already completed") ||
                                           messageLowercased.contains("has already been")
            
            // Check statusCode and status - both must be success, OR statusCode is 200 with success message
            // OR if signature is already submitted (400 status but already submitted message)
            if (responseModel.statusCode == 200 && responseModel.status == "success") || 
               (responseModel.statusCode == 200 && isSuccessMessage) ||
               (isAlreadySubmittedMessage && responseModel.statusCode == 400) {
                if isAlreadySubmittedMessage {
                    print("✅ [OrderShieldSDK] Signature already submitted - treating as success - statusCode: \(responseModel.statusCode), status: '\(responseModel.status)', message: '\(responseModel.message)'")
                } else {
                    print("✅ [OrderShieldSDK] Signature verification successful - statusCode: \(responseModel.statusCode), status: '\(responseModel.status)', message: '\(responseModel.message)'")
                }
                
                // Try to extract the actual StepCompletionData from the response if available
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let dataDict = json["data"] as? [String: Any],
                   let stepCompleted = dataDict["step_completed"] as? String,
                   let sessionDict = dataDict["verification_session"] as? [String: Any] {
                    let sessionId = sessionDict["session_id"] as? String ?? ""
                    let stepsCompleted = sessionDict["steps_completed"] as? [String] ?? []
                    let stepsRemaining = sessionDict["steps_remaining"] as? [String] ?? []
                    let stepsOptional = sessionDict["steps_optional"] as? [String] ?? []
                    let isComplete = sessionDict["is_complete"] as? Bool ?? false
                    let completedAt = sessionDict["completed_at"] as? String
                    
                    print("📡 [OrderShieldSDK] Using actual session data from response - sessionId: \(sessionId), stepsCompleted: \(stepsCompleted), stepsRemaining: \(stepsRemaining)")
                    
                    return StepCompletionData(
                        stepCompleted: stepCompleted,
                        verificationSession: VerificationSession(
                            sessionId: sessionId,
                            stepsCompleted: stepsCompleted,
                            stepsRemaining: stepsRemaining,
                            stepsOptional: stepsOptional,
                            isComplete: isComplete,
                            completedAt: completedAt
                        )
                    )
                }
                
                // Fallback to responseModel.data if available
                if let stepData = responseModel.data {
                    return stepData
                }
                
                // Fallback to dummy data if structure is different
                return StepCompletionData(
                    stepCompleted: "signature",
                    verificationSession: VerificationSession(
                        sessionId: "",
                        stepsCompleted: ["signature"],
                        stepsRemaining: [],
                        stepsOptional: [],
                        isComplete: false,
                        completedAt: nil
                    )
                )
            } else {
                // API returned error status - use the message from API
                let errorMessage = responseModel.message.isEmpty ? "Signature verification failed" : responseModel.message
                print("❌ [OrderShieldSDK] Signature verification failed - statusCode: \(responseModel.statusCode), status: '\(responseModel.status)', message: '\(errorMessage)'")
                throw NSError(
                    domain: "OrderShieldSDK",
                    code: responseModel.statusCode,
                    userInfo: [NSLocalizedDescriptionKey: errorMessage]
                )
            }
        } catch let error as NSError {
            // If it's already an NSError with our domain, re-throw it
            if error.domain == "OrderShieldSDK" {
                print("❌ [OrderShieldSDK] Signature verification error: \(error.localizedDescription)")
                throw error
            }
            
            // If decoding fails, try to extract error message from response
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                print("📡 [OrderShieldSDK] Decoding failed, trying to parse JSON: \(json)")
                if let message = json["message"] as? String,
                   let statusCode = json["statusCode"] as? Int,
                   let status = json["status"] as? String {
                    // Check if message indicates success
                    let messageLowercased = message.lowercased()
                    let isSuccessMessage = messageLowercased.contains("success") || 
                                           messageLowercased.contains("successfully") ||
                                           messageLowercased.contains("data fetched successfully") ||
                                           messageLowercased.contains("data created successfully")
                    
                    // Check if message indicates already submitted/completed (should be treated as success)
                    let isAlreadySubmittedMessage = messageLowercased.contains("already been submitted") ||
                                                   messageLowercased.contains("already submitted") ||
                                                   messageLowercased.contains("already completed") ||
                                                   messageLowercased.contains("has already been")
                    
                    // Check if it's actually a success response
                    // OR if signature is already submitted (400 status but already submitted message)
                    if (statusCode == 200 && status == "success") || 
                       (statusCode == 200 && isSuccessMessage) ||
                       (isAlreadySubmittedMessage && statusCode == 400) {
                        if isAlreadySubmittedMessage {
                            print("✅ [OrderShieldSDK] Signature already submitted - treating as success (parsed from JSON) - statusCode: \(statusCode), status: '\(status)', message: '\(message)'")
                        } else {
                            print("✅ [OrderShieldSDK] Signature verification successful (parsed from JSON) - statusCode: \(statusCode), status: '\(status)', message: '\(message)'")
                        }
                        
                        // Try to extract the actual StepCompletionData from response if available
                        if let dataDict = json["data"] as? [String: Any],
                           let stepCompleted = dataDict["step_completed"] as? String,
                           let sessionDict = dataDict["verification_session"] as? [String: Any] {
                            let sessionId = sessionDict["session_id"] as? String ?? ""
                            let stepsCompleted = sessionDict["steps_completed"] as? [String] ?? []
                            let stepsRemaining = sessionDict["steps_remaining"] as? [String] ?? []
                            let stepsOptional = sessionDict["steps_optional"] as? [String] ?? []
                            let isComplete = sessionDict["is_complete"] as? Bool ?? false
                            let completedAt = sessionDict["completed_at"] as? String
                            
                            return StepCompletionData(
                                stepCompleted: stepCompleted,
                                verificationSession: VerificationSession(
                                    sessionId: sessionId,
                                    stepsCompleted: stepsCompleted,
                                    stepsRemaining: stepsRemaining,
                                    stepsOptional: stepsOptional,
                                    isComplete: isComplete,
                                    completedAt: completedAt
                                )
                            )
                        }
                        
                        // Fallback to dummy data if structure is different
                        return StepCompletionData(
                            stepCompleted: "signature",
                            verificationSession: VerificationSession(
                                sessionId: "",
                                stepsCompleted: ["signature"],
                                stepsRemaining: [],
                                stepsOptional: [],
                                isComplete: false,
                                completedAt: nil
                            )
                        )
                    } else {
                        print("❌ [OrderShieldSDK] Signature verification failed - statusCode: \(statusCode), status: '\(status)', message: '\(message)'")
                        throw NSError(
                            domain: "OrderShieldSDK",
                            code: statusCode,
                            userInfo: [NSLocalizedDescriptionKey: message]
                        )
                    }
                }
            }
            
            // If HTTP status is not 200-299, throw invalid response
            if !(200...299).contains(httpResponse.statusCode) {
                print("❌ [OrderShieldSDK] Signature verification HTTP error - statusCode: \(httpResponse.statusCode)")
                throw NetworkError.invalidResponse
            }
            
            // If we can't extract message, throw original error
            print("❌ [OrderShieldSDK] Signature verification decoding error: \(error.localizedDescription)")
            throw error
        }
    }
    
    // MARK: - Terms Checkboxes
    func fetchTermsCheckboxes() async throws -> TermsCheckboxesResponse {
        guard let apiKey = apiKey else {
            throw NetworkError.missingAPIKey
        }
        
        let url = URL(string: "\(baseURL)/terms-checkboxes")!
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "GET"
        urlRequest.setValue("application/json", forHTTPHeaderField: "accept")
        urlRequest.setValue(apiKey, forHTTPHeaderField: "X-API-KEY")
        
        logCurlCommand(for: urlRequest, endpoint: "terms-checkboxes")
        
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        
        // Log raw response for debugging
        if let responseString = String(data: data, encoding: .utf8) {
            print("📡 [OrderShieldSDK] Terms Checkboxes Response: \(responseString)")
        }
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.invalidResponse
        }
        
        let decoder = JSONDecoder()
        let responseModel = try decoder.decode(TermsCheckboxesResponse.self, from: data)
        
        // Log response details
        print("📡 [OrderShieldSDK] Terms Checkboxes - statusCode: \(responseModel.statusCode), status: '\(responseModel.status)', message: '\(responseModel.message)', count: \(responseModel.data.count)")
        
        return responseModel
    }
}

// MARK: - Network Errors
enum NetworkError: Error {
    case missingAPIKey
    case invalidResponse
    case decodingError
    case encodingError
    
    var localizedDescription: String {
        switch self {
        case .missingAPIKey:
            return "API key is missing. Please configure the SDK first."
        case .invalidResponse:
            return "Invalid response from server."
        case .decodingError:
            return "Failed to decode response."
        case .encodingError:
            return "Failed to encode request."
        }
    }
}

