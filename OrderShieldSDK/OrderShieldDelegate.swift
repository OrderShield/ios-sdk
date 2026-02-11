import Foundation

// MARK: - Swift Delegate (Swift apps use this; Swift-friendly types)

/// Delegate protocol for OrderShield SDK callbacks. Use this from Swift apps.
@available(iOS 13.0, *)
public protocol OrderShieldDelegate: AnyObject {
    // MARK: - Initialization Callbacks
    
    func orderShieldDidRegisterDevice(success: Bool, error: Error?)
    func orderShieldDidFetchSettings(success: Bool, settings: VerificationSettingsData?, error: Error?)
    func orderShieldDidInitialize(success: Bool, error: Error?)
    
    // MARK: - Verification Flow Callbacks
    
    func orderShieldDidStartVerification(success: Bool, sessionToken: String?, error: Error?)
    func orderShieldDidStartVerificationWithDetails(
        success: Bool,
        sessionId: String?,
        sessionToken: String?,
        stepsRequired: [String]?,
        stepsOptional: [String]?,
        expiresAt: String?,
        error: Error?
    )
    func orderShieldDidStartStep(step: String, stepIndex: Int, totalSteps: Int)
    func orderShieldDidCompleteStep(step: String, stepIndex: Int, success: Bool, error: Error?)
    
    // MARK: - Terms & Signature Callbacks
    
    func orderShieldDidFetchTermsCheckboxes(success: Bool, checkboxes: [TermsCheckbox]?, error: Error?)
    func orderShieldDidAcceptTerms(success: Bool, acceptedCheckboxIds: [String]?, error: Error?)
    func orderShieldDidSubmitSignature(success: Bool, error: Error?)
    func orderShieldDidSubmitTermsAndSignature(success: Bool, acceptedCheckboxIds: [String]?, error: Error?)
    func orderShieldDidSubmitUserInfo(success: Bool, firstName: String?, lastName: String?, dateOfBirth: String?, error: Error?)
    func orderShieldDidCompleteVerification(sessionId: String?)
    func orderShieldDidCancelVerification(error: Error?)
    
    // MARK: - API Call Callbacks
    
    func orderShieldWillCallAPI(endpoint: String, method: String)
    func orderShieldDidCallAPI(endpoint: String, success: Bool, statusCode: Int?, error: Error?)

    // MARK: - Track Event Callback
    
    /// Called after the SDK logs a tracking event. Use this to see the API response (status, message, statusCode).
    func orderShieldDidTrackEvent(success: Bool, response: TrackEventResponse?, error: Error?)
}

// MARK: - Optional Delegate Methods (Swift)
@available(iOS 13.0, *)
extension OrderShieldDelegate {
    public func orderShieldDidRegisterDevice(success: Bool, error: Error?) {}
    public func orderShieldDidFetchSettings(success: Bool, settings: VerificationSettingsData?, error: Error?) {}
    public func orderShieldDidInitialize(success: Bool, error: Error?) {}
    public func orderShieldDidStartVerification(success: Bool, sessionToken: String?, error: Error?) {}
    public func orderShieldDidStartVerificationWithDetails(
        success: Bool,
        sessionId: String?,
        sessionToken: String?,
        stepsRequired: [String]?,
        stepsOptional: [String]?,
        expiresAt: String?,
        error: Error?
    ) {}
    public func orderShieldDidStartStep(step: String, stepIndex: Int, totalSteps: Int) {}
    public func orderShieldDidCompleteStep(step: String, stepIndex: Int, success: Bool, error: Error?) {}
    public func orderShieldDidFetchTermsCheckboxes(success: Bool, checkboxes: [TermsCheckbox]?, error: Error?) {}
    public func orderShieldDidAcceptTerms(success: Bool, acceptedCheckboxIds: [String]?, error: Error?) {}
    public func orderShieldDidSubmitSignature(success: Bool, error: Error?) {}
    public func orderShieldDidSubmitTermsAndSignature(success: Bool, acceptedCheckboxIds: [String]?, error: Error?) {}
    public func orderShieldDidSubmitUserInfo(success: Bool, firstName: String?, lastName: String?, dateOfBirth: String?, error: Error?) {}
    public func orderShieldDidCompleteVerification(sessionId: String?) {}
    public func orderShieldDidCancelVerification(error: Error?) {}
    public func orderShieldWillCallAPI(endpoint: String, method: String) {}
    public func orderShieldDidCallAPI(endpoint: String, success: Bool, statusCode: Int?, error: Error?) {}
    public func orderShieldDidTrackEvent(success: Bool, response: TrackEventResponse?, error: Error?) {}
}

// MARK: - Objective-C Delegate (Objective-C apps use this; ObjC-visible types)

/// Delegate protocol for OrderShield SDK callbacks from Objective-C. Use `objcDelegate` from ObjC apps.
@available(iOS 13.0, *)
@objc(OrderShieldDelegateObjC)
public protocol OrderShieldDelegateObjC: AnyObject {
    @objc optional func orderShieldDidRegisterDevice(success: Bool, error: Error?)
    @objc optional func orderShieldDidFetchSettings(success: Bool, settings: OSVerificationSettingsData?, error: Error?)
    @objc optional func orderShieldDidInitialize(success: Bool, error: Error?)
    @objc optional func orderShieldDidStartVerification(success: Bool, sessionToken: String?, error: Error?)
    @objc optional func orderShieldDidStartVerificationWithDetails(
        success: Bool,
        sessionId: String?,
        sessionToken: String?,
        stepsRequired: [String]?,
        stepsOptional: [String]?,
        expiresAt: String?,
        error: Error?
    )
    @objc optional func orderShieldDidStartStep(step: String, stepIndex: Int, totalSteps: Int)
    @objc optional func orderShieldDidCompleteStep(step: String, stepIndex: Int, success: Bool, error: Error?)
    @objc optional func orderShieldDidFetchTermsCheckboxes(success: Bool, checkboxes: [OSTermsCheckbox]?, error: Error?)
    @objc optional func orderShieldDidAcceptTerms(success: Bool, acceptedCheckboxIds: [String]?, error: Error?)
    @objc optional func orderShieldDidSubmitSignature(success: Bool, error: Error?)
    @objc optional func orderShieldDidSubmitTermsAndSignature(success: Bool, acceptedCheckboxIds: [String]?, error: Error?)
    @objc optional func orderShieldDidSubmitUserInfo(success: Bool, firstName: String?, lastName: String?, dateOfBirth: String?, error: Error?)
    @objc optional func orderShieldDidCompleteVerification(sessionId: String?)
    @objc optional func orderShieldDidCancelVerification(error: Error?)
    @objc optional func orderShieldWillCallAPI(endpoint: String, method: String)
    @objc optional func orderShieldDidCallAPI(endpoint: String, success: Bool, statusCode: NSNumber?, error: Error?)
    @objc optional func orderShieldDidTrackEvent(success: Bool, response: OSTrackEventResponse?, error: Error?)
}
