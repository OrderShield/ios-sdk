# Objective-C Support Guide for OrderShield SDK

This document describes **iOS compatibility** for using the OrderShield SDK from **Objective-C** and lists **where and how many changes** are required.

---

## 1. iOS Compatibility Summary

| Aspect | Requirement |
|--------|-------------|
| **Minimum iOS** | iOS 13.0 (matches current `@available(iOS 13.0, *)` and SDK deployment target 17.0) |
| **Swift → ObjC** | Public Swift APIs must be exposed via the generated `OrderShieldSDK-Swift.h` header |
| **Framework** | Must build with `SWIFT_INSTALL_OBJC_HEADER = YES` so ObjC apps can `#import <OrderShieldSDK/OrderShieldSDK-Swift.h>` |
| **Types** | Only ObjC-visible types (classes inheriting `NSObject`, `@objc` protocols, primitives, `NSString`, `NSError`, etc.) can appear in the public API used from ObjC |

The SDK is **Swift-only today**. To support Objective-C:

1. Enable generation of the Swift–ObjC header.
2. Make public entry points and delegate types visible to ObjC (`NSObject`, `@objc`).
3. Replace or wrap Swift-only types (structs, Swift enums) used in the public API with ObjC-visible types.
4. Expose completion-handler APIs for async operations so ObjC can use the SDK without Swift async/await.

---

## 2. Where Changes Are Required (File-by-File)

### 2.1 Xcode project (1 file)

| File | Change |
|------|--------|
| `OrderShieldSDK.xcodeproj/project.pbxproj` | Set **`SWIFT_INSTALL_OBJC_HEADER = YES`** for the OrderShieldSDK framework target (Debug and Release). |

**Why:** With `NO`, the framework does not install the generated `OrderShieldSDK-Swift.h` header, so ObjC apps cannot import the Swift API.

---

### 2.2 Public API and delegate (3 files)

#### A. `OrderShieldSDK/OrderShieldSDK.swift`

| Change | Purpose |
|--------|--------|
| Make `OrderShield` inherit from **`NSObject`** | Required for the class to be visible and usable from ObjC. |
| Add **`@objc(OrderShield)`** (optional) | Keeps the ObjC class name as `OrderShield`. |
| Add **completion-handler overloads** for async methods | ObjC cannot use Swift `async`; provide `initialize(completion:)` and `startVerification(presentingViewController:completion:)` that call the existing async implementation and then invoke the completion block. |

**Count:** 1 class change + 2 new methods (or 2 overloads).

#### B. `OrderShieldSDK/OrderShieldDelegate.swift`

| Change | Purpose |
|--------|--------|
| Mark protocol **`@objc`** | So ObjC can conform to the delegate. |
| Replace **`VerificationSettingsData?`** with an ObjC-visible type | Structs are not visible in ObjC. Use a new class type (e.g. `OSVerificationSettingsData : NSObject`) in the delegate method signature. |
| Replace **`[TermsCheckbox]?`** with an ObjC-visible type | Same; use e.g. `[OSTermsCheckbox]` (or `NSArray` of an ObjC-visible class). |
| Keep **default implementations** in a Swift extension | No change; ObjC will still only implement the methods it cares about. |

**Count:** 1 protocol annotation + 2 parameter type changes (and corresponding updates wherever the delegate is called).

#### C. `OrderShieldSDK/Models/VerificationModels.swift`

| Change | Purpose |
|--------|--------|
| Add **`OSVerificationSettingsData`** | ObjC-visible class (subclass of `NSObject`) with properties mirroring the data the delegate needs (e.g. from `VerificationSettingsData`). |
| Add **`OSTermsCheckbox`** | ObjC-visible class with properties: `id`, `checkboxText`, `isRequired`, `displayOrder`. |
| Add **initializers** that take the existing structs | So SDK code can construct these objects from `VerificationSettingsData` and `TermsCheckbox` when calling the delegate. |

**Count:** 2 new classes + conversion from structs where delegate is called.

---

### 2.3 Internal call sites (2 files)

