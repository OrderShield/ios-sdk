import Foundation
import UIKit

@available(iOS 13.0, *)
public class OrderShield {
    public static let shared = OrderShield()
    
    private var apiKey: String?
    private var isInitialized = false
    private var verificationFlowCoordinator: VerificationFlowCoordinator?
    
    /// Delegate for receiving SDK callbacks
    public weak var delegate: OrderShieldDelegate?
    
    private init() {}
    
    // MARK: - Public API
    
    /// Configure the SDK with API key
    /// - Parameter apiKey: Your OrderShield API key
    public func configure(apiKey: String) {
        // Clear all stored data first to avoid caching issues
        StorageService.shared.clearAll()
        print("OrderShieldSDK: Cleared all stored data before configuration")
        
        self.apiKey = apiKey
        NetworkService.shared.configure(apiKey: apiKey)
        isInitialized = true
        
        // Mask API key for logging (show first 8 and last 4 characters)
        let maskedKey: String
        if apiKey.count > 12 {
            let prefix = String(apiKey.prefix(8))
            let suffix = String(apiKey.suffix(4))
            maskedKey = "\(prefix)****\(suffix)"
        } else {
            maskedKey = "****"
        }
        
        print("\n✅ [OrderShieldSDK] SDK initialized with API key: \(maskedKey)")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
    }
    
    /// Register device and fetch verification settings
    /// - Returns: True if successful, false otherwise
    @discardableResult
    public func initialize() async -> Bool {
        guard isInitialized, apiKey != nil else {
            print("OrderShieldSDK: Please configure SDK with API key first")
            return false
        }
        
        do {
            // Step 1: Register device
            let deviceRequest = DeviceRegistrationRequest(
                deviceId: DeviceInfo.getDeviceId(),
                deviceType: "ios",
                deviceModel: DeviceInfo.getDeviceModel(),
                osVersion: DeviceInfo.getOSVersion(),
                appVersion: DeviceInfo.getAppVersion(),
                ipAddress: DeviceInfo.getIPAddress(),
                userAgent: DeviceInfo.getUserAgent(),
                timezone: DeviceInfo.getTimezone()
            )
            
            let registrationResponse = try await NetworkService.shared.registerDevice(deviceRequest)
            print("OrderShieldSDK: Device registered successfully")
            
            // Store customer_id locally
            StorageService.shared.saveCustomerId(registrationResponse.data.customerId)
            print("OrderShieldSDK: Customer ID stored: \(registrationResponse.data.customerId)")
            
            delegate?.orderShieldDidRegisterDevice(success: true, error: nil)
            
            // Step 2: Fetch verification settings
            let settingsResponse = try await NetworkService.shared.fetchVerificationSettings()
            StorageService.shared.saveRequiredSteps(settingsResponse.data.requiredSteps)
            StorageService.shared.saveVerificationSettings(settingsResponse.data)
            print("OrderShieldSDK: Verification settings fetched and saved")
            delegate?.orderShieldDidFetchSettings(success: true, settings: settingsResponse.data, error: nil)
            
            delegate?.orderShieldDidInitialize(success: true, error: nil)
            return true
        } catch {
            print("OrderShieldSDK: Initialization failed - \(error.localizedDescription)")
            delegate?.orderShieldDidRegisterDevice(success: false, error: error)
            delegate?.orderShieldDidFetchSettings(success: false, settings: nil, error: error)
            delegate?.orderShieldDidInitialize(success: false, error: error)
            return false
        }
    }
    
    /// Start verification flow with UI
    /// Calls verification/start API immediately and starts the verification flow based on required steps
    /// - Parameter presentingViewController: View controller to present the flow from
    public func startVerification(
        presentingViewController: UIViewController
    ) {
        guard isInitialized else {
            print("OrderShieldSDK: SDK not initialized. Call configure(apiKey:) first")
            delegate?.orderShieldDidStartVerification(success: false, sessionToken: nil, error: NetworkError.missingAPIKey)
            return
        }
        
        guard let customerId = StorageService.shared.getCustomerId() else {
            print("OrderShieldSDK: Customer ID not found. Please call initialize() first")
            let error = NSError(domain: "OrderShieldSDK", code: -1, userInfo: [NSLocalizedDescriptionKey: "Customer ID not found. Please call initialize() first"])
            delegate?.orderShieldDidStartVerification(success: false, sessionToken: nil, error: error)
            return
        }
        
        // Create coordinator - verification/start API will be called immediately
        verificationFlowCoordinator = VerificationFlowCoordinator(
            requiredSteps: [],
            presentingViewController: presentingViewController,
            delegate: delegate
        )
        
        verificationFlowCoordinator?.start()
    }
    
    /// Start verification flow with UI (async version)
    /// Calls verification/start API immediately and starts the verification flow based on required steps
    /// - Parameter presentingViewController: View controller to present the flow from
    /// - Returns: Session token if successful, nil otherwise
    @discardableResult
    public func startVerification(
        presentingViewController: UIViewController
    ) async -> String? {
        guard isInitialized else {
            print("OrderShieldSDK: SDK not initialized. Call configure(apiKey:) first")
            delegate?.orderShieldDidStartVerification(success: false, sessionToken: nil, error: NetworkError.missingAPIKey)
            return nil
        }
        
        guard let customerId = StorageService.shared.getCustomerId() else {
            print("OrderShieldSDK: Customer ID not found. Please call initialize() first")
            let error = NSError(domain: "OrderShieldSDK", code: -1, userInfo: [NSLocalizedDescriptionKey: "Customer ID not found. Please call initialize() first"])
            delegate?.orderShieldDidStartVerification(success: false, sessionToken: nil, error: error)
            return nil
        }
        
        let requiredSteps = StorageService.shared.getRequiredSteps()
        guard !requiredSteps.isEmpty else {
            print("OrderShieldSDK: No required steps found. Please call initialize() first")
            let error = NSError(domain: "OrderShieldSDK", code: -1, userInfo: [NSLocalizedDescriptionKey: "No required steps found. Please call initialize() first"])
            delegate?.orderShieldDidStartVerification(success: false, sessionToken: nil, error: error)
            return nil
        }
        
        do {
            let request = StartVerificationRequest(customerId: customerId)
            let response = try await NetworkService.shared.startVerification(request)
            
            guard let data = response.data else {
                let error = NSError(domain: "OrderShieldSDK", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to start verification session"])
                delegate?.orderShieldDidStartVerification(success: false, sessionToken: nil, error: error)
                return nil
            }
            
            let sessionToken = data.sessionToken
            
            // Store session token and required steps
            StorageService.shared.saveSessionToken(sessionToken)
            StorageService.shared.saveRequiredSteps(data.stepsRequired)
            
            delegate?.orderShieldDidStartVerification(success: true, sessionToken: sessionToken, error: nil)
            
            await MainActor.run {
                verificationFlowCoordinator = VerificationFlowCoordinator(
                    requiredSteps: data.stepsRequired,
                    presentingViewController: presentingViewController,
                    delegate: delegate
                )
                
                verificationFlowCoordinator?.start(with: sessionToken)
            }
            
            return sessionToken
        } catch {
            delegate?.orderShieldDidStartVerification(success: false, sessionToken: nil, error: error)
            return nil
        }
    }
}
