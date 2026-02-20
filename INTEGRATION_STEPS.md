# Step-by-Step Integration Guide

## Method 1: Swift Package Manager (recommended — no framework build)

Add the SDK as a package dependency so you don’t need to build or manually add a framework.

1. In Xcode: **File** → **Add Package Dependencies...**
2. Enter the package URL: `https://github.com/OrderShield/ios-sdk.git` and add the package.
3. Select the **OrderShieldSDK** library and add it to your app target.
4. Add camera permission to `Info.plist` (see Method 2, Step 4).

Then add your app code as in **Method 2, Step 5** (configure and initialize at launch in AppDelegate; start verification from a view controller). The project’s `Package.swift` is used automatically; no framework file is generated or added by hand.

---

## Method 2: Direct Framework Integration

### Step 1: Build the Framework

**In Terminal:**

```bash
cd /Users/rajkumar/Documents/OrderShieldSDK/OrderShieldSDK
./build_framework.sh release device
```

**Or in Xcode:**

1. Open `OrderShieldSDK.xcodeproj`
2. Select scheme: **OrderShieldSDK**
3. Select destination: **Any iOS Device**
4. Press **⌘B** (Build)
5. Framework location: Check DerivedData folder or use the script output

### Step 2: Create/Open Your Test App

1. Create a new iOS App project in Xcode, OR
2. Open your existing app project

### Step 3: Add Framework to Your App

1. **Locate the built framework:**

   - Path shown in build script output, OR
   - `~/Library/Developer/Xcode/DerivedData/OrderShieldSDK-*/Build/Products/Release-iphoneos/OrderShieldSDK.framework`

2. **Add to project:**

   - Drag `OrderShieldSDK.framework` into your app's project navigator
   - ✅ Check "Copy items if needed"
   - ✅ Select your app target
   - Click "Finish"

3. **Link the framework:**
   - Select your **app target** in Xcode
   - Go to **General** tab
   - Scroll to **"Frameworks, Libraries, and Embedded Content"**
   - Click **+** button
   - Select `OrderShieldSDK.framework`
   - Set to **"Embed & Sign"**

### Step 4: Add Camera Permission

1. Open your app's `Info.plist`
2. Add this key-value pair:
   - **Key:** `NSCameraUsageDescription`
   - **Value:** `We need access to your camera to verify your identity`

Or add this XML:

```xml
<key>NSCameraUsageDescription</key>
<string>We need access to your camera to verify your identity</string>
```

### Step 5: Add Code to Your App

**Important Notes:**
- The SDK automatically handles device registration and customer ID storage
- The verification flow starts directly with the first required step (no welcome screen)
- All delegate methods are optional - implement only what you need
- The SDK uses purple-themed buttons with arrow icons for consistency

**Basic Implementation (without delegate):**

```swift
import UIKit
import OrderShieldSDK

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        setupOrderShieldSDK()
    }

    private func setupOrderShieldSDK() {
        // Step 1: Configure with API key
        OrderShield.shared.configure(
            apiKey: "dev_0RZ-0SCe4BS4ORZhTuW5hL5HEfyFH6jIjH6iwWijLlk"
        )

        // Step 2: Initialize (register device & fetch settings)
        // Note: customer_id is automatically retrieved from device registration API
        // and stored internally. No need to pass it manually.
        Task {
            let success = await OrderShield.shared.initialize()
            if success {
                print("✅ SDK Ready!")
            } else {
                print("❌ SDK Initialization Failed")
            }
        }
    }

    @IBAction func startVerificationButtonTapped(_ sender: UIButton) {
        // Step 3: Start verification flow
        // The flow will directly start with the first required verification step
        // customer_id is automatically retrieved from storage (no parameter needed)
        OrderShield.shared.startVerification(
            presentingViewController: self
        )
    }
}
```

**Alternative: Using async/await version (returns session token):**

```swift
@IBAction func startVerificationButtonTapped(_ sender: UIButton) {
    Task {
        // Async version returns session token if successful
        if let sessionToken = await OrderShield.shared.startVerification(
            presentingViewController: self
        ) {
            print("✅ Verification started with session: \(sessionToken)")
        } else {
            print("❌ Failed to start verification")
        }
    }
}
```

