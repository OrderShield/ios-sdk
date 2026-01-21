import Foundation

/// Delegate protocol for OrderShield SDK callbacks
@available(iOS 13.0, *)
public protocol OrderShieldDelegate: AnyObject {
    // MARK: - Initialization Callbacks
    
    /// Called when device registration API call completes
    /// - Parameters:
    ///   - success: Whether the registration was successful
    ///   - error: Error if registration failed, nil otherwise
    func orderShieldDidRegisterDevice(success: Bool, error: Error?)
    
    /// Called when verification settings API call completes
    /// - Parameters:
    ///   - success: Whether fetching settings was successful
    ///   - settings: Verification settings data if successful, nil otherwise
    ///   - error: Error if fetching failed, nil otherwise
    func orderShieldDidFetchSettings(success: Bool, settings: VerificationSettingsData?, error: Error?)
    
    /// Called when SDK initialization completes
    /// - Parameters:
    ///   - success: Whether initialization was successful
    ///   - error: Error if initialization failed, nil otherwise
    func orderShieldDidInitialize(success: Bool, error: Error?)
    
    // MARK: - Verification Flow Callbacks
    
    /// Called when verification session starts
    /// - Parameters:
    ///   - success: Whether starting verification was successful
    ///   - sessionToken: Session token if successful, nil otherwise
    ///   - error: Error if starting failed, nil otherwise
    func orderShieldDidStartVerification(success: Bool, sessionToken: String?, error: Error?)
    
    /// Called when verification session starts with full session data
    /// - Parameters:
    ///   - success: Whether starting verification was successful
    ///   - sessionId: Session ID if successful, nil otherwise
    ///   - sessionToken: Session token if successful, nil otherwise
    ///   - stepsRequired: Array of required step names if successful, nil otherwise
    ///   - stepsOptional: Array of optional step names if successful, nil otherwise
    ///   - expiresAt: Session expiration date string if successful, nil otherwise
    ///   - error: Error if starting failed, nil otherwise
    func orderShieldDidStartVerificationWithDetails(
        success: Bool,
        sessionId: String?,
        sessionToken: String?,
        stepsRequired: [String]?,
        stepsOptional: [String]?,
        expiresAt: String?,
        error: Error?
    )
    
    /// Called when a verification step starts
    /// - Parameters:
    ///   - step: The verification step name (e.g., "selfie", "email", "sms", "terms", "signature")
    ///   - stepIndex: The index of the current step (0-based)
    ///   - totalSteps: Total number of steps
    func orderShieldDidStartStep(step: String, stepIndex: Int, totalSteps: Int)
    
    /// Called when a verification step completes
    /// - Parameters:
    ///   - step: The verification step name that completed
    ///   - stepIndex: The index of the completed step
    ///   - success: Whether the step completed successfully
    ///   - error: Error if step failed, nil otherwise
    func orderShieldDidCompleteStep(step: String, stepIndex: Int, success: Bool, error: Error?)
    
    // MARK: - Terms & Signature Callbacks
    
    /// Called when terms checkboxes are fetched
    /// - Parameters:
    ///   - success: Whether fetching checkboxes was successful
    ///   - checkboxes: Array of terms checkboxes if successful, nil otherwise
    ///   - error: Error if fetching failed, nil otherwise
    func orderShieldDidFetchTermsCheckboxes(success: Bool, checkboxes: [TermsCheckbox]?, error: Error?)
    
    /// Called when terms are accepted
    /// - Parameters:
    ///   - success: Whether accepting terms was successful
    ///   - acceptedCheckboxIds: Array of accepted checkbox IDs if successful, nil otherwise
    ///   - error: Error if accepting failed, nil otherwise
    func orderShieldDidAcceptTerms(success: Bool, acceptedCheckboxIds: [String]?, error: Error?)
    
    /// Called when signature is submitted
    /// - Parameters:
    ///   - success: Whether submitting signature was successful
    ///   - error: Error if submitting failed, nil otherwise
    func orderShieldDidSubmitSignature(success: Bool, error: Error?)
    
    /// Called when both terms and signature are submitted together (combined screen)
    /// - Parameters:
    ///   - success: Whether submitting both was successful
    ///   - acceptedCheckboxIds: Array of accepted checkbox IDs if successful, nil otherwise
    ///   - error: Error if submitting failed, nil otherwise
    func orderShieldDidSubmitTermsAndSignature(success: Bool, acceptedCheckboxIds: [String]?, error: Error?)
    
    /// Called when user information is submitted
    /// - Parameters:
    ///   - success: Whether submitting user info was successful
    ///   - firstName: First name that was submitted
    ///   - lastName: Last name that was submitted
    ///   - dateOfBirth: Date of birth that was submitted (yyyy-MM-dd format)
    ///   - error: Error if submitting failed, nil otherwise
    func orderShieldDidSubmitUserInfo(success: Bool, firstName: String?, lastName: String?, dateOfBirth: String?, error: Error?)
    
    /// Called when all verification steps are complete
    /// - Parameter sessionId: The verification session ID
    func orderShieldDidCompleteVerification(sessionId: String?)
    
    /// Called when verification flow is cancelled or fails
    /// - Parameter error: Error if verification failed, nil if cancelled
    func orderShieldDidCancelVerification(error: Error?)
    
    // MARK: - API Call Callbacks
    
    /// Called before any API call is made
    /// - Parameters:
    ///   - endpoint: The API endpoint being called
    ///   - method: HTTP method (GET, POST, etc.)
    func orderShieldWillCallAPI(endpoint: String, method: String)
    
    /// Called after any API call completes
    /// - Parameters:
    ///   - endpoint: The API endpoint that was called
    ///   - success: Whether the API call was successful
    ///   - statusCode: HTTP status code
    ///   - error: Error if API call failed, nil otherwise
    func orderShieldDidCallAPI(endpoint: String, success: Bool, statusCode: Int?, error: Error?)
}

// MARK: - Optional Delegate Methods
@available(iOS 13.0, *)
extension OrderShieldDelegate {
    // Default implementations make all methods optional
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
}

