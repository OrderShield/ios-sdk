# OrderShield iOS SDK

A comprehensive identity verification SDK for iOS applications that provides a complete verification flow with multiple verification steps.

## Features

- ✅ **Automatic Device Registration**: Device is registered automatically during initialization
- ✅ **Dynamic Verification Steps**: Which steps are required is fetched from the server, and the SDK automatically chooses an appropriate order for the current session
- ✅ **Start + Resume Flow**: A start screen is shown first, and the SDK either starts a new session or resumes an existing one from the first remaining step using the `verification/status` API
- ✅ **Multiple Verification Methods**:
  - Selfie verification with camera capture
  - Email verification with optional OTP
  - Phone/SMS verification with country picker and optional OTP
  - User information collection (name, date of birth)
  - Terms & conditions acceptance
  - Digital signature capture
- ✅ **Conditional OTP Verification**: Email and SMS OTP steps are shown/hidden based on server settings
- ✅ **Predefined User Info (Prefilled Data)**: Pass phone, email, and/or user info to skip steps or prefill fields; invalid data (e.g. phone without country code) surfaces an error and clears predefined data on dismiss so you can set corrected data and retry
- ✅ **Comprehensive Delegate Callbacks**: Monitor all SDK events and API calls
- ✅ **Modern UI**: Purple-themed buttons with arrow icons, consistent styling across all screens
- ✅ **Scrollable Content**: Email, phone, and user info screens support scrolling
- ✅ **Keyboard Handling**: Automatic keyboard dismissal on return key

## Requirements

- iOS 13.0+
- Xcode 12.0+
- Swift 5.0+

## Installation

### Method 1: Swift Package Manager (recommended)

Add the SDK as a **package dependency** — no need to build or manually add a framework.

1. In Xcode: **File** → **Add Package Dependencies...**
2. Enter the package URL: `https://github.com/OrderShield/ios-sdk.git` and add the package.
3. Select the **OrderShieldSDK** library and add it to your app target.
4. Add camera permission to `Info.plist`:
   ```xml
   <key>NSCameraUsageDescription</key>
   <string>We need access to your camera to verify your identity</string>
   ```

The project includes a `Package.swift`; when added via SPM, Xcode uses it and you do **not** need to generate or drag in a framework.

### Method 2: Direct Framework Integration

1. Build the framework:
   ```bash
   cd OrderShieldSDK
   ./build_framework.sh release device
   ```
2. Add `OrderShieldSDK.framework` to your project and link it (**General** → **Frameworks, Libraries, and Embedded Content** → **Embed & Sign**).
3. Add camera permission to `Info.plist` (see Method 1 step 4).

### Method 3: Workspace Integration

1. Create a workspace and add both SDK and your app projects.
2. Link the framework in your app target settings and add camera permission as in Method 1.

## Quick Start

Initialize the SDK **at app launch** (e.g. in `AppDelegate`) so it is ready before the user opens any screen. Start the verification flow from any view controller when needed.

```swift
import UIKit
import OrderShieldSDK

// 1. At app launch — configure and initialize in AppDelegate
class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        OrderShield.shared.configure(apiKey: "your-api-key-here")
        Task {
            let success = await OrderShield.shared.initialize()
            if success { print("✅ SDK Ready!") } else { print("❌ SDK Initialization Failed") }
        }
        return true
    }
}

// 2. When user taps "Start Verification" — from any view controller
class ViewController: UIViewController {
    @IBAction func startVerificationTapped(_ sender: UIButton) {
        OrderShield.shared.startVerification(presentingViewController: self)
    }
}
```

## Usage

### Basic Integration

1. **Configure** the SDK with your API key and **initialize** at **app launch** (e.g. in `AppDelegate`’s `application(_:didFinishLaunchingWithOptions:)`). This registers the device and fetches verification settings so the SDK is ready before the user opens any screen.
2. **Start Verification** from any view controller when the user is ready to begin the flow (e.g. button tap).

The SDK automatically:
- Registers the device and stores customer ID
- Fetches verification settings from the server (which steps are enabled/required)
- When starting verification:
  - Checks for an existing session token and, if found, calls `GET /verification/status` to resume from remaining steps
  - Otherwise calls `POST /verification/start` to create a new session
- Displays verification screens in a consistent SDK-controlled order, showing only the steps that are actually required/remaining for that session
- Handles API calls and error responses
- Manages verification flow state and completion

