# OrderShield iOS SDK

A comprehensive identity verification SDK for iOS applications that provides a complete verification flow with multiple verification steps.

## Features

- ✅ **Automatic Device Registration**: Device is registered automatically during initialization
- ✅ **Dynamic Verification Steps**: Steps are fetched from the server and displayed based on requirements
- ✅ **Direct Flow Start**: Verification flow starts immediately with the first required step (no welcome screen)
- ✅ **Multiple Verification Methods**:
  - Selfie verification with camera capture
  - Email verification with optional OTP
  - Phone/SMS verification with country picker and optional OTP
  - User information collection (name, date of birth)
  - Terms & conditions acceptance
  - Digital signature capture
- ✅ **Conditional OTP Verification**: Email and SMS OTP steps are shown/hidden based on server settings
- ✅ **Comprehensive Delegate Callbacks**: Monitor all SDK events and API calls
- ✅ **Modern UI**: Purple-themed buttons with arrow icons, consistent styling across all screens
- ✅ **Scrollable Content**: Email, phone, and user info screens support scrolling
- ✅ **Keyboard Handling**: Automatic keyboard dismissal on return key

## Requirements

- iOS 13.0+
- Xcode 12.0+
- Swift 5.0+

## Installation

### Method 1: Direct Framework Integration

1. Build the framework:
   ```bash
   cd OrderShieldSDK
   ./build_framework.sh release device
   ```

2. Add `OrderShieldSDK.framework` to your project

3. Link the framework:
   - Select your app target
   - Go to **General** → **Frameworks, Libraries, and Embedded Content**
   - Add `OrderShieldSDK.framework`
   - Set to **"Embed & Sign"**

4. Add camera permission to `Info.plist`:
   ```xml
   <key>NSCameraUsageDescription</key>
   <string>We need access to your camera to verify your identity</string>
   ```

### Method 2: Workspace Integration

1. Create a workspace and add both SDK and your app projects
2. Link the framework in your app target settings
3. Follow steps 3-4 from Method 1

## Quick Start

```swift
import UIKit
import OrderShieldSDK

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        setupSDK()
    }

    private func setupSDK() {
        // 1. Configure SDK with API key
        OrderShield.shared.configure(
            apiKey: "your-api-key-here"
        )

        // 2. Initialize (register device & fetch settings)
        // customer_id is automatically retrieved and stored
        Task {
            let success = await OrderShield.shared.initialize()
            if success {
                print("✅ SDK Ready!")
            } else {
                print("❌ SDK Initialization Failed")
            }
        }
    }

    @IBAction func startVerificationTapped(_ sender: UIButton) {
        // 3. Start verification flow
        // Flow starts directly with first required step
        OrderShield.shared.startVerification(
            presentingViewController: self
        )
    }
}
```

## Usage

### Basic Integration

1. **Configure** the SDK with your API key
2. **Initialize** to register device and fetch verification settings
3. **Start Verification** to begin the verification flow

The SDK automatically:
- Registers the device and stores customer ID
- Fetches required verification steps from the server
- Displays verification screens in the correct order
- Handles API calls and error responses
- Manages the verification flow state

### Advanced Integration with Delegate

```swift
class ViewController: UIViewController, OrderShieldDelegate {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set delegate before configuring
        OrderShield.shared.delegate = self
        
        OrderShield.shared.configure(apiKey: "your-api-key")
        
        Task {
            await OrderShield.shared.initialize()
        }
    }
    
    // Monitor verification progress
    func orderShieldDidStartStep(step: String, stepIndex: Int, totalSteps: Int) {
        print("Step \(stepIndex + 1)/\(totalSteps): \(step)")
    }
    
    // Handle errors
    func orderShieldDidCallAPI(endpoint: String, success: Bool, statusCode: Int?, error: Error?) {
        if !success {
            print("❌ API Error: \(endpoint) - \(error?.localizedDescription ?? "Unknown")")
        }
    }
    
    // Handle completion
    func orderShieldDidCompleteVerification(sessionId: String?) {
        print("✅ Verification completed! Session: \(sessionId ?? "N/A")")
    }
}
```

## Verification Steps

The SDK supports the following verification steps (displayed based on server configuration):

- **selfie**: Camera-based selfie capture with retake option
- **email**: Email address input with optional OTP verification
- **sms**: Phone number input with country picker and optional SMS OTP
- **user_info**: Personal information collection (first name, last name, date of birth)
- **terms**: Terms and conditions acceptance with dynamic checkboxes
- **signature**: Digital signature capture

## UI Features

- **Purple-themed buttons**: All Continue/Complete buttons use purple background (`UIColor(red: 0.42, green: 0.35, blue: 0.80, alpha: 1.0)`)
- **Arrow icons**: White right arrow icons on all action buttons
- **Enabled/Disabled states**: Visual feedback with opacity changes
- **Scrollable content**: Email, phone, and user info screens support scrolling
- **Keyboard handling**: Automatic dismissal on return key
- **Consistent styling**: White backgrounds and consistent spacing across all screens

## Delegate Methods

All delegate methods are optional. Implement only what you need:

### Initialization Callbacks
- `orderShieldDidRegisterDevice(success:error:)`
- `orderShieldDidFetchSettings(success:settings:error:)`
- `orderShieldDidInitialize(success:error:)`

### Verification Flow Callbacks
- `orderShieldDidStartVerification(success:sessionToken:error:)`
- `orderShieldDidStartVerificationWithDetails(...)`
- `orderShieldDidStartStep(step:stepIndex:totalSteps:)`
- `orderShieldDidCompleteStep(step:stepIndex:success:error:)`
- `orderShieldDidCompleteVerification(sessionId:)`
- `orderShieldDidCancelVerification(error:)`

### Step-Specific Callbacks
- `orderShieldDidSubmitUserInfo(success:firstName:lastName:dateOfBirth:error:)`
- `orderShieldDidFetchTermsCheckboxes(success:checkboxes:error:)`
- `orderShieldDidAcceptTerms(success:acceptedCheckboxIds:error:)`
- `orderShieldDidSubmitSignature(success:error:)`
- `orderShieldDidSubmitTermsAndSignature(success:acceptedCheckboxIds:error:)`

### API Call Callbacks
- `orderShieldWillCallAPI(endpoint:method:)`
- `orderShieldDidCallAPI(endpoint:success:statusCode:error:)`

## Documentation

- **[INTEGRATION_STEPS.md](INTEGRATION_STEPS.md)**: Detailed step-by-step integration guide
- **[QUICK_START.md](QUICK_START.md)**: Quick start guide for testing
- **TestAppExample/**: Complete example app implementation

## Troubleshooting

### "No such module 'OrderShieldSDK'"
- Ensure framework is set to "Embed & Sign"
- Clean build folder (⌘⇧K) and rebuild

### Customer ID not found
- Ensure `initialize()` is called before `startVerification()`
- Check delegate callback `orderShieldDidRegisterDevice` for errors

### API errors
- Verify API key is correct
- Check network connectivity
- Implement delegate to get detailed error information
- Check Xcode console for cURL logs

### Camera not working
- Verify `NSCameraUsageDescription` in Info.plist
- Test on real device (simulator may have issues)

## Example

See `TestAppExample/` folder for a complete working example.

## Support

For detailed integration instructions, error handling, and API documentation, see:
- `INTEGRATION_STEPS.md` - Complete integration guide
- `QUICK_START.md` - Quick testing guide

## License

[Add your license information here]

## Version

Current version supports iOS 13.0+ with Swift 5.0+.