**Advanced Implementation (with delegate for API errors and callbacks):**

```swift
import UIKit
import OrderShieldSDK

class ViewController: UIViewController, OrderShieldDelegate {

    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var logTextView: UITextView!

    override func viewDidLoad() {
        super.viewDidLoad()
        setupOrderShieldSDK()
    }

    private func setupOrderShieldSDK() {
        // Set delegate to receive callbacks
        OrderShield.shared.delegate = self

        // Step 1: Configure with API key
        OrderShield.shared.configure(
            apiKey: "dev_0RZ-0SCe4BS4ORZhTuW5hL5HEfyFH6jIjH6iwWijLlk"
        )

        // Step 2: Initialize (register device & fetch settings)
        Task {
            let success = await OrderShield.shared.initialize()
            updateStatus(success ? "SDK Ready" : "SDK Failed")
        }
    }

    @IBAction func startVerificationButtonTapped(_ sender: UIButton) {
        // Step 3: Start verification flow
        // The flow will directly start with the first required verification step
        // No welcome screen - verification steps begin immediately
        OrderShield.shared.startVerification(
            presentingViewController: self
        )
        
        // Or use async version to get session token:
        // Task {
        //     if let sessionToken = await OrderShield.shared.startVerification(
        //         presentingViewController: self
        //     ) {
        //         print("Session token: \(sessionToken)")
        //     }
        // }
    }

    // MARK: - Helper Methods

    private func updateStatus(_ message: String) {
        DispatchQueue.main.async {
            self.statusLabel.text = message
        }
    }

    private func addLog(_ message: String) {
        DispatchQueue.main.async {
            let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
            self.logTextView.text += "[\(timestamp)] \(message)\n"
            // Auto-scroll to bottom
            let bottom = NSRange(location: self.logTextView.text.count - 1, length: 1)
            self.logTextView.scrollRangeToVisible(bottom)
        }
    }

    // MARK: - OrderShieldDelegate - Initialization Callbacks

    func orderShieldDidRegisterDevice(success: Bool, error: Error?) {
        if success {
            addLog("✅ Device registered successfully")
        } else {
            addLog("❌ Device registration failed: \(error?.localizedDescription ?? "Unknown error")")
            updateStatus("Registration Failed")
        }
    }

    func orderShieldDidFetchSettings(success: Bool, settings: VerificationSettingsData?, error: Error?) {
        if success, let settings = settings {
            addLog("✅ Settings fetched: \(settings.requiredSteps.joined(separator: ", "))")
        } else {
            addLog("❌ Failed to fetch settings: \(error?.localizedDescription ?? "Unknown error")")
            updateStatus("Settings Fetch Failed")
        }
    }

    func orderShieldDidInitialize(success: Bool, error: Error?) {
        if success {
            addLog("✅ SDK initialized successfully")
            updateStatus("SDK Ready")
        } else {
            addLog("❌ SDK initialization failed: \(error?.localizedDescription ?? "Unknown error")")
            updateStatus("Initialization Failed")

            // Show error alert
            DispatchQueue.main.async {
                let alert = UIAlertController(
                    title: "Initialization Failed",
                    message: error?.localizedDescription ?? "Unknown error occurred",
                    preferredStyle: .alert
                )
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                self.present(alert, animated: true)
            }
        }
    }

    // MARK: - OrderShieldDelegate - Verification Flow Callbacks

    func orderShieldDidStartVerification(success: Bool, sessionToken: String?, error: Error?) {
        if success, let token = sessionToken {
            addLog("✅ Verification started - Session: \(token.prefix(20))...")
            updateStatus("Verification Started")
        } else {
            addLog("❌ Failed to start verification: \(error?.localizedDescription ?? "Unknown error")")
            updateStatus("Start Failed")

            // Show error alert
            DispatchQueue.main.async {
                let alert = UIAlertController(
                    title: "Verification Failed",
                    message: error?.localizedDescription ?? "Failed to start verification",
                    preferredStyle: .alert
                )
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                self.present(alert, animated: true)
            }
        }
    }
    
    // Optional: Get detailed verification start information
    func orderShieldDidStartVerificationWithDetails(
        success: Bool,
        sessionId: String?,
        sessionToken: String?,
        stepsRequired: [String]?,
        stepsOptional: [String]?,
        expiresAt: String?,
        error: Error?
    ) {
        if success {
            addLog("✅ Verification started with details:")
            addLog("   Session ID: \(sessionId ?? "N/A")")
            addLog("   Required Steps: \(stepsRequired?.joined(separator: ", ") ?? "N/A")")
            addLog("   Optional Steps: \(stepsOptional?.joined(separator: ", ") ?? "N/A")")
        }
    }

    func orderShieldDidStartStep(step: String, stepIndex: Int, totalSteps: Int) {
        addLog("📝 Step \(stepIndex + 1)/\(totalSteps) started: \(step)")
        updateStatus("Step \(stepIndex + 1)/\(totalSteps): \(step)")
    }

    func orderShieldDidCompleteStep(step: String, stepIndex: Int, success: Bool, error: Error?) {
        if success {
            addLog("✅ Step \(stepIndex + 1) completed: \(step)")
        } else {
            addLog("❌ Step \(stepIndex + 1) failed: \(step) - \(error?.localizedDescription ?? "Unknown error")")
            updateStatus("Step \(stepIndex + 1) Failed")
        }
    }

    // MARK: - OrderShieldDelegate - Terms & Signature Callbacks

    func orderShieldDidFetchTermsCheckboxes(success: Bool, checkboxes: [TermsCheckbox]?, error: Error?) {
        if success, let checkboxes = checkboxes {
            addLog("✅ Terms checkboxes fetched: \(checkboxes.count) items")
        } else {
            addLog("❌ Failed to fetch terms checkboxes: \(error?.localizedDescription ?? "Unknown error")")
        }
    }

    func orderShieldDidAcceptTerms(success: Bool, acceptedCheckboxIds: [String]?, error: Error?) {
        if success, let ids = acceptedCheckboxIds {
            addLog("✅ Terms accepted: \(ids.count) checkboxes")
        } else {
            addLog("❌ Failed to accept terms: \(error?.localizedDescription ?? "Unknown error")")
        }
    }

    func orderShieldDidSubmitSignature(success: Bool, error: Error?) {
        if success {
            addLog("✅ Signature submitted successfully")
        } else {
            addLog("❌ Failed to submit signature: \(error?.localizedDescription ?? "Unknown error")")
        }
    }

    func orderShieldDidSubmitTermsAndSignature(success: Bool, acceptedCheckboxIds: [String]?, error: Error?) {
        if success {
            addLog("✅ Terms and signature submitted together")
        } else {
            addLog("❌ Failed to submit terms and signature: \(error?.localizedDescription ?? "Unknown error")")
        }
    }

    // MARK: - OrderShieldDelegate - User Info Callback

    func orderShieldDidSubmitUserInfo(success: Bool, firstName: String?, lastName: String?, dateOfBirth: String?, error: Error?) {
        if success, let firstName = firstName, let lastName = lastName {
            addLog("✅ User info submitted: \(firstName) \(lastName)")
        } else {
            addLog("❌ Failed to submit user info: \(error?.localizedDescription ?? "Unknown error")")
        }
    }

    func orderShieldDidCompleteVerification(sessionId: String?) {
        addLog("🎉 Verification completed! Session ID: \(sessionId ?? "N/A")")
        updateStatus("Verification Complete!")

        // Show success message
        DispatchQueue.main.async {
            let alert = UIAlertController(
                title: "Success",
                message: "Verification completed successfully!",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            self.present(alert, animated: true)
        }
    }

    func orderShieldDidCancelVerification(error: Error?) {
        if let error = error {
            addLog("❌ Verification cancelled: \(error.localizedDescription)")
            updateStatus("Verification Cancelled")
        } else {
            addLog("⚠️ Verification cancelled by user")
            updateStatus("Cancelled")
        }
    }

    // MARK: - OrderShieldDelegate - API Call Callbacks

    func orderShieldWillCallAPI(endpoint: String, method: String) {
        addLog("📡 API Call: \(method) \(endpoint)")
    }

    func orderShieldDidCallAPI(endpoint: String, success: Bool, statusCode: Int?, error: Error?) {
        if success {
            addLog("✅ API Success: \(endpoint) (Status: \(statusCode ?? 0))")
        } else {
            addLog("❌ API Error: \(endpoint) - \(error?.localizedDescription ?? "Unknown error") (Status: \(statusCode ?? 0))")

            // Log detailed error information
            if let error = error {
                addLog("   Error Domain: \((error as NSError).domain)")
                addLog("   Error Code: \((error as NSError).code)")
                if let userInfo = (error as NSError).userInfo as? [String: Any] {
                    addLog("   User Info: \(userInfo)")
                }
            }
        }
    }
}
```

