import UIKit

@available(iOS 13.0, *)
class VerificationCompleteViewController: UIViewController {
    private let onDismiss: () -> Void
    
    private let checkmarkView = UIView()
    private let titleLabel = UILabel()
    private let messageLabel = UILabel()
    private let closeButton = UIButton(type: .system)
    
    init(onDismiss: @escaping () -> Void) {
        self.onDismiss = onDismiss
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        view.backgroundColor = .white
        
        // Close Button
        closeButton.setTitle("✕", for: .normal)
        closeButton.titleLabel?.font = .systemFont(ofSize: 24)
        closeButton.setTitleColor(.systemGray, for: .normal)
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(closeButton)
        
        // Checkmark Circle
        checkmarkView.backgroundColor = .systemGreen
        checkmarkView.layer.cornerRadius = 60
        checkmarkView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(checkmarkView)
        
        let checkmarkLabel = UILabel()
        checkmarkLabel.text = "✓"
        checkmarkLabel.font = .systemFont(ofSize: 60, weight: .bold)
        checkmarkLabel.textColor = .white
        checkmarkLabel.textAlignment = .center
        checkmarkLabel.translatesAutoresizingMaskIntoConstraints = false
        checkmarkView.addSubview(checkmarkLabel)
        
        NSLayoutConstraint.activate([
            checkmarkLabel.centerXAnchor.constraint(equalTo: checkmarkView.centerXAnchor),
            checkmarkLabel.centerYAnchor.constraint(equalTo: checkmarkView.centerYAnchor)
        ])
        
        // Title
        titleLabel.text = "Verification Complete!"
        titleLabel.font = .systemFont(ofSize: 28, weight: .bold)
        titleLabel.textColor = .black
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(titleLabel)
        
        // Message
        messageLabel.text = "Your account has been successfully verified."
        messageLabel.font = .systemFont(ofSize: 16)
        messageLabel.textColor = .systemGray
        messageLabel.textAlignment = .center
        messageLabel.numberOfLines = 0
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(messageLabel)
        
        NSLayoutConstraint.activate([
            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            closeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            closeButton.widthAnchor.constraint(equalToConstant: 44),
            closeButton.heightAnchor.constraint(equalToConstant: 44),
            
            checkmarkView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            checkmarkView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -60),
            checkmarkView.widthAnchor.constraint(equalToConstant: 120),
            checkmarkView.heightAnchor.constraint(equalToConstant: 120),
            
            titleLabel.topAnchor.constraint(equalTo: checkmarkView.bottomAnchor, constant: 32),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            messageLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),
            messageLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            messageLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])
    }
    
    @objc private func closeTapped() {
        onDismiss()
    }
}

