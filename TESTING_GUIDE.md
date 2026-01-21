# OrderShieldSDK Testing Guide

## Step 1: Build the Framework

### Option A: Build in Xcode

1. Open `OrderShieldSDK.xcodeproj` in Xcode
2. Select the **OrderShieldSDK** scheme
3. Select a **Generic iOS Device** or **Any iOS Device** (not a simulator) for framework builds
4. Go to **Product → Build** (⌘B) or **Product → Archive**
5. The framework will be built in:
   - Debug: `~/Library/Developer/Xcode/DerivedData/OrderShieldSDK-*/Build/Products/Debug-iphoneos/OrderShieldSDK.framework`
   - Release: `~/Library/Developer/Xcode/DerivedData/OrderShieldSDK-*/Build/Products/Release-iphoneos/OrderShieldSDK.framework`

### Option B: Build via Command Line

```bash
cd /Users/rajkumar/Documents/OrderShieldSDK/OrderShieldSDK

# Build for device (Release)
xcodebuild -project OrderShieldSDK.xcodeproj \
  -scheme OrderShieldSDK \
  -configuration Release \
  -sdk iphoneos \
  -arch arm64 \
  BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
  SKIP_INSTALL=NO

# Build for simulator (for testing)
xcodebuild -project OrderShieldSDK.xcodeproj \
  -scheme OrderShieldSDK \
  -configuration Debug \
  -sdk iphonesimulator \
  -arch x86_64 \
  BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
  SKIP_INSTALL=NO
```

## Step 2: Create a Test App

### Method 1: Add Framework to Existing App

1. **Create or Open Your Test App** in Xcode

2. **Add Framework to Project:**
   - Drag the `OrderShieldSDK.framework` file into your app's project navigator
   - Select "Copy items if needed"
   - Make sure your app target is checked

3. **Link the Framework:**
   - Select your app target
   - Go to **General** tab
   - Under **Frameworks, Libraries, and Embedded Content**
   - Click **+** and add `OrderShieldSDK.framework`
   - Set it to **Embed & Sign**

4. **Add Camera Permission:**
   - Open your app's `Info.plist`
   - Add:
   ```xml
   <key>NSCameraUsageDescription</key>
   <string>We need access to your camera to verify your identity</string>
   ```

### Method 2: Use Framework as Local Package (Recommended for Development)

1. **Create a Workspace:**
   - File → New → Workspace
   - Save as `OrderShieldSDK.xcworkspace`

2. **Add Both Projects:**
   - File → Add Files to Workspace
   - Add `OrderShieldSDK.xcodeproj`
   - Add your test app project

3. **Link Framework in Test App:**
   - Select your test app target
   - Go to **General** → **Frameworks, Libraries, and Embedded Content**
   - Click **+** → Add `OrderShieldSDK.framework` from the OrderShieldSDK project
   - Set to **Embed & Sign**

## Step 3: Test the Framework

### Basic Test Code

Create a test view controller in your app:

```swift
import UIKit
import OrderShieldSDK

class ViewController: UIViewController {
    
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var startButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupSDK()
    }
    
    private func setupSDK() {
        // Configure SDK with your API key
        OrderShieldSDK.shared.configure(
            apiKey: "dev_0RZ-0SCe4BS4ORZhTuW5hL5HEfyFH6jIjH6iwWijLlk"
        )
        
        // Initialize SDK (register device and fetch settings)
        Task {
            statusLabel.text = "Initializing SDK..."
            let success = await OrderShieldSDK.shared.initialize()
            
            await MainActor.run {
                if success {
                    statusLabel.text = "SDK Ready ✓"
                    startButton.isEnabled = true
                } else {
                    statusLabel.text = "SDK Initialization Failed ✗"
                    startButton.isEnabled = false
                }
            }
        }
    }
    
    @IBAction func startVerificationTapped(_ sender: UIButton) {
        // Replace with your actual customer ID
        let customerId = "550e8400-e29b-41d4-a716-446655440025"
        
        OrderShieldSDK.shared.startVerification(
            customerId: customerId,
            presentingViewController: self
        )
    }
}
```

### Complete Test App Example

```swift
import UIKit
import OrderShieldSDK

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    func application(_ application: UIApplication, 
                    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // Configure SDK early in app lifecycle
        OrderShieldSDK.shared.configure(
            apiKey: "dev_0RZ-0SCe4BS4ORZhTuW5hL5HEfyFH6jIjH6iwWijLlk"
        )
        
        // Initialize SDK
        Task {
            await OrderShieldSDK.shared.initialize()
        }
        
        return true
    }
}

class ViewController: UIViewController {
    
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var customerIdTextField: UITextField!
    @IBOutlet weak var startButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        customerIdTextField.text = "550e8400-e29b-41d4-a716-446655440025"
        customerIdTextField.placeholder = "Enter Customer ID"
        statusLabel.text = "Ready to start verification"
    }
    
    @IBAction func startVerification(_ sender: UIButton) {
        guard let customerId = customerIdTextField.text, !customerId.isEmpty else {
            showAlert(title: "Error", message: "Please enter a customer ID")
            return
        }
        
        OrderShieldSDK.shared.startVerification(
            customerId: customerId,
            presentingViewController: self
        )
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
```