### Step 6: Test

1. **Build and Run** (⌘R)
2. Tap your "Start Verification" button
3. The SDK "Start Verification" screen will appear; tap the button there to begin
4. The verification flow will:
   - For a **new** session, call `/verification/start` and begin from the first available step
   - For an **existing** session, call `/verification/status` and resume from the first remaining step
   - Show steps in a consistent SDK-controlled order based on which steps are required/remaining for that session
5. Complete all required verification steps
6. Verify completion screen appears
7. Check console logs for API calls and errors

**Note:** The verification flow automatically adapts based on which steps are required/remaining for the session. The **order** is determined by the SDK (not by the settings API order) and may evolve over time.

---

## Step 7: Monitor API Calls and Errors (Optional but Recommended)

### Using Delegate Callbacks

The SDK provides a comprehensive delegate protocol to monitor:

- ✅ API call states (before/after each call)
- ✅ Initialization progress
- ✅ Verification step progress
- ✅ Errors and completion
- ✅ Terms and signature submissions
- ✅ User information submissions

**Benefits:**

- Track all API calls in your app
- Get detailed error information
- Monitor verification progress
- Update UI based on SDK state
- Log analytics events
- Handle errors gracefully

**Note:** All delegate methods are optional. The SDK provides default empty implementations, so you only need to implement the methods you care about.

