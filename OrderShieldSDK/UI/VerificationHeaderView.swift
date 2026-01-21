import UIKit

@available(iOS 13.0, *)
class VerificationHeaderView: UIView {
    private let headerView = UIView()
    private let shieldIcon = UILabel()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    private func setupUI() {
        backgroundColor = .clear
        
        // Purple Header Background
        headerView.backgroundColor = UIColor(red: 0.5, green: 0.3, blue: 0.9, alpha: 1.0) // Purple color
        headerView.layer.cornerRadius = 12
        headerView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        headerView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(headerView)
        
        // Shield Icon
        shieldIcon.text = "🛡️"
        shieldIcon.font = .systemFont(ofSize: 24)
        shieldIcon.textColor = .white
        shieldIcon.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(shieldIcon)
        
        // Title
        titleLabel.text = "OrderShield Verification"
        titleLabel.font = .systemFont(ofSize: 20, weight: .bold)
        titleLabel.textColor = .white
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(titleLabel)
        
        // Subtitle
        subtitleLabel.text = "Secure identity verification process"
        subtitleLabel.font = .systemFont(ofSize: 14)
        subtitleLabel.textColor = .white.withAlphaComponent(0.9)
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(subtitleLabel)
        
        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: topAnchor),
            headerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            headerView.heightAnchor.constraint(equalToConstant: 80),
            
            shieldIcon.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 20),
            shieldIcon.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            shieldIcon.widthAnchor.constraint(equalToConstant: 30),
            
            titleLabel.leadingAnchor.constraint(equalTo: shieldIcon.trailingAnchor, constant: 12),
            titleLabel.topAnchor.constraint(equalTo: headerView.topAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -20),
            
            subtitleLabel.leadingAnchor.constraint(equalTo: shieldIcon.trailingAnchor, constant: 12),
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            subtitleLabel.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -20),
            
            bottomAnchor.constraint(equalTo: headerView.bottomAnchor)
        ])
    }
}

