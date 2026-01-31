import Foundation
import UIKit

@available(iOS 13.0, *)
class VerificationFlowCoordinator {
    // Static navigation sequence - steps will be shown in this order
    private static let staticNavigationSequence: [String] = [
        "sms",
        "selfie",
        "userInfo",
        "email",
        "terms",
        "signature"
    ]
    
    private var customerId: String? {
        return StorageService.shared.getCustomerId()
    }
    private var requiredSteps: [String] = []
    private weak var presentingViewController: UIViewController?
    private weak var delegate: OrderShieldDelegate?
    private weak var objcDelegate: OrderShieldDelegateObjC?
    private var currentStepIndex = 0
    private var sessionToken: String?
    private var navigationController: UINavigationController?
    
    init(
        requiredSteps: [String] = [],
        presentingViewController: UIViewController,
        delegate: OrderShieldDelegate?,
        objcDelegate: OrderShieldDelegateObjC? = nil
    ) {
        self.requiredSteps = requiredSteps
        self.presentingViewController = presentingViewController
        self.delegate = delegate
        self.objcDelegate = objcDelegate
    }
    
    /// Filters and orders steps from API response based on static navigation sequence
    /// - Parameter apiSteps: Steps from API response (steps_required or steps_remaining)
    /// - Returns: Filtered and ordered steps that match static sequence
    private func filterStepsByStaticSequence(_ apiSteps: [String]) -> [String] {
        var filteredSteps: [String] = []
        
        // Iterate through static sequence in order
        for step in Self.staticNavigationSequence {
            // Check if this step exists in API response
            if apiSteps.contains(step) {
                // If yes, add it to filtered steps (maintains static sequence order)
                filteredSteps.append(step)
                print("OrderShieldSDK: Step '\(step)' found in API response - including in navigation flow")
            } else {
                print("OrderShieldSDK: Step '\(step)' not found in API response - skipping")
            }
        }
        
        print("OrderShieldSDK: Static sequence: \(Self.staticNavigationSequence)")
        print("OrderShieldSDK: API steps: \(apiSteps)")
        print("OrderShieldSDK: Filtered steps (final navigation order): \(filteredSteps)")
        
        return filteredSteps
    }
    
    func start() {
        Task {
            await startVerificationSession()
        }
    }
    
    func start(with sessionToken: String) {
        self.sessionToken = sessionToken
        // Steps should already be set from session API response (via initializer)
        // Do NOT overwrite with storage steps as that contains settings steps, not session-specific steps
        // The requiredSteps are set either:
        // 1. Via initializer (from /verification/start response) - for new sessions
        // 2. Via startVerificationSession() (from /verification/status response) - for resumed sessions
        // Both use session-specific steps, not settings steps
        Task { @MainActor in
            setupNavigationController()
            // Don't show first step immediately - wait for user to click "Start Verification" button
        }
    }
    