### Complete Example with Error Handling

```swift
import UIKit
import OrderShieldSDK

class ViewController: UIViewController, OrderShieldDelegate {

    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var errorLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Set delegate BEFORE configuring
        OrderShield.shared.delegate = self

        setupSDK()
    }

    private func setupSDK() {
        OrderShield.shared.configure(apiKey: "your-api-key")

        Task {
            await OrderShield.shared.initialize()
        }
    }

    @IBAction func startTapped() {
        // Start verification flow - directly begins with first required step
        OrderShield.shared.startVerification(
            presentingViewController: self
        )
    }

    // MARK: - OrderShieldDelegate

    // Get API errors
    func orderShieldDidCallAPI(endpoint: String, success: Bool, statusCode: Int?, error: Error?) {
        if !success {
            // Handle API error
            DispatchQueue.main.async {
                self.errorLabel.text = "API Error: \(endpoint)\n\(error?.localizedDescription ?? "Unknown")"
                self.errorLabel.isHidden = false
            }

            // Log to your analytics
            print("❌ API Error - Endpoint: \(endpoint), Status: \(statusCode ?? 0), Error: \(error?.localizedDescription ?? "Unknown")")
        }
    }

    // Get initialization errors
    func orderShieldDidInitialize(success: Bool, error: Error?) {
        if !success {
            // Handle initialization error
            DispatchQueue.main.async {
                self.statusLabel.text = "Initialization Failed"
                self.errorLabel.text = error?.localizedDescription ?? "Unknown error"
                self.errorLabel.isHidden = false
            }
        }
    }

    // Get verification errors
    func orderShieldDidStartVerification(success: Bool, sessionToken: String?, error: Error?) {
        if !success {
            // Handle verification start error
            DispatchQueue.main.async {
                let alert = UIAlertController(
                    title: "Verification Failed",
                    message: error?.localizedDescription ?? "Failed to start verification",
                    preferredStyle: .alert
                )
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                self.present(alert, animated: true)
            }
        }
    }

    // Track step progress
    func orderShieldDidStartStep(step: String, stepIndex: Int, totalSteps: Int) {
        DispatchQueue.main.async {
            self.statusLabel.text = "Step \(stepIndex + 1)/\(totalSteps): \(step)"
        }
    }

    // Get step errors
    func orderShieldDidCompleteStep(step: String, stepIndex: Int, success: Bool, error: Error?) {
        if !success {
            // Handle step error
            print("Step \(step) failed: \(error?.localizedDescription ?? "Unknown")")
        }
    }

    // Get user info submission callback
    func orderShieldDidSubmitUserInfo(success: Bool, firstName: String?, lastName: String?, dateOfBirth: String?, error: Error?) {
        if success {
            print("✅ User info submitted: \(firstName ?? "") \(lastName ?? "")")
        } else {
            print("❌ User info submission failed: \(error?.localizedDescription ?? "Unknown")")
        }
    }

    // Get terms and signature callbacks
    func orderShieldDidAcceptTerms(success: Bool, acceptedCheckboxIds: [String]?, error: Error?) {
        if success {
            print("✅ Terms accepted")
        } else {
            print("❌ Terms acceptance failed: \(error?.localizedDescription ?? "Unknown")")
        }
    }

    func orderShieldDidSubmitSignature(success: Bool, error: Error?) {
        if success {
            print("✅ Signature submitted")
        } else {
            print("❌ Signature submission failed: \(error?.localizedDescription ?? "Unknown")")
        }
    }
}
```

