import Foundation

class StorageService {
    static let shared = StorageService()
    
    private let userDefaults = UserDefaults.standard
    private let requiredStepsKey = "OrderShieldSDK.requiredSteps"
    private let verificationSettingsKey = "OrderShieldSDK.verificationSettings"
    private let customerIdKey = "OrderShieldSDK.customerId"
    private let sessionTokenKey = "OrderShieldSDK.sessionToken"
    private let sessionIdKey = "OrderShieldSDK.sessionId"
    private let deviceIdKey = "OrderShieldSDK.deviceId"
    
    private init() {}
    
    // MARK: - Customer ID
    func saveCustomerId(_ customerId: String) {
        userDefaults.set(customerId, forKey: customerIdKey)
    }
    
    func getCustomerId() -> String? {
        return userDefaults.string(forKey: customerIdKey)
    }
    
    // MARK: - Required Steps
    func saveRequiredSteps(_ steps: [String]) {
        userDefaults.set(steps, forKey: requiredStepsKey)
    }
    
    func getRequiredSteps() -> [String] {
        return userDefaults.stringArray(forKey: requiredStepsKey) ?? []
    }
    
    // MARK: - Verification Settings
    func saveVerificationSettings(_ settings: VerificationSettingsData) {
        if let encoded = try? JSONEncoder().encode(settings) {
            userDefaults.set(encoded, forKey: verificationSettingsKey)
        }
    }
    
    func getVerificationSettings() -> VerificationSettingsData? {
        guard let data = userDefaults.data(forKey: verificationSettingsKey),
              let settings = try? JSONDecoder().decode(VerificationSettingsData.self, from: data) else {
            return nil
        }
        return settings
    }
    
    // MARK: - Session Token
    func saveSessionToken(_ sessionToken: String) {
        userDefaults.set(sessionToken, forKey: sessionTokenKey)
    }
    
    func getSessionToken() -> String? {
        return userDefaults.string(forKey: sessionTokenKey)
    }
    
    // MARK: - Session ID
    func saveSessionId(_ sessionId: String) {
        userDefaults.set(sessionId, forKey: sessionIdKey)
    }
    
    func getSessionId() -> String? {
        return userDefaults.string(forKey: sessionIdKey)
    }
    
    // MARK: - Device ID
    func getDeviceId() -> String? {
        return userDefaults.string(forKey: deviceIdKey)
    }
    
    func saveDeviceId(_ deviceId: String) {
        userDefaults.set(deviceId, forKey: deviceIdKey)
    }
    
    // MARK: - Cleanup
    /// Clear all stored data (called during configure to reset SDK state)
    /// Note: This preserves device_id, customer_id, session_token, and session_id to allow session resumption
    func clearAll() {
        // Only clear settings and steps, but preserve session data for resume capability
        userDefaults.removeObject(forKey: requiredStepsKey)
        userDefaults.removeObject(forKey: verificationSettingsKey)
        // Note: We intentionally do NOT clear:
        // - customerIdKey (needed for resume)
        // - sessionTokenKey (needed for resume)
        // - sessionIdKey (needed for resume)
        // - deviceIdKey (needed for device registration skip logic)
    }
    
    /// Clear configuration data only (settings and steps, but keep session data)
    func clearConfiguration() {
        userDefaults.removeObject(forKey: requiredStepsKey)
        userDefaults.removeObject(forKey: verificationSettingsKey)
    }
    
    /// Clear device identifier and session data (called on verification completion)
    func clearDeviceIdentifier() {
        userDefaults.removeObject(forKey: deviceIdKey)
        userDefaults.removeObject(forKey: sessionIdKey)
        userDefaults.removeObject(forKey: sessionTokenKey)
    }
    
    /// Clear everything including session data (use with caution - breaks resume capability)
    func clearAllIncludingSession() {
        userDefaults.removeObject(forKey: requiredStepsKey)
        userDefaults.removeObject(forKey: verificationSettingsKey)
        userDefaults.removeObject(forKey: customerIdKey)
        userDefaults.removeObject(forKey: sessionTokenKey)
        userDefaults.removeObject(forKey: sessionIdKey)
        userDefaults.removeObject(forKey: deviceIdKey)
    }
}

