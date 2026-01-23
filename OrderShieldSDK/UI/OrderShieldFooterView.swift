import UIKit

@available(iOS 13.0, *)
class OrderShieldFooterView: UIView {
    private let separatorLine = UIView()
    private let footerContainerView = UIView()
    private let footerShieldIcon = UIImageView()
    private let footerSecuredByLabel = UILabel()
    private let footerOrderShieldLabel = UILabel()
    private let footerSubtextLabel = UILabel()
    
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
        
        // Separator Line
        separatorLine.backgroundColor = .systemGray4
        separatorLine.translatesAutoresizingMaskIntoConstraints = false
        addSubview(separatorLine)
        
        // Footer Container
        footerContainerView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(footerContainerView)
        
        // Footer Shield Icon (using asset image)
        footerShieldIcon.image = UIImage(named: "ordershield_icon", in: Bundle(for: OrderShieldFooterView.self), compatibleWith: nil)
        footerShieldIcon.contentMode = .scaleAspectFit
        footerShieldIcon.translatesAutoresizingMaskIntoConstraints = false
        footerContainerView.addSubview(footerShieldIcon)
        
        // Footer "Secured By" Text (gray)
        footerSecuredByLabel.text = "Secured By"
        footerSecuredByLabel.font = .systemFont(ofSize: 14, weight: .medium)
        footerSecuredByLabel.textColor = .systemGray
        footerSecuredByLabel.translatesAutoresizingMaskIntoConstraints = false
        footerContainerView.addSubview(footerSecuredByLabel)
        
        // Footer "OrderShield" Text (blue)
        footerOrderShieldLabel.text = "OrderShield"
        footerOrderShieldLabel.font = .systemFont(ofSize: 14, weight: .medium)
        footerOrderShieldLabel.textColor = UIColor(red: 0.0, green: 0.48, blue: 1.0, alpha: 1.0) // Blue
        footerOrderShieldLabel.translatesAutoresizingMaskIntoConstraints = false
        footerContainerView.addSubview(footerOrderShieldLabel)
        
        // Footer Subtext
        footerSubtextLabel.text = "Trusted verification for millions of users"
        footerSubtextLabel.font = .systemFont(ofSize: 12)
        footerSubtextLabel.textColor = .systemGray
        footerSubtextLabel.textAlignment = .center
        footerSubtextLabel.numberOfLines = 0
        footerSubtextLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(footerSubtextLabel)
        
        NSLayoutConstraint.activate([
            // Separator Line (with leading/trailing margins)
            separatorLine.topAnchor.constraint(equalTo: topAnchor),
            separatorLine.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            separatorLine.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            separatorLine.heightAnchor.constraint(equalToConstant: 1),
            
            // Footer Container (positioned after separator)
            footerContainerView.topAnchor.constraint(equalTo: separatorLine.bottomAnchor, constant: 16),
            footerContainerView.centerXAnchor.constraint(equalTo: centerXAnchor),
            
            footerShieldIcon.leadingAnchor.constraint(equalTo: footerContainerView.leadingAnchor),
            footerShieldIcon.centerYAnchor.constraint(equalTo: footerContainerView.centerYAnchor),
            footerShieldIcon.widthAnchor.constraint(equalToConstant: 20),
            footerShieldIcon.heightAnchor.constraint(equalToConstant: 20),
            
            footerSecuredByLabel.leadingAnchor.constraint(equalTo: footerShieldIcon.trailingAnchor, constant: 6),
            footerSecuredByLabel.centerYAnchor.constraint(equalTo: footerContainerView.centerYAnchor),
            
            footerOrderShieldLabel.leadingAnchor.constraint(equalTo: footerSecuredByLabel.trailingAnchor, constant: 4),
            footerOrderShieldLabel.trailingAnchor.constraint(equalTo: footerContainerView.trailingAnchor),
            footerOrderShieldLabel.centerYAnchor.constraint(equalTo: footerContainerView.centerYAnchor),
            
            footerContainerView.topAnchor.constraint(equalTo: footerShieldIcon.topAnchor),
            footerContainerView.bottomAnchor.constraint(equalTo: footerShieldIcon.bottomAnchor),
            footerContainerView.leadingAnchor.constraint(equalTo: footerShieldIcon.leadingAnchor),
            footerContainerView.trailingAnchor.constraint(equalTo: footerOrderShieldLabel.trailingAnchor),
            
            // Footer Subtext
            footerSubtextLabel.topAnchor.constraint(equalTo: footerContainerView.bottomAnchor, constant: 8),
            footerSubtextLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            footerSubtextLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            footerSubtextLabel.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
}