### Accessing Error Details

All delegate methods provide `Error` objects with detailed information:

```swift
func orderShieldDidCallAPI(endpoint: String, success: Bool, statusCode: Int?, error: Error?) {
    if let error = error {
        // Cast to NSError for detailed information
        let nsError = error as NSError

        print("Error Domain: \(nsError.domain)")
        print("Error Code: \(nsError.code)")
        print("Error Description: \(nsError.localizedDescription)")
        print("User Info: \(nsError.userInfo)")

        // Check specific error types
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
    }
}
```

### Console Logs

The SDK automatically logs:

- ✅ cURL commands for each API call (for debugging)
- ✅ SDK initialization status
- ✅ Device registration status
- ✅ Settings fetch status

**Check Xcode Console** for detailed logs like:

```
📡 [OrderShieldSDK] API Call: register-device
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
curl -X 'POST' \
  'https://ordershield-api.projectbeta.biz/api/sdk/register-device' \
  ...
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## Method 3: Workspace Integration (Better for Development)

### Step 1: Create Workspace

1. In Xcode: **File → New → Workspace**
2. Save as `OrderShieldSDK.xcworkspace` in the OrderShieldSDK folder

### Step 2: Add Projects to Workspace

1. **File → Add Files to "OrderShieldSDK.xcworkspace"**
2. Add `OrderShieldSDK.xcodeproj`
3. Add your test app project (or create new one)

### Step 3: Link Framework

1. Select your **test app target**
2. **General → Frameworks, Libraries, and Embedded Content**
3. Click **+**
4. Select `OrderShieldSDK.framework` from the OrderShieldSDK project
5. Set to **"Embed & Sign"**

### Step 4-6: Same as Method 1

Follow steps 4-6 from Method 1 above.

---

## Visual Guide

### Adding Framework to Target

```
┌─────────────────────────────────────────┐
│ Your App Target                          │
├─────────────────────────────────────────┤
│ General                                 │
│                                         │
│ Frameworks, Libraries, and Embedded    │
│ Content:                                │
│                                         │
│  ┌───────────────────────────────┐    │
│  │ OrderShieldSDK.framework      │    │
│  │ [Embed & Sign] ▼              │    │
│  └───────────────────────────────┘    │
│                                         │
│  [+ Add]                                │
└─────────────────────────────────────────┘
```

### Project Structure

```
YourApp/
├── AppDelegate.swift
├── ViewController.swift
├── Info.plist (with camera permission)
└── Frameworks/
    └── OrderShieldSDK.framework ✅
