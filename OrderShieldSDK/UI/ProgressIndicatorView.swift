import UIKit

@available(iOS 13.0, *)
class ProgressIndicatorView: UIView {
    private let stepLabel = UILabel()
    private let percentageLabel = UILabel()
    private let progressBar = UIProgressView(progressViewStyle: .default)
    
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
        
        // Step Label (e.g., "Step 1 of 5")
        stepLabel.font = .systemFont(ofSize: 14, weight: .medium)
        stepLabel.textColor = .label
        stepLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stepLabel)
        
        // Percentage Label (e.g., "20% Complete")
        percentageLabel.font = .systemFont(ofSize: 14, weight: .medium)
        percentageLabel.textColor = .label
        percentageLabel.textAlignment = .right
        percentageLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(percentageLabel)
        
        // Progress Bar
        progressBar.progressTintColor = .systemBlue
        progressBar.trackTintColor = .systemGray5
        progressBar.layer.cornerRadius = 2
        progressBar.clipsToBounds = true
        progressBar.translatesAutoresizingMaskIntoConstraints = false
        addSubview(progressBar)
        
        NSLayoutConstraint.activate([
            stepLabel.topAnchor.constraint(equalTo: topAnchor),
            stepLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            
            percentageLabel.topAnchor.constraint(equalTo: topAnchor),
            percentageLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            percentageLabel.leadingAnchor.constraint(greaterThanOrEqualTo: stepLabel.trailingAnchor, constant: 16),
            
            progressBar.topAnchor.constraint(equalTo: stepLabel.bottomAnchor, constant: 8),
            progressBar.leadingAnchor.constraint(equalTo: leadingAnchor),
            progressBar.trailingAnchor.constraint(equalTo: trailingAnchor),
            progressBar.bottomAnchor.constraint(equalTo: bottomAnchor),
            progressBar.heightAnchor.constraint(equalToConstant: 4)
        ])
    }
    
    func updateProgress(currentStep: Int, totalSteps: Int) {
        stepLabel.text = "Step \(currentStep) of \(totalSteps)"
        
        let percentage = Int((Float(currentStep) / Float(totalSteps)) * 100)
        percentageLabel.text = "\(percentage)% Complete"
        
        let progress = Float(currentStep) / Float(totalSteps)
        progressBar.setProgress(progress, animated: true)
    }
}

