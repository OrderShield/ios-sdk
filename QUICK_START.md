# Quick Start Guide - Testing OrderShieldSDK

## 🚀 Fastest Way to Test

### Step 1: Build the Framework

1. Open `OrderShieldSDK.xcodeproj` in Xcode
2. Select **OrderShieldSDK** scheme
3. Select **Any iOS Device** or **Generic iOS Device**
4. Press **⌘B** (Build)
5. Framework is ready!

### Step 2: Add to Your Test App

#### Option A: Add Framework File Directly

1. Find the built framework:

   - Go to: `~/Library/Developer/Xcode/DerivedData/OrderShieldSDK-*/Build/Products/Debug-iphoneos/`
   - Copy `OrderShieldSDK.framework`

2. In your test app:
   - Drag framework into project
   - Select your app target
   - **General** → **Frameworks, Libraries, and Embedded Content**
   - Add `OrderShieldSDK.framework`
   - Set to **"Embed & Sign"**

#### Option B: Use Workspace (Recommended)

1. Create workspace:

   ```bash
   # In terminal, navigate to OrderShieldSDK directory
   # Create workspace file (or do it in Xcode)
   ```

2. In Xcode:
   - File → New → Workspace
   - Save as `OrderShieldSDK.xcworkspace`
   - Add both `OrderShieldSDK.xcodeproj` and your test app project
   - Link framework in test app target settings

### Step 3: Add Camera Permission

Add to your app's `Info.plist`:

```xml
<key>NSCameraUsageDescription</key>
<string>We need access to your camera to verify your identity</string>
```

### Step 4: Use in Code

```swift
import UIKit
import OrderShieldSDK

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // 1. Configure SDK with API key
        OrderShield.shared.configure(
            apiKey: "dev_0RZ-0SCe4BS4ORZhTuW5hL5HEfyFH6jIjH6iwWijLlk"
        )

        // 2. Initialize (register device & fetch settings)
        // Note: customer_id is automatically retrieved from device registration API
        Task {
            let success = await OrderShield.shared.initialize()
            if success {
                print("✅ SDK Ready!")
            } else {
                print("❌ SDK Initialization Failed")
            }
        }
    }

    @IBAction func startTapped() {
        // 3. Start verification flow
        // The flow will directly start with the first required verification step
        // customer_id is automatically retrieved from storage (no parameter needed)
        OrderShield.shared.startVerification(
            presentingViewController: self
        )
    }
}
```

### Step 5: Run and Test

1. Connect iOS device (or use simulator)
2. Build and run (⌘R)
3. Tap "Start Verification"
4. Complete the flow!

## ✅ Verification Checklist

- [ ] Framework builds without errors
- [ ] Framework is linked in app target
- [ ] Framework is set to "Embed & Sign"
- [ ] Camera permission added to Info.plist
- [ ] SDK configures successfully
- [ ] SDK initializes successfully
- [ ] Customer ID is stored after initialization
- [ ] Verification flow starts directly (no welcome screen)
- [ ] All verification steps complete successfully
- [ ] Continue buttons display with purple background and arrow icons
- [ ] Buttons show proper enabled/disabled states
- [ ] Keyboard dismisses on return key
- [ ] Scrollable content works on email, phone, and user info screens

## 🐛 Troubleshooting

### "No such module 'OrderShieldSDK'"

- Make sure framework is in "Frameworks, Libraries, and Embedded Content"
- Clean build folder (⌘⇧K) and rebuild

### Camera not working

- Check Info.plist has `NSCameraUsageDescription`
- Test on real device (simulator may have issues)

### API errors

- Verify API key is correct
- Check network connection
- Check Xcode console for error messages
- Implement `OrderShieldDelegate` to get detailed error callbacks
- Check that `initialize()` completed successfully before calling `startVerification()`

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
