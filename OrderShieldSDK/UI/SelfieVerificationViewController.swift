import UIKit
import AVFoundation

@available(iOS 13.0, *)
class SelfieVerificationViewController: UIViewController {
    private let sessionToken: String
    private let onComplete: () -> Void
    private let onError: ((Error) -> Void)?
    
    private var customerId: String? {
        return StorageService.shared.getCustomerId()
    }
    
    private var captureSession: AVCaptureSession?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var photoOutput: AVCapturePhotoOutput?
    private var isCapturing = false
    
    private let titleLabel = UILabel()
    private let captureButton = UIButton(type: .system)
    private let previewImageView = UIImageView()
    private let retakeButton = UIButton(type: .system)
    private let submitButton = UIButton(type: .system)
    private let activityIndicator = UIActivityIndicatorView(style: .medium)
    
    init(sessionToken: String, onComplete: @escaping () -> Void, onError: ((Error) -> Void)? = nil) {
        self.sessionToken = sessionToken
        self.onComplete = onComplete
        self.onError = onError
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.setNavigationBarHidden(true, animated: false)
        setupUI()
        setupCamera()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        startCamera()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopCamera()
    }
    
    private func setupUI() {
        view.backgroundColor = .white
        
        // Title
        titleLabel.text = "Take a Selfie"
        titleLabel.font = .systemFont(ofSize: 18, weight: .medium)
        titleLabel.textColor = .black
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(titleLabel)
        
        // Preview Image View (hidden initially)
        previewImageView.contentMode = .scaleAspectFill
        previewImageView.clipsToBounds = true
        previewImageView.isHidden = true
        previewImageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(previewImageView)
        
        // Capture Button
        captureButton.setTitle("Capture", for: .normal)
        captureButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        captureButton.backgroundColor = UIColor(red: 100/255.0, green: 104/255.0, blue: 254/255.0, alpha: 1.0) // RGB(100, 104, 254)
        captureButton.setTitleColor(.white, for: .normal)
        captureButton.setTitleColor(.white.withAlphaComponent(0.5), for: .disabled)
        captureButton.layer.cornerRadius = 12
        captureButton.addTarget(self, action: #selector(capturePhoto), for: .touchUpInside)
        captureButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(captureButton)
        
        // Retake Button (hidden initially, positioned at top right)
        retakeButton.setTitle("Retake", for: .normal)
        retakeButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        retakeButton.setTitleColor(.systemBlue, for: .normal)
        retakeButton.addTarget(self, action: #selector(retakePhoto), for: .touchUpInside)
        retakeButton.isHidden = true
        retakeButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(retakeButton)
        
        // Submit Button (hidden initially)
        submitButton.setTitle("Continue", for: .normal)
        submitButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        submitButton.backgroundColor = UIColor(red: 100/255.0, green: 104/255.0, blue: 254/255.0, alpha: 1.0) // RGB(100, 104, 254)
        submitButton.setTitleColor(.white, for: .normal)
        submitButton.setTitleColor(.white.withAlphaComponent(0.5), for: .disabled)
        submitButton.layer.cornerRadius = 12
        submitButton.addTarget(self, action: #selector(submitPhoto), for: .touchUpInside)
        submitButton.isHidden = true
        submitButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(submitButton)
        
        // Arrow Icon on Button
        let arrowIcon = UIImageView(image: UIImage(systemName: "arrow.right"))
        arrowIcon.tintColor = .white
        arrowIcon.contentMode = .scaleAspectFit
        arrowIcon.translatesAutoresizingMaskIntoConstraints = false
        submitButton.addSubview(arrowIcon)
        
        // Activity Indicator
        activityIndicator.hidesWhenStopped = true
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(activityIndicator)
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            retakeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            retakeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            previewImageView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),
            previewImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            previewImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            previewImageView.bottomAnchor.constraint(equalTo: captureButton.topAnchor, constant: -20),
            
            captureButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -40),
            captureButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            captureButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            captureButton.heightAnchor.constraint(equalToConstant: 56),
            
            submitButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -40),
            submitButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            submitButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            submitButton.heightAnchor.constraint(equalToConstant: 56),
            
            arrowIcon.trailingAnchor.constraint(equalTo: submitButton.trailingAnchor, constant: -20),
            arrowIcon.centerYAnchor.constraint(equalTo: submitButton.centerYAnchor),
            arrowIcon.widthAnchor.constraint(equalToConstant: 20),
            arrowIcon.heightAnchor.constraint(equalToConstant: 20),
            
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    private func setupCamera() {
        let captureSession = AVCaptureSession()
        self.captureSession = captureSession
        
        guard let videoCaptureDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
              let videoInput = try? AVCaptureDeviceInput(device: videoCaptureDevice),
              captureSession.canAddInput(videoInput) else {
            return
        }
        
        captureSession.addInput(videoInput)
        
        let photoOutput = AVCapturePhotoOutput()
        if captureSession.canAddOutput(photoOutput) {
            captureSession.addOutput(photoOutput)
            self.photoOutput = photoOutput
        }
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.videoGravity = .resizeAspectFill
        // Frame will be updated in viewDidLayoutSubviews
        view.layer.insertSublayer(previewLayer, at: 0)
        self.previewLayer = previewLayer
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // Update preview layer frame to extend from below title to above capture button
        let titleBottom = titleLabel.frame.maxY + 20
        let captureTop = captureButton.frame.minY - 20
        previewLayer?.frame = CGRect(
            x: 0,
            y: titleBottom,
            width: view.bounds.width,
            height: captureTop - titleBottom
        )
    }
    
    private func startCamera() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.captureSession?.startRunning()
        }
    }
    
    private func stopCamera() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.captureSession?.stopRunning()
        }
    }
    
    @objc private func capturePhoto() {
        guard !isCapturing, let photoOutput = photoOutput else { return }
        isCapturing = true
        
        let settings = AVCapturePhotoSettings()
        photoOutput.capturePhoto(with: settings, delegate: self)
    }
    
    @objc private func retakePhoto() {
        previewImageView.isHidden = true
        previewImageView.image = nil
        retakeButton.isHidden = true
        submitButton.isHidden = true
        captureButton.isHidden = false
        startCamera()
    }
    
    @objc private func submitPhoto() {
        guard let image = previewImageView.image,
              let imageData = image.jpegData(compressionQuality: 0.8),
              let customerId = customerId else {
            showError("Customer ID not found")
            return
        }
        
        submitButton.isEnabled = false
        submitButton.setTitle("Submitting...", for: .normal)
        activityIndicator.startAnimating()
        
        Task {
            do {
                _ = try await NetworkService.shared.submitSelfie(
                    customerId: customerId,
                    sessionToken: sessionToken,
                    imageData: imageData,
                    imageFormat: "jpeg"
                )
                
                await MainActor.run {
                    activityIndicator.stopAnimating()
                    onComplete()
                }
            } catch {
                await MainActor.run {
                    activityIndicator.stopAnimating()
                    submitButton.isEnabled = true
                    submitButton.setTitle("Continue", for: .normal)
                    showError("Failed to submit selfie: \(error.localizedDescription)")
                    onError?(error)
                }
            }
        }
    }
    
    private func fixImageOrientation(_ image: UIImage) -> UIImage {
        // If image is already correctly oriented (.up), just flip horizontally
        if image.imageOrientation == .up {
            return flipImageHorizontally(image)
        }
        
        guard let cgImage = image.cgImage else { return image }
        
        // Determine output dimensions based on orientation
        let outputWidth: Int
        let outputHeight: Int
        
        switch image.imageOrientation {
        case .left, .leftMirrored, .right, .rightMirrored:
            // Rotated 90 degrees - swap dimensions
            outputWidth = cgImage.height
            outputHeight = cgImage.width
        default:
            outputWidth = cgImage.width
            outputHeight = cgImage.height
        }
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
        
        guard let context = CGContext(
            data: nil,
            width: outputWidth,
            height: outputHeight,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: bitmapInfo.rawValue
        ) else {
            return image
        }
        
        // Apply transformations based on orientation
        switch image.imageOrientation {
        case .rightMirrored:
            // Rotate 90° CCW and flip horizontally
            context.translateBy(x: CGFloat(outputWidth), y: 0)
            context.rotate(by: -CGFloat.pi / 2)
            context.scaleBy(x: -1.0, y: 1.0)
        case .leftMirrored:
            // Rotate 90° CW and flip horizontally
            context.translateBy(x: 0, y: CGFloat(outputHeight))
            context.rotate(by: -CGFloat.pi / 2)
            context.scaleBy(x: -1.0, y: 1.0)
        case .right:
            // Rotate 90° CCW and flip horizontally for front camera
            context.translateBy(x: CGFloat(outputWidth), y: 0)
            context.rotate(by: -CGFloat.pi / 2)
            context.scaleBy(x: -1.0, y: 1.0)
        case .left:
            // Rotate 90° CW and flip horizontally for front camera
            context.translateBy(x: 0, y: CGFloat(outputHeight))
            context.rotate(by: -CGFloat.pi / 2)
            context.scaleBy(x: -1.0, y: 1.0)
        case .down, .downMirrored:
            // Rotate 180° and flip horizontally
            context.translateBy(x: CGFloat(outputWidth), y: CGFloat(outputHeight))
            context.rotate(by: CGFloat.pi)
            context.scaleBy(x: -1.0, y: 1.0)
        case .upMirrored:
            // Just flip horizontally
            context.translateBy(x: CGFloat(outputWidth), y: 0)
            context.scaleBy(x: -1.0, y: 1.0)
        default:
            // .up - just flip horizontally for front camera
            context.translateBy(x: CGFloat(outputWidth), y: 0)
            context.scaleBy(x: -1.0, y: 1.0)
        }
        
        // Draw the image
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: cgImage.width, height: cgImage.height))
        
        guard let fixedCGImage = context.makeImage() else {
            return image
        }
        
        return UIImage(cgImage: fixedCGImage, scale: image.scale, orientation: .up)
    }
    
    private func flipImageHorizontally(_ image: UIImage) -> UIImage {
        guard let cgImage = image.cgImage else { return image }
        
        let width = cgImage.width
        let height = cgImage.height
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
        
        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: bitmapInfo.rawValue
        ) else {
            return image
        }
        
        // Flip horizontally by translating and scaling
        context.translateBy(x: CGFloat(width), y: 0)
        context.scaleBy(x: -1.0, y: 1.0)
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        
        guard let flippedCGImage = context.makeImage() else {
            return image
        }
        
        return UIImage(cgImage: flippedCGImage, scale: image.scale, orientation: .up)
    }
    
    private func showError(_ message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

@available(iOS 13.0, *)
extension SelfieVerificationViewController: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        isCapturing = false
        
        guard let imageData = photo.fileDataRepresentation(),
              let image = UIImage(data: imageData) else {
            return
        }
        
        // Fix image orientation and flip horizontally for front camera mirror effect
        let fixedImage = fixImageOrientation(image)
        
        DispatchQueue.main.async { [weak self] in
            self?.stopCamera()
            self?.previewImageView.image = fixedImage
            self?.previewImageView.isHidden = false
            self?.captureButton.isHidden = true
            self?.retakeButton.isHidden = false
            self?.submitButton.isHidden = false
        }
    }
}