    private func startVerificationSession() async {
        guard let customerId = customerId else {
            await MainActor.run {
                let error = NSError(domain: "OrderShieldSDK", code: -1, userInfo: [NSLocalizedDescriptionKey: "Customer ID not found"])
                delegate?.orderShieldDidStartVerification(success: false, sessionToken: nil, error: error)
                objcDelegate?.orderShieldDidStartVerification?(success: false, sessionToken: nil, error: error)
                showError("Customer ID not found. Please call initialize() first")
            }
            return
        }
        
        // Try to resume from existing session first
        let existingSessionToken = StorageService.shared.getSessionToken()
        print("OrderShieldSDK: Checking for existing session...")
        print("OrderShieldSDK: - Customer ID: \(customerId)")
        print("OrderShieldSDK: - Existing session token: \(existingSessionToken ?? "nil")")
        
        if let existingSessionToken = existingSessionToken {
            print("OrderShieldSDK: Found existing session token, calling /verification/status API...")
            do {
                let statusResponse = try await NetworkService.shared.getVerificationStatus(
                    customerId: customerId,
                    sessionToken: existingSessionToken
                )
                
                if let statusData = statusResponse.data {
                    // If verification is complete, show completion screen
                    if statusData.isComplete {
                        print("OrderShieldSDK: Verification already complete. Showing completion screen.")
                        await MainActor.run {
                            // Clear device identifier on completion
                            StorageService.shared.clearDeviceIdentifier()
                            setupNavigationController()
                            // Show completion screen immediately
                            showCompletion()
                        }
                        return
                    }
                    
                    // If not complete, resume from first remaining step
                    if !statusData.stepsRemaining.isEmpty {
                        print("OrderShieldSDK: Resuming verification")
                        print("OrderShieldSDK: - Steps completed: \(statusData.stepsCompleted)")
                        print("OrderShieldSDK: - Steps remaining: \(statusData.stepsRemaining)")
                        
                        // Filter and order remaining steps based on static navigation sequence
                        let filteredRemainingSteps = filterStepsByStaticSequence(statusData.stepsRemaining)
                        
                        guard !filteredRemainingSteps.isEmpty else {
                            print("OrderShieldSDK: No remaining steps match static sequence after filtering")
                            await MainActor.run {
                                showError("No remaining verification steps found")
                            }
                            return
                        }
                        
                        let nextStepKey = filteredRemainingSteps[0]
                        print("OrderShieldSDK: Resuming verification at step: \(nextStepKey)")
                        
                        // IMPORTANT: Use filtered remaining steps (ordered by static sequence)
                        // This ensures we only show steps that haven't been completed yet, in static order
                        self.requiredSteps = filteredRemainingSteps
                        self.currentStepIndex = 0  // Always start from first remaining step (index 0)
                        
                        self.sessionToken = existingSessionToken
                        
                        // Store session ID if available
                        if let sessionId = statusData.sessionId {
                            StorageService.shared.saveSessionId(sessionId)
                        }
                        
                        // Store only remaining steps (not all steps) for consistency
                        StorageService.shared.saveRequiredSteps(statusData.stepsRemaining)
                        
                        await MainActor.run {
                            delegate?.orderShieldDidStartVerification(success: true, sessionToken: existingSessionToken, error: nil)
                            objcDelegate?.orderShieldDidStartVerification?(success: true, sessionToken: existingSessionToken, error: nil)
                            delegate?.orderShieldDidStartVerificationWithDetails(
                                success: true,
                                sessionId: statusData.sessionId,
                                sessionToken: existingSessionToken,
                                stepsRequired: statusData.stepsRemaining,
                                stepsOptional: statusData.stepsOptional,
                                expiresAt: statusData.expiresAt,
                                error: nil
                            )
                            objcDelegate?.orderShieldDidStartVerificationWithDetails?(
                                success: true,
                                sessionId: statusData.sessionId,
                                sessionToken: existingSessionToken,
                                stepsRequired: statusData.stepsRemaining,
                                stepsOptional: statusData.stepsOptional,
                                expiresAt: statusData.expiresAt,
                                error: nil
                            )
                            setupNavigationController()
                            // Don't show first step immediately - wait for user to click "Start Verification" button
                        }
                        return
                    }
                }
            } catch {
                // If status check fails, continue to start new session
                print("OrderShieldSDK: Failed to resume from existing session: \(error.localizedDescription). Starting new session.")
            }
        } else {
            print("OrderShieldSDK: No existing session token found. Starting new verification session...")
        }
        
        // No existing session or resume failed - start new verification session
        print("OrderShieldSDK: Calling /verification/start API to create new session...")
        do {
            let request = StartVerificationRequest(customerId: customerId)
            let response = try await NetworkService.shared.startVerification(request)
            
            guard let data = response.data else {
                await MainActor.run {
                    let error = NSError(domain: "OrderShieldSDK", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to start verification session"])
                    delegate?.orderShieldDidStartVerification(success: false, sessionToken: nil, error: error)
                    objcDelegate?.orderShieldDidStartVerification?(success: false, sessionToken: nil, error: error)
                    showError("Failed to start verification session")
                }
                return
            }
            
            let sessionToken = data.sessionToken
            self.sessionToken = sessionToken
            
            // Filter and order required steps based on static navigation sequence
            print("OrderShieldSDK: New session - steps from API: \(data.stepsRequired)")
            let filteredRequiredSteps = filterStepsByStaticSequence(data.stepsRequired)
            
            guard !filteredRequiredSteps.isEmpty else {
                await MainActor.run {
                    let error = NSError(domain: "OrderShieldSDK", code: -1, userInfo: [NSLocalizedDescriptionKey: "No required steps match static navigation sequence"])
                    delegate?.orderShieldDidStartVerification(success: false, sessionToken: nil, error: error)
                    objcDelegate?.orderShieldDidStartVerification?(success: false, sessionToken: nil, error: error)
                    showError("No required verification steps found")
                }
                return
            }
            
            self.requiredSteps = filteredRequiredSteps
            
            // Store session token, session ID, and filtered required steps
            StorageService.shared.saveSessionToken(sessionToken)
            StorageService.shared.saveSessionId(data.sessionId)
            StorageService.shared.saveRequiredSteps(filteredRequiredSteps)
            
            await MainActor.run {
                delegate?.orderShieldDidStartVerification(success: true, sessionToken: sessionToken, error: nil)
                objcDelegate?.orderShieldDidStartVerification?(success: true, sessionToken: sessionToken, error: nil)
                delegate?.orderShieldDidStartVerificationWithDetails(
                    success: true,
                    sessionId: data.sessionId,
                    sessionToken: sessionToken,
                    stepsRequired: data.stepsRequired,
                    stepsOptional: data.stepsOptional,
                    expiresAt: data.expiresAt,
                    error: nil
                )
                objcDelegate?.orderShieldDidStartVerificationWithDetails?(
                    success: true,
                    sessionId: data.sessionId,
                    sessionToken: sessionToken,
                    stepsRequired: data.stepsRequired,
                    stepsOptional: data.stepsOptional,
                    expiresAt: data.expiresAt,
                    error: nil
                )
                setupNavigationController()
            }
        } catch {
            await MainActor.run {
                delegate?.orderShieldDidStartVerification(success: false, sessionToken: nil, error: error)
                objcDelegate?.orderShieldDidStartVerification?(success: false, sessionToken: nil, error: error)
                delegate?.orderShieldDidStartVerificationWithDetails(
                    success: false,
                    sessionId: nil,
                    sessionToken: nil,
                    stepsRequired: nil,
                    stepsOptional: nil,
                    expiresAt: nil,
                    error: error
                )
                objcDelegate?.orderShieldDidStartVerificationWithDetails?(
                    success: false,
                    sessionId: nil,
                    sessionToken: nil,
                    stepsRequired: nil,
                    stepsOptional: nil,
                    expiresAt: nil,
                    error: error
                )
                showError("Failed to start verification: \(error.localizedDescription)")
            }
        }
    }
    
    @MainActor
    private func setupNavigationController() {
        // Only create navigation controller if it doesn't exist
        guard navigationController == nil else { return }
        
        // Create start verification view controller as root
        let startVC = StartVerificationViewController(onStart: { [weak self] in
            self?.proceedToVerificationFlow()
        })
        
        let navController = UINavigationController(rootViewController: startVC)
        navController.modalPresentationStyle = .fullScreen
        navController.setNavigationBarHidden(true, animated: false)
        navigationController = navController
        presentingViewController?.present(navController, animated: true)
    }
    
    @MainActor
    private func proceedToVerificationFlow() {
        showFirstStep()
    }
    
    @MainActor
    private func showFirstStep() {
        guard !requiredSteps.isEmpty else {
            showCompletion()
            return
        }
        
        let firstStep = requiredSteps[0]
        showStep(firstStep)
    }
    
    @MainActor
    private func showStep(_ step: String) {
        guard let sessionToken = sessionToken else {
            showError("Session token missing")
            return
        }
        
        guard let customerId = customerId else {
            showError("Customer ID not found")
            return
        }
        
        // Notify delegate that step is starting
        delegate?.orderShieldDidStartStep(step: step, stepIndex: currentStepIndex, totalSteps: requiredSteps.count)
        objcDelegate?.orderShieldDidStartStep?(step: step, stepIndex: currentStepIndex, totalSteps: requiredSteps.count)
        
        let viewController: UIViewController
        
        switch step {
        case "selfie":
            viewController = SelfieVerificationViewController(
                sessionToken: sessionToken,
                onComplete: { [weak self] in
                    Task { @MainActor [weak self] in
                        self?.delegate?.orderShieldDidCompleteStep(step: step, stepIndex: self?.currentStepIndex ?? 0, success: true, error: nil)
                        self?.objcDelegate?.orderShieldDidCompleteStep?(step: step, stepIndex: self?.currentStepIndex ?? 0, success: true, error: nil)
                        self?.moveToNextStep()
                    }
                },
                onError: { [weak self] error in
                    Task { @MainActor [weak self] in
                        self?.delegate?.orderShieldDidCompleteStep(step: step, stepIndex: self?.currentStepIndex ?? 0, success: false, error: error)
                        self?.objcDelegate?.orderShieldDidCompleteStep?(step: step, stepIndex: self?.currentStepIndex ?? 0, success: false, error: error)
                    }
                }
            )
        case "email":
            viewController = EmailVerificationViewController(
                sessionToken: sessionToken,
                onComplete: { [weak self] in
                    Task { @MainActor [weak self] in
                        self?.delegate?.orderShieldDidCompleteStep(step: step, stepIndex: self?.currentStepIndex ?? 0, success: true, error: nil)
                        self?.objcDelegate?.orderShieldDidCompleteStep?(step: step, stepIndex: self?.currentStepIndex ?? 0, success: true, error: nil)
                        self?.moveToNextStep()
                    }
                },
                onError: { [weak self] error in
                    Task { @MainActor [weak self] in
                        self?.delegate?.orderShieldDidCompleteStep(step: step, stepIndex: self?.currentStepIndex ?? 0, success: false, error: error)
                        self?.objcDelegate?.orderShieldDidCompleteStep?(step: step, stepIndex: self?.currentStepIndex ?? 0, success: false, error: error)
                    }
                }
            )
        case "sms":
            viewController = PhoneVerificationViewController(
                sessionToken: sessionToken,
                onComplete: { [weak self] in
                    Task { @MainActor [weak self] in
                        self?.delegate?.orderShieldDidCompleteStep(step: step, stepIndex: self?.currentStepIndex ?? 0, success: true, error: nil)
                        self?.objcDelegate?.orderShieldDidCompleteStep?(step: step, stepIndex: self?.currentStepIndex ?? 0, success: true, error: nil)
                        self?.moveToNextStep()
                    }
                },
                onError: { [weak self] error in
                    Task { @MainActor [weak self] in
                        self?.delegate?.orderShieldDidCompleteStep(step: step, stepIndex: self?.currentStepIndex ?? 0, success: false, error: error)
                        self?.objcDelegate?.orderShieldDidCompleteStep?(step: step, stepIndex: self?.currentStepIndex ?? 0, success: false, error: error)
                    }
                }
            )
        case "terms":
            // Always use combined screen for terms + signature
            // Check if signature is the next step - if so, mark both as complete
            let nextStepIndex = currentStepIndex + 1
            let isSignatureNext = nextStepIndex < requiredSteps.count && requiredSteps[nextStepIndex] == "signature"
            
            viewController = TermsAndSignatureVerificationViewController(
                sessionToken: sessionToken,
                onComplete: { [weak self] in
                    Task { @MainActor [weak self] in
                        // Mark terms as complete
                        self?.delegate?.orderShieldDidCompleteStep(step: "terms", stepIndex: self?.currentStepIndex ?? 0, success: true, error: nil)
                        self?.objcDelegate?.orderShieldDidCompleteStep?(step: "terms", stepIndex: self?.currentStepIndex ?? 0, success: true, error: nil)
                        // If signature is next, skip it and mark it complete too
                        if isSignatureNext {
                            self?.currentStepIndex += 1
                            self?.delegate?.orderShieldDidCompleteStep(step: "signature", stepIndex: self?.currentStepIndex ?? 0, success: true, error: nil)
                            self?.objcDelegate?.orderShieldDidCompleteStep?(step: "signature", stepIndex: self?.currentStepIndex ?? 0, success: true, error: nil)
                        }
                        self?.moveToNextStep()
                    }
                },
                onError: { [weak self] error in
                    Task { @MainActor [weak self] in
                        self?.delegate?.orderShieldDidCompleteStep(step: step, stepIndex: self?.currentStepIndex ?? 0, success: false, error: error)
                        self?.objcDelegate?.orderShieldDidCompleteStep?(step: step, stepIndex: self?.currentStepIndex ?? 0, success: false, error: error)
                    }
                },
                delegate: self
            )
        case "signature":
            // Check if terms was the previous step - if so, it was already handled
            let prevStepIndex = currentStepIndex - 1
            if prevStepIndex >= 0 && requiredSteps[prevStepIndex] == "terms" {
                // Terms was previous, so it should have been combined - skip this
                moveToNextStep()
                return
            } else {
                // Signature comes alone, use separate screen
                viewController = SignatureVerificationViewController(
                    sessionToken: sessionToken,
                    onComplete: { [weak self] in
                        Task { @MainActor [weak self] in
                            self?.delegate?.orderShieldDidCompleteStep(step: step, stepIndex: self?.currentStepIndex ?? 0, success: true, error: nil)
                            self?.objcDelegate?.orderShieldDidCompleteStep?(step: step, stepIndex: self?.currentStepIndex ?? 0, success: true, error: nil)
                            self?.moveToNextStep()
                        }
                    },
                    onError: { [weak self] error in
                        Task { @MainActor [weak self] in
                            self?.delegate?.orderShieldDidCompleteStep(step: step, stepIndex: self?.currentStepIndex ?? 0, success: false, error: error)
                            self?.objcDelegate?.orderShieldDidCompleteStep?(step: step, stepIndex: self?.currentStepIndex ?? 0, success: false, error: error)
                        }
                    },
                    delegate: self
                )
            }
        case "userInfo":
            viewController = UserInfoVerificationViewController(
                sessionToken: sessionToken,
                currentStep: currentStepIndex + 1,
                totalSteps: requiredSteps.count,
                onComplete: { [weak self] in
                    Task { @MainActor [weak self] in
                        self?.delegate?.orderShieldDidCompleteStep(step: step, stepIndex: self?.currentStepIndex ?? 0, success: true, error: nil)
                        self?.objcDelegate?.orderShieldDidCompleteStep?(step: step, stepIndex: self?.currentStepIndex ?? 0, success: true, error: nil)
                        self?.moveToNextStep()
                    }
                },
                onError: { [weak self] error in
                    Task { @MainActor [weak self] in
                        self?.delegate?.orderShieldDidCompleteStep(step: step, stepIndex: self?.currentStepIndex ?? 0, success: false, error: error)
                        self?.objcDelegate?.orderShieldDidCompleteStep?(step: step, stepIndex: self?.currentStepIndex ?? 0, success: false, error: error)
                    }
                },
                delegate: self
            )
        default:
            // Unknown step, skip it
            moveToNextStep()
            return
        }
        
        navigationController?.pushViewController(viewController, animated: true)
    }
    
    @MainActor
    private func moveToNextStep() {
        currentStepIndex += 1
        
        if currentStepIndex >= requiredSteps.count {
            // All steps completed, show completion screen
            showCompletion()
        } else {
            // Move to next step automatically
            let nextStep = requiredSteps[currentStepIndex]
            showStep(nextStep)
        }
    }
    
    @MainActor
    private func showCompletion() {
        let completionVC = VerificationCompleteViewController(
            onDismiss: { [weak self] in
                self?.navigationController?.dismiss(animated: true)
            }
        )
        navigationController?.pushViewController(completionVC, animated: true)
        
        // Get session ID from stored verification session
        let sessionId = StorageService.shared.getSessionId()
        
        // Clear device identifier and session data on completion
        StorageService.shared.clearDeviceIdentifier()
        print("OrderShieldSDK: Cleared device identifier and session data on verification completion")
        
        delegate?.orderShieldDidCompleteVerification(sessionId: sessionId)
        objcDelegate?.orderShieldDidCompleteVerification?(sessionId: sessionId)
    }
    
    @MainActor
    private func showError(_ message: String) {
        let error = NSError(domain: "OrderShieldSDK", code: -1, userInfo: [NSLocalizedDescriptionKey: message])
        delegate?.orderShieldDidCancelVerification(error: error)
        objcDelegate?.orderShieldDidCancelVerification?(error: error)
        
        let alert = UIAlertController(
            title: "Error",
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            self?.navigationController?.dismiss(animated: true)
        })
        navigationController?.present(alert, animated: true)
    }
}