| File | Change |
|------|--------|
| `OrderShieldSDK/OrderShieldSDK.swift` | When calling `orderShieldDidFetchSettings`, pass an `OSVerificationSettingsData` instance created from `settingsResponse.data`. |
| `OrderShieldSDK/UI/TermsAndSignatureVerificationViewController.swift` | When calling `orderShieldDidFetchTermsCheckboxes`, pass `[OSTermsCheckbox]` built from `checkboxes` (array of `TermsCheckbox`). |

**Count:** 2 call sites updated to use the new ObjC-visible types.

---

### 2.4 Errors (optional but recommended)

| File | Change |
|------|--------|
| `OrderShieldSDK/Services/NetworkService.swift` | Make **`NetworkError`** conform to **`CustomNSError`** (and optionally `LocalizedError`) so that when passed to ObjC as `Error?` it becomes an `NSError` with a stable domain and code. |

**Count:** 1 enum conformance.

---

## 3. Total Change Summary

| Category | Files | Approx. changes |
|----------|-------|------------------|
| Project settings | 1 | 1 build setting (×2 configs) |
| Main API | 1 (`OrderShieldSDK.swift`) | NSObject, @objc, 2 completion-handler APIs |
| Delegate | 1 (`OrderShieldDelegate.swift`) | @objc, 2 parameter types |
| Models | 1 (`VerificationModels.swift`) | 2 new ObjC classes + conversions |
| Delegate call sites | 2 | Convert struct → class when calling delegate |
| Errors | 1 (optional) | CustomNSError on NetworkError |
| **Total** | **5–6 files** | **~15–20 discrete edits** |

---

## 4. What Stays the Same

- All **internal** types (e.g. `VerificationFlowCoordinator`, `NetworkService`, view controllers, other structs in `VerificationModels`) can remain Swift-only; they are not part of the public ObjC API.
- **UI** and **coordinators** do not need `@objc` unless they are exposed to the host app.
- **Build** (e.g. deployment target, `BUILD_LIBRARY_FOR_DISTRIBUTION`) can stay as-is; only `SWIFT_INSTALL_OBJC_HEADER` must be enabled for ObjC.

---

## 5. How Each Platform Uses the SDK

### Swift apps (unchanged)

- Set **`OrderShield.shared.delegate = self`** and conform to **`OrderShieldDelegate`**.
- Use Swift types: `VerificationSettingsData?`, `[TermsCheckbox]?`, `Int?` for `statusCode`, async/await, etc.
- No changes required in existing Swift sample or app code.

### Objective-C apps

- Set **`[OrderShield shared].objcDelegate = self`** and conform to **`OrderShieldDelegateObjC`**.
- Use completion-handler APIs and ObjC-visible types: `OSVerificationSettingsData *`, `NSArray<OSTermsCheckbox *> *`, `NSNumber *` for status code.

```objc
#import <OrderShieldSDK/OrderShieldSDK-Swift.h>

// Configure – use objcDelegate for Objective-C
[OrderShield shared].objcDelegate = self;
[[OrderShield shared] configureWithApiKey:@"your-api-key"];

// Initialize (completion handler)
[[OrderShield shared] initializeWithCompletion:^(BOOL success) {
    if (success) {
        [[OrderShield shared] startVerificationWithPresentingViewController:self
                                                                completion:^(NSString * _Nullable sessionToken) {
            // ...
        }];
    }
}];
```

**Objective-C API names:**
- `OrderShield.shared` → `[OrderShield shared]`
- `configure(apiKey:)` → `configureWithApiKey:`
- `initialize(completion:)` → `initializeWithCompletion:`
- `startVerification(presentingViewController:completion:)` → `startVerificationWithPresentingViewController:completion:`
- Delegate: use **`objcDelegate`** and **`OrderShieldDelegateObjC`**; settings type is `OSVerificationSettingsData *`, checkboxes `NSArray<OSTermsCheckbox *> *`, status code `NSNumber *` (use `.intValue`); checkbox id is `checkboxId` in ObjC.

---

## 6. Verification

After making the changes:

1. Build the framework with the OrderShieldSDK scheme.
2. Create a minimal **Objective-C** app, add the framework, and:
   - `#import <OrderShieldSDK/OrderShieldSDK-Swift.h>`
   - Configure, initialize (with completion), and start verification.
3. Confirm there are no ObjC compile errors and that the flow runs correctly.

This completes the list of places and the number of changes needed to support Objective-C while keeping the SDK working for Swift.
