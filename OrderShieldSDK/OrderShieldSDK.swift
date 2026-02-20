import Foundation
import UIKit

/// Main entry point for the OrderShield SDK. Objective-C apps use `OrderShield.shared` and the completion-handler APIs.
@available(iOS 13.0, *)
@objc(OrderShield)
public class OrderShield: NSObject {
    @objc public static let shared = OrderShield()
    
    private var apiKey: String?
    private var isInitialized = false
    private var verificationFlowCoordinator: VerificationFlowCoordinator?
    /// Stored predefined user info. Set via setPredefinedUserInfo(_:); used when startVerification is called and cleared after that flow uses it.
    private var storedPredefinedUserInfo: PredefinedUserInfo?
    
    /// Delegate for receiving SDK callbacks (Swift apps)
    public weak var delegate: OrderShieldDelegate?
    
    /// Delegate for receiving SDK callbacks from Objective-C apps. Set this when integrating from ObjC.
    @objc public weak var objcDelegate: OrderShieldDelegateObjC?
    
    private override init() {
        super.init()
    }
    
    // MARK: - Public API
    
    /// Configure the SDK with API key
    /// - Parameter apiKey: Your OrderShield API key
    @objc public func configure(apiKey: String) {
        // Clear only configuration data (settings, steps) but preserve session data
        // This allows session resumption to work across app restarts
        StorageService.shared.clearConfiguration()
        print("OrderShieldSDK: Cleared configuration data (preserved session data for resume capability)")
        
        self.apiKey = apiKey
        NetworkService.shared.configure(apiKey: apiKey)
        isInitialized = true
        
        // Ensure device_id is synced between DeviceInfo and StorageService
        let deviceId = DeviceInfo.getDeviceId()
        StorageService.shared.saveDeviceId(deviceId)
        
        // Mask API key for logging (show first 8 and last 4 characters)
        let maskedKey: String
        if apiKey.count > 12 {
            let prefix = String(apiKey.prefix(8))
            let suffix = String(apiKey.suffix(4))
            maskedKey = "\(prefix)****\(suffix)"
        } else {
            maskedKey = "****"
        }
        
        print("\n✅ :- [OrderShieldSDK] SDK initialized with API key: \(maskedKey)")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
    }
    
    /// Register device and fetch verification settings (async). Use from Swift.
    /// - Returns: True if successful, false otherwise
    @discardableResult
    public func initialize() async -> Bool {
        guard isInitialized, apiKey != nil else {
            print("OrderShieldSDK: Please configure SDK with API key first")
            return false
        }
        
        do {
            // Step 1: Register device (skip if device_id already exists)
            let deviceId = DeviceInfo.getDeviceId()
            let existingDeviceId = StorageService.shared.getDeviceId()
            
            if existingDeviceId != nil && existingDeviceId == deviceId {
                print("OrderShieldSDK: Device ID found in storage. Skipping Register Device API call.")
                // Ensure customer_id is available from storage
                if let customerId = StorageService.shared.getCustomerId() {
                    print("OrderShieldSDK: Using existing Customer ID: \(customerId)")
                } else {
                    print("OrderShieldSDK: Warning - Device ID exists but Customer ID not found. Registering device.")
                    // Register device via API
                    let deviceRequest = DeviceRegistrationRequest(
                        deviceId: deviceId,
                        deviceType: "ios",
                        deviceModel: DeviceInfo.getDeviceModel(),
                        osVersion: DeviceInfo.getOSVersion(),
                        appVersion: DeviceInfo.getAppVersion(),
                        ipAddress: DeviceInfo.getIPAddress(),
                        userAgent: DeviceInfo.getUserAgent(),
                        timezone: DeviceInfo.getTimezone()
                    )
                    
                    let registrationResponse = try await NetworkService.shared.registerDevice(deviceRequest)
                    print("OrderShieldSDK:- Device registered successfully")
                    
                    // Store device_id, customer_id locally
                    StorageService.shared.saveDeviceId(deviceId)
                    StorageService.shared.saveCustomerId(registrationResponse.data.customerId)
                    print("OrderShieldSDK:- Device ID and Customer ID stored")
                    
                    delegate?.orderShieldDidRegisterDevice(success: true, error: nil)
                    objcDelegate?.orderShieldDidRegisterDevice?(success: true, error: nil)
                }
            } else {
                // Register device via API
                let deviceRequest = DeviceRegistrationRequest(
                    deviceId: deviceId,
                    deviceType: "ios",
                    deviceModel: DeviceInfo.getDeviceModel(),
                    osVersion: DeviceInfo.getOSVersion(),
                    appVersion: DeviceInfo.getAppVersion(),
                    ipAddress: DeviceInfo.getIPAddress(),
                    userAgent: DeviceInfo.getUserAgent(),
                    timezone: DeviceInfo.getTimezone()
                )
                
                let registrationResponse = try await NetworkService.shared.registerDevice(deviceRequest)
                print("OrderShieldSDK:- Device registered successfully")
                
                // Store device_id, customer_id locally
                StorageService.shared.saveDeviceId(deviceId)
                StorageService.shared.saveCustomerId(registrationResponse.data.customerId)
                print("OrderShieldSDK:- Device ID and Customer ID stored")
                
                delegate?.orderShieldDidRegisterDevice(success: true, error: nil)
                objcDelegate?.orderShieldDidRegisterDevice?(success: true, error: nil)
            }
            
            // Step 2: Fetch verification settings
            let settingsResponse = try await NetworkService.shared.fetchVerificationSettings()
            StorageService.shared.saveRequiredSteps(settingsResponse.data.requiredSteps)
            StorageService.shared.saveVerificationSettings(settingsResponse.data)
            print("OrderShieldSDK: Verification settings fetched and saved")
            delegate?.orderShieldDidFetchSettings(success: true, settings: settingsResponse.data, error: nil)
            objcDelegate?.orderShieldDidFetchSettings?(success: true, settings: OSVerificationSettingsData(from: settingsResponse.data), error: nil)
            
            delegate?.orderShieldDidInitialize(success: true, error: nil)
            objcDelegate?.orderShieldDidInitialize?(success: true, error: nil)
            return true
        } catch {
            print("OrderShieldSDK: Initialization failed - \(error.localizedDescription)")
            delegate?.orderShieldDidRegisterDevice(success: false, error: error)
            objcDelegate?.orderShieldDidRegisterDevice?(success: false, error: error)
            delegate?.orderShieldDidFetchSettings(success: false, settings: nil, error: error)
            objcDelegate?.orderShieldDidFetchSettings?(success: false, settings: nil, error: error)
            delegate?.orderShieldDidInitialize(success: false, error: error)
            objcDelegate?.orderShieldDidInitialize?(success: false, error: error)
            return false
        }
    }
    
