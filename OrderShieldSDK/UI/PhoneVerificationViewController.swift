
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
    private let titleLabel = UILabel()
    private let instructionLabel = UILabel()
    private let countryCodeButton = UIButton(type: .system)
    private let phoneTextField = UITextField()
    private let codeTextField = UITextField()
    private let continueButton = UIButton(type: .system)
    private let phoneIconView = UIView()
    private let activityIndicator = UIActivityIndicatorView(style: .medium)
    private let countryPickerView = UIPickerView()
    private let pickerToolbar = UIToolbar()
    private var pickerContainerView: UIView?
    private var pickerBottomConstraint: NSLayoutConstraint?
    
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
        iconLabel.text = "📞"
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
        mainTitleLabel.text = "Phone Number Verification"
        mainTitleLabel.font = .systemFont(ofSize: 24, weight: .bold)
        mainTitleLabel.textColor = .black
        mainTitleLabel.textAlignment = .center
        mainTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(mainTitleLabel)
        
        // Instructions
        instructionLabel.text = "Please enter your phone number to verify your identity.\nThis helps us ensure account security and prevent fraud."
        instructionLabel.font = .systemFont(ofSize: 14)
        instructionLabel.textColor = .systemGray
        instructionLabel.numberOfLines = 0
        instructionLabel.textAlignment = .left
        instructionLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(instructionLabel)
        
        // Phone Number Label
        let phoneLabel = UILabel()
        phoneLabel.text = "Phone Number"
        phoneLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        phoneLabel.textColor = .black
        phoneLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(phoneLabel)
        
        // Phone Input Container
        let phoneContainer = UIView()
        phoneContainer.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(phoneContainer)
        
        // Country Code Button
        countryCodeButton.backgroundColor = .systemGray6
        countryCodeButton.layer.cornerRadius = 8
        countryCodeButton.titleLabel?.font = .systemFont(ofSize: 16)
        countryCodeButton.setTitleColor(.black, for: .normal)
        countryCodeButton.contentHorizontalAlignment = .left
        countryCodeButton.titleEdgeInsets = UIEdgeInsets(top: 0, left: 12, bottom: 0, right: 30)
        countryCodeButton.addTarget(self, action: #selector(countryCodeButtonTapped), for: .touchUpInside)
        countryCodeButton.translatesAutoresizingMaskIntoConstraints = false
        updateCountryButton()
        phoneContainer.addSubview(countryCodeButton)
        
        // Add chevron icon to country button
        let chevronImageView = UIImageView(image: UIImage(systemName: "chevron.down"))
        chevronImageView.tintColor = .systemGray
        chevronImageView.contentMode = .scaleAspectFit
        chevronImageView.translatesAutoresizingMaskIntoConstraints = false
        countryCodeButton.addSubview(chevronImageView)
        
        NSLayoutConstraint.activate([
            chevronImageView.trailingAnchor.constraint(equalTo: countryCodeButton.trailingAnchor, constant: -12),
            chevronImageView.centerYAnchor.constraint(equalTo: countryCodeButton.centerYAnchor),
            chevronImageView.widthAnchor.constraint(equalToConstant: 12),
            chevronImageView.heightAnchor.constraint(equalToConstant: 12)
        ])
        
        // Phone Number
        phoneTextField.placeholder = "Enter your phone number"
        phoneTextField.borderStyle = .roundedRect
        phoneTextField.keyboardType = .phonePad
        phoneTextField.backgroundColor = .systemGray6
        phoneTextField.font = .systemFont(ofSize: 16)
        phoneTextField.translatesAutoresizingMaskIntoConstraints = false
        phoneContainer.addSubview(phoneTextField)
        
        // Add Done button toolbar for phone text field
        let phoneToolbar = UIToolbar()
        phoneToolbar.sizeToFit()
        let phoneDoneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(phoneTextFieldDone))
        let phoneFlexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        phoneToolbar.setItems([phoneFlexSpace, phoneDoneButton], animated: false)
        phoneTextField.inputAccessoryView = phoneToolbar
        
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
        disclaimerLabel.text = "We'll use this number for verification purposes only"
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
            
            phoneLabel.topAnchor.constraint(equalTo: instructionLabel.bottomAnchor, constant: 24),
            phoneLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            phoneLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            phoneContainer.topAnchor.constraint(equalTo: phoneLabel.bottomAnchor, constant: 8),
            phoneContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            phoneContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            phoneContainer.heightAnchor.constraint(equalToConstant: 50),
            
            countryCodeButton.leadingAnchor.constraint(equalTo: phoneContainer.leadingAnchor),
            countryCodeButton.centerYAnchor.constraint(equalTo: phoneContainer.centerYAnchor),
            countryCodeButton.widthAnchor.constraint(equalToConstant: 100),
            countryCodeButton.heightAnchor.constraint(equalToConstant: 50),
            
            phoneTextField.leadingAnchor.constraint(equalTo: countryCodeButton.trailingAnchor, constant: 8),
            phoneTextField.trailingAnchor.constraint(equalTo: phoneContainer.trailingAnchor),
            phoneTextField.centerYAnchor.constraint(equalTo: phoneContainer.centerYAnchor),
            phoneTextField.heightAnchor.constraint(equalToConstant: 50),
            
            codeTextField.topAnchor.constraint(equalTo: phoneContainer.bottomAnchor, constant: 16),
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
        
        phoneTextField.addTarget(self, action: #selector(textFieldChanged), for: .editingChanged)
        codeTextField.addTarget(self, action: #selector(textFieldChanged), for: .editingChanged)
        
        // Set text field delegates for keyboard handling
        phoneTextField.delegate = self
        codeTextField.delegate = self
        
        // Setup country picker
        setupCountryPicker()
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
            continueButton.backgroundColor = hasCode ? UIColor(red: 100/255.0, green: 104/255.0, blue: 254/255.0, alpha: 1.0) : UIColor(red: 100/255.0, green: 104/255.0, blue: 254/255.0, alpha: 0.5)
        } else {
            let hasPhone = !(phoneTextField.text?.isEmpty ?? true)
            continueButton.isEnabled = hasPhone
            continueButton.backgroundColor = hasPhone ? UIColor(red: 100/255.0, green: 104/255.0, blue: 254/255.0, alpha: 1.0) : UIColor(red: 100/255.0, green: 104/255.0, blue: 254/255.0, alpha: 0.5)
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
                    phoneNumber: fullPhoneNumber
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
                    codeTextField.isHidden = false
                    phoneTextField.isEnabled = false
                    countryCodeButton.isEnabled = false
                    continueButton.setTitle("Verify", for: .normal)
                    continueButton.isEnabled = false
                    view.endEditing(true)
                }
            } catch {
                await MainActor.run {
                    activityIndicator.stopAnimating()
                    continueButton.isEnabled = true
                    continueButton.setTitle("Continue", for: .normal)
                    showError("Failed to send code: \(error.localizedDescription)")
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
                    showError("Invalid verification code. Please try again.")
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

