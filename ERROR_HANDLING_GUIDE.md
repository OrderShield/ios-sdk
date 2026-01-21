# Error Handling Guide - OrderShieldSDK

## Overview

This guide shows you how to get API errors, verification errors, and monitor all SDK activities in your sample app.

## Quick Start: Get All Errors

### Step 1: Set Delegate

```swift
import OrderShieldSDK

class ViewController: UIViewController, OrderShieldDelegate {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set delegate BEFORE configuring
        OrderShield.shared.delegate = self
        
        // Configure SDK
        OrderShield.shared.configure(apiKey: "your-api-key")
    }
}
```

### Step 2: Implement Error Callbacks

```swift
// MARK: - OrderShieldDelegate

// Get ALL API errors
func orderShieldDidCallAPI(endpoint: String, success: Bool, statusCode: Int?, error: Error?) {
    if !success {
        print("❌ API Error: \(endpoint)")
        print("   Status: \(statusCode ?? 0)")
        print("   Error: \(error?.localizedDescription ?? "Unknown")")
        
        // Show to user
        showErrorAlert("API Error", message: error?.localizedDescription ?? "Unknown error")
    }
}

// Get initialization errors
func orderShieldDidInitialize(success: Bool, error: Error?) {
    if !success {
        print("❌ Initialization failed: \(error?.localizedDescription ?? "Unknown")")
        showErrorAlert("Initialization Failed", message: error?.localizedDescription ?? "Unknown error")
    }
}

// Get verification errors
func orderShieldDidStartVerification(success: Bool, sessionToken: String?, error: Error?) {
    if !success {
        print("❌ Verification failed: \(error?.localizedDescription ?? "Unknown")")
        showErrorAlert("Verification Failed", message: error?.localizedDescription ?? "Unknown error")
    }
}

// Get step errors
func orderShieldDidCompleteStep(step: String, stepIndex: Int, success: Bool, error: Error?) {
    if !success {
        print("❌ Step \(step) failed: \(error?.localizedDescription ?? "Unknown")")
    }
}
```

## Complete Example with Error Handling

```swift
import UIKit
import OrderShieldSDK

class ViewController: UIViewController, OrderShieldDelegate {
    
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var errorTextView: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set delegate
        OrderShield.shared.delegate = self
        
        // Setup SDK
        setupSDK()
    }
    
    private func setupSDK() {
        OrderShield.shared.configure(apiKey: "your-api-key")
        
        Task {
            await OrderShield.shared.initialize()
        }
    }
    
    @IBAction func startVerification() {
        Task {
            await OrderShield.shared.startVerification(
                presentingViewController: self
            )
        }
    }
    
    // MARK: - Helper Methods
    
    private func logError(_ message: String) {
        DispatchQueue.main.async {
            let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
            self.errorTextView.text += "[\(timestamp)] \(message)\n"
        }
    }
    
    private func updateStatus(_ message: String) {
        DispatchQueue.main.async {
            self.statusLabel.text = message
        }
    }
    
    // MARK: - OrderShieldDelegate
    
    // API Call Monitoring
    func orderShieldWillCallAPI(endpoint: String, method: String) {
        logError("📡 Calling: \(method) \(endpoint)")
    }
    
    func orderShieldDidCallAPI(endpoint: String, success: Bool, statusCode: Int?, error: Error?) {
        if success {
            logError("✅ Success: \(endpoint) (Status: \(statusCode ?? 0))")
        } else {
            logError("❌ Failed: \(endpoint)")
            logError("   Status Code: \(statusCode ?? 0)")
            logError("   Error: \(error?.localizedDescription ?? "Unknown")")
            
            // Log detailed error info
            if let error = error as NSError? {
                logError("   Domain: \(error.domain)")
                logError("   Code: \(error.code)")
            }
        }
    }
    
    // Initialization Errors
    func orderShieldDidRegisterDevice(success: Bool, error: Error?) {
        if success {
            logError("✅ Device registered")
        } else {
            logError("❌ Device registration failed: \(error?.localizedDescription ?? "Unknown")")
            updateStatus("Registration Failed")
        }
    }
    
    func orderShieldDidFetchSettings(success: Bool, settings: VerificationSettingsData?, error: Error?) {
        if success {
            logError("✅ Settings fetched")
        } else {
            logError("❌ Settings fetch failed: \(error?.localizedDescription ?? "Unknown")")
            updateStatus("Settings Failed")
        }
    }
    
    func orderShieldDidInitialize(success: Bool, error: Error?) {
        if success {
            logError("✅ SDK initialized")
            updateStatus("Ready")
        } else {
            logError("❌ Initialization failed: \(error?.localizedDescription ?? "Unknown")")
            updateStatus("Failed")
        }
    }
    
    // Verification Errors
    func orderShieldDidStartVerification(success: Bool, sessionToken: String?, error: Error?) {
        if success {
            logError("✅ Verification started")
            updateStatus("Verification Started")
        } else {
            logError("❌ Verification start failed: \(error?.localizedDescription ?? "Unknown")")
            updateStatus("Start Failed")
        }
    }
    
    func orderShieldDidStartStep(step: String, stepIndex: Int, totalSteps: Int) {
        logError("📝 Step \(stepIndex + 1)/\(totalSteps): \(step)")
        updateStatus("Step \(stepIndex + 1)/\(totalSteps)")
    }
    
    func orderShieldDidCompleteStep(step: String, stepIndex: Int, success: Bool, error: Error?) {
        if success {
            logError("✅ Step \(stepIndex + 1) completed: \(step)")
        } else {
            logError("❌ Step \(stepIndex + 1) failed: \(step)")
            logError("   Error: \(error?.localizedDescription ?? "Unknown")")
            updateStatus("Step \(stepIndex + 1) Failed")
        }
    }
    
    func orderShieldDidCompleteVerification(sessionId: String?) {
        logError("🎉 Verification completed!")
        updateStatus("Complete!")
    }
    
    func orderShieldDidCancelVerification(error: Error?) {
        if let error = error {
            logError("❌ Verification cancelled: \(error.localizedDescription)")
        } else {
            logError("⚠️ Verification cancelled")
        }
        updateStatus("Cancelled")
    }
}
```

