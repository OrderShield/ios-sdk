# Objective-C Sample App – Required Changes

## What to change

1. **Use `objcDelegate` instead of `delegate`**  
   Objective-C must use `objcDelegate` and conform to `OrderShieldDelegateObjC`.  
   `delegate` is for Swift and uses Swift-only types.

2. **Use completion-handler for initialize**  
   Call `initializeWithCompletion:` instead of `initialize`.  
   `initialize` is async (Swift) and is not appropriate to call from ObjC without a completion block.

3. **Optional: use completion for start verification**  
   You can keep `startVerificationWithPresentingViewController:` or switch to  
   `startVerificationWithPresentingViewController:completion:` if you need the session token.

---

## Updated ViewController.m

See the full example below with these changes applied.
