
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
    private let titleLabel = UILabel()
    private let instructionLabel = UILabel()
    private let emailTextField = UITextField()
    private let codeTextField = UITextField()
    private let continueButton = UIButton(type: .system)
    private let phoneIconView = UIView()
    private let activityIndicator = UIActivityIndicatorView(style: .medium)
    
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
        
        // Title
        titleLabel.text = "Verification Protection"
        titleLabel.font = .systemFont(ofSize: 18, weight: .medium)
        titleLabel.textColor = .black
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(titleLabel)
        
        // Icon
        phoneIconView.backgroundColor = .systemGray5
        phoneIconView.layer.cornerRadius = 50
        phoneIconView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(phoneIconView)
        
        let iconLabel = UILabel()
        iconLabel.text = "✉️"
        iconLabel.font = .systemFont(ofSize: 40)
        iconLabel.textAlignment = .center
        iconLabel.translatesAutoresizingMaskIntoConstraints = false
        phoneIconView.addSubview(iconLabel)
        
        NSLayoutConstraint.activate([
            iconLabel.centerXAnchor.constraint(equalTo: phoneIconView.centerXAnchor),
            iconLabel.centerYAnchor.constraint(equalTo: phoneIconView.centerYAnchor)
        ])
        
        // Main Title
        let mainTitleLabel = UILabel()
        mainTitleLabel.text = "Email Verification"
        mainTitleLabel.font = .systemFont(ofSize: 24, weight: .bold)
        mainTitleLabel.textColor = .black
        mainTitleLabel.textAlignment = .center
        mainTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(mainTitleLabel)
        
        // Instructions
        instructionLabel.text = "Please enter your email address to verify your identity.\nThis helps us ensure account security and prevent fraud."
        instructionLabel.font = .systemFont(ofSize: 14)
        instructionLabel.textColor = .systemGray
        instructionLabel.numberOfLines = 0
        instructionLabel.textAlignment = .left
        instructionLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(instructionLabel)
        
        // Email Text Field
        emailTextField.placeholder = "Enter your email"
        emailTextField.borderStyle = .roundedRect
        emailTextField.keyboardType = .emailAddress
        emailTextField.autocapitalizationType = .none
        emailTextField.autocorrectionType = .no
        emailTextField.backgroundColor = .systemGray6
        emailTextField.font = .systemFont(ofSize: 16)
        emailTextField.returnKeyType = .done
        emailTextField.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(emailTextField)
        
        // Code Text Field (hidden initially)
        codeTextField.placeholder = "Enter verification code"
        codeTextField.borderStyle = .roundedRect
        codeTextField.keyboardType = .numberPad
        codeTextField.backgroundColor = .systemGray6
        codeTextField.font = .systemFont(ofSize: 16)
        codeTextField.isHidden = true
        codeTextField.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(codeTextField)
        
        // Add Done button toolbar for code text field
        let codeToolbar = UIToolbar()
        codeToolbar.sizeToFit()
        let codeDoneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(codeTextFieldDone))
        let codeFlexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        codeToolbar.setItems([codeFlexSpace, codeDoneButton], animated: false)
        codeTextField.inputAccessoryView = codeToolbar
        
        // Continue Button
        continueButton.setTitle("Continue", for: .normal)
        continueButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        continueButton.backgroundColor = UIColor(red: 100/255.0, green: 104/255.0, blue: 254/255.0, alpha: 0.5) // RGB(100, 104, 254) disabled
        continueButton.setTitleColor(.white, for: .normal)
        continueButton.setTitleColor(.white.withAlphaComponent(0.5), for: .disabled)
        continueButton.layer.cornerRadius = 12
        continueButton.isEnabled = false
        continueButton.addTarget(self, action: #selector(continueTapped), for: .touchUpInside)
        continueButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(continueButton)
        
        // Arrow Icon on Button
        let arrowIcon = UIImageView(image: UIImage(systemName: "arrow.right"))
        arrowIcon.tintColor = .white
        arrowIcon.contentMode = .scaleAspectFit
        arrowIcon.translatesAutoresizingMaskIntoConstraints = false
        continueButton.addSubview(arrowIcon)
        
        // Disclaimer
        let disclaimerLabel = UILabel()
        disclaimerLabel.text = "We'll use this email for verification purposes only"
        disclaimerLabel.font = .systemFont(ofSize: 12)
        disclaimerLabel.textColor = .systemGray
        disclaimerLabel.textAlignment = .center
        disclaimerLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(disclaimerLabel)
        
        // Activity Indicator
        activityIndicator.hidesWhenStopped = true
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(activityIndicator)
        
        NSLayoutConstraint.activate([
            // Scroll View
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: continueButton.topAnchor, constant: -20),
            
            // Content View
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            phoneIconView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 40),
            phoneIconView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            phoneIconView.widthAnchor.constraint(equalToConstant: 100),
            phoneIconView.heightAnchor.constraint(equalToConstant: 100),
            
            mainTitleLabel.topAnchor.constraint(equalTo: phoneIconView.bottomAnchor, constant: 24),
            mainTitleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            mainTitleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            instructionLabel.topAnchor.constraint(equalTo: mainTitleLabel.bottomAnchor, constant: 16),
            instructionLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            instructionLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            emailTextField.topAnchor.constraint(equalTo: instructionLabel.bottomAnchor, constant: 24),
            emailTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            emailTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            emailTextField.heightAnchor.constraint(equalToConstant: 50),
            
            codeTextField.topAnchor.constraint(equalTo: emailTextField.bottomAnchor, constant: 16),
            codeTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            codeTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            codeTextField.heightAnchor.constraint(equalToConstant: 50),
            
            disclaimerLabel.topAnchor.constraint(equalTo: codeTextField.bottomAnchor, constant: 32),
            disclaimerLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            disclaimerLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            disclaimerLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20),
            
            // Continue Button (fixed at bottom, outside scroll view)
            continueButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            continueButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            continueButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            continueButton.heightAnchor.constraint(equalToConstant: 56),
            
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
    }
    
    @objc private func textFieldChanged() {
        if isCodeSent {
            let hasCode = !(codeTextField.text?.isEmpty ?? true)
            continueButton.isEnabled = hasCode
            continueButton.backgroundColor = hasCode ? UIColor(red: 100/255.0, green: 104/255.0, blue: 254/255.0, alpha: 1.0) : UIColor(red: 100/255.0, green: 104/255.0, blue: 254/255.0, alpha: 0.5)
        } else {
            let hasEmail = isValidEmail(emailTextField.text ?? "")
            continueButton.isEnabled = hasEmail
            continueButton.backgroundColor = hasEmail ? UIColor(red: 100/255.0, green: 104/255.0, blue: 254/255.0, alpha: 1.0) : UIColor(red: 100/255.0, green: 104/255.0, blue: 254/255.0, alpha: 0.5)
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
                    codeTextField.isHidden = false
                    emailTextField.isEnabled = false
                    continueButton.setTitle("Verify", for: .normal)
                    continueButton.isEnabled = false
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