```

---

## Quick Verification

Run this in your app to verify framework is accessible:

```swift
// In viewDidLoad or AppDelegate
if Bundle.main.path(forResource: "OrderShieldSDK", ofType: "framework") != nil {
    print("✅ Framework found!")
} else {
    print("❌ Framework not found - check linking")
}
```

---

## Common Issues & Solutions

### Issue: "No such module 'OrderShieldSDK'"

**Solution:**

1. Clean build folder: **⌘⇧K**
2. Check framework is in "Frameworks, Libraries, and Embedded Content"
3. Set to "Embed & Sign"
4. Rebuild: **⌘B**

### Issue: "dyld: Library not loaded"

**Solution:**

1. Ensure framework is set to "Embed & Sign" (not just "Do Not Embed")
2. Clean and rebuild

### Issue: Camera not working

**Solution:**

1. Verify `NSCameraUsageDescription` in Info.plist
2. Test on real device (simulator may have issues)
3. Check camera permission in Settings → Your App

### Issue: API errors

**Solution:**

1. Verify API key is correct
2. Check network connectivity
3. Check Xcode console for detailed error messages
4. Verify server endpoints are accessible
5. **Use delegate callbacks** to get detailed error information:
   ```swift
   func orderShieldDidCallAPI(endpoint: String, success: Bool, statusCode: Int?, error: Error?) {
       if !success {
           print("API Error: \(endpoint)")
           print("Status Code: \(statusCode ?? 0)")
           print("Error: \(error?.localizedDescription ?? "Unknown")")
       }
   }
   ```

### Issue: Customer ID not found

**Solution:**

1. Ensure `initialize()` is called before `startVerification()`
2. Check that device registration API returned customer_id
3. Verify network connectivity during initialization
4. Check delegate callback `orderShieldDidRegisterDevice` for errors

---

## Testing Checklist

- [ ] Framework builds successfully
- [ ] Framework added to project
- [ ] Framework linked in target settings
- [ ] Framework set to "Embed & Sign"
- [ ] Camera permission added to Info.plist
- [ ] Code imports OrderShieldSDK without errors
- [ ] SDK configures successfully
- [ ] SDK initializes successfully
- [ ] Customer ID is stored after initialization
- [ ] Delegate is set and receiving callbacks (if implemented)
- [ ] API calls are logged in console
- [ ] Verification flow starts directly (no welcome screen)
- [ ] All verification steps complete in correct order
- [ ] Email/SMS OTP verification respects server settings (shown/hidden based on `emailVerificationRequired`/`smsVerificationRequired` flags)
- [ ] Continue buttons display with purple background (`UIColor(red: 0.42, green: 0.35, blue: 0.80, alpha: 1.0)`) and white arrow icons
- [ ] Buttons show proper enabled/disabled states (enabled: full opacity purple, disabled: 50% opacity purple)
- [ ] Keyboard dismisses on return key for all text fields
- [ ] Scrollable content works on email, phone, and user info screens
- [ ] Selfie capture works with retake option
- [ ] Country picker works for phone verification
- [ ] Date picker works for user info
- [ ] Signature capture works with clear option
- [ ] Completion screen appears
- [ ] Errors are handled gracefully

---

## Next Steps

Once integration is complete:

1. **Test all verification steps:**

   - **Selfie verification**: Camera capture with retake option
   - **Email verification**: Email input with optional OTP verification (based on server settings)
   - **Phone verification**: Phone number input with country picker and optional SMS OTP (based on server settings)
   - **User Information**: First name, last name, and date of birth
   - **Terms agreement**: Dynamic checkboxes fetched from server
   - **Signature capture**: Digital signature with clear option

**Note:** Email and SMS OTP verification steps are conditionally shown based on `emailVerificationRequired` and `smsVerificationRequired` flags from the server. If these are `false`, the OTP input step is skipped.

2. **Test error handling:**

   - Invalid API key (check delegate callbacks)
   - Network errors (check `orderShieldDidCallAPI` callback)
   - Missing customer ID (check `orderShieldDidRegisterDevice` callback)
   - Step failures (check `orderShieldDidCompleteStep` callback)

3. **Test on different devices:**

   - iPhone (various models)
   - iPad (if supported)
   - Different iOS versions

4. **Customize if needed:**
   - Modify UI colors/branding
   - Add custom error handling
   - Integrate with your app's navigation

---

## Getting API Errors and Monitoring

### Method 1: Using Delegate (Recommended)

Implement `OrderShieldDelegate` to receive all callbacks:

```swift
class ViewController: UIViewController, OrderShieldDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()
        OrderShield.shared.delegate = self
        // ... rest of setup
    }

    // Get API errors
    func orderShieldDidCallAPI(endpoint: String, success: Bool, statusCode: Int?, error: Error?) {
        if !success {
            // Handle error
            print("❌ API Error: \(endpoint)")
            print("   Status: \(statusCode ?? 0)")
            print("   Error: \(error?.localizedDescription ?? "Unknown")")
        }
    }

    // Get initialization errors
    func orderShieldDidInitialize(success: Bool, error: Error?) {
        if !success {
            print("❌ Initialization failed: \(error?.localizedDescription ?? "Unknown")")
        }
    }

    // Get verification errors
    func orderShieldDidStartVerification(success: Bool, sessionToken: String?, error: Error?) {
        if !success {
            print("❌ Verification start failed: \(error?.localizedDescription ?? "Unknown")")
        }
    }

    // Get step errors
    func orderShieldDidCompleteStep(step: String, stepIndex: Int, success: Bool, error: Error?) {
        if !success {
            print("❌ Step \(step) failed: \(error?.localizedDescription ?? "Unknown")")
        }
    }
}
```

### Method 2: Check Console Logs

The SDK automatically prints:

- ✅ cURL commands for each API call
- ✅ API call status
- ✅ Error messages
- ✅ Initialization status

**Check Xcode Console** for all logs.

### Method 3: Check Return Values

```swift
// Initialize returns Bool
Task {
    let success = await OrderShield.shared.initialize()
    if !success {
        // Check console for error details
        // Or use delegate callback
    }
}

