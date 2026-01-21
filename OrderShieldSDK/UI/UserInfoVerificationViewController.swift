import UIKit

@available(iOS 13.0, *)
class UserInfoVerificationViewController: UIViewController {
    private let sessionToken: String
    private let onComplete: () -> Void
    private let onError: ((Error) -> Void)?
    private weak var delegate: OrderShieldDelegate?
    
    private var customerId: String? {
        return StorageService.shared.getCustomerId()
    }
    
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    private let userInfoSection = UIView()
    private let userInfoIcon = UILabel()
    private let userInfoTitleLabel = UILabel()
    private let userInfoSubtitleLabel = UILabel()
    
    private let firstNameLabel = UILabel()
    private let firstNameTextField = UITextField()
    private let lastNameLabel = UILabel()
    private let lastNameTextField = UITextField()
    private let dateOfBirthLabel = UILabel()
    private let dateOfBirthTextField = UITextField()
    private let datePicker = UIDatePicker()
    
    private let privacyProtectedView = UIView()
    private let privacyIcon = UILabel()
    private let privacyTitleLabel = UILabel()
    private let privacySubtitleLabel = UILabel()
    
    private let continueButton = UIButton(type: .system)
    private let activityIndicator = UIActivityIndicatorView(style: .medium)
    
    private var currentStep: Int = 1
    private var totalSteps: Int = 2
    
    init(sessionToken: String, currentStep: Int, totalSteps: Int, onComplete: @escaping () -> Void, onError: ((Error) -> Void)? = nil, delegate: OrderShieldDelegate? = nil) {
        self.sessionToken = sessionToken
        self.currentStep = currentStep
        self.totalSteps = totalSteps
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
    }
    
    private func setupUI() {
        view.backgroundColor = .white // Match other screens
        
        // Scroll View
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsVerticalScrollIndicator = true // Enable scroll indicator
        scrollView.keyboardDismissMode = .interactive // Allow dismissing keyboard by scrolling
        view.addSubview(scrollView)
        
        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)
        
        // White Card Container
        let cardView = UIView()
        cardView.backgroundColor = .white
        cardView.layer.cornerRadius = 12
        cardView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(cardView)
        
        // User Information Section
        userInfoSection.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(userInfoSection)
        
        // User Info Icon
        userInfoIcon.text = "👤"
        userInfoIcon.font = .systemFont(ofSize: 24)
        userInfoIcon.translatesAutoresizingMaskIntoConstraints = false
        userInfoSection.addSubview(userInfoIcon)
        
        // User Info Title
        userInfoTitleLabel.text = "User Information"
        userInfoTitleLabel.font = .systemFont(ofSize: 18, weight: .bold)
        userInfoTitleLabel.textColor = .black
        userInfoTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        userInfoSection.addSubview(userInfoTitleLabel)
        
        // User Info Subtitle
        userInfoSubtitleLabel.text = "Please provide your personal information"
        userInfoSubtitleLabel.font = .systemFont(ofSize: 14)
        userInfoSubtitleLabel.textColor = .systemGray
        userInfoSubtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        userInfoSection.addSubview(userInfoSubtitleLabel)
        
        // First Name Label
        firstNameLabel.text = "First Name*"
        firstNameLabel.font = .systemFont(ofSize: 14, weight: .medium)
        firstNameLabel.textColor = .black
        firstNameLabel.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(firstNameLabel)
        
