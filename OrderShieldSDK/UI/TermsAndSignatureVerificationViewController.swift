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
    
    // Track which sections are enabled based on requiredSteps
    private var isTermsEnabled: Bool {
        let requiredSteps = StorageService.shared.getRequiredSteps()
        return requiredSteps.contains("terms")
    }
    
    private var isSignatureEnabled: Bool {
        let requiredSteps = StorageService.shared.getRequiredSteps()
        return requiredSteps.contains("signature")
    }
    
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let titleLabel = UILabel()
    private let descriptionLabel = UILabel()
    private let checkboxesStack = UIStackView()
    private let signatureLabel = UILabel()
    private let signatureView = SignatureView()
    private let clearSignatureButton = UIButton(type: .system)
    private let completeButton = UIButton(type: .system)
    private let loadingIndicator = UIActivityIndicatorView(style: .medium)
    private let activityIndicator = UIActivityIndicatorView(style: .medium)
    
    // Store references to signature UI elements for hiding/showing
    private var signatureInstructionLabel: UILabel?
    private var signatureContainer: UIView?
    
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
        
        // Title - Update based on enabled sections
        if isTermsEnabled && isSignatureEnabled {
            titleLabel.text = "Terms & Signature"
            descriptionLabel.text = "Please review and accept our terms, then provide your signature."
        } else if isTermsEnabled {
            titleLabel.text = "Terms & Conditions"
            descriptionLabel.text = "Please review and accept our terms."
        } else if isSignatureEnabled {
            titleLabel.text = "Signature"
            descriptionLabel.text = "Please provide your signature."
        } else {
            titleLabel.text = "Verification"
            descriptionLabel.text = "Complete verification."
        }
        
        titleLabel.font = .systemFont(ofSize: 24, weight: .bold)
        titleLabel.textColor = .black
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(titleLabel)
        
        descriptionLabel.font = .systemFont(ofSize: 16)
        descriptionLabel.textColor = .systemGray
        descriptionLabel.numberOfLines = 0
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(descriptionLabel)
        
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
        
        // Signature Label
        signatureLabel.text = "Signature *"
        signatureLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        signatureLabel.textColor = .black
        signatureLabel.translatesAutoresizingMaskIntoConstraints = false
        signatureLabel.isHidden = !isSignatureEnabled
        contentView.addSubview(signatureLabel)
        
        // Signature Instructions
        let signatureInstructionLabel = UILabel()
        signatureInstructionLabel.text = "Please sign with your finger or mouse to confirm your agreement."
        signatureInstructionLabel.font = .systemFont(ofSize: 14)
        signatureInstructionLabel.textColor = .systemGray
        signatureInstructionLabel.numberOfLines = 0
        signatureInstructionLabel.translatesAutoresizingMaskIntoConstraints = false
        signatureInstructionLabel.isHidden = !isSignatureEnabled
        self.signatureInstructionLabel = signatureInstructionLabel
        contentView.addSubview(signatureInstructionLabel)
        
        // Signature View Container
        let signatureContainer = UIView()
        signatureContainer.backgroundColor = .white
        signatureContainer.layer.borderWidth = 1
        signatureContainer.layer.borderColor = UIColor.systemGray3.cgColor
        signatureContainer.layer.cornerRadius = 8
        signatureContainer.translatesAutoresizingMaskIntoConstraints = false
        signatureContainer.isHidden = !isSignatureEnabled
        self.signatureContainer = signatureContainer
        contentView.addSubview(signatureContainer)
        
        signatureView.backgroundColor = .white
        signatureView.isUserInteractionEnabled = true // Ensure signature view can receive touches
        signatureView.translatesAutoresizingMaskIntoConstraints = false
        signatureContainer.addSubview(signatureView)
        
        // Clear Signature Button (X button in top right)
        clearSignatureButton.setTitle("✕", for: .normal)
        clearSignatureButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .bold)
        clearSignatureButton.setTitleColor(.systemRed, for: .normal)
        clearSignatureButton.backgroundColor = .white
        clearSignatureButton.layer.cornerRadius = 15
        clearSignatureButton.addTarget(self, action: #selector(clearSignatureTapped), for: .touchUpInside)
        clearSignatureButton.isHidden = true
        clearSignatureButton.translatesAutoresizingMaskIntoConstraints = false
        signatureContainer.addSubview(clearSignatureButton)
        
        // Complete Button
        completeButton.setTitle("Complete", for: .normal)
        completeButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        completeButton.backgroundColor = UIColor(red: 100/255.0, green: 104/255.0, blue: 254/255.0, alpha: 0.5) // RGB(100, 104, 254) disabled
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
            titleLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            titleLabel.leadingAnchor.constraint(greaterThanOrEqualTo: contentView.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -20),
            
            descriptionLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            descriptionLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            descriptionLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            loadingIndicator.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: 20),
            loadingIndicator.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            
            checkboxesStack.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: 20),
            checkboxesStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            checkboxesStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
        ])
        
        // Set signature label constraint based on whether terms is enabled
        if isTermsEnabled {
            NSLayoutConstraint.activate([
                signatureLabel.topAnchor.constraint(equalTo: checkboxesStack.bottomAnchor, constant: 32),
            ])
        } else {
            NSLayoutConstraint.activate([
                signatureLabel.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: 20),
            ])
        }
        
        NSLayoutConstraint.activate([
            signatureLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            signatureLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            signatureInstructionLabel.topAnchor.constraint(equalTo: signatureLabel.bottomAnchor, constant: 8),
            signatureInstructionLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            signatureInstructionLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            signatureContainer.topAnchor.constraint(equalTo: signatureInstructionLabel.bottomAnchor, constant: 12),
            signatureContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            signatureContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            signatureContainer.heightAnchor.constraint(equalToConstant: 200),
            
            signatureView.topAnchor.constraint(equalTo: signatureContainer.topAnchor),
            signatureView.leadingAnchor.constraint(equalTo: signatureContainer.leadingAnchor),
            signatureView.trailingAnchor.constraint(equalTo: signatureContainer.trailingAnchor),
            signatureView.bottomAnchor.constraint(equalTo: signatureContainer.bottomAnchor),
            
            clearSignatureButton.topAnchor.constraint(equalTo: signatureContainer.topAnchor, constant: 8),
            clearSignatureButton.trailingAnchor.constraint(equalTo: signatureContainer.trailingAnchor, constant: -8),
            clearSignatureButton.widthAnchor.constraint(equalToConstant: 30),
            clearSignatureButton.heightAnchor.constraint(equalToConstant: 30),
            
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
        if isSignatureEnabled {
            NSLayoutConstraint.activate([
                signatureContainer.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20)
            ])
        } else if isTermsEnabled {
            NSLayoutConstraint.activate([
                checkboxesStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20)
            ])
        } else {
            NSLayoutConstraint.activate([
                descriptionLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20)
            ])
        }
        
        signatureView.onSignatureChanged = { [weak self] hasSignature in
            self?.clearSignatureButton.isHidden = !hasSignature
            self?.updateCompleteButton()
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
                    // Notify delegate
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
    
    @objc private func clearSignatureTapped() {
        signatureView.clear()
    }
    
    private func updateCompleteButton() {
        var canComplete = true
        
        // Check if all required checkboxes are checked (only if terms is enabled)
        if isTermsEnabled {
            let requiredCheckboxes = checkboxes.filter { $0.isRequired }
            if !requiredCheckboxes.isEmpty {
                // If there are required checkboxes, all must be checked
                let allRequiredChecked = requiredCheckboxes.allSatisfy { checkboxStates[$0.id] == true }
                canComplete = canComplete && allRequiredChecked
            } else if !checkboxes.isEmpty {
                // If there are no required checkboxes but there are optional ones, at least one must be checked
                let atLeastOneChecked = checkboxStates.values.contains(true)
                canComplete = canComplete && atLeastOneChecked
            }
            // If no checkboxes at all, terms requirement is satisfied
        }
        
        // Check if signature is present (only if signature is enabled)
        if isSignatureEnabled {
            let hasSignature = signatureView.getSignatureImage() != nil
            canComplete = canComplete && hasSignature
        }
        
        completeButton.isEnabled = canComplete
        completeButton.backgroundColor = canComplete ? UIColor(red: 100/255.0, green: 104/255.0, blue: 254/255.0, alpha: 1.0) : UIColor(red: 100/255.0, green: 104/255.0, blue: 254/255.0, alpha: 0.5)
    }
    
    @objc private func completeTapped() {
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
                    guard let signatureImage = signatureView.getSignatureImage(),
                          let imageData = signatureImage.pngData() else {
                        await MainActor.run {
                            activityIndicator.stopAnimating()
                            completeButton.isEnabled = true
                            completeButton.setTitle("Continue", for: .normal)
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
                    completeButton.setTitle("Complete", for: .normal)
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