// Start verification has two versions:

// Version 1: Synchronous (no return value)
OrderShield.shared.startVerification(
    presentingViewController: self
)

// Version 2: Async (returns session token)
Task {
    if let sessionToken = await OrderShield.shared.startVerification(
        presentingViewController: self
    ) {
        print("Success: Session token = \(sessionToken)")
    } else {
        // Check console or delegate for error
        print("Failed to start verification")
    }
}
```

### Error Types

The SDK uses these error types:

```swift
enum NetworkError: Error {
    case missingAPIKey
    case invalidResponse
    case decodingError
    case encodingError
}
```

You can check error types in delegate callbacks:

```swift
func orderShieldDidCallAPI(endpoint: String, success: Bool, statusCode: Int?, error: Error?) {
    if let error = error as? NetworkError {
        switch error {
        case .missingAPIKey:
            // Handle missing API key
        case .invalidResponse:
            // Handle invalid response
        case .decodingError:
            // Handle decoding error
        case .encodingError:
            // Handle encoding error
        }
    }
}
```

---

## Support

If you encounter issues:

1. **Check Xcode console** for error messages and cURL logs
2. **Implement delegate** to get detailed error callbacks
3. **Verify all steps** above are completed
4. **Check `TESTING_GUIDE.md`** for detailed troubleshooting
5. **Review `USAGE.md`** for API documentation
6. **Review `DELEGATE_USAGE_EXAMPLE.md`** for delegate implementation examples

---

## Quick Reference: Getting API Errors in Your App

### Setup (One Time)

```swift
// In viewDidLoad or AppDelegate
OrderShield.shared.delegate = self  // Set delegate

// Configure SDK
OrderShield.shared.configure(apiKey: "your-api-key")