    /// Set predefined user info to skip steps when you later call startVerification.
    /// Call this before startVerification; the stored value is used for the next verification flow and then cleared.
    /// - Email: skip email step when set. Phone: skip SMS step when set. UserInfo: skip the name/DOB screen only when firstName, lastName, and dateOfBirth are all set.
    /// - Parameter info: Predefined values, or nil to clear. Pass nil for normal flow with no skips.
    public func setPredefinedUserInfo(_ info: PredefinedUserInfo?) {
        storedPredefinedUserInfo = info
    }
    
    /// Set predefined user info from Objective-C. Call before startVerification.
    @objc public func setPredefinedUserInfoWithObjC(_ info: OSPredefinedUserInfo?) {
        storedPredefinedUserInfo = info.map { PredefinedUserInfo(from: $0) }
    }
    
    /// Returns current stored predefined user info and clears it. Called when user taps "Start" so the flow uses the latest data (e.g. after they corrected format).
    func consumeStoredPredefinedUserInfo() -> PredefinedUserInfo? {
        let value = storedPredefinedUserInfo
        storedPredefinedUserInfo = nil
        return value
    }
    
    /// Start verification flow with UI.
    /// Uses any predefined user info previously set via setPredefinedUserInfo(_:); that stored value is consumed and cleared for this flow.
    /// - Parameter presentingViewController: View controller to present the flow from
    @objc public func startVerification(
        presentingViewController: UIViewController
    ) {
        guard isInitialized else {
            print("OrderShieldSDK: SDK not initialized. Call configure(apiKey:) first")
            delegate?.orderShieldDidStartVerification(success: false, sessionToken: nil, error: NetworkError.missingAPIKey)
            objcDelegate?.orderShieldDidStartVerification?(success: false, sessionToken: nil, error: NetworkError.missingAPIKey)
            return
        }
        
        guard let customerId = StorageService.shared.getCustomerId() else {
            print("OrderShieldSDK: Customer ID not found. Please call initialize() first")
            let error = NSError(domain: "OrderShieldSDK", code: -1, userInfo: [NSLocalizedDescriptionKey: "Customer ID not found. Please call initialize() first"])
            delegate?.orderShieldDidStartVerification(success: false, sessionToken: nil, error: error)
            objcDelegate?.orderShieldDidStartVerification?(success: false, sessionToken: nil, error: error)
            return
        }
        
        // Don't consume predefined here – coordinator will read it when user taps "Start" so corrected data is used
        verificationFlowCoordinator = VerificationFlowCoordinator(
            requiredSteps: [],
            presentingViewController: presentingViewController,
            delegate: delegate,
            objcDelegate: objcDelegate,
            getPredefinedUserInfo: { OrderShield.shared.consumeStoredPredefinedUserInfo() }
        )
        
        verificationFlowCoordinator?.start()
    }
    
