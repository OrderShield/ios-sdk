import UIKit

@available(iOS 13.0, *)
class OrderShieldHeaderView: UIView {
    private let logoContainerView = UIView()
    private let shieldIcon = UIImageView()
    private let logoTitleLabel = UILabel()
    private let logoSubtitleLabel = UILabel()
    
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
        
        // Logo Container
        logoContainerView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(logoContainerView)
        
        // Shield Icon (using asset image)
        shieldIcon.image = UIImage(named: "ordershield_icon", in: Bundle(for: OrderShieldHeaderView.self), compatibleWith: nil)
        shieldIcon.contentMode = .scaleAspectFit
        shieldIcon.translatesAutoresizingMaskIntoConstraints = false
        logoContainerView.addSubview(shieldIcon)
        
        // Logo Title
        logoTitleLabel.text = "OrderShield"
        logoTitleLabel.font = .systemFont(ofSize: 24, weight: .bold)
        logoTitleLabel.textColor = .black
        logoTitleLabel.textAlignment = .left
        logoTitleLabel.numberOfLines = 0
        logoTitleLabel.adjustsFontSizeToFitWidth = true
        logoTitleLabel.minimumScaleFactor = 0.8
        logoTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        logoContainerView.addSubview(logoTitleLabel)
        
        // Logo Subtitle
        logoSubtitleLabel.text = "Verification Protection"
        logoSubtitleLabel.font = .systemFont(ofSize: 18)
        logoSubtitleLabel.textColor = .systemGray
        logoSubtitleLabel.textAlignment = .left
        logoSubtitleLabel.numberOfLines = 0
        logoSubtitleLabel.adjustsFontSizeToFitWidth = true
        logoSubtitleLabel.minimumScaleFactor = 0.8
        logoSubtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        logoContainerView.addSubview(logoSubtitleLabel)
        
        NSLayoutConstraint.activate([
            // Logo Container
            logoContainerView.topAnchor.constraint(equalTo: topAnchor),
            logoContainerView.centerXAnchor.constraint(equalTo: centerXAnchor),
            logoContainerView.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 20),
            logoContainerView.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -20),
            logoContainerView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            // Shield Icon - left side, top aligned
            shieldIcon.leadingAnchor.constraint(equalTo: logoContainerView.leadingAnchor),
            shieldIcon.topAnchor.constraint(equalTo: logoContainerView.topAnchor),
            shieldIcon.widthAnchor.constraint(equalToConstant: 48),
            shieldIcon.heightAnchor.constraint(equalToConstant: 48),
            
            // Logo Title - beside icon, vertically centered with icon
            logoTitleLabel.leadingAnchor.constraint(equalTo: shieldIcon.trailingAnchor, constant: 12),
            logoTitleLabel.centerYAnchor.constraint(equalTo: shieldIcon.centerYAnchor),
            logoTitleLabel.trailingAnchor.constraint(lessThanOrEqualTo: logoContainerView.trailingAnchor),
            
            // Logo Subtitle - below icon and title, aligned with icon's leading edge
            logoSubtitleLabel.topAnchor.constraint(equalTo: shieldIcon.bottomAnchor, constant: 8),
            logoSubtitleLabel.leadingAnchor.constraint(equalTo: logoContainerView.leadingAnchor),
            logoSubtitleLabel.trailingAnchor.constraint(lessThanOrEqualTo: logoContainerView.trailingAnchor),
            logoSubtitleLabel.bottomAnchor.constraint(equalTo: logoContainerView.bottomAnchor)
        ])
    }
}
