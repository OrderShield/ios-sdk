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
    
    // Header and Footer
    private let headerView = OrderShieldHeaderView()
    private let footerView = OrderShieldFooterView()
    
    // Title
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    
    // Text Input Fields
    private let firstNameLabel = UILabel()
    private let firstNameContainerView = UIView()
    private let firstNameTextField = UITextField()
    
    private let lastNameLabel = UILabel()
    private let lastNameContainerView = UIView()
    private let lastNameTextField = UITextField()
    
    private let dateOfBirthLabel = UILabel()
    private let dateOfBirthContainerView = UIView()
    private let dateOfBirthTextField = UITextField()
    private let datePicker = UIDatePicker()
    private let calendarIcon = UIImageView()
    
    private let continueButton = UIButton(type: .system)
    private let activityIndicator = UIActivityIndicatorView(style: .medium)
    
    private let footerSpacerView = UIView()
    
    private var currentStep: Int = 1
    private var totalSteps: Int = 2
    
    /// Optional prefill: when userInfo step is shown with partial predefined data, these values prefill the fields.
    private let prefilledFirstName: String?
    private let prefilledLastName: String?
    private let prefilledDateOfBirth: String?
    
    init(sessionToken: String, currentStep: Int, totalSteps: Int, onComplete: @escaping () -> Void, onError: ((Error) -> Void)? = nil, delegate: OrderShieldDelegate? = nil, prefilledFirstName: String? = nil, prefilledLastName: String? = nil, prefilledDateOfBirth: String? = nil) {
        self.sessionToken = sessionToken
        self.currentStep = currentStep
        self.totalSteps = totalSteps
        self.onComplete = onComplete
        self.onError = onError
        self.delegate = delegate
        self.prefilledFirstName = prefilledFirstName
        self.prefilledLastName = prefilledLastName
        self.prefilledDateOfBirth = prefilledDateOfBirth
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
        titleLabel.text = "User Information Verification"
        titleLabel.font = .systemFont(ofSize: 24, weight: .bold)
        titleLabel.textColor = .black
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(titleLabel)
        
        // Subtitle
        subtitleLabel.text = "Please provide your personal information"
        subtitleLabel.font = .systemFont(ofSize: 14)
        subtitleLabel.textColor = .systemGray
        subtitleLabel.textAlignment = .center
        subtitleLabel.numberOfLines = 0
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(subtitleLabel)
        
        // First Name Label (above input, not floating)
        firstNameLabel.text = "First Name*"
        firstNameLabel.font = .systemFont(ofSize: 12)
        firstNameLabel.textColor = .systemGray
        firstNameLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(firstNameLabel)
        
        // First Name Container
        firstNameContainerView.translatesAutoresizingMaskIntoConstraints = false
        firstNameContainerView.layer.borderWidth = 1.0
        firstNameContainerView.layer.borderColor = UIColor.black.cgColor
        firstNameContainerView.layer.cornerRadius = 8
        firstNameContainerView.backgroundColor = .white
        contentView.addSubview(firstNameContainerView)
        
        // First Name Text Field
        firstNameTextField.placeholder = "Enter First Name"
        firstNameTextField.borderStyle = .none
        firstNameTextField.autocapitalizationType = .words
        firstNameTextField.autocorrectionType = .no
        firstNameTextField.backgroundColor = .clear
        firstNameTextField.font = .systemFont(ofSize: 16)
        firstNameTextField.returnKeyType = .next
        firstNameTextField.delegate = self
        firstNameTextField.translatesAutoresizingMaskIntoConstraints = false
        firstNameTextField.addTarget(self, action: #selector(textFieldChanged), for: .editingChanged)
        firstNameContainerView.addSubview(firstNameTextField)
        
        // Last Name Label (above input, not floating)
        lastNameLabel.text = "Last Name*"
        lastNameLabel.font = .systemFont(ofSize: 12)
        lastNameLabel.textColor = .systemGray
        lastNameLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(lastNameLabel)
        
        // Last Name Container
        lastNameContainerView.translatesAutoresizingMaskIntoConstraints = false
        lastNameContainerView.layer.borderWidth = 1.0
        lastNameContainerView.layer.borderColor = UIColor.black.cgColor
        lastNameContainerView.layer.cornerRadius = 8
        lastNameContainerView.backgroundColor = .white
        contentView.addSubview(lastNameContainerView)
        
        // Last Name Text Field
        lastNameTextField.placeholder = "Enter Last Name"
        lastNameTextField.borderStyle = .none
        lastNameTextField.autocapitalizationType = .words
        lastNameTextField.autocorrectionType = .no
        lastNameTextField.backgroundColor = .clear
        lastNameTextField.font = .systemFont(ofSize: 16)
        lastNameTextField.returnKeyType = .next
        lastNameTextField.delegate = self
        lastNameTextField.translatesAutoresizingMaskIntoConstraints = false
        lastNameTextField.addTarget(self, action: #selector(textFieldChanged), for: .editingChanged)
        lastNameContainerView.addSubview(lastNameTextField)
        
        // Date of Birth Label (above input, not floating)
        dateOfBirthLabel.text = "Date of Birth*"
        dateOfBirthLabel.font = .systemFont(ofSize: 12)
        dateOfBirthLabel.textColor = .systemGray
        dateOfBirthLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(dateOfBirthLabel)
        
        // Date of Birth Container
        dateOfBirthContainerView.translatesAutoresizingMaskIntoConstraints = false
        dateOfBirthContainerView.layer.borderWidth = 1.0
        dateOfBirthContainerView.layer.borderColor = UIColor.black.cgColor
        dateOfBirthContainerView.layer.cornerRadius = 8
        dateOfBirthContainerView.backgroundColor = .white
        contentView.addSubview(dateOfBirthContainerView)
        
        // Date of Birth Text Field
        dateOfBirthTextField.placeholder = "mm/dd/yyyy"
        dateOfBirthTextField.borderStyle = .none
        dateOfBirthTextField.backgroundColor = .clear
        dateOfBirthTextField.font = .systemFont(ofSize: 16)
        dateOfBirthTextField.delegate = self
        dateOfBirthTextField.translatesAutoresizingMaskIntoConstraints = false
        dateOfBirthTextField.addTarget(self, action: #selector(textFieldChanged), for: .editingChanged)
        dateOfBirthContainerView.addSubview(dateOfBirthTextField)
        
        // Date Picker
        datePicker.datePickerMode = .date
        if #available(iOS 13.4, *) {
            datePicker.preferredDatePickerStyle = .wheels
        } else {
            datePicker.datePickerMode = .date
        }
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
        calendarIcon.image = UIImage(systemName: "calendar")
        calendarIcon.tintColor = .black
        calendarIcon.contentMode = .scaleAspectFit
        calendarIcon.translatesAutoresizingMaskIntoConstraints = false
        dateOfBirthContainerView.addSubview(calendarIcon)
        
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
            
            // First Name Label (above input)
            firstNameLabel.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 24),
            firstNameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            
            // First Name Container
            firstNameContainerView.topAnchor.constraint(equalTo: firstNameLabel.bottomAnchor, constant: 8),
            firstNameContainerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            firstNameContainerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            firstNameContainerView.heightAnchor.constraint(equalToConstant: 56),
            
            // First Name Text Field
            firstNameTextField.topAnchor.constraint(equalTo: firstNameContainerView.topAnchor, constant: 8),
            firstNameTextField.leadingAnchor.constraint(equalTo: firstNameContainerView.leadingAnchor, constant: 16),
            firstNameTextField.trailingAnchor.constraint(equalTo: firstNameContainerView.trailingAnchor, constant: -16),
            firstNameTextField.bottomAnchor.constraint(equalTo: firstNameContainerView.bottomAnchor, constant: -8),
            
            // Last Name Label (above input)
            lastNameLabel.topAnchor.constraint(equalTo: firstNameContainerView.bottomAnchor, constant: 24),
            lastNameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            
            // Last Name Container
            lastNameContainerView.topAnchor.constraint(equalTo: lastNameLabel.bottomAnchor, constant: 8),
            lastNameContainerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            lastNameContainerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            lastNameContainerView.heightAnchor.constraint(equalToConstant: 56),
            
            // Last Name Text Field
            lastNameTextField.topAnchor.constraint(equalTo: lastNameContainerView.topAnchor, constant: 8),
            lastNameTextField.leadingAnchor.constraint(equalTo: lastNameContainerView.leadingAnchor, constant: 16),
            lastNameTextField.trailingAnchor.constraint(equalTo: lastNameContainerView.trailingAnchor, constant: -16),
            lastNameTextField.bottomAnchor.constraint(equalTo: lastNameContainerView.bottomAnchor, constant: -8),
            
            // Date of Birth Label (above input)
            dateOfBirthLabel.topAnchor.constraint(equalTo: lastNameContainerView.bottomAnchor, constant: 24),
            dateOfBirthLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            
            // Date of Birth Container
            dateOfBirthContainerView.topAnchor.constraint(equalTo: dateOfBirthLabel.bottomAnchor, constant: 8),
            dateOfBirthContainerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            dateOfBirthContainerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            dateOfBirthContainerView.heightAnchor.constraint(equalToConstant: 56),
            
            // Date of Birth Text Field
            dateOfBirthTextField.topAnchor.constraint(equalTo: dateOfBirthContainerView.topAnchor, constant: 8),
            dateOfBirthTextField.leadingAnchor.constraint(equalTo: dateOfBirthContainerView.leadingAnchor, constant: 16),
            dateOfBirthTextField.trailingAnchor.constraint(equalTo: calendarIcon.leadingAnchor, constant: -12),
            dateOfBirthTextField.bottomAnchor.constraint(equalTo: dateOfBirthContainerView.bottomAnchor, constant: -8),
            
            // Calendar Icon
            calendarIcon.trailingAnchor.constraint(equalTo: dateOfBirthContainerView.trailingAnchor, constant: -16),
            calendarIcon.centerYAnchor.constraint(equalTo: dateOfBirthContainerView.centerYAnchor),
            calendarIcon.widthAnchor.constraint(equalToConstant: 20),
            calendarIcon.heightAnchor.constraint(equalToConstant: 20),
            
            // Continue Button (after inputs)
            continueButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            continueButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            continueButton.heightAnchor.constraint(equalToConstant: 56),
            continueButton.topAnchor.constraint(equalTo: dateOfBirthContainerView.bottomAnchor, constant: 32),
            
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
            
            // Activity Indicator
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        
        // Set text field delegates for keyboard handling
        firstNameTextField.delegate = self
        lastNameTextField.delegate = self
        dateOfBirthTextField.delegate = self
        
        // Add tap gesture to dismiss keyboard
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
        
        applyPrefilledValues()
    }
    
    /// Prefill fields from predefined data when only partial data was provided (so we show the screen but with available values).
    private func applyPrefilledValues() {
        if let fn = prefilledFirstName?.trimmingCharacters(in: .whitespacesAndNewlines), !fn.isEmpty {
            firstNameTextField.text = fn
        }
        if let ln = prefilledLastName?.trimmingCharacters(in: .whitespacesAndNewlines), !ln.isEmpty {
            lastNameTextField.text = ln
        }
        if let dob = prefilledDateOfBirth?.trimmingCharacters(in: .whitespacesAndNewlines), !dob.isEmpty {
            let displayDOB = dateOfBirthDisplayString(from: dob)
            dateOfBirthTextField.text = displayDOB
            if let date = parseDateOfBirth(displayDOB) {
                datePicker.date = date
            }
        }
        textFieldChanged()
    }
    
    /// Converts yyyy-MM-dd or MM/dd/yyyy to MM/dd/yyyy for display in the text field.
    private func dateOfBirthDisplayString(from value: String) -> String {
        let inIso = DateFormatter()
        inIso.dateFormat = "yyyy-MM-dd"
        let inMmDd = DateFormatter()
        inMmDd.dateFormat = "MM/dd/yyyy"
        let outMmDd = DateFormatter()
        outMmDd.dateFormat = "MM/dd/yyyy"
        if let date = inIso.date(from: value) {
            return outMmDd.string(from: date)
        }
        if let date = inMmDd.date(from: value) {
            return outMmDd.string(from: date)
        }
        return value
    }
    
    private func parseDateOfBirth(_ value: String) -> Date? {
        let iso = DateFormatter()
        iso.dateFormat = "yyyy-MM-dd"
        let mmddyyyy = DateFormatter()
        mmddyyyy.dateFormat = "MM/dd/yyyy"
        return iso.date(from: value) ?? mmddyyyy.date(from: value)
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    @objc private func textFieldChanged() {
        let hasFirstName = !(firstNameTextField.text?.isEmpty ?? true)
        let hasLastName = !(lastNameTextField.text?.isEmpty ?? true)
        let hasDateOfBirth = !(dateOfBirthTextField.text?.isEmpty ?? true)
        
        let isValid = hasFirstName && hasLastName && hasDateOfBirth
        continueButton.isEnabled = isValid
        continueButton.backgroundColor = isValid ? .black : .black.withAlphaComponent(0.5)
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

