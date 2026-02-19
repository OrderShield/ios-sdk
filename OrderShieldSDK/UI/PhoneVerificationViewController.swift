
import UIKit

@available(iOS 13.0, *)
class PhoneVerificationViewController: UIViewController {
    private let sessionToken: String
    private let onComplete: () -> Void
    private let onError: ((Error) -> Void)?
    
    private var customerId: String? {
        return StorageService.shared.getCustomerId()
    }
    
    private var phoneNumber: String?
    private var isCodeSent = false
    
    private var isSmsVerificationRequired: Bool {
        return StorageService.shared.getVerificationSettings()?.settings.smsVerificationRequired ?? true
    }
    
    private var selectedCountry: Country {
        didSet {
            updateCountryButton()
        }
    }
    
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    // Header and Footer
    private let headerView = OrderShieldHeaderView()
    private let footerView = OrderShieldFooterView()
    
    // Title
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    
    // Phone Input
    private let phoneLabel = UILabel()
    private let phoneContainerView = UIView()
    private let countryCodeButton = UIButton(type: .system)
    private let phoneTextField = UITextField()
    
    // Code Input
    private let codeLabel = UILabel()
    private let codeContainerView = UIView()
    private let codeTextField = UITextField()
    
    private let continueButton = UIButton(type: .system)
    private let activityIndicator = UIActivityIndicatorView(style: .medium)
    private let countryPickerView = UIPickerView()
    private let pickerToolbar = UIToolbar()
    private var pickerContainerView: UIView?
    private var pickerBottomConstraint: NSLayoutConstraint?
    
    private var continueButtonTopConstraint: NSLayoutConstraint?
    private let footerSpacerView = UIView()
    
    init(sessionToken: String, onComplete: @escaping () -> Void, onError: ((Error) -> Void)? = nil) {
        self.sessionToken = sessionToken
        self.onComplete = onComplete
        self.onError = onError
        // Default to United States
        self.selectedCountry = CountryData.getDefaultCountry()
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
        titleLabel.text = "SMS Verification"
        titleLabel.font = .systemFont(ofSize: 24, weight: .bold)
        titleLabel.textColor = .black
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(titleLabel)
        
        // Subtitle
        subtitleLabel.text = "Verify user phone number via SMS"
        subtitleLabel.font = .systemFont(ofSize: 14)
        subtitleLabel.textColor = .systemGray
        subtitleLabel.textAlignment = .center
        subtitleLabel.numberOfLines = 0
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(subtitleLabel)
        
        // Phone Label (above input, not floating)
        phoneLabel.text = "Phone Number*"
        phoneLabel.font = .systemFont(ofSize: 12)
        phoneLabel.textColor = .systemGray
        phoneLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(phoneLabel)
        
        // Phone Container
        phoneContainerView.translatesAutoresizingMaskIntoConstraints = false
        phoneContainerView.layer.borderWidth = 1.0
        phoneContainerView.layer.borderColor = UIColor.black.cgColor
        phoneContainerView.layer.cornerRadius = 8
        phoneContainerView.backgroundColor = .white
        contentView.addSubview(phoneContainerView)
        
        // Country Code Button
        countryCodeButton.backgroundColor = .clear
        countryCodeButton.layer.cornerRadius = 8
        countryCodeButton.titleLabel?.font = .systemFont(ofSize: 16)
        countryCodeButton.setTitleColor(.black, for: .normal)
        countryCodeButton.contentHorizontalAlignment = .left
        countryCodeButton.titleEdgeInsets = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 30)
        countryCodeButton.addTarget(self, action: #selector(countryCodeButtonTapped), for: .touchUpInside)
        countryCodeButton.translatesAutoresizingMaskIntoConstraints = false
        updateCountryButton()
        phoneContainerView.addSubview(countryCodeButton)
        
        // Add chevron icon to country button
        let chevronImageView = UIImageView(image: UIImage(systemName: "chevron.down"))
        chevronImageView.tintColor = .black
        chevronImageView.contentMode = .scaleAspectFit
        chevronImageView.translatesAutoresizingMaskIntoConstraints = false
        countryCodeButton.addSubview(chevronImageView)
        
        NSLayoutConstraint.activate([
            chevronImageView.trailingAnchor.constraint(equalTo: countryCodeButton.trailingAnchor, constant: -12),
            chevronImageView.centerYAnchor.constraint(equalTo: countryCodeButton.centerYAnchor),
            chevronImageView.widthAnchor.constraint(equalToConstant: 12),
            chevronImageView.heightAnchor.constraint(equalToConstant: 12)
        ])
        
        // Phone Text Field
        phoneTextField.placeholder = "Enter phone number"
        phoneTextField.borderStyle = .none
        phoneTextField.keyboardType = .phonePad
        phoneTextField.autocapitalizationType = .none
        phoneTextField.autocorrectionType = .no
        phoneTextField.backgroundColor = .clear
        phoneTextField.font = .systemFont(ofSize: 16)
        phoneTextField.returnKeyType = .done
        phoneTextField.translatesAutoresizingMaskIntoConstraints = false
        phoneContainerView.addSubview(phoneTextField)
        
        // Add Done button toolbar for phone text field
        let phoneToolbar = UIToolbar()
        phoneToolbar.sizeToFit()
        let phoneDoneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(phoneTextFieldDone))
        let phoneFlexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        phoneToolbar.setItems([phoneFlexSpace, phoneDoneButton], animated: false)
        phoneTextField.inputAccessoryView = phoneToolbar
        
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
            
