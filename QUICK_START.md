# Quick Start Guide - Testing OrderShieldSDK

## 🚀 Fastest Way to Test

### Step 1: Add the SDK via Swift Package Manager (no framework build needed)

1. Open your app project in Xcode.
2. **File** → **Add Package Dependencies...**
3. Enter the package URL: `https://github.com/OrderShield/ios-sdk.git` and add the package.
4. Select the **OrderShieldSDK** library and add it to your app target.

You do **not** need to build a framework or add any file manually — the project’s `Package.swift` is used by Xcode.

**Alternative (manual framework):** If you prefer not to use SPM, build the framework from `OrderShieldSDK.xcodeproj` (OrderShieldSDK scheme, Generic iOS Device, ⌘B), then drag `OrderShieldSDK.framework` into your app and add it under **Frameworks, Libraries, and Embedded Content** → **Embed & Sign**.

### Step 2: Add Camera Permission

Add to your app's `Info.plist`:

```xml
<key>NSCameraUsageDescription</key>
<string>We need access to your camera to verify your identity</string>
```

### Step 3: Use in Code

Initialize the SDK **at app launch** in `AppDelegate`; start verification from any view controller when the user taps your button.

```swift
import UIKit
import OrderShieldSDK

// In AppDelegate — run at app launch
class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        OrderShield.shared.configure(apiKey: "dev_0RZ-0SCe4BS4ORZhTuW5hL5HEfyFH6jIjH6iwWijLlk")
        Task {
            let success = await OrderShield.shared.initialize()
            if success { print("✅ SDK Ready!") } else { print("❌ SDK Initialization Failed") }
        }
        return true
    }
}

// In your view controller — when user taps "Start Verification"
class ViewController: UIViewController {
    @IBAction func startTapped() {
        OrderShield.shared.startVerification(presentingViewController: self)
    }
}
```

### Step 4: Run and Test

1. Connect iOS device (or use simulator)
2. Build and run (⌘R)
3. Tap "Start Verification"
4. On the SDK "Start Verification" screen, tap the button to begin
5. Complete the flow (new sessions start from the first available step; existing sessions resume from the first remaining step)

## ✅ Verification Checklist

- [ ] OrderShieldSDK package (or framework) is added to the app target
- [ ] If using framework: it is set to "Embed & Sign"
- [ ] Camera permission added to Info.plist
- [ ] SDK configures successfully
- [ ] SDK initializes successfully
- [ ] Customer ID is stored after initialization
- [ ] Start screen appears and verification flow begins after tapping "Start Verification"
- [ ] All verification steps complete successfully
- [ ] Continue buttons display with purple background and arrow icons
- [ ] Buttons show proper enabled/disabled states
- [ ] Keyboard dismisses on return key
- [ ] Scrollable content works on email, phone, and user info screens

## 🐛 Troubleshooting

### "No such module 'OrderShieldSDK'"

- **SPM:** Ensure the OrderShieldSDK package is added to your app target (File → Add Package Dependencies; add the package and select the target).
- **Framework:** Ensure the framework is in "Frameworks, Libraries, and Embedded Content".
- Clean build folder (⌘⇧K) and rebuild.

### Camera not working

- Check Info.plist has `NSCameraUsageDescription`
- Test on real device (simulator may have issues)

### API errors

- Verify API key is correct
- Check network connection
- Check Xcode console for error messages
- Implement `OrderShieldDelegate` to get detailed error callbacks
- Check that `initialize()` completed successfully before calling `startVerification()`
- If you expect a resumed session, confirm that a previous verification session was started and that a session token exists (you should see a `GET /verification/status` call in the console when resuming)

### Build errors

- Ensure iOS deployment target is 13.0+
- Clean build folder
- Restart Xcode

## 📱 Testing on Device

1. Connect iPhone via USB
2. Trust computer on device
3. Select device in Xcode
4. Build and run (⌘R)

## 📝 Example Test App Structure

```
TestApp/
├── AppDelegate.swift
├── ViewController.swift
├── Main.storyboard (or programmatic UI)
└── Info.plist (with camera permission)
```

See `TestAppExample/` folder for complete example code.
