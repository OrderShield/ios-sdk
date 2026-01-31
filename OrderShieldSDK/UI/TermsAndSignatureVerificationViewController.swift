import UIKit

@available(iOS 13.0, *)
class TermsAndSignatureVerificationViewController: UIViewController {
    private let sessionToken: String
    private let onComplete: () -> Void
    private let onError: ((Error) -> Void)?
    private weak var delegate: OrderShieldDelegate?
    
    private var customerId: String? {
        return StorageService.shared.getCustomerId()
    }
    
    private var checkboxStates: [String: Bool] = [:]
    private var checkboxes: [TermsCheckbox] = []
    private var isLoadingCheckboxes = false
    
    // Track which sections are enabled based on requiredSteps + settings
    private var isTermsEnabled: Bool {
        let requiredSteps = StorageService.shared.getRequiredSteps()
        return requiredSteps.contains("terms")
    }
    
    /// Signature step is considered enabled only when:
    /// - The current session's required steps include "signature"
    /// - AND the signature confirmation feature is enabled in verification settings
    private var isSignatureEnabled: Bool {
        let requiredSteps = StorageService.shared.getRequiredSteps()
        guard requiredSteps.contains("signature") else { return false }
        
        // If settings are available, honor the signatureConfirmationEnabled flag.
        // If settings are missing (unexpected), default to requiring signature.
        if let settings = StorageService.shared.getVerificationSettings()?.settings {
            return settings.signatureConfirmationEnabled
        }
        return true
    }
    
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let titleLabel = UILabel()
    private let descriptionLabel = UILabel()
    
    // Key Points Section
    private let keyPointsLabel = UILabel()
    private let keyPointsContainer = UIView()
    private let keyPointsStack = UIStackView()
    
    // Checkboxes Section
    private let checkboxesTitleLabel = UILabel()
    private let checkboxesStack = UIStackView()
    private let completeButton = UIButton(type: .system)
    private let loadingIndicator = UIActivityIndicatorView(style: .medium)
    private let activityIndicator = UIActivityIndicatorView(style: .medium)
    
    // Signature Sheet (Modal)
    private var signatureSheetViewController: SignatureSheetViewController?
    
    init(sessionToken: String, onComplete: @escaping () -> Void, onError: ((Error) -> Void)? = nil, delegate: OrderShieldDelegate? = nil) {
        self.sessionToken = sessionToken
        self.onComplete = onComplete
        self.onError = onError
        self.delegate = delegate
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.setNavigationBarHidden(true, animated: false)
        setupUI()
        loadCheckboxes()
    }
    
    private func setupUI() {
        view.backgroundColor = .white
        
        // Scroll View
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        
        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)
        
        // Title
        titleLabel.text = "Terms of Service Agreement"
        titleLabel.font = .systemFont(ofSize: 24, weight: .bold)
        titleLabel.textColor = .black
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(titleLabel)
        
        // Subtitle
        descriptionLabel.text = "Require users to accept terms and conditions"
        descriptionLabel.font = .systemFont(ofSize: 14)
        descriptionLabel.textColor = .systemGray
        descriptionLabel.textAlignment = .center
        descriptionLabel.numberOfLines = 0
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(descriptionLabel)
        
        // Key Points Section
        keyPointsLabel.text = "Key points"
        keyPointsLabel.font = .systemFont(ofSize: 16, weight: .bold)
        keyPointsLabel.textColor = .black
        keyPointsLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(keyPointsLabel)
        
        // Key Points Container (grey box)
        keyPointsContainer.backgroundColor = UIColor.systemGray6
        keyPointsContainer.layer.cornerRadius = 8
        keyPointsContainer.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(keyPointsContainer)
        
        // Key Points Stack
        keyPointsStack.axis = .vertical
        keyPointsStack.spacing = 12
        keyPointsStack.distribution = .fill
        keyPointsStack.alignment = .leading
        keyPointsStack.translatesAutoresizingMaskIntoConstraints = false
        keyPointsContainer.addSubview(keyPointsStack)
        
