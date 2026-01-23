import UIKit

@available(iOS 13.0, *)
class StartVerificationViewController: UIViewController {
    private let onStart: () -> Void
    
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    // Header
    private let headerView = OrderShieldHeaderView()
    
    // Main Content
    private let titleLabel = UILabel()
    private let paragraph1Label = UILabel()
    private let paragraph2Label = UILabel()
    
    // Feature Items
    private let featuresStackView = UIStackView()
    private let feature1View = UIView()
    private let feature1ImageView = UIImageView()
    private let feature1Label = UILabel()
    private let feature2View = UIView()
    private let feature2ImageView = UIImageView()
    private let feature2Label = UILabel()
    private let feature3View = UIView()
    private let feature3ImageView = UIImageView()
    private let feature3Label = UILabel()
    
    // Start Button Section
    private let buttonSpacerView = UIView()
    private let startButton = UIButton(type: .system)
    private let buttonContentStackView = UIStackView()
    private let cameraImageView = UIImageView()
    private let startTextLabel = UILabel()
    private let lightingTipLabel = UILabel()
    
    // Footer
    private let footerView = OrderShieldFooterView()
    
    init(onStart: @escaping () -> Void) {
        self.onStart = onStart
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
        scrollView.showsVerticalScrollIndicator = false
        view.addSubview(scrollView)
        
        // Content View
        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)
        
        // Header View
        headerView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(headerView)
        
        // Main Title
        titleLabel.text = "Quick identity verification"
        titleLabel.font = .systemFont(ofSize: 28, weight: .bold)
        titleLabel.textColor = .black
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(titleLabel)
        
        // Paragraph 1
        paragraph1Label.text = "To start your trial, we'll complete a fast verification using a selfie."
        paragraph1Label.font = .systemFont(ofSize: 16)
        paragraph1Label.textColor = .systemGray
        paragraph1Label.textAlignment = .left
        paragraph1Label.numberOfLines = 0
        paragraph1Label.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(paragraph1Label)
        
        // Paragraph 2
        paragraph2Label.text = "This simply confirms it's you and helps keep accounts secure."
        paragraph2Label.font = .systemFont(ofSize: 16)
        paragraph2Label.textColor = .systemGray
        paragraph2Label.textAlignment = .left
        paragraph2Label.numberOfLines = 0
        paragraph2Label.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(paragraph2Label)
        
        // Features Stack View
        featuresStackView.axis = .vertical
        featuresStackView.spacing = 16
        featuresStackView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(featuresStackView)
        
        // Feature 1
        feature1View.translatesAutoresizingMaskIntoConstraints = false
        featuresStackView.addArrangedSubview(feature1View)
        
        feature1ImageView.image = UIImage(systemName: "checkmark.circle.fill")
        feature1ImageView.tintColor = .systemGreen
        feature1ImageView.contentMode = .scaleAspectFit
        feature1ImageView.translatesAutoresizingMaskIntoConstraints = false
        feature1View.addSubview(feature1ImageView)
        
        feature1Label.text = "Used only for account verification and security"
        feature1Label.font = .systemFont(ofSize: 16)
        feature1Label.textColor = .black
        feature1Label.numberOfLines = 0
        feature1Label.translatesAutoresizingMaskIntoConstraints = false
        feature1View.addSubview(feature1Label)
        
        // Feature 2
        feature2View.translatesAutoresizingMaskIntoConstraints = false
        featuresStackView.addArrangedSubview(feature2View)
        
        feature2ImageView.image = UIImage(systemName: "lock.fill")
        feature2ImageView.tintColor = .black
        feature2ImageView.contentMode = .scaleAspectFit
        feature2ImageView.translatesAutoresizingMaskIntoConstraints = false
        feature2View.addSubview(feature2ImageView)
        
        feature2Label.text = "Your data is protected and never sold"
        feature2Label.font = .systemFont(ofSize: 16)
        feature2Label.textColor = .black
        feature2Label.numberOfLines = 0
        feature2Label.translatesAutoresizingMaskIntoConstraints = false
        feature2View.addSubview(feature2Label)
        
        // Feature 3
        feature3View.translatesAutoresizingMaskIntoConstraints = false
        featuresStackView.addArrangedSubview(feature3View)
        
        feature3ImageView.image = UIImage(systemName: "info.circle.fill")
        feature3ImageView.tintColor = UIColor(red: 0.0, green: 0.48, blue: 1.0, alpha: 1.0) // Blue
        feature3ImageView.contentMode = .scaleAspectFit
        feature3ImageView.translatesAutoresizingMaskIntoConstraints = false
        feature3View.addSubview(feature3ImageView)
        
        feature3Label.text = "You can contact support anytime with questions"
        feature3Label.font = .systemFont(ofSize: 16)
        feature3Label.textColor = .black
        feature3Label.numberOfLines = 0
        feature3Label.translatesAutoresizingMaskIntoConstraints = false
        feature3View.addSubview(feature3Label)
        
        // Spacer View to push button down
        buttonSpacerView.translatesAutoresizingMaskIntoConstraints = false
        buttonSpacerView.setContentHuggingPriority(.defaultLow, for: .vertical)
        contentView.addSubview(buttonSpacerView)
        
