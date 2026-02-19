import Foundation

// MARK: - Predefined User Info (optional values to skip steps)
/// Optional values the SDK user can provide to skip corresponding verification steps.
/// - If `email` is provided, the email step is skipped.
/// - If `phoneNumber` is provided, the SMS/phone step is skipped.
/// - The userInfo step (first name, last name, date of birth) is skipped only when all three are provided.
public struct PredefinedUserInfo {
    public var email: String?
    public var phoneNumber: String?
    public var firstName: String?
    public var lastName: String?
    public var dateOfBirth: String?
    
    public init(
        email: String? = nil,
        phoneNumber: String? = nil,
        firstName: String? = nil,
        lastName: String? = nil,
        dateOfBirth: String? = nil
    ) {
        self.email = email
        self.phoneNumber = phoneNumber
        self.firstName = firstName
        self.lastName = lastName
        self.dateOfBirth = dateOfBirth
    }
    
    /// Returns true if all userInfo fields are non-empty (so we can skip the userInfo step).
    public var hasAllUserInfoFields: Bool {
        let first = (firstName ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let last = (lastName ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let dob = (dateOfBirth ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        return !first.isEmpty && !last.isEmpty && !dob.isEmpty
    }
    
    /// Normalizes date of birth to yyyy-MM-dd for API. Accepts mm/dd/yyyy or yyyy-MM-dd.
    public var normalizedDateOfBirth: String? {
        guard let dob = dateOfBirth?.trimmingCharacters(in: .whitespacesAndNewlines), !dob.isEmpty else { return nil }
        let inMmDd = DateFormatter()
        inMmDd.dateFormat = "MM/dd/yyyy"
        let inIso = DateFormatter()
        inIso.dateFormat = "yyyy-MM-dd"
        if let date = inMmDd.date(from: dob) {
            return inIso.string(from: date)
        }
        if let date = inIso.date(from: dob) {
            return inIso.string(from: date)
        }
        return dob
    }
    
    /// Build from ObjC-friendly type.
    public init(from objc: OSPredefinedUserInfo?) {
        self.init(
            email: objc?.email as String?,
            phoneNumber: objc?.phoneNumber as String?,
            firstName: objc?.firstName as String?,
            lastName: objc?.lastName as String?,
            dateOfBirth: objc?.dateOfBirth as String?
        )
    }
}

/// Objective-C compatible predefined user info. Use this from ObjC when calling startVerification to skip steps.
@objc(OSPredefinedUserInfo)
public class OSPredefinedUserInfo: NSObject {
    @objc public let email: String?
    @objc public let phoneNumber: String?
    @objc public let firstName: String?
    @objc public let lastName: String?
    @objc public let dateOfBirth: String?
    
    @objc public init(
        email: String? = nil,
        phoneNumber: String? = nil,
        firstName: String? = nil,
        lastName: String? = nil,
        dateOfBirth: String? = nil
    ) {
        self.email = email
        self.phoneNumber = phoneNumber
        self.firstName = firstName
        self.lastName = lastName
        self.dateOfBirth = dateOfBirth
    }
}

// MARK: - Device Registration
struct DeviceRegistrationRequest: Codable {
    let deviceId: String
    let deviceType: String
    let deviceModel: String
    let osVersion: String
    let appVersion: String
    let ipAddress: String
    let userAgent: String
    let timezone: String
    
    enum CodingKeys: String, CodingKey {
        case deviceId = "device_id"
        case deviceType = "device_type"
        case deviceModel = "device_model"
        case osVersion = "os_version"
        case appVersion = "app_version"
        case ipAddress = "ip_address"
        case userAgent = "user_agent"
        case timezone
    }
}

struct DeviceRegistrationResponse: Codable {
    let message: String
    let data: DeviceRegistrationData
    let statusCode: Int
    let status: String
}

struct DeviceRegistrationData: Codable {
    let success: Bool
    let customerId: String
    let isNewCustomer: Bool
    let isBanned: Bool
    
    enum CodingKeys: String, CodingKey {
        case success
        case customerId = "customer_id"
        case isNewCustomer = "is_new_customer"
        case isBanned = "is_banned"
    }
}

// MARK: - Verification Settings
struct VerificationSettingsResponse: Codable {
    let message: String
    let data: VerificationSettingsData
    let statusCode: Int
    let status: String
}

public struct VerificationSettingsData: Codable {
    public let success: Bool
    public let verificationEnabled: Bool
    public let settings: VerificationSettings
    public let requiredSteps: [String]
    public let optionalSteps: [String]
    
    public init(success: Bool, verificationEnabled: Bool, settings: VerificationSettings, requiredSteps: [String], optionalSteps: [String]) {
        self.success = success
        self.verificationEnabled = verificationEnabled
        self.settings = settings
        self.requiredSteps = requiredSteps
        self.optionalSteps = optionalSteps
    }
    
    enum CodingKeys: String, CodingKey {
        case success
        case verificationEnabled = "verification_enabled"
        case settings
        case requiredSteps = "required_steps"
        case optionalSteps = "optional_steps"
    }
}

public struct VerificationSettings: Codable {
    public let selfieVerificationEnabled: Bool
    public let emailVerificationEnabled: Bool
    public let emailVerificationRequired: Bool
    public let smsVerificationEnabled: Bool
    public let smsVerificationRequired: Bool
    public let termsAgreementEnabled: Bool
    public let signatureConfirmationEnabled: Bool
    public let userInfoVerificationEnabled: Bool
    
    public init(selfieVerificationEnabled: Bool, emailVerificationEnabled: Bool, emailVerificationRequired: Bool, smsVerificationEnabled: Bool, smsVerificationRequired: Bool, termsAgreementEnabled: Bool, signatureConfirmationEnabled: Bool, userInfoVerificationEnabled: Bool) {
        self.selfieVerificationEnabled = selfieVerificationEnabled
        self.emailVerificationEnabled = emailVerificationEnabled
        self.emailVerificationRequired = emailVerificationRequired
        self.smsVerificationEnabled = smsVerificationEnabled
        self.smsVerificationRequired = smsVerificationRequired
        self.termsAgreementEnabled = termsAgreementEnabled
        self.signatureConfirmationEnabled = signatureConfirmationEnabled
        self.userInfoVerificationEnabled = userInfoVerificationEnabled
    }
    
    enum CodingKeys: String, CodingKey {
        case selfieVerificationEnabled = "selfie_verification_enabled"
        case emailVerificationEnabled = "email_verification_enabled"
        case emailVerificationRequired = "email_verification_required"
        case smsVerificationEnabled = "sms_verification_enabled"
        case smsVerificationRequired = "sms_verification_required"
        case termsAgreementEnabled = "terms_agreement_enabled"
        case signatureConfirmationEnabled = "signature_confirmation_enabled"
        case userInfoVerificationEnabled = "user_info_verification_enabled"
    }
}

// MARK: - Start Verification
struct StartVerificationRequest: Codable {
    let customerId: String
    
    enum CodingKeys: String, CodingKey {
        case customerId = "customer_id"
    }
}

struct StartVerificationResponse: Codable {
    let status: String
    let message: String
    let data: VerificationSessionData?
    let statusCode: Int
}

struct VerificationSessionData: Codable {
    let sessionId: String
    let sessionToken: String
    let stepsRequired: [String]
    let stepsOptional: [String]
    let expiresAt: String
    let createdAt: String
    
    enum CodingKeys: String, CodingKey {
        case sessionId = "session_id"
        case sessionToken = "session_token"
        case stepsRequired = "steps_required"
        case stepsOptional = "steps_optional"
        case expiresAt = "expires_at"
        case createdAt = "created_at"
    }
}

struct VerificationSession: Codable {
    let sessionId: String
    let stepsCompleted: [String]
    let stepsRemaining: [String]
    let stepsOptional: [String]
    let isComplete: Bool
    let completedAt: String?
    
    init(sessionId: String, stepsCompleted: [String], stepsRemaining: [String], stepsOptional: [String], isComplete: Bool, completedAt: String?) {
        self.sessionId = sessionId
        self.stepsCompleted = stepsCompleted
        self.stepsRemaining = stepsRemaining
        self.stepsOptional = stepsOptional
        self.isComplete = isComplete
        self.completedAt = completedAt
    }
    
    enum CodingKeys: String, CodingKey {
        case sessionId = "session_id"
        case stepsCompleted = "steps_completed"
        case stepsRemaining = "steps_remaining"
        case stepsOptional = "steps_optional"
        case isComplete = "is_complete"
        case completedAt = "completed_at"
    }
}

// MARK: - Selfie Verification
struct SelfieVerificationResponse: Codable {
    let status: String
    let message: String
    let data: StepCompletionData?
    let statusCode: Int
}

struct StepCompletionData: Codable {
    let stepCompleted: String
    let verificationSession: VerificationSession
    
    init(stepCompleted: String, verificationSession: VerificationSession) {
        self.stepCompleted = stepCompleted
        self.verificationSession = verificationSession
    }
    
    enum CodingKeys: String, CodingKey {
        case stepCompleted = "step_completed"
        case verificationSession = "verification_session"
    }
}

// MARK: - Email Verification
struct EmailSendCodeRequest: Codable {
    let customerId: String
    let sessionToken: String
    let email: String
    let skipVerification: Bool
    
    enum CodingKeys: String, CodingKey {
        case customerId = "customer_id"
        case sessionToken = "session_token"
        case email
        case skipVerification = "skip_verification"
    }
}

struct EmailVerifyCodeRequest: Codable {
    let customerId: String
    let sessionToken: String
    let email: String
    let verificationCode: String
    
    enum CodingKeys: String, CodingKey {
        case customerId = "customer_id"
        case sessionToken = "session_token"
        case email
        case verificationCode = "verification_code"
    }
}

// MARK: - Email Verification Response
struct EmailSendCodeResponse: Codable {
    let message: String
    let data: EmailSendCodeData?
    let statusCode: Int
    let status: String
    
    enum CodingKeys: String, CodingKey {
        case message
        case data
        case statusCode
        case status
    }
}

struct EmailSendCodeData: Codable {
    let success: Bool
}

struct EmailVerifyCodeResponse: Codable {
    let message: String
    let data: EmailVerifyCodeData?
    let statusCode: Int
    let status: String
    
    enum CodingKeys: String, CodingKey {
        case message
        case data
        case statusCode
        case status
    }
}

struct EmailVerifyCodeData: Codable {
    let success: Bool
}

// MARK: - Phone Verification Response
struct PhoneSendCodeResponse: Codable {
    let message: String
    let data: PhoneSendCodeData?
    let statusCode: Int
    let status: String
    
    enum CodingKeys: String, CodingKey {
        case message
        case data
        case statusCode
        case status
    }
}

struct PhoneSendCodeData: Codable {
    let success: Bool
}

struct PhoneVerifyCodeResponse: Codable {
    let message: String
    let data: PhoneVerifyCodeData?
    let statusCode: Int
    let status: String
    
    enum CodingKeys: String, CodingKey {
        case message
        case data
        case statusCode
        case status
    }
}

struct PhoneVerifyCodeData: Codable {
    let success: Bool
}

// MARK: - Phone Verification
struct PhoneSendCodeRequest: Codable {
    let customerId: String
    let sessionToken: String
    let phoneNumber: String
    let skipVerification: Bool
    
    enum CodingKeys: String, CodingKey {
        case customerId = "customer_id"
        case sessionToken = "session_token"
        case phoneNumber = "phone_number"
        case skipVerification = "skip_verification"
    }
}

struct PhoneVerifyCodeRequest: Codable {
    let customerId: String
    let sessionToken: String
    let phoneNumber: String
    let verificationCode: String
    
    enum CodingKeys: String, CodingKey {
        case customerId = "customer_id"
        case sessionToken = "session_token"
        case phoneNumber = "phone_number"
        case verificationCode = "verification_code"
    }
}

// MARK: - Terms Verification
struct TermsVerificationRequest: Codable {
    let customerId: String
    let sessionToken: String
    let acceptedCheckboxes: [CheckboxAcceptance]
    
    enum CodingKeys: String, CodingKey {
        case customerId = "customer_id"
        case sessionToken = "session_token"
        case acceptedCheckboxes = "accepted_checkboxes"
    }
}

struct CheckboxAcceptance: Codable {
    let checkboxId: String
    let accepted: Bool
    
    enum CodingKeys: String, CodingKey {
        case checkboxId = "checkbox_id"
        case accepted
    }
}

// MARK: - Terms Checkboxes
struct TermsCheckboxesResponse: Codable {
    let message: String
    let data: [TermsCheckbox]
    let statusCode: Int
    let status: String
}

public struct TermsCheckbox: Codable {
    public let id: String
    public let checkboxText: String
    public let isRequired: Bool
    public let displayOrder: Int
    
    public init(id: String, checkboxText: String, isRequired: Bool, displayOrder: Int) {
        self.id = id
        self.checkboxText = checkboxText
        self.isRequired = isRequired
        self.displayOrder = displayOrder
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case checkboxText = "checkboxText"
        case isRequired = "isRequired"
        case displayOrder = "displayOrder"
    }
}

// MARK: - Objective-C Visible Types (for delegate and public API)

/// Objective-C visible wrapper for verification settings. Use in delegate callbacks.
@objc(OSVerificationSettings)
public class OSVerificationSettings: NSObject {
    @objc public let selfieVerificationEnabled: Bool
    @objc public let emailVerificationEnabled: Bool
    @objc public let emailVerificationRequired: Bool
    @objc public let smsVerificationEnabled: Bool
    @objc public let smsVerificationRequired: Bool
    @objc public let termsAgreementEnabled: Bool
    @objc public let signatureConfirmationEnabled: Bool
    @objc public let userInfoVerificationEnabled: Bool

    @objc public init(
        selfieVerificationEnabled: Bool,
        emailVerificationEnabled: Bool,
        emailVerificationRequired: Bool,
        smsVerificationEnabled: Bool,
        smsVerificationRequired: Bool,
        termsAgreementEnabled: Bool,
        signatureConfirmationEnabled: Bool,
        userInfoVerificationEnabled: Bool
    ) {
        self.selfieVerificationEnabled = selfieVerificationEnabled
        self.emailVerificationEnabled = emailVerificationEnabled
        self.emailVerificationRequired = emailVerificationRequired
        self.smsVerificationEnabled = smsVerificationEnabled
        self.smsVerificationRequired = smsVerificationRequired
        self.termsAgreementEnabled = termsAgreementEnabled
        self.signatureConfirmationEnabled = signatureConfirmationEnabled
        self.userInfoVerificationEnabled = userInfoVerificationEnabled
    }

    init(from settings: VerificationSettings) {
        self.selfieVerificationEnabled = settings.selfieVerificationEnabled
        self.emailVerificationEnabled = settings.emailVerificationEnabled
        self.emailVerificationRequired = settings.emailVerificationRequired
        self.smsVerificationEnabled = settings.smsVerificationEnabled
        self.smsVerificationRequired = settings.smsVerificationRequired
        self.termsAgreementEnabled = settings.termsAgreementEnabled
        self.signatureConfirmationEnabled = settings.signatureConfirmationEnabled
        self.userInfoVerificationEnabled = settings.userInfoVerificationEnabled
    }
}

/// Objective-C visible wrapper for verification settings data. Use in delegate callbacks.
@objc(OSVerificationSettingsData)
public class OSVerificationSettingsData: NSObject {
    @objc public let success: Bool
    @objc public let verificationEnabled: Bool
    @objc public let settings: OSVerificationSettings
    @objc public let requiredSteps: [String]
    @objc public let optionalSteps: [String]

    @objc public init(success: Bool, verificationEnabled: Bool, settings: OSVerificationSettings, requiredSteps: [String], optionalSteps: [String]) {
        self.success = success
        self.verificationEnabled = verificationEnabled
        self.settings = settings
        self.requiredSteps = requiredSteps
        self.optionalSteps = optionalSteps
    }

    init(from data: VerificationSettingsData) {
        self.success = data.success
        self.verificationEnabled = data.verificationEnabled
        self.settings = OSVerificationSettings(from: data.settings)
        self.requiredSteps = data.requiredSteps
        self.optionalSteps = data.optionalSteps
    }
}

/// Objective-C visible wrapper for a terms checkbox. Use in delegate callbacks.
@objc(OSTermsCheckbox)
public class OSTermsCheckbox: NSObject {
    /// Checkbox identifier (exposed as checkboxId in Objective-C to avoid conflict with `id` type)
    @objc(checkboxId) public let id: String
    @objc public let checkboxText: String
    @objc public let isRequired: Bool
    @objc public let displayOrder: Int

    @objc public init(id: String, checkboxText: String, isRequired: Bool, displayOrder: Int) {
        self.id = id
        self.checkboxText = checkboxText
        self.isRequired = isRequired
        self.displayOrder = displayOrder
    }

    init(from checkbox: TermsCheckbox) {
        self.id = checkbox.id
        self.checkboxText = checkbox.checkboxText
        self.isRequired = checkbox.isRequired
        self.displayOrder = checkbox.displayOrder
    }
}

// MARK: - Signature Verification
// Note: Signature is now sent as multipart/form-data, not JSON
// This struct is kept for backward compatibility but won't be used for encoding
struct SignatureVerificationRequest: Codable {
    let customerId: String
    let sessionToken: String
    let signature: String // Base64 encoded signature image
    
    enum CodingKeys: String, CodingKey {
        case customerId = "customer_id"
        case sessionToken = "session_token"
        case signature
    }
}

// MARK: - User Info Verification
struct UserInfoVerificationRequest: Codable {
    let customerId: String
    let sessionToken: String
    let firstName: String
    let lastName: String
    let dateOfBirth: String
    
    enum CodingKeys: String, CodingKey {
        case customerId = "customer_id"
        case sessionToken = "session_token"
        case firstName = "first_name"
        case lastName = "last_name"
        case dateOfBirth = "date_of_birth"
    }
}

// MARK: - Verification Status
struct VerificationStatusResponse: Codable {
    let status: String
    let message: String
    let data: VerificationStatusData?
    let statusCode: Int
}

struct VerificationStatusData: Codable {
    let sessionId: String?
    let customerId: String?
    let sessionToken: String?
    let stepsCompleted: [String]
    let stepsRemaining: [String]
    let stepsOptional: [String]
    let isComplete: Bool
    let expiresAt: String?
    let createdAt: String?
    let completedAt: String?
    
    enum CodingKeys: String, CodingKey {
        case sessionId = "session_id"
        case customerId = "customer_id"
        case sessionToken = "session_token"
        case stepsCompleted = "steps_completed"
        case stepsRemaining = "steps_remaining"
        case stepsOptional = "steps_optional"
        case isComplete = "is_complete"
        case expiresAt = "expires_at"
        case createdAt = "created_at"
        case completedAt = "completed_at"
    }
}

// MARK: - Track Event (SDK session/step events)
/// Event types supported by the track-event API for verification flow.
public enum SDKEventType: String, Codable, CaseIterable {
    case sessionStart = "session_start"
    case sessionEnd = "session_end"
    case stepStart = "step_start"
    case stepEnd = "step_end"
    case stepRetry = "step_retry"
}

/// Current time string for track-event descriptions (ISO8601).
func trackEventCurrentTime() -> String {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    return formatter.string(from: Date())
}

struct TrackEventRequest: Codable {
    let customerId: String
    let sessionToken: String
    let eventType: String
    let description: String

    enum CodingKeys: String, CodingKey {
        case customerId = "customer_id"
        case sessionToken = "session_token"
        case eventType = "event_type"
        case description
    }

    init(customerId: String, sessionToken: String, eventType: SDKEventType, description: String) {
        self.customerId = customerId
        self.sessionToken = sessionToken
        self.eventType = eventType.rawValue
        self.description = description
    }

    init(customerId: String, sessionToken: String, eventType: String, description: String) {
        self.customerId = customerId
        self.sessionToken = sessionToken
        self.eventType = eventType
        self.description = description
    }
}

/// Response from the track-event API. Passed to the delegate in `orderShieldDidTrackEvent(success:response:error:)`.
public struct TrackEventResponse: Codable {
    public let status: String?
    public let message: String?
    public let statusCode: Int?

    public init(status: String?, message: String?, statusCode: Int?) {
        self.status = status
        self.message = message
        self.statusCode = statusCode
    }
}

/// Objective-C visible wrapper for track-event API response. Use in delegate callbacks.
@objc(OSTrackEventResponse)
public class OSTrackEventResponse: NSObject {
    @objc public let status: String?
    @objc public let message: String?
    @objc public let statusCode: NSNumber?

    @objc public init(status: String?, message: String?, statusCode: NSNumber?) {
        self.status = status
        self.message = message
        self.statusCode = statusCode
    }

    init(from response: TrackEventResponse) {
        self.status = response.status
        self.message = response.message
        self.statusCode = response.statusCode.map { NSNumber(value: $0) }
    }
}

// MARK: - API Error
struct APIError: Codable, Error {
    let status: String
    let message: String
    let statusCode: Int
}

// MARK: - Verification Step
enum VerificationStep: String, CaseIterable {
    case selfie = "selfie"
    case email = "email"
    case sms = "sms"
    case terms = "terms"
    case signature = "signature"
    case userInfo = "userInfo"
    
    var displayName: String {
        switch self {
        case .selfie: return "Selfie Verification"
        case .email: return "Email Verification"
        case .sms: return "Phone Verification"
        case .terms: return "Terms Agreement"
        case .signature: return "Digital Signature"
        case .userInfo: return "User Information"
        }
    }
}