        // Add key points items
        let keyPoints = [
            "Your verification photo is used to confirm you authorized this trial.",
            "Disputing a valid transaction is fraud and may be prosecuted.",
            "Need help? Contact support@bigbraintech.ai.",
            "Purchases and renewals will appear as Parallel Live on your bank statement."
        ]
        
        for point in keyPoints {
            let pointLabel = UILabel()
            pointLabel.text = "• \(point)"
            pointLabel.font = .systemFont(ofSize: 14)
            pointLabel.textColor = .black
            pointLabel.numberOfLines = 0
            pointLabel.translatesAutoresizingMaskIntoConstraints = false
            keyPointsStack.addArrangedSubview(pointLabel)
        }
        
        // Checkboxes Title
        checkboxesTitleLabel.text = "Tap to accept the following check boxes"
        checkboxesTitleLabel.font = .systemFont(ofSize: 16, weight: .bold)
        checkboxesTitleLabel.textColor = .black
        checkboxesTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        checkboxesTitleLabel.isHidden = !isTermsEnabled
        contentView.addSubview(checkboxesTitleLabel)
        
        // Checkboxes Stack
        checkboxesStack.axis = .vertical
        checkboxesStack.spacing = 16
        checkboxesStack.translatesAutoresizingMaskIntoConstraints = false
        checkboxesStack.isHidden = !isTermsEnabled
        contentView.addSubview(checkboxesStack)
        
        // Loading Indicator
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        loadingIndicator.isHidden = !isTermsEnabled
        contentView.addSubview(loadingIndicator)
        