// Initialize SDK
Task {
    let success = await OrderShield.shared.initialize()
    if success {
        print("✅ SDK Ready")
    }
}
```

### Get All API Errors

```swift
func orderShieldDidCallAPI(endpoint: String, success: Bool, statusCode: Int?, error: Error?) {
    if !success {
        // This is called for EVERY API call that fails
        print("❌ API Error:")
        print("   Endpoint: \(endpoint)")
        print("   Status Code: \(statusCode ?? 0)")
        print("   Error: \(error?.localizedDescription ?? "Unknown")")

        // Update your UI
        DispatchQueue.main.async {
            self.showError("API call failed: \(endpoint)")
        }
    }
}
```

### Get Initialization Errors

```swift
func orderShieldDidInitialize(success: Bool, error: Error?) {
    if !success {
        // Handle initialization failure
        print("Initialization failed: \(error?.localizedDescription ?? "Unknown")")
    }
}
```

### Get Verification Errors

```swift
func orderShieldDidStartVerification(success: Bool, sessionToken: String?, error: Error?) {
    if !success {
        // Handle verification start failure
        print("Verification failed: \(error?.localizedDescription ?? "Unknown")")
    }
}

func orderShieldDidCompleteStep(step: String, stepIndex: Int, success: Bool, error: Error?) {
    if !success {
        // Handle step failure
        print("Step \(step) failed: \(error?.localizedDescription ?? "Unknown")")
    }
}

// Get user info submission callback
func orderShieldDidSubmitUserInfo(success: Bool, firstName: String?, lastName: String?, dateOfBirth: String?, error: Error?) {
    if !success {
        print("❌ User info submission failed: \(error?.localizedDescription ?? "Unknown")")
    }
}
```

### Monitor All API Calls

```swift
func orderShieldWillCallAPI(endpoint: String, method: String) {
    print("📡 Calling: \(method) \(endpoint)")
}

func orderShieldDidCallAPI(endpoint: String, success: Bool, statusCode: Int?, error: Error?) {
    if success {
        print("✅ Success: \(endpoint) (Status: \(statusCode ?? 0))")
    } else {
        print("❌ Failed: \(endpoint) (Status: \(statusCode ?? 0))")
    }
}
```

### Example: Complete Error Handling

```swift
class ViewController: UIViewController, OrderShieldDelegate {

    @IBOutlet weak var errorLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        OrderShield.shared.delegate = self
    }

    // Centralized error handling
    private func handleError(_ error: Error?, context: String) {
        let message = error?.localizedDescription ?? "Unknown error"
        print("❌ \(context): \(message)")

        DispatchQueue.main.async {
            self.errorLabel.text = "\(context): \(message)"
            self.errorLabel.isHidden = false
        }
    }

    // MARK: - OrderShieldDelegate

    func orderShieldDidCallAPI(endpoint: String, success: Bool, statusCode: Int?, error: Error?) {
        if !success {
            handleError(error, context: "API Error (\(endpoint))")
        }
    }

    func orderShieldDidInitialize(success: Bool, error: Error?) {
        if !success {
            handleError(error, context: "Initialization")
        }
    }

    func orderShieldDidStartVerification(success: Bool, sessionToken: String?, error: Error?) {
        if !success {
            handleError(error, context: "Verification Start")
        }
    }

    func orderShieldDidCompleteStep(step: String, stepIndex: Int, success: Bool, error: Error?) {
        if !success {
            handleError(error, context: "Step \(step)")
        }
    }

    func orderShieldDidSubmitUserInfo(success: Bool, firstName: String?, lastName: String?, dateOfBirth: String?, error: Error?) {
        if !success {
            handleError(error, context: "User Info Submission")
        }
    }

    func orderShieldDidAcceptTerms(success: Bool, acceptedCheckboxIds: [String]?, error: Error?) {
        if !success {
            handleError(error, context: "Terms Acceptance")
        }
    }

    func orderShieldDidSubmitSignature(success: Bool, error: Error?) {
        if !success {
            handleError(error, context: "Signature Submission")
        }
    }
}
```
