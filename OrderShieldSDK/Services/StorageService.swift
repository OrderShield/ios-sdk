import Foundation

class StorageService {
    static let shared = StorageService()
    
    private let userDefaults = UserDefaults.standard
    private let requiredStepsKey = "OrderShieldSDK.requiredSteps"
    private let verificationSettingsKey = "OrderShieldSDK.verificationSettings"
    private let customerIdKey = "OrderShieldSDK.customerId"
    private let sessionTokenKey = "OrderShieldSDK.sessionToken"
    
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
    
    func clearAll() {
        userDefaults.removeObject(forKey: requiredStepsKey)
        userDefaults.removeObject(forKey: verificationSettingsKey)
        userDefaults.removeObject(forKey: customerIdKey)
        userDefaults.removeObject(forKey: sessionTokenKey)
    }
}

