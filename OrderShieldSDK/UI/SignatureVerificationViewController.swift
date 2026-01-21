import UIKit

@available(iOS 13.0, *)
class SignatureVerificationViewController: UIViewController {
    private let sessionToken: String
    private let onComplete: () -> Void
    private let onError: ((Error) -> Void)?
    private weak var delegate: OrderShieldDelegate?
    
    private var customerId: String? {
        return StorageService.shared.getCustomerId()
    }
    
    private var signatureImage: UIImage?
    
    private let titleLabel = UILabel()
    private let instructionLabel = UILabel()
    private let signatureView = SignatureView()
    private let clearButton = UIButton(type: .system)
    private let acceptButton = UIButton(type: .system)
    private let cancelButton = UIButton(type: .system)
    private let activityIndicator = UIActivityIndicatorView(style: .medium)
    
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
    }
    
    private func setupUI() {
        view.backgroundColor = .white
        
        // Title
        titleLabel.text = "Digital Signature Required"
        titleLabel.font = .systemFont(ofSize: 20, weight: .bold)
        titleLabel.textColor = .black
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(titleLabel)
        
        // Instructions
        instructionLabel.text = "Please sign in the box below to complete your verification."
        instructionLabel.font = .systemFont(ofSize: 16)
        instructionLabel.textColor = .black
        instructionLabel.textAlignment = .center
        instructionLabel.numberOfLines = 0
        instructionLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(instructionLabel)
        
        // Sign Here Label
        let signHereLabel = UILabel()
        signHereLabel.text = "Sign here"
        signHereLabel.font = .systemFont(ofSize: 14)
        signHereLabel.textColor = .systemGray
        signHereLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(signHereLabel)
        
        // Signature View
        signatureView.backgroundColor = .white
        signatureView.layer.borderWidth = 1
        signatureView.layer.borderColor = UIColor.systemGray3.cgColor
        signatureView.layer.cornerRadius = 8
        signatureView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(signatureView)
        
        // Clear Button
        clearButton.setTitle("Clear", for: .normal)
        clearButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        clearButton.setTitleColor(.systemBlue, for: .normal)
        clearButton.layer.borderWidth = 1
        clearButton.layer.borderColor = UIColor.systemBlue.cgColor
        clearButton.layer.cornerRadius = 8
        clearButton.addTarget(self, action: #selector(clearTapped), for: .touchUpInside)
        clearButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(clearButton)
        
        // Accept Button
        acceptButton.setTitle("Accept Signature", for: .normal)
        acceptButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        acceptButton.backgroundColor = .black
        acceptButton.setTitleColor(.white, for: .normal)
        acceptButton.layer.cornerRadius = 8
        acceptButton.isEnabled = false
        acceptButton.alpha = 0.5
        acceptButton.addTarget(self, action: #selector(acceptTapped), for: .touchUpInside)
        acceptButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(acceptButton)
        
        // Cancel Button
        cancelButton.setTitle("Cancel", for: .normal)
        cancelButton.titleLabel?.font = .systemFont(ofSize: 16)
        cancelButton.setTitleColor(.systemGray, for: .normal)
        cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(cancelButton)
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 40),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            instructionLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
            instructionLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            instructionLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            signHereLabel.topAnchor.constraint(equalTo: instructionLabel.bottomAnchor, constant: 24),
            signHereLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            
            signatureView.topAnchor.constraint(equalTo: signHereLabel.bottomAnchor, constant: 8),
            signatureView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            signatureView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            signatureView.heightAnchor.constraint(equalToConstant: 200),
            
            clearButton.topAnchor.constraint(equalTo: signatureView.bottomAnchor, constant: 20),
            clearButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            clearButton.widthAnchor.constraint(equalToConstant: 100),
            clearButton.heightAnchor.constraint(equalToConstant: 44),
            
            acceptButton.topAnchor.constraint(equalTo: signatureView.bottomAnchor, constant: 20),
            acceptButton.leadingAnchor.constraint(equalTo: clearButton.trailingAnchor, constant: 12),
            acceptButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            acceptButton.heightAnchor.constraint(equalToConstant: 44),
            
            cancelButton.topAnchor.constraint(equalTo: acceptButton.bottomAnchor, constant: 16),
            cancelButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        
        // Activity Indicator
        activityIndicator.hidesWhenStopped = true
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(activityIndicator)
        
        signatureView.onSignatureChanged = { [weak self] hasSignature in
            self?.acceptButton.isEnabled = hasSignature
            self?.acceptButton.alpha = hasSignature ? 1.0 : 0.5
        }
    }
    
    @objc private func clearTapped() {
        signatureView.clear()
    }
    
    @objc private func acceptTapped() {
        guard let signatureImage = signatureView.getSignatureImage() else {
            showError("Please provide a signature")
            return
        }
        
        acceptButton.isEnabled = false
        acceptButton.setTitle("Submitting...", for: .normal)
        activityIndicator.startAnimating()
        
        guard let imageData = signatureImage.pngData() else {
            activityIndicator.stopAnimating()
            acceptButton.isEnabled = true
            acceptButton.setTitle("Accept Signature", for: .normal)
            showError("Failed to process signature")
            return
        }
        
        guard let customerId = customerId else {
            showError("Customer ID not found")
            return
        }
        
        Task {
            do {
                _ = try await NetworkService.shared.submitSignature(
                    customerId: customerId,
                    sessionToken: sessionToken,
                    imageData: imageData,
                    imageFormat: "png"
                )
                
                await MainActor.run {
                    activityIndicator.stopAnimating()
                    // Notify delegate
                    self.delegate?.orderShieldDidSubmitSignature(success: true, error: nil)
                    onComplete()
                }
            } catch {
                await MainActor.run {
                    activityIndicator.stopAnimating()
                    acceptButton.isEnabled = true
                    acceptButton.setTitle("Accept Signature", for: .normal)
                    showError("Failed to submit signature: \(error.localizedDescription)")
                    // Notify delegate
                    self.delegate?.orderShieldDidSubmitSignature(success: false, error: error)
                    onError?(error)
                }
            }
        }
    }
    
    @objc private func cancelTapped() {
        navigationController?.popViewController(animated: true)
    }
    
    private func showError(_ message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - Signature View
@available(iOS 13.0, *)
class SignatureView: UIView {
    private var path = UIBezierPath()
    private var lastPoint = CGPoint.zero
    var onSignatureChanged: ((Bool) -> Void)?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    private func setup() {
        isMultipleTouchEnabled = false
        path.lineWidth = 2.0
        path.lineCapStyle = .round
        path.lineJoinStyle = .round
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        lastPoint = touch.location(in: self)
        path.move(to: lastPoint)
        onSignatureChanged?(true)
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let currentPoint = touch.location(in: self)
        path.addLine(to: currentPoint)
        lastPoint = currentPoint
        setNeedsDisplay()
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let currentPoint = touch.location(in: self)
        path.addLine(to: currentPoint)
        setNeedsDisplay()
    }
    
    override func draw(_ rect: CGRect) {
        UIColor.black.setStroke()
        path.stroke()
    }
    
    func clear() {
        path = UIBezierPath()
        path.lineWidth = 2.0
        path.lineCapStyle = .round
        path.lineJoinStyle = .round
        setNeedsDisplay()
        onSignatureChanged?(false)
    }
    
    func getSignatureImage() -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(bounds.size, false, 0.0)
        defer { UIGraphicsEndImageContext() }
        
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        layer.render(in: context)
        return UIGraphicsGetImageFromCurrentImageContext()
    }
}

