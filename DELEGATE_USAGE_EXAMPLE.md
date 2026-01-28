# OrderShieldSDK Delegate Usage Example

## Overview

The SDK provides a comprehensive delegate protocol (`OrderShieldDelegate`) that allows you to receive callbacks for:
- API call states (before/after each call)
- Initialization progress
- Verification step progress
- Errors and completion

## Setup

### 1. Implement the Delegate Protocol

```swift
import UIKit
import OrderShieldSDK

class ViewController: UIViewController, OrderShieldDelegate {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set delegate
        OrderShield.shared.delegate = self
        
        // Configure SDK
        OrderShield.shared.configure(apiKey: "your-api-key")
    }
    
    // MARK: - OrderShieldDelegate Methods
    
    // Initialization Callbacks
    func orderShieldDidRegisterDevice(success: Bool, error: Error?) {
        if success {
            print("✅ Device registered successfully")
        } else {
            print("❌ Device registration failed: \(error?.localizedDescription ?? "Unknown error")")
        }
    }
    
    func orderShieldDidFetchSettings(success: Bool, settings: VerificationSettingsData?, error: Error?) {
        if success, let settings = settings {
            // These are configuration steps from verification-settings (not the final runtime order)
            // The SDK will still order actual runtime steps using its static sequence:
            // sms → selfie → userInfo → email → terms → signature
            print("✅ Settings fetched - required steps from settings API: \(settings.requiredSteps)")
        } else {
            print("❌ Failed to fetch settings: \(error?.localizedDescription ?? "Unknown error")")
        }
    }
    
    func orderShieldDidInitialize(success: Bool, error: Error?) {
        if success {
            print("✅ SDK initialized successfully")
        } else {
            print("❌ SDK initialization failed: \(error?.localizedDescription ?? "Unknown error")")
        }
    }
    
    // Verification Flow Callbacks
    func orderShieldDidStartVerification(success: Bool, sessionToken: String?, error: Error?) {
        if success, let token = sessionToken {
            print("✅ Verification started with session token: \(token)")
        } else {
            print("❌ Failed to start verification: \(error?.localizedDescription ?? "Unknown error")")
        }
    }
    
    func orderShieldDidStartStep(step: String, stepIndex: Int, totalSteps: Int) {
        print("📝 Starting step \(stepIndex + 1)/\(totalSteps): \(step)")
    }
    
    func orderShieldDidCompleteStep(step: String, stepIndex: Int, success: Bool, error: Error?) {
        if success {
            print("✅ Step \(stepIndex + 1) completed: \(step)")
        } else {
            print("❌ Step \(stepIndex + 1) failed: \(step) - \(error?.localizedDescription ?? "Unknown error")")
        }
    }
    
    func orderShieldDidCompleteVerification(sessionId: String?) {
        print("🎉 Verification completed! Session ID: \(sessionId ?? "N/A")")
    }
    
    func orderShieldDidCancelVerification(error: Error?) {
        if let error = error {
            print("❌ Verification cancelled due to error: \(error.localizedDescription)")
        } else {
            print("⚠️ Verification cancelled by user")
        }
    }
    
    // API Call Callbacks
    func orderShieldWillCallAPI(endpoint: String, method: String) {
        print("📡 Will call API: \(method) \(endpoint)")
    }
    
    func orderShieldDidCallAPI(endpoint: String, success: Bool, statusCode: Int?, error: Error?) {
        if success {
            print("✅ API call succeeded: \(endpoint) (Status: \(statusCode ?? 0))")
        } else {
            print("❌ API call failed: \(endpoint) - \(error?.localizedDescription ?? "Unknown error")")
        }
    }
}
```

## Usage with Async/Await

### Initialize with Callbacks

```swift
Task {
    // Initialize SDK - delegate will receive callbacks
    let success = await OrderShield.shared.initialize()
    
    if success {
        print("Ready to start verification")
    }
}
```

### Start Verification with Callbacks

```swift
// Option 1: Using async/await (returns session token)
// Note: customer_id is automatically retrieved from device registration during initialize()
Task {
    if let sessionToken = await OrderShield.shared.startVerification(
        presentingViewController: self
    ) {
        print("Verification started with token: \(sessionToken)")
        // Delegate will receive all step callbacks
    }
}

// Option 2: Using traditional method (delegate receives callbacks)
// Note: customer_id is automatically retrieved from device registration during initialize()
OrderShield.shared.startVerification(
    presentingViewController: self
)
// Delegate will receive all callbacks
```

## Complete Example

```swift
import UIKit
import OrderShieldSDK

class ViewController: UIViewController, OrderShieldDelegate {
    
    @IBOutlet weak var statusLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set delegate
        OrderShield.shared.delegate = self
        
        // Configure and initialize
        setupSDK()
    }
    
    private func setupSDK() {
        OrderShield.shared.configure(apiKey: "your-api-key")
        
        Task {
            await OrderShield.shared.initialize()
        }
    }
    
    @IBAction func startVerificationTapped() {
        Task {
            // customer_id is automatically retrieved from device registration
            await OrderShield.shared.startVerification(
                presentingViewController: self
            )
        }
    }
    
    // MARK: - OrderShieldDelegate
    
    func orderShieldDidInitialize(success: Bool, error: Error?) {
        DispatchQueue.main.async {
            self.statusLabel.text = success ? "SDK Ready" : "SDK Failed"
        }
    }
    
    func orderShieldDidStartStep(step: String, stepIndex: Int, totalSteps: Int) {
        DispatchQueue.main.async {
            self.statusLabel.text = "Step \(stepIndex + 1)/\(totalSteps): \(step)"
        }
    }
    
    func orderShieldDidCompleteVerification(sessionId: String?) {
        DispatchQueue.main.async {
            self.statusLabel.text = "Verification Complete!"
        }
    }
}
```

## All Delegate Methods

### Initialization
- `orderShieldDidRegisterDevice(success:error:)` - Device registration result
- `orderShieldDidFetchSettings(success:settings:error:)` - Settings fetch result
- `orderShieldDidInitialize(success:error:)` - Overall initialization result

### Verification Flow
- `orderShieldDidStartVerification(success:sessionToken:error:)` - Verification session started
- `orderShieldDidStartStep(step:stepIndex:totalSteps:)` - Step started
- `orderShieldDidCompleteStep(step:stepIndex:success:error:)` - Step completed
- `orderShieldDidCompleteVerification(sessionId:)` - All steps completed
- `orderShieldDidCancelVerification(error:)` - Verification cancelled/failed

### API Calls
- `orderShieldWillCallAPI(endpoint:method:)` - Before API call
- `orderShieldDidCallAPI(endpoint:success:statusCode:error:)` - After API call

## Notes

- All delegate methods are **optional** - implement only what you need
- Delegate callbacks are called on the **main thread** for UI updates
- You can track the entire verification flow through these callbacks
- Use callbacks to update your UI, log analytics, or handle errors