            // Phone Label (above input)
            phoneLabel.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 24),
            phoneLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            
            // Phone Container
            phoneContainerView.topAnchor.constraint(equalTo: phoneLabel.bottomAnchor, constant: 8),
            phoneContainerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            phoneContainerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            phoneContainerView.heightAnchor.constraint(equalToConstant: 56),
            
            // Country Code Button
            countryCodeButton.leadingAnchor.constraint(equalTo: phoneContainerView.leadingAnchor),
            countryCodeButton.centerYAnchor.constraint(equalTo: phoneContainerView.centerYAnchor, constant: 4),
            countryCodeButton.widthAnchor.constraint(equalToConstant: 100),
            countryCodeButton.heightAnchor.constraint(equalToConstant: 40),
            
            // Phone Text Field
            phoneTextField.topAnchor.constraint(equalTo: phoneContainerView.topAnchor, constant: 8),
            phoneTextField.leadingAnchor.constraint(equalTo: countryCodeButton.trailingAnchor, constant: 12),
            phoneTextField.trailingAnchor.constraint(equalTo: phoneContainerView.trailingAnchor, constant: -16),
            phoneTextField.bottomAnchor.constraint(equalTo: phoneContainerView.bottomAnchor, constant: -8),
            
            // Code Label (above input)
            codeLabel.topAnchor.constraint(equalTo: phoneContainerView.bottomAnchor, constant: 24),
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
            
            // Continue Button (after inputs - initially after phone, will update when code is shown)
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
        
        phoneTextField.addTarget(self, action: #selector(textFieldChanged), for: .editingChanged)
        codeTextField.addTarget(self, action: #selector(textFieldChanged), for: .editingChanged)
        
        // Set text field delegates for keyboard handling
        phoneTextField.delegate = self
        codeTextField.delegate = self
        
        // Set initial button position (after phone field)
        continueButtonTopConstraint = continueButton.topAnchor.constraint(equalTo: phoneContainerView.bottomAnchor, constant: 32)
        continueButtonTopConstraint?.isActive = true
        
        // Setup country picker
        setupCountryPicker()
        
        // Add tap gesture to dismiss keyboard
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    private func setupCountryPicker() {
        countryPickerView.delegate = self
        countryPickerView.dataSource = self
        countryPickerView.backgroundColor = .systemBackground
        
        // Find default country index (United States)
        if let defaultIndex = CountryData.countries.firstIndex(where: { $0.code == "US" }) {
            countryPickerView.selectRow(defaultIndex, inComponent: 0, animated: false)
        }
        
        // Setup toolbar
        pickerToolbar.barStyle = .default
        pickerToolbar.isTranslucent = true
        pickerToolbar.sizeToFit()
        
        let doneButton = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(pickerDoneTapped))
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let cancelButton = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(pickerCancelTapped))
        
        pickerToolbar.setItems([cancelButton, flexSpace, doneButton], animated: false)
        pickerToolbar.isUserInteractionEnabled = true
    }
    
    private func updateCountryButton() {
        let title = "\(selectedCountry.flag) \(selectedCountry.dialCode)"
        countryCodeButton.setTitle(title, for: .normal)
    }
    
    @objc private func countryCodeButtonTapped() {
        view.endEditing(true)
        
        // If picker is already showing, hide it
        if pickerContainerView != nil {
            hideCountryPicker()
            return
        }
        
        // Create overlay
        let overlayView = UIView()
        overlayView.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        overlayView.alpha = 0
        overlayView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(overlayView)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(hideCountryPicker))
        overlayView.addGestureRecognizer(tapGesture)
        
        // Create picker container
        let pickerContainer = UIView()
        pickerContainer.backgroundColor = .systemBackground
        pickerContainer.layer.cornerRadius = 16
        pickerContainer.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        pickerContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(pickerContainer)
        self.pickerContainerView = pickerContainer
        
        pickerContainer.addSubview(pickerToolbar)
        pickerContainer.addSubview(countryPickerView)
        
        countryPickerView.translatesAutoresizingMaskIntoConstraints = false
        pickerToolbar.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            overlayView.topAnchor.constraint(equalTo: view.topAnchor),
            overlayView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            overlayView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            overlayView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            pickerToolbar.topAnchor.constraint(equalTo: pickerContainer.topAnchor),
            pickerToolbar.leadingAnchor.constraint(equalTo: pickerContainer.leadingAnchor),
            pickerToolbar.trailingAnchor.constraint(equalTo: pickerContainer.trailingAnchor),
            pickerToolbar.heightAnchor.constraint(equalToConstant: 44),
            
            countryPickerView.topAnchor.constraint(equalTo: pickerToolbar.bottomAnchor),
            countryPickerView.leadingAnchor.constraint(equalTo: pickerContainer.leadingAnchor),
            countryPickerView.trailingAnchor.constraint(equalTo: pickerContainer.trailingAnchor),
            countryPickerView.bottomAnchor.constraint(equalTo: pickerContainer.bottomAnchor),
            countryPickerView.heightAnchor.constraint(equalToConstant: 216),
            
            pickerContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            pickerContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            pickerContainer.heightAnchor.constraint(equalToConstant: 260)
        ])
        
        // Position picker off-screen initially
        let bottomConstraint = pickerContainer.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 260)
        bottomConstraint.isActive = true
        pickerBottomConstraint = bottomConstraint
        view.layoutIfNeeded()
        
        // Select current country in picker
        if let currentIndex = CountryData.countries.firstIndex(where: { $0.code == selectedCountry.code }) {
            countryPickerView.selectRow(currentIndex, inComponent: 0, animated: false)
        }
        
        // Animate in
        UIView.animate(withDuration: 0.3) {
            overlayView.alpha = 1
            bottomConstraint.constant = 0
            self.view.layoutIfNeeded()
        }
    }
    
    @objc private func hideCountryPicker() {
        guard let pickerContainer = pickerContainerView,
              let bottomConstraint = pickerBottomConstraint else { return }
        
        let overlayView = pickerContainer.superview?.subviews.first { $0.backgroundColor == UIColor.black.withAlphaComponent(0.3) }
        
        UIView.animate(withDuration: 0.3, animations: {
            overlayView?.alpha = 0
            bottomConstraint.constant = 260
            self.view.layoutIfNeeded()
        }) { _ in
            pickerContainer.removeFromSuperview()
            overlayView?.removeFromSuperview()
            self.pickerContainerView = nil
            self.pickerBottomConstraint = nil
        }
    }
    
    @objc private func pickerDoneTapped() {
        // Update selected country from picker
        let selectedRow = countryPickerView.selectedRow(inComponent: 0)
        if selectedRow >= 0 && selectedRow < CountryData.countries.count {
            selectedCountry = CountryData.countries[selectedRow]
        }
        hideCountryPicker()
    }
    
    @objc private func pickerCancelTapped() {
        // Reset to previous selection
        if let currentIndex = CountryData.countries.firstIndex(where: { $0.code == selectedCountry.code }) {
            countryPickerView.selectRow(currentIndex, inComponent: 0, animated: false)
        }
        hideCountryPicker()
    }
    
    @objc private func textFieldChanged() {
        if isCodeSent {
            let hasCode = !(codeTextField.text?.isEmpty ?? true)
            continueButton.isEnabled = hasCode
            continueButton.backgroundColor = hasCode ? .black : .black.withAlphaComponent(0.5)
        } else {
            let hasPhone = !(phoneTextField.text?.isEmpty ?? true)
            continueButton.isEnabled = hasPhone
            continueButton.backgroundColor = hasPhone ? .black : .black.withAlphaComponent(0.5)
        }
    }
    
    @objc private func continueTapped() {
        if !isCodeSent {
            sendPhoneCode()
        } else {
            verifyPhoneCode()
        }
    }
    
    private func sendPhoneCode() {
        guard let phone = phoneTextField.text, !phone.isEmpty else {
            showError("Please enter a valid phone number")
            return
        }
        
        let fullPhoneNumber = "\(selectedCountry.dialCode)\(phone)"
        self.phoneNumber = fullPhoneNumber
        
        guard let customerId = customerId else {
            showError("Customer ID not found")
            return
        }
        
        continueButton.isEnabled = false
        continueButton.setTitle("Sending...", for: .normal)
        activityIndicator.startAnimating()
        
        Task {
            do {
                let request = PhoneSendCodeRequest(
                    customerId: customerId,
                    sessionToken: sessionToken,
                    phoneNumber: fullPhoneNumber,
                    skipVerification: false
                )
                
                _ = try await NetworkService.shared.sendPhoneCode(request)
                
                await MainActor.run {
                    activityIndicator.stopAnimating()
                    
                    // If SMS verification is not required, skip OTP verification and move to next step
                    if !isSmsVerificationRequired {
                        onComplete()
                        return
                    }
                    
                    // Otherwise, show OTP input field
                    isCodeSent = true
                    codeLabel.isHidden = false
                    codeContainerView.isHidden = false
                    phoneTextField.isEnabled = false
                    countryCodeButton.isEnabled = false
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
    
    private func verifyPhoneCode() {
        guard let phoneNumber = phoneNumber,
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
                let request = PhoneVerifyCodeRequest(
                    customerId: customerId,
                    sessionToken: sessionToken,
                    phoneNumber: phoneNumber,
                    verificationCode: code
                )
                
                _ = try await NetworkService.shared.verifyPhoneCode(request)
                
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
    
    @objc private func phoneTextFieldDone() {
        phoneTextField.resignFirstResponder()
    }
    
    @objc private func codeTextFieldDone() {
        codeTextField.resignFirstResponder()
    }
    
    private func showError(_ message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UITextFieldDelegate
extension PhoneVerificationViewController: UITextFieldDelegate {
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

// MARK: - UIPickerViewDataSource & UIPickerViewDelegate
@available(iOS 13.0, *)
extension PhoneVerificationViewController: UIPickerViewDataSource, UIPickerViewDelegate {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return CountryData.countries.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        let country = CountryData.countries[row]
        return "\(country.flag) \(country.name) \(country.dialCode)"
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        // Don't update selectedCountry here - only update when Done is tapped
        // This allows users to cancel and revert their selection
    }
}