        // Complete Button
        completeButton.setTitle(isSignatureEnabled ? "Accept and Sign" : "Accept", for: .normal)
        completeButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        completeButton.backgroundColor = .black
        completeButton.setTitleColor(.white, for: .normal)
        completeButton.setTitleColor(.white.withAlphaComponent(0.5), for: .disabled)
        completeButton.layer.cornerRadius = 12
        completeButton.isEnabled = false
        completeButton.addTarget(self, action: #selector(completeTapped), for: .touchUpInside)
        completeButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(completeButton)
        
        // Arrow Icon on Button
        let arrowIcon = UIImageView(image: UIImage(systemName: "arrow.right"))
        arrowIcon.tintColor = .white
        arrowIcon.contentMode = .scaleAspectFit
        arrowIcon.translatesAutoresizingMaskIntoConstraints = false
        completeButton.addSubview(arrowIcon)
        
        // Activity Indicator for API calls
        activityIndicator.hidesWhenStopped = true
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(activityIndicator)
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: completeButton.topAnchor, constant: -20),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            descriptionLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            descriptionLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            descriptionLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            // Key Points Section
            keyPointsLabel.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: 24),
            keyPointsLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            keyPointsLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            keyPointsContainer.topAnchor.constraint(equalTo: keyPointsLabel.bottomAnchor, constant: 12),
            keyPointsContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            keyPointsContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            keyPointsStack.topAnchor.constraint(equalTo: keyPointsContainer.topAnchor, constant: 16),
            keyPointsStack.leadingAnchor.constraint(equalTo: keyPointsContainer.leadingAnchor, constant: 16),
            keyPointsStack.trailingAnchor.constraint(equalTo: keyPointsContainer.trailingAnchor, constant: -16),
            keyPointsStack.bottomAnchor.constraint(equalTo: keyPointsContainer.bottomAnchor, constant: -16),
            
            // Checkboxes Title
            checkboxesTitleLabel.topAnchor.constraint(equalTo: keyPointsContainer.bottomAnchor, constant: 24),
            checkboxesTitleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            checkboxesTitleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            loadingIndicator.topAnchor.constraint(equalTo: checkboxesTitleLabel.bottomAnchor, constant: 20),
            loadingIndicator.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            
            checkboxesStack.topAnchor.constraint(equalTo: checkboxesTitleLabel.bottomAnchor, constant: 16),
            checkboxesStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            checkboxesStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            completeButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            completeButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            completeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            completeButton.heightAnchor.constraint(equalToConstant: 56),
            
            arrowIcon.trailingAnchor.constraint(equalTo: completeButton.trailingAnchor, constant: -20),
            arrowIcon.centerYAnchor.constraint(equalTo: completeButton.centerYAnchor),
            arrowIcon.widthAnchor.constraint(equalToConstant: 20),
            arrowIcon.heightAnchor.constraint(equalToConstant: 20),
            
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        
        // Set bottom spacing for contentView based on last visible element
        if isTermsEnabled {
            NSLayoutConstraint.activate([
                checkboxesStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20)
            ])
        } else {
            NSLayoutConstraint.activate([
                keyPointsContainer.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20)
            ])
        }
    }
    
    private func loadCheckboxes() {
        // Only load checkboxes if terms is enabled
        guard isTermsEnabled else {
            // Terms not enabled, update button state
            updateCompleteButton()
            return
        }
        
        isLoadingCheckboxes = true
        loadingIndicator.startAnimating()
        checkboxesStack.isHidden = true
        
        Task {
            do {
                let response = try await NetworkService.shared.fetchTermsCheckboxes()
                await MainActor.run {
                    self.checkboxes = response.data.sorted { $0.displayOrder < $1.displayOrder }
                    self.setupCheckboxes()
                    self.isLoadingCheckboxes = false
                    self.loadingIndicator.stopAnimating()
                    self.checkboxesStack.isHidden = false
                    // Notify delegate (Swift delegate gets [TermsCheckbox]; ObjC delegate is notified by coordinator if needed)
                    self.delegate?.orderShieldDidFetchTermsCheckboxes(success: true, checkboxes: self.checkboxes, error: nil)
                    // Update button state after checkboxes are loaded
                    self.updateCompleteButton()
                }
            } catch {
                await MainActor.run {
                    self.isLoadingCheckboxes = false
                    self.loadingIndicator.stopAnimating()
                    self.showError("Failed to load terms: \(error.localizedDescription)")
                    // Notify delegate
                    self.delegate?.orderShieldDidFetchTermsCheckboxes(success: false, checkboxes: nil, error: error)
                    self.onError?(error)
                }
            }
        }
    }
    
    private func setupCheckboxes() {
        checkboxesStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        checkboxStates.removeAll()
        
        for checkbox in checkboxes {
            let checkboxView = createCheckboxView(checkbox: checkbox)
            checkboxesStack.addArrangedSubview(checkboxView)
            checkboxStates[checkbox.id] = false
        }
    }
    
    private func createCheckboxView(checkbox: TermsCheckbox) -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        
        let checkboxButton = UIButton(type: .system)
        checkboxButton.tag = Int(checkbox.id.hashValue)
        checkboxButton.layer.borderWidth = 2
        checkboxButton.layer.borderColor = UIColor.systemGray3.cgColor
        checkboxButton.layer.cornerRadius = 4
        checkboxButton.backgroundColor = .white
        checkboxButton.addTarget(self, action: #selector(checkboxTapped(_:)), for: .touchUpInside)
        checkboxButton.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(checkboxButton)
        
        let textLabel = UILabel()
        textLabel.text = checkbox.checkboxText + (checkbox.isRequired ? " *" : "")
        textLabel.font = .systemFont(ofSize: 16)
        textLabel.textColor = .black
        textLabel.numberOfLines = 0
        textLabel.isUserInteractionEnabled = false // Prevent label from blocking touches
        textLabel.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(textLabel)
        
        NSLayoutConstraint.activate([
            checkboxButton.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            checkboxButton.topAnchor.constraint(equalTo: container.topAnchor),
            checkboxButton.widthAnchor.constraint(equalToConstant: 24),
            checkboxButton.heightAnchor.constraint(equalToConstant: 24),
            
            textLabel.leadingAnchor.constraint(equalTo: checkboxButton.trailingAnchor, constant: 12),
            textLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            textLabel.topAnchor.constraint(equalTo: container.topAnchor),
            textLabel.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])
        
        // Store checkbox ID on both button and container for tap handling
        objc_setAssociatedObject(checkboxButton, &AssociatedKeys.checkboxId, checkbox.id, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        objc_setAssociatedObject(container, &AssociatedKeys.checkboxId, checkbox.id, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        
        // Make entire container tappable
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(checkboxContainerTapped(_:)))
        container.addGestureRecognizer(tapGesture)
        container.isUserInteractionEnabled = true
        
        return container
    }
    
    @objc private func checkboxContainerTapped(_ gesture: UITapGestureRecognizer) {
        guard let container = gesture.view,
              let checkboxId = objc_getAssociatedObject(container, &AssociatedKeys.checkboxId) as? String else {
            return
        }
        
        // Find the checkbox button in the container
        if let checkboxButton = container.subviews.first(where: { $0 is UIButton }) as? UIButton {
            checkboxTapped(checkboxButton)
        }
    }
    
    @objc private func checkboxTapped(_ sender: UIButton) {
        guard let checkboxId = objc_getAssociatedObject(sender, &AssociatedKeys.checkboxId) as? String else {
            return
        }
        
        let isChecked = checkboxStates[checkboxId] ?? false
        checkboxStates[checkboxId] = !isChecked
        
        if !isChecked {
            sender.backgroundColor = .systemBlue
            sender.setTitle("✓", for: .normal)
            sender.setTitleColor(.white, for: .normal)
        } else {
            sender.backgroundColor = .white
            sender.setTitle("", for: .normal)
        }
        
        updateCompleteButton()
    }
    
    private func updateCompleteButton() {
        var canComplete = true
        
        // Check if ALL checkboxes are checked (only if terms is enabled)
        if isTermsEnabled {
            if !checkboxes.isEmpty {
                // All checkboxes must be checked, regardless of whether they're required or optional
                let allCheckboxesChecked = checkboxes.allSatisfy { checkboxStates[$0.id] == true }
                canComplete = canComplete && allCheckboxesChecked
            }
            // If no checkboxes at all, terms requirement is satisfied
        }
        
        // Note: Signature check is removed - button enables when all checkboxes are selected
        // Signature will be collected in the modal sheet
        
        completeButton.isEnabled = canComplete
        completeButton.backgroundColor = canComplete ? .black : .black.withAlphaComponent(0.5)
    }
    
    @objc private func completeTapped() {
        // If signature is enabled, collect signature via sheet.
        // If signature is disabled (by settings / required steps), skip the sheet and submit directly.
        if isSignatureEnabled {
            // Show signature sheet modal
            showSignatureSheet()
        } else {
            // No signature required - proceed with terms submission only
            handleSignatureAccepted(signatureImage: nil)
        }
    }
    
    private func showSignatureSheet() {
        let signatureSheet = SignatureSheetViewController()
        // Use overFullScreen to have complete control and prevent any dragging
        signatureSheet.modalPresentationStyle = .overFullScreen
        signatureSheet.modalTransitionStyle = .coverVertical
        
        // No need for sheet presentation controller with overFullScreen
        // The view controller will handle its own layout
        
        // Handle signature acceptance
        signatureSheet.onAccept = { [weak self] signatureImage in
            self?.handleSignatureAccepted(signatureImage: signatureImage)
        }
        
        signatureSheet.onCancel = { [weak self] in
            // Just dismiss the sheet, do nothing else
        }
        
        self.signatureSheetViewController = signatureSheet
        present(signatureSheet, animated: true)
    }
    
    private func handleSignatureAccepted(signatureImage: UIImage?) {
        guard let customerId = customerId else {
            showError("Customer ID not found")
            return
        }
        
        completeButton.isEnabled = false
        completeButton.setTitle("Submitting...", for: .normal)
        activityIndicator.startAnimating()
        
        Task {
            do {
                var acceptedCheckboxIds: [String] = []
                
                // Submit terms first (only if terms is enabled)
                if isTermsEnabled {
                    let acceptedCheckboxes = checkboxStates.compactMap { key, value -> CheckboxAcceptance? in
                        guard value else { return nil }
                        return CheckboxAcceptance(checkboxId: key, accepted: true)
                    }
                    
                    acceptedCheckboxIds = acceptedCheckboxes.map { $0.checkboxId }
                    
                    // Only submit terms if there are checkboxes to submit
                    // Skip API call if no checkboxes are selected (all optional checkboxes)
                    if !acceptedCheckboxes.isEmpty {
                        print("📡 [OrderShieldSDK] Submitting \(acceptedCheckboxes.count) checkbox(es) to terms API")
                        let termsRequest = TermsVerificationRequest(
                            customerId: customerId,
                            sessionToken: sessionToken,
                            acceptedCheckboxes: acceptedCheckboxes
                        )
                        _ = try await NetworkService.shared.submitTerms(termsRequest)
                        // Notify delegate about terms acceptance
                        await MainActor.run {
                            self.delegate?.orderShieldDidAcceptTerms(success: true, acceptedCheckboxIds: acceptedCheckboxIds, error: nil)
                        }
                    } else {
                        // No checkboxes selected - skip terms submission
                        print("📡 [OrderShieldSDK] No checkboxes selected, skipping terms API call")
                    }
                }
                
                // Submit signature (only if signature is enabled)
                if isSignatureEnabled {
                    guard let signatureImage = signatureImage,
                          let imageData = signatureImage.pngData() else {
                        await MainActor.run {
                            activityIndicator.stopAnimating()
                            completeButton.isEnabled = true
                            completeButton.setTitle("Accept and Sign", for: .normal)
                            showError("Please provide a signature")
                        }
                        return
                    }
                    
                    _ = try await NetworkService.shared.submitSignature(
                        customerId: customerId,
                        sessionToken: sessionToken,
                        imageData: imageData,
                        imageFormat: "png"
                    )
                    
                    // Notify delegate about signature submission
                    await MainActor.run {
                        self.delegate?.orderShieldDidSubmitSignature(success: true, error: nil)
                    }
                }
                
                // Notify delegate about combined submission
                await MainActor.run {
                    activityIndicator.stopAnimating()
                    self.delegate?.orderShieldDidSubmitTermsAndSignature(success: true, acceptedCheckboxIds: acceptedCheckboxIds.isEmpty ? nil : acceptedCheckboxIds, error: nil)
                    onComplete()
                }
            } catch {
                await MainActor.run {
                    activityIndicator.stopAnimating()
                    completeButton.isEnabled = true
                    completeButton.setTitle("Accept and Sign", for: .normal)
                    showError("Failed to submit: \(error.localizedDescription)")
                    // Notify delegate about failure
                    self.delegate?.orderShieldDidSubmitTermsAndSignature(success: false, acceptedCheckboxIds: nil, error: error)
                    onError?(error)
                }
            }
        }
    }
    
    private func showError(_ message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - Associated Keys
private struct AssociatedKeys {
    static var checkboxId = "checkboxId"
}

// MARK: - Signature Sheet View Controller
@available(iOS 13.0, *)
class SignatureSheetViewController: UIViewController {
    var onAccept: ((UIImage?) -> Void)?
    var onCancel: (() -> Void)?
    
    private let backgroundOverlay = UIView()
    private let sheetContainer = UIView()
    private let titleLabel = UILabel()
    private let instructionLabel = UILabel()
    private let signHereLabel = UILabel()
    private let signatureView = SignatureView()
    private let signatureContainer = UIView()
    private let clearButton = UIButton(type: .system)
    private let acceptButton = UIButton(type: .system)
    private let cancelButton = UIButton(type: .system)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupPresentationController()
    }
    
    private func setupPresentationController() {
        // No need for presentation controller delegate with overFullScreen
    }
    
    
    private func setupUI() {
        view.backgroundColor = .clear
        
        // Background Overlay (semi-transparent)
        backgroundOverlay.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        backgroundOverlay.translatesAutoresizingMaskIntoConstraints = false
        // Add tap gesture to dismiss when tapping outside
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(backgroundTapped))
        backgroundOverlay.addGestureRecognizer(tapGesture)
        view.addSubview(backgroundOverlay)
        
        // Sheet Container (white rounded container at bottom)
        sheetContainer.backgroundColor = .white
        sheetContainer.layer.cornerRadius = 20
        sheetContainer.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        sheetContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(sheetContainer)
        
        // Title
        titleLabel.text = "Digital Signature Required"
        titleLabel.font = .systemFont(ofSize: 20, weight: .bold)
        titleLabel.textColor = .black
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        sheetContainer.addSubview(titleLabel)
        
        // Instructions
        instructionLabel.text = "Please sign in the box below to complete your verification."
        instructionLabel.font = .systemFont(ofSize: 14)
        instructionLabel.textColor = .systemGray
        instructionLabel.textAlignment = .center
        instructionLabel.numberOfLines = 0
        instructionLabel.translatesAutoresizingMaskIntoConstraints = false
        sheetContainer.addSubview(instructionLabel)
        
        // Sign Here Label
        signHereLabel.text = "Sign here"
        signHereLabel.font = .systemFont(ofSize: 12)
        signHereLabel.textColor = .systemGray
        signHereLabel.translatesAutoresizingMaskIntoConstraints = false
        sheetContainer.addSubview(signHereLabel)
        
        // Signature Container
        signatureContainer.backgroundColor = .white
        signatureContainer.layer.borderWidth = 1
        signatureContainer.layer.borderColor = UIColor.systemGray3.cgColor
        signatureContainer.layer.cornerRadius = 8
        signatureContainer.translatesAutoresizingMaskIntoConstraints = false
        sheetContainer.addSubview(signatureContainer)
        
        // Signature View
        signatureView.backgroundColor = .white
        signatureView.isUserInteractionEnabled = true
        signatureView.translatesAutoresizingMaskIntoConstraints = false
        signatureContainer.addSubview(signatureView)
        
        // Clear Button
        clearButton.setTitle("Clear", for: .normal)
        clearButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        clearButton.setTitleColor(UIColor.systemBlue, for: .normal)
        clearButton.backgroundColor = .white
        clearButton.layer.borderWidth = 1
        clearButton.layer.borderColor = UIColor.systemBlue.cgColor
        clearButton.layer.cornerRadius = 8
        clearButton.addTarget(self, action: #selector(clearTapped), for: .touchUpInside)
        clearButton.translatesAutoresizingMaskIntoConstraints = false
        sheetContainer.addSubview(clearButton)
        
        // Accept Button
        acceptButton.setTitle("Accept", for: .normal)
        acceptButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        acceptButton.backgroundColor = .black
        acceptButton.setTitleColor(.white, for: .normal)
        acceptButton.layer.cornerRadius = 8
        acceptButton.isEnabled = false
        acceptButton.addTarget(self, action: #selector(acceptTapped), for: .touchUpInside)
        acceptButton.translatesAutoresizingMaskIntoConstraints = false
        sheetContainer.addSubview(acceptButton)
        
        // Cancel Button
        cancelButton.setTitle("Cancel", for: .normal)
        cancelButton.titleLabel?.font = .systemFont(ofSize: 16)
        cancelButton.setTitleColor(.systemBlue, for: .normal)
        cancelButton.backgroundColor = .clear
        cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        sheetContainer.addSubview(cancelButton)
        
        NSLayoutConstraint.activate([
            // Background Overlay - fills entire screen
            backgroundOverlay.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundOverlay.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundOverlay.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backgroundOverlay.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // Sheet Container - fixed at bottom, approximately 60% of screen height
            sheetContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            sheetContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            sheetContainer.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            sheetContainer.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.6),
            
            // Title
            titleLabel.topAnchor.constraint(equalTo: sheetContainer.topAnchor, constant: 24),
            titleLabel.leadingAnchor.constraint(equalTo: sheetContainer.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: sheetContainer.trailingAnchor, constant: -20),
            
            // Instructions
            instructionLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),
            instructionLabel.leadingAnchor.constraint(equalTo: sheetContainer.leadingAnchor, constant: 20),
            instructionLabel.trailingAnchor.constraint(equalTo: sheetContainer.trailingAnchor, constant: -20),
            
            // Sign Here Label
            signHereLabel.topAnchor.constraint(equalTo: instructionLabel.bottomAnchor, constant: 20),
            signHereLabel.leadingAnchor.constraint(equalTo: sheetContainer.leadingAnchor, constant: 20),
            
            // Signature Container
            signatureContainer.topAnchor.constraint(equalTo: signHereLabel.bottomAnchor, constant: 8),
            signatureContainer.leadingAnchor.constraint(equalTo: sheetContainer.leadingAnchor, constant: 20),
            signatureContainer.trailingAnchor.constraint(equalTo: sheetContainer.trailingAnchor, constant: -20),
            signatureContainer.heightAnchor.constraint(equalToConstant: 200),
            
            // Signature View
            signatureView.topAnchor.constraint(equalTo: signatureContainer.topAnchor),
            signatureView.leadingAnchor.constraint(equalTo: signatureContainer.leadingAnchor),
            signatureView.trailingAnchor.constraint(equalTo: signatureContainer.trailingAnchor),
            signatureView.bottomAnchor.constraint(equalTo: signatureContainer.bottomAnchor),
            
            // Clear Button
            clearButton.topAnchor.constraint(equalTo: signatureContainer.bottomAnchor, constant: 24),
            clearButton.leadingAnchor.constraint(equalTo: sheetContainer.leadingAnchor, constant: 20),
            clearButton.widthAnchor.constraint(equalToConstant: 100),
            clearButton.heightAnchor.constraint(equalToConstant: 44),
            
            // Accept Button
            acceptButton.topAnchor.constraint(equalTo: signatureContainer.bottomAnchor, constant: 24),
            acceptButton.trailingAnchor.constraint(equalTo: sheetContainer.trailingAnchor, constant: -20),
            acceptButton.leadingAnchor.constraint(equalTo: clearButton.trailingAnchor, constant: 12),
            acceptButton.heightAnchor.constraint(equalToConstant: 44),
            
            // Cancel Button
            cancelButton.topAnchor.constraint(equalTo: acceptButton.bottomAnchor, constant: 16),
            cancelButton.centerXAnchor.constraint(equalTo: sheetContainer.centerXAnchor),
            cancelButton.bottomAnchor.constraint(lessThanOrEqualTo: sheetContainer.safeAreaLayoutGuide.bottomAnchor, constant: -20)
        ])
        
        // Monitor signature changes
        signatureView.onSignatureChanged = { [weak self] hasSignature in
            self?.acceptButton.isEnabled = hasSignature
            self?.acceptButton.backgroundColor = hasSignature ? .black : .black.withAlphaComponent(0.5)
        }
    }
    
    @objc private func clearTapped() {
        signatureView.clear()
    }
    
    @objc private func acceptTapped() {
        let signatureImage = signatureView.getSignatureImage()
        dismiss(animated: true) {
            self.onAccept?(signatureImage)
        }
    }
    
    @objc private func cancelTapped() {
        dismiss(animated: true) {
            self.onCancel?()
        }
    }
    
    @objc private func backgroundTapped() {
        // Dismiss when tapping the background overlay
        dismiss(animated: true) {
            self.onCancel?()
        }
    }
}

