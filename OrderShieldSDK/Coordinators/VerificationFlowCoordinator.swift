import Foundation
import UIKit

@available(iOS 13.0, *)
class VerificationFlowCoordinator {
    private var customerId: String? {
        return StorageService.shared.getCustomerId()
    }
    private var requiredSteps: [String] = []
    private weak var presentingViewController: UIViewController?
    private weak var delegate: OrderShieldDelegate?
    private var currentStepIndex = 0
    private var sessionToken: String?
    private var navigationController: UINavigationController?
    
    init(
        requiredSteps: [String] = [],
        presentingViewController: UIViewController,
        delegate: OrderShieldDelegate?
    ) {
        self.requiredSteps = requiredSteps
        self.presentingViewController = presentingViewController
        self.delegate = delegate
    }
    
    func start() {
        Task {
            await startVerificationSession()
        }
    }
    
    func start(with sessionToken: String) {
        self.sessionToken = sessionToken
        // Load required steps from storage if available
        self.requiredSteps = StorageService.shared.getRequiredSteps()
        Task { @MainActor in
            setupNavigationController()
            showFirstStep()
        }
    }
    
    private func startVerificationSession() async {
        guard let customerId = customerId else {
            await MainActor.run {
                let error = NSError(domain: "OrderShieldSDK", code: -1, userInfo: [NSLocalizedDescriptionKey: "Customer ID not found"])
                delegate?.orderShieldDidStartVerification(success: false, sessionToken: nil, error: error)
                showError("Customer ID not found. Please call initialize() first")
            }
            return
        }
        
        do {
            // Start verification session (register-device and verification-settings are called in initialize())
            let request = StartVerificationRequest(customerId: customerId)
            let response = try await NetworkService.shared.startVerification(request)
            
            guard let data = response.data else {
                await MainActor.run {
                    let error = NSError(domain: "OrderShieldSDK", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to start verification session"])
                    delegate?.orderShieldDidStartVerification(success: false, sessionToken: nil, error: error)
                    showError("Failed to start verification session")
                }
                return
            }
            
            let sessionToken = data.sessionToken
            self.sessionToken = sessionToken
            self.requiredSteps = data.stepsRequired
            
            // Store session token and required steps
            StorageService.shared.saveSessionToken(sessionToken)
            StorageService.shared.saveRequiredSteps(data.stepsRequired)
            
            await MainActor.run {
                // Call both delegate methods for backward compatibility
                delegate?.orderShieldDidStartVerification(success: true, sessionToken: sessionToken, error: nil)
                delegate?.orderShieldDidStartVerificationWithDetails(
                    success: true,
                    sessionId: data.sessionId,
                    sessionToken: sessionToken,
                    stepsRequired: data.stepsRequired,
                    stepsOptional: data.stepsOptional,
                    expiresAt: data.expiresAt,
                    error: nil
                )
                setupNavigationController()
                showFirstStep()
            }
        } catch {
            await MainActor.run {
                // Call both delegate methods for backward compatibility
                delegate?.orderShieldDidStartVerification(success: false, sessionToken: nil, error: error)
                delegate?.orderShieldDidStartVerificationWithDetails(
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
        
        // Create an empty root view controller for the navigation stack
        let rootVC = UIViewController()
        rootVC.view.backgroundColor = .systemBackground
        
        let navController = UINavigationController(rootViewController: rootVC)
        navController.modalPresentationStyle = .fullScreen
        navController.setNavigationBarHidden(true, animated: false)
        navigationController = navController
        presentingViewController?.present(navController, animated: true)
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
        
        let viewController: UIViewController
        
        switch step {
        case "selfie":
            viewController = SelfieVerificationViewController(
                sessionToken: sessionToken,
                onComplete: { [weak self] in
                    Task { @MainActor [weak self] in
                        self?.delegate?.orderShieldDidCompleteStep(step: step, stepIndex: self?.currentStepIndex ?? 0, success: true, error: nil)
                        self?.moveToNextStep()
                    }
                },
                onError: { [weak self] error in
                    Task { @MainActor [weak self] in
                        self?.delegate?.orderShieldDidCompleteStep(step: step, stepIndex: self?.currentStepIndex ?? 0, success: false, error: error)
                    }
                }
            )
        case "email":
            viewController = EmailVerificationViewController(
                sessionToken: sessionToken,
                onComplete: { [weak self] in
                    Task { @MainActor [weak self] in
                        self?.delegate?.orderShieldDidCompleteStep(step: step, stepIndex: self?.currentStepIndex ?? 0, success: true, error: nil)
                        self?.moveToNextStep()
                    }
                },
                onError: { [weak self] error in
                    Task { @MainActor [weak self] in
                        self?.delegate?.orderShieldDidCompleteStep(step: step, stepIndex: self?.currentStepIndex ?? 0, success: false, error: error)
                    }
                }
            )
        case "sms":
            viewController = PhoneVerificationViewController(
                sessionToken: sessionToken,
                onComplete: { [weak self] in
                    Task { @MainActor [weak self] in
                        self?.delegate?.orderShieldDidCompleteStep(step: step, stepIndex: self?.currentStepIndex ?? 0, success: true, error: nil)
                        self?.moveToNextStep()
                    }
                },
                onError: { [weak self] error in
                    Task { @MainActor [weak self] in
                        self?.delegate?.orderShieldDidCompleteStep(step: step, stepIndex: self?.currentStepIndex ?? 0, success: false, error: error)
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
                        // If signature is next, skip it and mark it complete too
                        if isSignatureNext {
                            self?.currentStepIndex += 1
                            self?.delegate?.orderShieldDidCompleteStep(step: "signature", stepIndex: self?.currentStepIndex ?? 0, success: true, error: nil)
                        }
                        // Move to next step
                        self?.moveToNextStep()
                    }
                },
                onError: { [weak self] error in
                    Task { @MainActor [weak self] in
                        self?.delegate?.orderShieldDidCompleteStep(step: step, stepIndex: self?.currentStepIndex ?? 0, success: false, error: error)
                    }
                },
                delegate: delegate
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
                            self?.moveToNextStep()
                        }
                    },
                    onError: { [weak self] error in
                        Task { @MainActor [weak self] in
                            self?.delegate?.orderShieldDidCompleteStep(step: step, stepIndex: self?.currentStepIndex ?? 0, success: false, error: error)
                        }
                    },
                    delegate: delegate
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
                        self?.moveToNextStep()
                    }
                },
                onError: { [weak self] error in
                    Task { @MainActor [weak self] in
                        self?.delegate?.orderShieldDidCompleteStep(step: step, stepIndex: self?.currentStepIndex ?? 0, success: false, error: error)
                    }
                },
                delegate: delegate
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
        
        // Get session ID from stored verification session if available
        // For now, we'll pass nil as we don't store it, but you can enhance this
        delegate?.orderShieldDidCompleteVerification(sessionId: nil)
    }
    
    @MainActor
    private func showError(_ message: String) {
        let error = NSError(domain: "OrderShieldSDK", code: -1, userInfo: [NSLocalizedDescriptionKey: message])
        delegate?.orderShieldDidCancelVerification(error: error)
        
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

