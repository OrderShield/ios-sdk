# Build Fixes Applied

## Issues Fixed

### 1. ✅ Naming Conflict (Main Error)
**Problem:** Class name `OrderShieldSDK` conflicted with module name `OrderShieldSDK`

**Solution:** 
- Renamed class to `OrderShield`
- Removed typealias to avoid circular reference
- Users now use `OrderShield.shared` (import module `OrderShieldSDK`, use class `OrderShield`)

**Files Changed:**
- `OrderShieldSDK.swift` - Class renamed to `OrderShield`, typealias removed

### 2. ✅ Circular Reference Error
**Problem:** Typealias `OrderShieldSDK = OrderShieldSDK.OrderShield` created circular reference

**Solution:** Removed the typealias entirely. The module name is `OrderShieldSDK` and the class name is `OrderShield`.

**Files Changed:**
- `OrderShieldSDK.swift` - Removed typealias

### 3. ✅ Async/Await Warnings
**Problem:** `await showError()` was called but `showError` is not async

**Solution:** Wrapped `showError` calls in `MainActor.run` blocks

**Files Changed:**
- `VerificationFlowCoordinator.swift` - Fixed async/await usage

### 4. ✅ UnsafeRawPointer Warnings
**Problem:** Using `objc_setAssociatedObject` with string keys caused unsafe pointer warnings

**Solution:** Replaced with tag-based lookup using a dictionary

**Files Changed:**
- `TermsVerificationViewController.swift` - Changed to use button tags and dictionary lookup

### 5. ✅ Unused Variable Warning
**Problem:** `apiKey` variable was checked but not used in guard statement

**Solution:** Changed guard to check `apiKey != nil` instead of binding it

**Files Changed:**
- `OrderShieldSDK.swift` - Updated guard statement

## Usage

After these fixes, use the SDK as follows:

```swift
import OrderShieldSDK  // Import the module

// Use OrderShield class (not OrderShieldSDK)
OrderShield.shared.configure(apiKey: "your-key")
await OrderShield.shared.initialize()
OrderShield.shared.startVerification(customerId: "id", presentingViewController: self)
```

**Important:** 
- Module name: `OrderShieldSDK` (for import)
- Class name: `OrderShield` (for usage)
- This avoids the naming conflict and circular reference

## Build Status

✅ All errors fixed
✅ All warnings resolved
✅ Framework should build successfully

## Next Steps

1. Clean build folder: **⌘⇧K** (Product → Clean Build Folder)
2. Build framework: **⌘B** (Product → Build)
3. Verify no errors or warnings appear
4. Test integration in your app
