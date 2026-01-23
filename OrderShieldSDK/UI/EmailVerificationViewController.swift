
import UIKit

@available(iOS 13.0, *)
class EmailVerificationViewController: UIViewController {
    private let sessionToken: String
    private let onComplete: () -> Void
    private let onError: ((Error) -> Void)?
    
    private var customerId: String? {
        return StorageService.shared.getCustomerId()
    }
    
    private var email: String?
    private var isCodeSent = false
    
    private var isEmailVerificationRequired: Bool {
        return StorageService.shared.getVerificationSettings()?.settings.emailVerificationRequired ?? true
    }
    
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    // Header and Footer
    private let headerView = OrderShieldHeaderView()
    private let footerView = OrderShieldFooterView()
    
    // Title
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    
    // Text Fields with Floating Labels
    private let emailContainerView = UIView()
    private let emailLabel = UILabel()
    private let emailTextField = UITextField()
    private let emailIconView = UIImageView()
    
    private let codeContainerView = UIView()
    private let codeLabel = UILabel()
    private let codeTextField = UITextField()
    
    private let continueButton = UIButton(type: .system)
    private let activityIndicator = UIActivityIndicatorView(style: .medium)
    
    private var continueButtonTopConstraint: NSLayoutConstraint?
    private let footerSpacerView = UIView()
    
    init(sessionToken: String, onComplete: @escaping () -> Void, onError: ((Error) -> Void)? = nil) {
        self.sessionToken = sessionToken
        self.onComplete = onComplete
        self.onError = onError
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.setNavigationBarHidden(true, animated: false)
        setupUI()
    }
    
    private func setupUI() {
        view.backgroundColor = .white
        
        // Scroll View
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsVerticalScrollIndicator = true
        scrollView.keyboardDismissMode = .interactive
        view.addSubview(scrollView)
        
        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)
        
        // Header View
        headerView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(headerView)
        
        // Title
        titleLabel.text = "Email Verification"
        titleLabel.font = .systemFont(ofSize: 24, weight: .bold)
        titleLabel.textColor = .black
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(titleLabel)
        
        // Subtitle
        subtitleLabel.text = "Verify user email address via link or code"
        subtitleLabel.font = .systemFont(ofSize: 14)
        subtitleLabel.textColor = .systemGray
        subtitleLabel.textAlignment = .center
        subtitleLabel.numberOfLines = 0
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(subtitleLabel)
        
        // Email Label (above input, not floating)
        emailLabel.text = "Email*"
        emailLabel.font = .systemFont(ofSize: 12)
        emailLabel.textColor = .systemGray
        emailLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(emailLabel)
        
        // Email Container
        emailContainerView.translatesAutoresizingMaskIntoConstraints = false
        emailContainerView.layer.borderWidth = 1.0
        emailContainerView.layer.borderColor = UIColor.black.cgColor
        emailContainerView.layer.cornerRadius = 8
        emailContainerView.backgroundColor = .white
        contentView.addSubview(emailContainerView)
        
        // Email Icon
        emailIconView.image = UIImage(systemName: "envelope.fill")
        emailIconView.tintColor = .black
        emailIconView.contentMode = .scaleAspectFit
        emailIconView.translatesAutoresizingMaskIntoConstraints = false
        emailContainerView.addSubview(emailIconView)
        
        // Email Text Field
        emailTextField.placeholder = "abcd@gmail.com"
        emailTextField.borderStyle = .none
        emailTextField.keyboardType = .emailAddress
        emailTextField.autocapitalizationType = .none
        emailTextField.autocorrectionType = .no
        emailTextField.backgroundColor = .clear
        emailTextField.font = .systemFont(ofSize: 16)
        emailTextField.returnKeyType = .done
        emailTextField.translatesAutoresizingMaskIntoConstraints = false
        emailContainerView.addSubview(emailTextField)
        
        // Code Label (above input, not floating, hidden initially)
        codeLabel.text = "Verification Code*"
        codeLabel.font = .systemFont(ofSize: 12)
        codeLabel.textColor = .systemGray
        codeLabel.isHidden = true
        codeLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(codeLabel)
        
        // Code Container (hidden initially)
        codeContainerView.translatesAutoresizingMaskIntoConstraints = false
        codeContainerView.layer.borderWidth = 1.0
        codeContainerView.layer.borderColor = UIColor.black.cgColor
        codeContainerView.layer.cornerRadius = 8
        codeContainerView.backgroundColor = .white
        codeContainerView.isHidden = true
        contentView.addSubview(codeContainerView)
        
        // Code Text Field
        codeTextField.placeholder = "Enter code"
        codeTextField.borderStyle = .none
        codeTextField.keyboardType = .numberPad
        codeTextField.backgroundColor = .clear
        codeTextField.font = .systemFont(ofSize: 16)
        codeTextField.isSecureTextEntry = true
        codeTextField.translatesAutoresizingMaskIntoConstraints = false
        codeContainerView.addSubview(codeTextField)
        