    /// Start verification flow with UI (async version).
    /// Uses any predefined user info previously set via setPredefinedUserInfo(_:); that stored value is consumed and cleared for this flow.
    /// - Parameter presentingViewController: View controller to present the flow from
    /// - Returns: Session token if successful, nil otherwise
    @discardableResult
    public func startVerification(
        presentingViewController: UIViewController
    ) async -> String? {
        guard isInitialized else {
            print("OrderShieldSDK: SDK not initialized. Call configure(apiKey:) first")
            delegate?.orderShieldDidStartVerification(success: false, sessionToken: nil, error: NetworkError.missingAPIKey)
            objcDelegate?.orderShieldDidStartVerification?(success: false, sessionToken: nil, error: NetworkError.missingAPIKey)
            return nil
        }
        
        guard let customerId = StorageService.shared.getCustomerId() else {
            print("OrderShieldSDK: Customer ID not found. Please call initialize() first")
            let error = NSError(domain: "OrderShieldSDK", code: -1, userInfo: [NSLocalizedDescriptionKey: "Customer ID not found. Please call initialize() first"])
            delegate?.orderShieldDidStartVerification(success: false, sessionToken: nil, error: error)
            objcDelegate?.orderShieldDidStartVerification?(success: false, sessionToken: nil, error: error)
            return nil
        }
        
        await MainActor.run {
            verificationFlowCoordinator = VerificationFlowCoordinator(
                requiredSteps: [],
                presentingViewController: presentingViewController,
                delegate: delegate,
                objcDelegate: objcDelegate,
                getPredefinedUserInfo: { OrderShield.shared.consumeStoredPredefinedUserInfo() }
            )
            
            verificationFlowCoordinator?.start()
        }
        
        return StorageService.shared.getSessionToken()
    }

    // MARK: - Objective-C Completion Handler APIs

    /// Initialize the SDK (completion-handler version for Objective-C).
    /// Registers device and fetches verification settings, then calls the completion on the main queue.
    /// - Parameter completion: Called on the main queue with success (true/false).
    @objc public func initialize(completion: @escaping (Bool) -> Void) {
        Task { @MainActor in
            let success = await initialize()
            completion(success)
        }
    }

    /// Start verification flow with UI (completion-handler version for Objective-C).
    /// Uses any predefined user info previously set via setPredefinedUserInfoWithObjC(_:).
    @objc public func startVerification(
        presentingViewController: UIViewController,
        completion: @escaping (String?) -> Void
    ) {
        Task { @MainActor in
            let token = await startVerification(presentingViewController: presentingViewController)
            completion(token)
        }
    }

    // MARK: - Track Event

    /// Log a tracking event (e.g. app_open, login, consumption, custom). Delegate receives the API response via `orderShieldDidTrackEvent(success:response:error:)`.
    /// - Parameters:
    ///   - customerId: Customer ID (e.g. from StorageService or verification session).
    ///   - sessionToken: Session token (optional for events like app_open; use nil if not in a session).
    ///   - eventType: One of app_open, login, consumption, custom.
    ///   - description: Human-readable description of the event.
    /// - Returns: True if the API call succeeded, false otherwise. Delegate is always called with the full response.
    @discardableResult
    public func trackEvent(
        customerId: String,
        sessionToken: String?,
        eventType: SDKEventType,
        description: String
    ) async -> Bool {
        let token = sessionToken ?? ""
        let request = TrackEventRequest(customerId: customerId, sessionToken: token, eventType: eventType, description: description)
        return await performTrackEvent(request: request)
    }

    /// Log a tracking event with a custom event type string. Delegate receives the API response via `orderShieldDidTrackEvent(success:response:error:)`.
    @discardableResult
    public func trackEvent(
        customerId: String,
        sessionToken: String?,
        eventType: String,
        description: String
    ) async -> Bool {
        let token = sessionToken ?? ""
        let request = TrackEventRequest(customerId: customerId, sessionToken: token, eventType: eventType, description: description)
        return await performTrackEvent(request: request)
    }

    /// Track event (completion-handler version for Objective-C). Use eventType string: "app_open", "login", "consumption", or "custom".
    @objc public func trackEvent(
        customerId: String,
        sessionToken: String?,
        eventType: String,
        description: String,
        completion: @escaping (Bool) -> Void
    ) {
        Task { @MainActor in
            let success = await trackEvent(customerId: customerId, sessionToken: sessionToken, eventType: eventType, description: description)
            completion(success)
        }
    }

    private func performTrackEvent(request: TrackEventRequest) async -> Bool {
        do {
            let response = try await NetworkService.shared.trackEvent(request)
            await MainActor.run {
                delegate?.orderShieldDidTrackEvent(success: true, response: response, error: nil)
                objcDelegate?.orderShieldDidTrackEvent?(success: true, response: OSTrackEventResponse(from: response), error: nil)
            }
            print("✅ [OrderShieldSDK] Track event API call succeeded – event_type: \(request.eventType), description: \(request.description)")
            return true
        } catch {
            await MainActor.run {
                delegate?.orderShieldDidTrackEvent(success: false, response: nil, error: error)
                objcDelegate?.orderShieldDidTrackEvent?(success: false, response: nil, error: error)
            }
            print("❌ [OrderShieldSDK] Track event API call failed – \(error.localizedDescription)")
            return false
        }
    }
}
