//
//  ViewController.swift
//  TestAppExample
//
//  Example test app for OrderShieldSDK
//

import UIKit
import OrderShieldSDK

class ViewController: UIViewController {
    
    // MARK: - IBOutlets
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var customerIdTextField: UITextField!
    @IBOutlet weak var apiKeyTextField: UITextField!
    @IBOutlet weak var initializeButton: UIButton!
    @IBOutlet weak var startVerificationButton: UIButton!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    // MARK: - Properties
    private var isSDKInitialized = false
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupSDK()
    }
    
    // MARK: - Setup
    private func setupUI() {
        title = "OrderShield SDK Test"
        
        // Set default values
        apiKeyTextField.text = "dev_0RZ-0SCe4BS4ORZhTuW5hL5HEfyFH6jIjH6iwWijLlk"
        customerIdTextField.text = "550e8400-e29b-41d4-a716-446655440025"
        
        // Initial state
        statusLabel.text = "Ready to configure SDK"
        startVerificationButton.isEnabled = false
        activityIndicator.hidesWhenStopped = true
    }
    
    private func setupSDK() {
        // Configure SDK with API key
        guard let apiKey = apiKeyTextField.text, !apiKey.isEmpty else {
            statusLabel.text = "Please enter API key"
            return
        }
        
        OrderShield.shared.configure(apiKey: apiKey)
        statusLabel.text = "SDK configured. Tap 'Initialize SDK' to continue."
    }
    
    // MARK: - Actions
    @IBAction func initializeButtonTapped(_ sender: UIButton) {
        guard let apiKey = apiKeyTextField.text, !apiKey.isEmpty else {
            showAlert(title: "Error", message: "Please enter an API key")
            return
        }
        
        // Reconfigure if API key changed
        OrderShield.shared.configure(apiKey: apiKey)
        
        // Disable button and show loading
        initializeButton.isEnabled = false
        activityIndicator.startAnimating()
        statusLabel.text = "Initializing SDK..."
        
        // Initialize SDK
        Task {
            let success = await OrderShield.shared.initialize()
            
            await MainActor.run {
                activityIndicator.stopAnimating()
                initializeButton.isEnabled = true
                
                if success {
                    isSDKInitialized = true
                    statusLabel.text = "✓ SDK Initialized Successfully"
                    statusLabel.textColor = .systemGreen
                    startVerificationButton.isEnabled = true
                } else {
                    isSDKInitialized = false
                    statusLabel.text = "✗ SDK Initialization Failed"
                    statusLabel.textColor = .systemRed
                    startVerificationButton.isEnabled = false
                    showAlert(title: "Initialization Failed", 
                            message: "Please check your API key and network connection")
                }
            }
        }
    }
    
    @IBAction func startVerificationButtonTapped(_ sender: UIButton) {
        guard isSDKInitialized else {
            showAlert(title: "Error", message: "Please initialize SDK first")
            return
        }
        
        // Optional: set predefined user info before starting to skip steps (phone, email, or userInfo when all 3 name/dob provided)
        // OrderShield.shared.setPredefinedUserInfo(PredefinedUserInfo(phoneNumber: "+15551234567"))
        
        OrderShield.shared.startVerification(presentingViewController: self)
    }
    
    @IBAction func apiKeyChanged(_ sender: UITextField) {
        // Reconfigure SDK when API key changes
        if let apiKey = sender.text, !apiKey.isEmpty {
            OrderShield.shared.configure(apiKey: apiKey)
        }
    }
    
    // MARK: - Helpers
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UITextFieldDelegate
extension ViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