        // First Name Text Field
        firstNameTextField.placeholder = "Enter First Name"
        firstNameTextField.borderStyle = .roundedRect
        firstNameTextField.backgroundColor = .white
        firstNameTextField.layer.borderWidth = 1
        firstNameTextField.layer.borderColor = UIColor.systemGray4.cgColor
        firstNameTextField.layer.cornerRadius = 8
        firstNameTextField.font = .systemFont(ofSize: 16)
        firstNameTextField.autocapitalizationType = .words
        firstNameTextField.autocorrectionType = .no
        firstNameTextField.returnKeyType = .next
        firstNameTextField.delegate = self
        firstNameTextField.translatesAutoresizingMaskIntoConstraints = false
        firstNameTextField.addTarget(self, action: #selector(textFieldChanged), for: .editingChanged)
        cardView.addSubview(firstNameTextField)
        
        // Last Name Label
        lastNameLabel.text = "Last Name*"
        lastNameLabel.font = .systemFont(ofSize: 14, weight: .medium)
        lastNameLabel.textColor = .black
        lastNameLabel.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(lastNameLabel)
        
        // Last Name Text Field
        lastNameTextField.placeholder = "Enter Last Name"
        lastNameTextField.borderStyle = .roundedRect
        lastNameTextField.backgroundColor = .white
        lastNameTextField.layer.borderWidth = 1
        lastNameTextField.layer.borderColor = UIColor.systemGray4.cgColor
        lastNameTextField.layer.cornerRadius = 8
        lastNameTextField.font = .systemFont(ofSize: 16)
        lastNameTextField.autocapitalizationType = .words
        lastNameTextField.autocorrectionType = .no
        lastNameTextField.returnKeyType = .next
        lastNameTextField.delegate = self
        lastNameTextField.translatesAutoresizingMaskIntoConstraints = false
        lastNameTextField.addTarget(self, action: #selector(textFieldChanged), for: .editingChanged)
        cardView.addSubview(lastNameTextField)
        
        // Date of Birth Label
        dateOfBirthLabel.text = "Date of Birth*"
        dateOfBirthLabel.font = .systemFont(ofSize: 14, weight: .medium)
        dateOfBirthLabel.textColor = .black
        dateOfBirthLabel.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(dateOfBirthLabel)
        
        // Date of Birth Text Field
        dateOfBirthTextField.placeholder = "mm/dd/yyyy"
        dateOfBirthTextField.borderStyle = .roundedRect
        dateOfBirthTextField.backgroundColor = .white
        dateOfBirthTextField.layer.borderWidth = 1
        dateOfBirthTextField.layer.borderColor = UIColor.systemGray4.cgColor
        dateOfBirthTextField.layer.cornerRadius = 8
        dateOfBirthTextField.font = .systemFont(ofSize: 16)
        dateOfBirthTextField.delegate = self
        dateOfBirthTextField.translatesAutoresizingMaskIntoConstraints = false
        dateOfBirthTextField.addTarget(self, action: #selector(textFieldChanged), for: .editingChanged)
        cardView.addSubview(dateOfBirthTextField)
        
        // Date Picker
        datePicker.datePickerMode = .date
        datePicker.preferredDatePickerStyle = .wheels
        datePicker.maximumDate = Date()
        datePicker.addTarget(self, action: #selector(datePickerChanged), for: .valueChanged)
        
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(datePickerDone))
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        toolbar.setItems([flexSpace, doneButton], animated: false)
        
        dateOfBirthTextField.inputView = datePicker
        dateOfBirthTextField.inputAccessoryView = toolbar
        
        // Calendar Icon
        let calendarIcon = UIImageView(image: UIImage(systemName: "calendar"))
        calendarIcon.tintColor = .systemGray
        calendarIcon.contentMode = .scaleAspectFit
        calendarIcon.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(calendarIcon)
        
        // Privacy Protected View
        privacyProtectedView.backgroundColor = UIColor(red: 0.9, green: 0.85, blue: 1.0, alpha: 1.0) // Light purple
        privacyProtectedView.layer.cornerRadius = 8
        privacyProtectedView.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(privacyProtectedView)
        
        privacyIcon.text = "🛡️"
        privacyIcon.font = .systemFont(ofSize: 20)
        privacyIcon.translatesAutoresizingMaskIntoConstraints = false
        privacyProtectedView.addSubview(privacyIcon)
        
        privacyTitleLabel.text = "Privacy protected"
        privacyTitleLabel.font = .systemFont(ofSize: 14, weight: .bold)
        privacyTitleLabel.textColor = .black
        privacyTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        privacyProtectedView.addSubview(privacyTitleLabel)
        
        privacySubtitleLabel.text = "Your information is securely stored and encrypted."
        privacySubtitleLabel.font = .systemFont(ofSize: 12)
        privacySubtitleLabel.textColor = .systemGray
        privacySubtitleLabel.numberOfLines = 0
        privacySubtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        privacyProtectedView.addSubview(privacySubtitleLabel)
        
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
        
        // Activity Indicator
        activityIndicator.hidesWhenStopped = true
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(activityIndicator)
        
        NSLayoutConstraint.activate([
            // Scroll View
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: continueButton.topAnchor, constant: -20),
            
            // Content View
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            // Card View
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            // User Info Section
            userInfoSection.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 24),
            userInfoSection.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 20),
            userInfoSection.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -20),
            
            userInfoIcon.leadingAnchor.constraint(equalTo: userInfoSection.leadingAnchor),
            userInfoIcon.topAnchor.constraint(equalTo: userInfoSection.topAnchor),
            
            userInfoTitleLabel.leadingAnchor.constraint(equalTo: userInfoIcon.trailingAnchor, constant: 12),
            userInfoTitleLabel.centerYAnchor.constraint(equalTo: userInfoIcon.centerYAnchor),
            userInfoTitleLabel.trailingAnchor.constraint(equalTo: userInfoSection.trailingAnchor),
            
            userInfoSubtitleLabel.topAnchor.constraint(equalTo: userInfoTitleLabel.bottomAnchor, constant: 4),
            userInfoSubtitleLabel.leadingAnchor.constraint(equalTo: userInfoTitleLabel.leadingAnchor),
            userInfoSubtitleLabel.trailingAnchor.constraint(equalTo: userInfoSection.trailingAnchor),
            userInfoSubtitleLabel.bottomAnchor.constraint(equalTo: userInfoSection.bottomAnchor),
            
            // First Name
            firstNameLabel.topAnchor.constraint(equalTo: userInfoSection.bottomAnchor, constant: 24),
            firstNameLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 20),
            firstNameLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -20),
            
            firstNameTextField.topAnchor.constraint(equalTo: firstNameLabel.bottomAnchor, constant: 8),
            firstNameTextField.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 20),
            firstNameTextField.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -20),
            firstNameTextField.heightAnchor.constraint(equalToConstant: 50),
            
            // Last Name
            lastNameLabel.topAnchor.constraint(equalTo: firstNameTextField.bottomAnchor, constant: 16),
            lastNameLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 20),
            lastNameLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -20),
            
            lastNameTextField.topAnchor.constraint(equalTo: lastNameLabel.bottomAnchor, constant: 8),
            lastNameTextField.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 20),
            lastNameTextField.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -20),
            lastNameTextField.heightAnchor.constraint(equalToConstant: 50),
            
            // Date of Birth
            dateOfBirthLabel.topAnchor.constraint(equalTo: lastNameTextField.bottomAnchor, constant: 16),
            dateOfBirthLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 20),
            dateOfBirthLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -20),
            
            dateOfBirthTextField.topAnchor.constraint(equalTo: dateOfBirthLabel.bottomAnchor, constant: 8),
            dateOfBirthTextField.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 20),
            dateOfBirthTextField.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -20),
            dateOfBirthTextField.heightAnchor.constraint(equalToConstant: 50),
            
            calendarIcon.trailingAnchor.constraint(equalTo: dateOfBirthTextField.trailingAnchor, constant: -12),
            calendarIcon.centerYAnchor.constraint(equalTo: dateOfBirthTextField.centerYAnchor),
            calendarIcon.widthAnchor.constraint(equalToConstant: 20),
            calendarIcon.heightAnchor.constraint(equalToConstant: 20),
            
            // Privacy Protected View
            privacyProtectedView.topAnchor.constraint(equalTo: dateOfBirthTextField.bottomAnchor, constant: 24),
            privacyProtectedView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 20),
            privacyProtectedView.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -20),
            
            privacyIcon.leadingAnchor.constraint(equalTo: privacyProtectedView.leadingAnchor, constant: 12),
            privacyIcon.topAnchor.constraint(equalTo: privacyProtectedView.topAnchor, constant: 12),
            
            privacyTitleLabel.leadingAnchor.constraint(equalTo: privacyIcon.trailingAnchor, constant: 12),
            privacyTitleLabel.topAnchor.constraint(equalTo: privacyProtectedView.topAnchor, constant: 12),
            privacyTitleLabel.trailingAnchor.constraint(equalTo: privacyProtectedView.trailingAnchor, constant: -12),
            
            privacySubtitleLabel.topAnchor.constraint(equalTo: privacyTitleLabel.bottomAnchor, constant: 4),
            privacySubtitleLabel.leadingAnchor.constraint(equalTo: privacyTitleLabel.leadingAnchor),
            privacySubtitleLabel.trailingAnchor.constraint(equalTo: privacyProtectedView.trailingAnchor, constant: -12),
            privacySubtitleLabel.bottomAnchor.constraint(equalTo: privacyProtectedView.bottomAnchor, constant: -12),
            
            // Card View bottom constraint (set to privacy protected view)
            cardView.bottomAnchor.constraint(equalTo: privacyProtectedView.bottomAnchor, constant: 20),
            
            // Content View bottom constraint (set to card view for proper scrolling)
            contentView.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: 20),
            
            // Continue Button
            continueButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            continueButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            continueButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            continueButton.heightAnchor.constraint(equalToConstant: 56),
            
            arrowIcon.trailingAnchor.constraint(equalTo: continueButton.trailingAnchor, constant: -20),
            arrowIcon.centerYAnchor.constraint(equalTo: continueButton.centerYAnchor),
            arrowIcon.widthAnchor.constraint(equalToConstant: 20),
            arrowIcon.heightAnchor.constraint(equalToConstant: 20),
            
            // Activity Indicator
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    @objc private func textFieldChanged() {
        let hasFirstName = !(firstNameTextField.text?.isEmpty ?? true)
        let hasLastName = !(lastNameTextField.text?.isEmpty ?? true)
        let hasDateOfBirth = !(dateOfBirthTextField.text?.isEmpty ?? true)
        
        let isValid = hasFirstName && hasLastName && hasDateOfBirth
        continueButton.isEnabled = isValid
        continueButton.backgroundColor = isValid ? UIColor(red: 100/255.0, green: 104/255.0, blue: 254/255.0, alpha: 1.0) : UIColor(red: 100/255.0, green: 104/255.0, blue: 254/255.0, alpha: 0.5)
    }
    
    @objc private func datePickerChanged() {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd/yyyy"
        dateOfBirthTextField.text = formatter.string(from: datePicker.date)
        textFieldChanged()
    }
    
    @objc private func datePickerDone() {
        dateOfBirthTextField.resignFirstResponder()
    }
    
    @objc private func continueTapped() {
        guard let firstName = firstNameTextField.text, !firstName.isEmpty,
              let lastName = lastNameTextField.text, !lastName.isEmpty,
              let dateOfBirth = dateOfBirthTextField.text, !dateOfBirth.isEmpty,
              let customerId = customerId else {
            showError("Please fill in all required fields")
            return
        }
        
        // Convert date format from MM/dd/yyyy to yyyy-MM-dd
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM/dd/yyyy"
        guard let date = dateFormatter.date(from: dateOfBirth) else {
            showError("Invalid date format")
            return
        }
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let formattedDate = dateFormatter.string(from: date)
        
        continueButton.isEnabled = false
        continueButton.setTitle("Submitting...", for: .normal)
        activityIndicator.startAnimating()
        
        Task {
            do {
                let request = UserInfoVerificationRequest(
                    customerId: customerId,
                    sessionToken: sessionToken,
                    firstName: firstName,
                    lastName: lastName,
                    dateOfBirth: formattedDate
                )
                
                _ = try await NetworkService.shared.submitUserInfo(request)
                
                await MainActor.run {
                    activityIndicator.stopAnimating()
                    // Notify delegate
                    delegate?.orderShieldDidSubmitUserInfo(success: true, firstName: firstName, lastName: lastName, dateOfBirth: formattedDate, error: nil)
                    onComplete()
                }
            } catch {
                await MainActor.run {
                    activityIndicator.stopAnimating()
                    continueButton.isEnabled = true
                    continueButton.setTitle("Continue", for: .normal)
                    // Notify delegate
                    delegate?.orderShieldDidSubmitUserInfo(success: false, firstName: nil, lastName: nil, dateOfBirth: nil, error: error)
                    showError("Failed to submit user information: \(error.localizedDescription)")
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

// MARK: - UITextFieldDelegate
extension UserInfoVerificationViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == firstNameTextField {
            lastNameTextField.becomeFirstResponder()
        } else if textField == lastNameTextField {
            dateOfBirthTextField.becomeFirstResponder()
        } else {
            textField.resignFirstResponder()
        }
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