### Advanced Integration with Delegate

Initialize at launch in `AppDelegate` and set the delegate there (or on your first view controller). Implement delegate methods to monitor progress and errors.

```swift
// AppDelegate — init at launch and set delegate (or set delegate on your view controller)
func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    OrderShield.shared.delegate = self  // or set on ViewController
    OrderShield.shared.configure(apiKey: "your-api-key")
    Task { await OrderShield.shared.initialize() }
    return true
}

// Delegate implementation (e.g. in AppDelegate or a view controller)
extension AppDelegate: OrderShieldDelegate {
    func orderShieldDidStartStep(step: String, stepIndex: Int, totalSteps: Int) {
        print("Step \(stepIndex + 1)/\(totalSteps): \(step)")
    }
    func orderShieldDidCallAPI(endpoint: String, success: Bool, statusCode: Int?, error: Error?) {
        if !success { print("❌ API Error: \(endpoint) - \(error?.localizedDescription ?? "Unknown")") }
    }
    func orderShieldDidCompleteVerification(sessionId: String?) {
        print("✅ Verification completed! Session: \(sessionId ?? "N/A")")
    }
}
```

## Verification Steps

The SDK supports the following verification steps (whether each step is required/optional is controlled by server configuration; the display **order** is determined by the SDK at runtime):

- **sms**: Phone number input with country picker and optional SMS OTP
- **selfie**: Camera-based selfie capture with retake option
- **userInfo**: Personal information collection (first name, last name, date of birth)
- **email**: Email address input with optional OTP verification
- **terms**: Terms and conditions acceptance with dynamic checkboxes
- **signature**: Digital signature capture

At runtime the SDK:
- Looks at the required/optional steps from the server
- Shows only the steps that are required/remaining for the current session, in a consistent SDK-controlled order

## Predefined User Info (Prefilled Data)

You can pass user data **before** starting verification so the SDK skips steps or prefills fields.

### When to use

- You already have the user’s phone, email, or name/DOB and want to skip the corresponding screens.
- You want to prefill the user info screen with partial data (e.g. name only); the user fills the rest.

### API

Call **`setPredefinedUserInfo(_:)`** **before** **`startVerification(presentingViewController:)`**. Pass a `PredefinedUserInfo` value (or `nil` to clear).

| Field | Effect |
|-------|--------|
| **phoneNumber** | If the SMS step is required, it is **skipped** and the number is submitted in the background. Must include **country code** (e.g. `+1234567890`). |
| **email** | If the email step is required, it is **skipped** and the email is submitted in the background. |
| **firstName**, **lastName**, **dateOfBirth** | If **all three** are non-empty, the userInfo step is **skipped**. If only some are set, the userInfo screen is **shown with those fields prefilled**; the user completes and submits. |

**Selfie**, **terms**, and **signature** steps are never skipped by predefined data.

### Swift example

```swift
// Before starting verification, set predefined data (optional)
let predefined = PredefinedUserInfo(
    phoneNumber: "+1234567890",
    email: "user@example.com",
    firstName: "Jane",
    lastName: "Doe",
    dateOfBirth: "1990-01-15"  // MM/dd/yyyy or yyyy-MM-dd
)
OrderShield.shared.setPredefinedUserInfo(predefined)

// Then start the flow as usual
OrderShield.shared.startVerification(presentingViewController: self)
```

### Objective-C example

```objc
OSPredefinedUserInfo *predefined = [[OSPredefinedUserInfo alloc] initWithEmail:@"user@example.com"
                                                                   phoneNumber:@"+1234567890"
                                                                     firstName:@"Jane"
                                                                      lastName:@"Doe"
                                                                   dateOfBirth:@"1990-01-15"];
[OrderShield.shared setPredefinedUserInfoWithObjC:predefined];
[OrderShield.shared startVerificationWithPresentingViewController:self completion:^(NSString * _Nullable token) { }];
```

### Clearing predefined data

- Predefined data is **consumed** when the user taps **Start** on the verification start screen (used for that run only).
- If the SDK shows an **error** (e.g. invalid phone format or missing country code), predefined data is **cleared when the user dismisses the alert**. Your app can then call `setPredefinedUserInfo(correctedInfo)` and the user can tap Start again to use the updated data.

### Notes

- If a step (e.g. SMS) is **not** in the session’s required steps, any predefined value for that step is ignored.
- Phone number should be in E.164-style with country code to avoid backend validation errors.

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