        // Start Button
        startButton.backgroundColor = .black
        startButton.layer.cornerRadius = 12
        startButton.addTarget(self, action: #selector(startButtonTapped), for: .touchUpInside)
        startButton.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(startButton)
        
        // Button Content Stack View (to center camera icon and text together)
        buttonContentStackView.axis = .horizontal
        buttonContentStackView.spacing = 8
        buttonContentStackView.alignment = .center
        buttonContentStackView.translatesAutoresizingMaskIntoConstraints = false
        startButton.addSubview(buttonContentStackView)
        
        // Camera Icon in Button
        cameraImageView.image = UIImage(systemName: "camera.fill")
        cameraImageView.tintColor = .white
        cameraImageView.contentMode = .scaleAspectFit
        cameraImageView.translatesAutoresizingMaskIntoConstraints = false
        buttonContentStackView.addArrangedSubview(cameraImageView)
        
        // Start Text in Button
        startTextLabel.text = "Start"
        startTextLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        startTextLabel.textColor = .white
        buttonContentStackView.addArrangedSubview(startTextLabel)
        
        // Lighting Tip
        lightingTipLabel.text = "Works best on your device with good lighting"
        lightingTipLabel.font = .systemFont(ofSize: 14)
        lightingTipLabel.textColor = .systemGray
        lightingTipLabel.textAlignment = .center
        lightingTipLabel.numberOfLines = 0
        lightingTipLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(lightingTipLabel)
        
        // Footer View
        footerView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(footerView)
        
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
            
            // Main Title
            titleLabel.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 40),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            // Paragraph 1
            paragraph1Label.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
            paragraph1Label.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            paragraph1Label.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            // Paragraph 2
            paragraph2Label.topAnchor.constraint(equalTo: paragraph1Label.bottomAnchor, constant: 12),
            paragraph2Label.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            paragraph2Label.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            // Features Stack View
            featuresStackView.topAnchor.constraint(equalTo: paragraph2Label.bottomAnchor, constant: 24),
            featuresStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            featuresStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            // Spacer View (creates space between features and button)
            buttonSpacerView.topAnchor.constraint(equalTo: featuresStackView.bottomAnchor, constant: 40),
            buttonSpacerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            buttonSpacerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            buttonSpacerView.heightAnchor.constraint(greaterThanOrEqualToConstant: 100),
            
            // Feature 1
            feature1ImageView.leadingAnchor.constraint(equalTo: feature1View.leadingAnchor),
            feature1ImageView.topAnchor.constraint(equalTo: feature1View.topAnchor),
            feature1ImageView.widthAnchor.constraint(equalToConstant: 24),
            feature1ImageView.heightAnchor.constraint(equalToConstant: 24),
            
            feature1Label.leadingAnchor.constraint(equalTo: feature1ImageView.trailingAnchor, constant: 12),
            feature1Label.trailingAnchor.constraint(equalTo: feature1View.trailingAnchor),
            feature1Label.topAnchor.constraint(equalTo: feature1View.topAnchor),
            feature1Label.bottomAnchor.constraint(equalTo: feature1View.bottomAnchor),
            
            // Feature 2
            feature2ImageView.leadingAnchor.constraint(equalTo: feature2View.leadingAnchor),
            feature2ImageView.topAnchor.constraint(equalTo: feature2View.topAnchor),
            feature2ImageView.widthAnchor.constraint(equalToConstant: 24),
            feature2ImageView.heightAnchor.constraint(equalToConstant: 24),
            
            feature2Label.leadingAnchor.constraint(equalTo: feature2ImageView.trailingAnchor, constant: 12),
            feature2Label.trailingAnchor.constraint(equalTo: feature2View.trailingAnchor),
            feature2Label.topAnchor.constraint(equalTo: feature2View.topAnchor),
            feature2Label.bottomAnchor.constraint(equalTo: feature2View.bottomAnchor),
            
            // Feature 3
            feature3ImageView.leadingAnchor.constraint(equalTo: feature3View.leadingAnchor),
            feature3ImageView.topAnchor.constraint(equalTo: feature3View.topAnchor),
            feature3ImageView.widthAnchor.constraint(equalToConstant: 24),
            feature3ImageView.heightAnchor.constraint(equalToConstant: 24),
            
            feature3Label.leadingAnchor.constraint(equalTo: feature3ImageView.trailingAnchor, constant: 12),
            feature3Label.trailingAnchor.constraint(equalTo: feature3View.trailingAnchor),
            feature3Label.topAnchor.constraint(equalTo: feature3View.topAnchor),
            feature3Label.bottomAnchor.constraint(equalTo: feature3View.bottomAnchor),
            
            // Start Button (positioned after spacer)
            startButton.topAnchor.constraint(equalTo: buttonSpacerView.bottomAnchor),
            startButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            startButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            startButton.heightAnchor.constraint(equalToConstant: 56),
            
            // Lighting Tip (below button)
            lightingTipLabel.topAnchor.constraint(equalTo: startButton.bottomAnchor, constant: 12),
            lightingTipLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            lightingTipLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            // Button Content Stack View (centered in button)
            buttonContentStackView.centerXAnchor.constraint(equalTo: startButton.centerXAnchor),
            buttonContentStackView.centerYAnchor.constraint(equalTo: startButton.centerYAnchor),
            
            cameraImageView.widthAnchor.constraint(equalToConstant: 20),
            cameraImageView.heightAnchor.constraint(equalToConstant: 20),
            
            // Footer View (positioned after lighting tip)
            footerView.topAnchor.constraint(equalTo: lightingTipLabel.bottomAnchor, constant: 40),
            footerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            footerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            footerView.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -20)
        ])
    }
    
    @objc private func startButtonTapped() {
        onStart()
    }
}