## Step 4: Testing Checklist

### ✅ Initialization Test
- [ ] SDK configures without errors
- [ ] Device registration API call succeeds
- [ ] Verification settings are fetched and stored
- [ ] Required steps are saved locally

### ✅ UI Flow Test
- [ ] Welcome screen appears
- [ ] Navigation between steps works
- [ ] Each step's UI displays correctly
- [ ] Back navigation works (if applicable)

### ✅ Selfie Verification Test
- [ ] Camera permission is requested
- [ ] Camera preview displays
- [ ] Photo capture works
- [ ] Selfie submission API succeeds
- [ ] Next step appears after success

### ✅ Email Verification Test
- [ ] Email input accepts valid emails
- [ ] Send code API succeeds
- [ ] OTP input appears
- [ ] Verify code API succeeds
- [ ] Next step appears after success

### ✅ Phone Verification Test
- [ ] Phone input accepts valid numbers
- [ ] Send code API succeeds
- [ ] OTP input appears
- [ ] Verify code API succeeds
- [ ] Next step appears after success

### ✅ Terms Verification Test
- [ ] All checkboxes are displayed
- [ ] Checkboxes can be toggled
- [ ] Submit button enables when all checked
- [ ] Terms submission API succeeds
- [ ] Next step appears after success

### ✅ Signature Verification Test
- [ ] Signature view accepts drawing
- [ ] Clear button works
- [ ] Signature submission API succeeds
- [ ] Next step appears after success

### ✅ Completion Test
- [ ] Completion screen appears after all steps
- [ ] Close button dismisses the flow
- [ ] Flow completes successfully

## Step 5: Debugging Tips

### Check Framework is Linked
```swift
// Add this to verify framework is accessible
if let frameworkPath = Bundle.main.path(forResource: "OrderShieldSDK", ofType: "framework") {
    print("Framework found at: \(frameworkPath)")
} else {
    print("Framework not found!")
}
```

### Enable Debug Logging
The SDK prints debug messages. Check Xcode console for:
- "OrderShieldSDK: Device registered successfully"
- "OrderShieldSDK: Verification settings fetched and saved"
- Any error messages

### Common Issues

1. **Framework Not Found:**
   - Ensure framework is in "Frameworks, Libraries, and Embedded Content"
   - Set to "Embed & Sign"
   - Clean build folder (⌘⇧K) and rebuild

2. **Camera Not Working:**
   - Check `NSCameraUsageDescription` in Info.plist
   - Test on a real device (simulator camera may have issues)

3. **API Errors:**
   - Verify API key is correct
   - Check network connectivity
   - Verify server endpoints are accessible

4. **Build Errors:**
   - Ensure iOS deployment target is 13.0+
   - Check Swift version compatibility
   - Clean build folder

## Step 6: Testing on Device

1. **Connect iOS Device:**
   - Connect via USB
   - Trust the computer on device
   - Select device in Xcode

2. **Build and Run:**
   - Select your device as destination
   - Click Run (⌘R)
   - App will install and launch

3. **Test Verification Flow:**
   - Tap "Start Verification"
   - Complete each step
   - Verify completion screen appears

## Step 7: Distribution

### For App Store Distribution

1. Build framework for **Release** configuration
2. Use **Archive** to create distribution build
3. Framework will be embedded in your app bundle

### For Development/Testing

1. Use **Debug** configuration
2. Framework can be linked directly from build folder
3. Easier to debug and iterate

## Quick Test Script

Save this as a test file to quickly verify SDK integration:

```swift
// QuickSDKTest.swift
import UIKit
import OrderShieldSDK

extension ViewController {
    func quickTest() {
        // Test 1: Configuration
        OrderShieldSDK.shared.configure(apiKey: "test-key")
        print("✓ Configuration successful")
        
        // Test 2: Initialization
        Task {
            let success = await OrderShieldSDK.shared.initialize()
            print(success ? "✓ Initialization successful" : "✗ Initialization failed")
        }
        
        // Test 3: Start Verification
        // Uncomment when ready:
        // OrderShieldSDK.shared.startVerification(
        //     customerId: "test-id",
        //     presentingViewController: self
        // )
    }
}
```