// MARK: - OrderShieldDelegate (forward view controller callbacks to both Swift and ObjC delegates)
@available(iOS 13.0, *)
extension VerificationFlowCoordinator: OrderShieldDelegate {
    public func orderShieldDidFetchTermsCheckboxes(success: Bool, checkboxes: [TermsCheckbox]?, error: Error?) {
        delegate?.orderShieldDidFetchTermsCheckboxes(success: success, checkboxes: checkboxes, error: error)
        objcDelegate?.orderShieldDidFetchTermsCheckboxes?(success: success, checkboxes: checkboxes?.map { OSTermsCheckbox(from: $0) }, error: error)
    }
    public func orderShieldDidAcceptTerms(success: Bool, acceptedCheckboxIds: [String]?, error: Error?) {
        delegate?.orderShieldDidAcceptTerms(success: success, acceptedCheckboxIds: acceptedCheckboxIds, error: error)
        objcDelegate?.orderShieldDidAcceptTerms?(success: success, acceptedCheckboxIds: acceptedCheckboxIds, error: error)
    }
    public func orderShieldDidSubmitSignature(success: Bool, error: Error?) {
        delegate?.orderShieldDidSubmitSignature(success: success, error: error)
        objcDelegate?.orderShieldDidSubmitSignature?(success: success, error: error)
    }
    public func orderShieldDidSubmitTermsAndSignature(success: Bool, acceptedCheckboxIds: [String]?, error: Error?) {
        delegate?.orderShieldDidSubmitTermsAndSignature(success: success, acceptedCheckboxIds: acceptedCheckboxIds, error: error)
        objcDelegate?.orderShieldDidSubmitTermsAndSignature?(success: success, acceptedCheckboxIds: acceptedCheckboxIds, error: error)
    }
    public func orderShieldDidSubmitUserInfo(success: Bool, firstName: String?, lastName: String?, dateOfBirth: String?, error: Error?) {
        delegate?.orderShieldDidSubmitUserInfo(success: success, firstName: firstName, lastName: lastName, dateOfBirth: dateOfBirth, error: error)
        objcDelegate?.orderShieldDidSubmitUserInfo?(success: success, firstName: firstName, lastName: lastName, dateOfBirth: dateOfBirth, error: error)
    }
}

