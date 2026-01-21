# OrderShieldSDK Usage Guide

## Overview

OrderShieldSDK is a dynamic framework for iOS that provides a complete verification flow with UI screens. The SDK automatically handles the verification sequence based on the required steps from the server.

## Installation

1. Add the `OrderShieldSDK.framework` to your Xcode project
2. Link the framework in your target's "Frameworks, Libraries, and Embedded Content"
3. Import the framework in your code: `import OrderShieldSDK`

## Setup

### 1. Configure the SDK

First, configure the SDK with your API key:

```swift
import OrderShieldSDK

// In your AppDelegate or SceneDelegate
OrderShield.shared.configure(apiKey: "your-api-key-here")
```

### 2. Initialize the SDK

Initialize the SDK to register the device and fetch verification settings. This should be done once, typically at app launch:

```swift
Task {
    let success = await OrderShieldSDK.shared.initialize()
    if success {
        print("SDK initialized successfully")
    } else {
        print("SDK initialization failed")
    }
}
```

### 3. Start Verification

When you're ready to start the verification flow, call `startVerification`:

```swift
OrderShieldSDK.shared.startVerification(
    customerId: "your-customer-id",
    presentingViewController: self
)
```

## Complete Example

```swift
import UIKit
import OrderShieldSDK

class ViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupSDK()
    }
    
    private func setupSDK() {
        // Step 1: Configure with API key
        OrderShield.shared.configure(apiKey: "dev_0RZ-0SCe4BS4ORZhTuW5hL5HEfyFH6jIjH6iwWijLlk")
        
        // Step 2: Initialize (register device and fetch settings)
        Task {
            let success = await OrderShield.shared.initialize()
            if success {
                print("SDK ready")
            }
        }
    }
    
    @IBAction func startVerificationTapped(_ sender: UIButton) {
        // Step 3: Start verification flow
OrderShield.shared.startVerification(
    presentingViewController: self
)
    }
}
```

## Verification Flow

The SDK automatically handles the verification flow based on the `required_steps` returned from the verification settings API. The flow includes:

1. **Welcome Screen** - Introduction to the verification process
2. **Selfie Verification** - Camera-based face verification
3. **Email Verification** - Email address verification with OTP
4. **Phone Verification** - Phone number verification with OTP
5. **Terms Agreement** - Accept terms and conditions
6. **Digital Signature** - Capture user signature
7. **Completion Screen** - Verification complete confirmation

The SDK will automatically:
- Show only the required steps based on server configuration
- Navigate between steps in the correct order
- Handle API calls for each step
- Show the completion screen when all steps are done

## Permissions Required

Add the following to your app's `Info.plist`:

```xml
<key>NSCameraUsageDescription</key>
<string>We need access to your camera to verify your identity</string>
```

## Error Handling

The SDK handles errors internally and displays appropriate error messages to users. If initialization fails, check:

1. API key is valid
2. Network connectivity
3. Server is accessible

## Requirements

- iOS 13.0 or later
- Swift 5.0 or later
- Xcode 12.0 or later

## API Endpoints Used

The SDK uses the following endpoints:

- `POST /api/sdk/register-device` - Device registration
- `GET /api/sdk/verification-settings` - Fetch verification settings
- `POST /api/sdk/verification/start` - Start verification session
- `POST /api/sdk/verification/selfie` - Submit selfie
- `POST /api/sdk/verification/email/send-code` - Send email OTP
- `POST /api/sdk/verification/email/verify-code` - Verify email OTP
- `POST /api/sdk/verification/phone/send-code` - Send phone OTP
- `POST /api/sdk/verification/phone/verify-code` - Verify phone OTP
- `POST /api/sdk/verification/terms` - Submit terms acceptance
- `POST /api/sdk/verification/signature` - Submit signature

## Notes

- The SDK automatically stores verification settings locally
- Device ID is generated and stored automatically
- All network calls use async/await for modern Swift concurrency
- UI screens are built programmatically with Auto Layout constraints
- The SDK manages its own navigation flow internally