## Error Types

### Network Errors

```swift
enum NetworkError: Error {
    case missingAPIKey
    case invalidResponse
    case decodingError
    case encodingError
}
```

### Handling Specific Errors

```swift
func orderShieldDidCallAPI(endpoint: String, success: Bool, statusCode: Int?, error: Error?) {
    guard let error = error else { return }
    
    // Check error type
    if let networkError = error as? NetworkError {
        switch networkError {
        case .missingAPIKey:
            print("API Key is missing")
        case .invalidResponse:
            print("Invalid server response")
        case .decodingError:
            print("Failed to decode response")
        case .encodingError:
            print("Failed to encode request")
        }
    }
    
    // Check HTTP status code
    if let statusCode = statusCode {
        switch statusCode {
        case 400:
            print("Bad Request")
        case 401:
            print("Unauthorized - Check API key")
        case 404:
            print("Endpoint not found")
        case 500:
            print("Server error")
        default:
            print("HTTP Error: \(statusCode)")
        }
    }
}
```

## Console Logs

The SDK automatically logs to console:

1. **cURL Commands** - For every API call
2. **Initialization Status** - Device registration and settings fetch
3. **API Call Status** - Success/failure for each call

**Check Xcode Console** to see all logs.

## All Available Callbacks

### Initialization
- `orderShieldDidRegisterDevice(success:error:)` - Device registration result
- `orderShieldDidFetchSettings(success:settings:error:)` - Settings fetch result
- `orderShieldDidInitialize(success:error:)` - Overall initialization result

### Verification Flow
- `orderShieldDidStartVerification(success:sessionToken:error:)` - Verification start
- `orderShieldDidStartStep(step:stepIndex:totalSteps:)` - Step started
- `orderShieldDidCompleteStep(step:stepIndex:success:error:)` - Step completed
- `orderShieldDidCompleteVerification(sessionId:)` - All steps completed
- `orderShieldDidCancelVerification(error:)` - Verification cancelled

### API Monitoring
- `orderShieldWillCallAPI(endpoint:method:)` - Before API call
- `orderShieldDidCallAPI(endpoint:success:statusCode:error:)` - After API call

## Best Practices

1. **Always set delegate** before configuring SDK
2. **Implement all error callbacks** you need
3. **Log errors** for debugging
4. **Show user-friendly messages** for critical errors
5. **Check console logs** for detailed information
6. **Use cURL logs** to test API calls manually

## Example: Error Logging Service

```swift
class ErrorLogger {
    static func logAPIError(endpoint: String, statusCode: Int?, error: Error?) {
        let errorInfo: [String: Any] = [
            "endpoint": endpoint,
            "statusCode": statusCode ?? 0,
            "error": error?.localizedDescription ?? "Unknown",
            "timestamp": Date()
        ]
        
        // Log to your analytics service
        Analytics.logEvent("api_error", parameters: errorInfo)
        
        // Log to console
        print("❌ API Error: \(errorInfo)")
    }
}

// Use in delegate
func orderShieldDidCallAPI(endpoint: String, success: Bool, statusCode: Int?, error: Error?) {
    if !success {
        ErrorLogger.logAPIError(endpoint: endpoint, statusCode: statusCode, error: error)
    }
}
```