        // Add Done button toolbar for code text field
        let codeToolbar = UIToolbar()
        codeToolbar.sizeToFit()
        let codeDoneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(codeTextFieldDone))
        let codeFlexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        codeToolbar.setItems([codeFlexSpace, codeDoneButton], animated: false)
        codeTextField.inputAccessoryView = codeToolbar
        
        // Continue Button (black) - inside scroll view
        continueButton.setTitle("Continue", for: .normal)
        continueButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        continueButton.backgroundColor = .black
        continueButton.setTitleColor(.white, for: .normal)
        continueButton.setTitleColor(.white.withAlphaComponent(0.5), for: .disabled)
        continueButton.layer.cornerRadius = 12
        continueButton.isEnabled = false
        continueButton.addTarget(self, action: #selector(continueTapped), for: .touchUpInside)
        continueButton.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(continueButton)
        
        // Footer Spacer (pushes footer to bottom)
        footerSpacerView.translatesAutoresizingMaskIntoConstraints = false
        footerSpacerView.setContentHuggingPriority(.defaultLow, for: .vertical)
        footerSpacerView.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        contentView.addSubview(footerSpacerView)
        
        // Footer View
        footerView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(footerView)
        
        // Arrow Icon on Button
        let arrowIcon = UIImageView(image: UIImage(systemName: "arrow.right"))
        arrowIcon.tintColor = .white
        arrowIcon.contentMode = .scaleAspectFit
        arrowIcon.translatesAutoresizingMaskIntoConstraints = false
        continueButton.addSubview(arrowIcon)
        
        // Activity Indicator
        activityIndicator.hidesWhenStopped = true
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(activityIndicator)
        
        NSLayoutConstraint.activate([
            // Scroll View
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // Content View
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            // Header View
            headerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 40),
            headerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            
            // Title
            titleLabel.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 40),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            // Subtitle
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            subtitleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            subtitleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            // Email Label (above input)
            emailLabel.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 24),
            emailLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            
            // Email Container
            emailContainerView.topAnchor.constraint(equalTo: emailLabel.bottomAnchor, constant: 8),
            emailContainerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            emailContainerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            emailContainerView.heightAnchor.constraint(equalToConstant: 56),
            
            // Email Icon
            emailIconView.leadingAnchor.constraint(equalTo: emailContainerView.leadingAnchor, constant: 16),
            emailIconView.centerYAnchor.constraint(equalTo: emailContainerView.centerYAnchor, constant: 4),
            emailIconView.widthAnchor.constraint(equalToConstant: 20),
            emailIconView.heightAnchor.constraint(equalToConstant: 20),
            
            // Email Text Field
            emailTextField.topAnchor.constraint(equalTo: emailContainerView.topAnchor, constant: 8),
            emailTextField.leadingAnchor.constraint(equalTo: emailIconView.trailingAnchor, constant: 12),
            emailTextField.trailingAnchor.constraint(equalTo: emailContainerView.trailingAnchor, constant: -16),
            emailTextField.bottomAnchor.constraint(equalTo: emailContainerView.bottomAnchor, constant: -8),
            
            // Code Label (above input)
            codeLabel.topAnchor.constraint(equalTo: emailContainerView.bottomAnchor, constant: 24),
            codeLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            
            // Code Container
            codeContainerView.topAnchor.constraint(equalTo: codeLabel.bottomAnchor, constant: 8),
            codeContainerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            codeContainerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            codeContainerView.heightAnchor.constraint(equalToConstant: 56),
            
            // Code Text Field
            codeTextField.topAnchor.constraint(equalTo: codeContainerView.topAnchor, constant: 8),
            codeTextField.leadingAnchor.constraint(equalTo: codeContainerView.leadingAnchor, constant: 16),
            codeTextField.trailingAnchor.constraint(equalTo: codeContainerView.trailingAnchor, constant: -16),
            codeTextField.bottomAnchor.constraint(equalTo: codeContainerView.bottomAnchor, constant: -8),
            
            // Continue Button (after inputs - initially after email, will update when code is shown)
            continueButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            continueButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            continueButton.heightAnchor.constraint(equalToConstant: 56),
            
            // Footer Spacer (pushes footer to bottom - expands to fill space)
            footerSpacerView.topAnchor.constraint(equalTo: continueButton.bottomAnchor, constant: 40),
            footerSpacerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            footerSpacerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            footerSpacerView.bottomAnchor.constraint(equalTo: footerView.topAnchor),
            
            // Footer View (at bottom of content view)
            footerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            footerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            footerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20),
            
            arrowIcon.trailingAnchor.constraint(equalTo: continueButton.trailingAnchor, constant: -20),
            arrowIcon.centerYAnchor.constraint(equalTo: continueButton.centerYAnchor),
            arrowIcon.widthAnchor.constraint(equalToConstant: 20),
            arrowIcon.heightAnchor.constraint(equalToConstant: 20),
            
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        
        emailTextField.addTarget(self, action: #selector(textFieldChanged), for: .editingChanged)
        codeTextField.addTarget(self, action: #selector(textFieldChanged), for: .editingChanged)
        
        // Set text field delegates for keyboard handling
        emailTextField.delegate = self
        codeTextField.delegate = self
        
        // Set initial button position (after email field)
        continueButtonTopConstraint = continueButton.topAnchor.constraint(equalTo: emailContainerView.bottomAnchor, constant: 32)
        continueButtonTopConstraint?.isActive = true
        
        // Add tap gesture to dismiss keyboard
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    @objc private func textFieldChanged() {
        if isCodeSent {
            let hasCode = !(codeTextField.text?.isEmpty ?? true)
            continueButton.isEnabled = hasCode
            continueButton.backgroundColor = hasCode ? .black : .black.withAlphaComponent(0.5)
        } else {
            let hasEmail = isValidEmail(emailTextField.text ?? "")
            continueButton.isEnabled = hasEmail
            continueButton.backgroundColor = hasEmail ? .black : .black.withAlphaComponent(0.5)
        }
    }
    
    @objc private func continueTapped() {
        if !isCodeSent {
            sendEmailCode()
        } else {
            verifyEmailCode()
        }
    }
    
    private func sendEmailCode() {
        guard let email = emailTextField.text, isValidEmail(email) else {
            showError("Please enter a valid email address")
            return
        }
        
        guard let customerId = customerId else {
            showError("Customer ID not found")
            return
        }
        
        self.email = email
        continueButton.isEnabled = false
        continueButton.setTitle("Sending...", for: .normal)
        activityIndicator.startAnimating()
        
        Task {
            do {
                let request = EmailSendCodeRequest(
                    customerId: customerId,
                    sessionToken: sessionToken,
                    email: email
                )
                
                _ = try await NetworkService.shared.sendEmailCode(request)
                
                await MainActor.run {
                    activityIndicator.stopAnimating()
                    
                    // If email verification is not required, skip OTP verification and move to next step
                    if !isEmailVerificationRequired {
                        onComplete()
                        return
                    }
                    
                    // Otherwise, show OTP input field
                    isCodeSent = true
                    codeLabel.isHidden = false
                    codeContainerView.isHidden = false
                    emailTextField.isEnabled = false
                    continueButton.setTitle("Verify", for: .normal)
                    continueButton.isEnabled = false
                    
                    // Update button position to be below code field
                    continueButtonTopConstraint?.isActive = false
                    continueButtonTopConstraint = continueButton.topAnchor.constraint(equalTo: codeContainerView.bottomAnchor, constant: 32)
                    continueButtonTopConstraint?.isActive = true
                    
                    UIView.animate(withDuration: 0.3) {
                        self.view.layoutIfNeeded()
                    }
                    view.endEditing(true)
                }
            } catch {
                await MainActor.run {
                    activityIndicator.stopAnimating()
                    continueButton.isEnabled = true
                    continueButton.setTitle("Continue", for: .normal)
                    // Show the actual error message from API
                    let errorMessage = error.localizedDescription
                    showError(errorMessage)
                    onError?(error)
                }
            }
        }
    }
    
    private func verifyEmailCode() {
        guard let email = email,
              let code = codeTextField.text, !code.isEmpty else {
            showError("Please enter the verification code")
            return
        }
        
        guard let customerId = customerId else {
            showError("Customer ID not found")
            return
        }
        
        continueButton.isEnabled = false
        continueButton.setTitle("Verifying...", for: .normal)
        activityIndicator.startAnimating()
        
        Task {
            do {
                let request = EmailVerifyCodeRequest(
                    customerId: customerId,
                    sessionToken: sessionToken,
                    email: email,
                    verificationCode: code
                )
                
                _ = try await NetworkService.shared.verifyEmailCode(request)
                
                await MainActor.run {
                    activityIndicator.stopAnimating()
                    onComplete()
                }
            } catch {
                await MainActor.run {
                    activityIndicator.stopAnimating()
                    continueButton.isEnabled = true
                    continueButton.setTitle("Verify", for: .normal)
                    // Show the actual error message from API
                    let errorMessage = error.localizedDescription
                    showError(errorMessage)
                    onError?(error)
                }
            }
        }
    }
    
    @objc private func codeTextFieldDone() {
        codeTextField.resignFirstResponder()
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    private func showError(_ message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UITextFieldDelegate
extension EmailVerificationViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        // Scroll to make text field visible when keyboard appears
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            let rect = textField.convert(textField.bounds, to: self.scrollView)
            self.scrollView.scrollRectToVisible(rect, animated: true)
        }
    }
}

