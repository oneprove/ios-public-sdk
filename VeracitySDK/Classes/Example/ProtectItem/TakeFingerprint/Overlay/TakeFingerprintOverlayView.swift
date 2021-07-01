//
//  TakeFingerprintOverlayView.swift
//  Veracity Authenticator
//
//  Created by Minh Chu on 3/11/21.
//  Copyright © 2021 ONEPROVE s.r.o. All rights reserved.
//

import UIKit
import BlurDetector

protocol TakeFingerprintOverlayViewDelegate: AnyObject {
    func onTakenOverlayFingers(photos: [(blurScore: Float, image: UIImage)])
}


class TakeFingerprintOverlayView: UIView {
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var cameraStreamView: CameraStreamPreview!
    @IBOutlet weak var snapPhotoButton: UIButton!
    @IBOutlet weak var flashButton: UIButton!
    private weak var overlayImageView: UIImageView?
    private weak var toastView: AppToastView?
    
    public weak var delegate: TakeFingerprintOverlayViewDelegate?
    private var blurScore : Double?
    private var fingerprintPhotos: [(blurScore: Float, image: UIImage)] = []
    private var createItemStream: MutableProtectItemStream?
    private var verifyItemStream: MutableVerifyItemStream?
    
    init(createItemStream: MutableProtectItemStream?, verifyItemStream: MutableVerifyItemStream?) {
        self.createItemStream = createItemStream
        self.verifyItemStream = verifyItemStream
        super.init(frame: .zero)
        
        self.setupView()
        
        // Delay to make sure view layout did load
        Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(updateLayout), userInfo: nil, repeats: false)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    private func turnOnFlash() {
        guard isUserOnFlash(),
              let device = cameraStreamView.captureDevice,
              !device.isTorchActive
        else { return }
        
        _ = DeviceManager.shared.toggleFlashlight(turnOn: true, for: device, 1.0)
    }
    
    private func turnOffFlash() {
        guard let device = cameraStreamView.captureDevice,
              device.isTorchActive
        else { return }
        
        _ = DeviceManager.shared.toggleFlashlight(turnOn: false, for: device, 1.0)
    }
    
    private func isUserOnFlash() -> Bool {
        return !flashButton.isSelected
    }
    
    private func isSmallFingerprint() -> Bool {
        return CreateItemHelper.isSmallFingerprint(dimension: createItemStream?.dimension)
    }
    
    private func isVerificationFlow() -> Bool {
        guard let _ = verifyItemStream else {
            return false
        }
        
        return true
    }
    
    private func startCamera() {
        guard !cameraStreamView.isSessionRunning() else {
            return
        }
        
        cameraStreamView.activateSession()
        turnOnFlash()
    }
    
    public func stopCamera() {
        hideToast()
        overlayImageView?.removeFromSuperview()
        cameraStreamView.deactivateSession()
        cameraStreamView.removeShapeOverlay()
    }
    
    // MARK: - Photo Taken Handle
    private func runBlurDetector(sourceImage: UIImage) {
        let maskFactor = isSmallFingerprint() ? 1 : BlurDetector.defaultMaskFactor
        BlurDetector.evaluate(image: sourceImage, maskFactor: maskFactor) { [weak self] (score, _) in
            DispatchQueue.main.async {
                self?.handleBlurDetectResult(score, photo: sourceImage)
            }
        }
    }
    
    private func handleBlurDetectResult(_ blurScore: Double, photo: UIImage) {
        self.blurScore = blurScore
        if blurScore > Constants.blurDetectScoreLimit {
            let message = "\(Text.blurErrorTitle.localizedText.uppercased())\n\n\(Text.blurErrorMessage.localizedText)"
            
            self.startCamera()
            self.showToastMessage(message, type: .error, position: .bottom)
        } else {
            self.onTakenFinger(photo: (Float(blurScore), photo))
        }
    }
    
    /// If This is Verification flow
    /// - Confirm photo taken
    /// - Then submit to complete Verify flow
    ///
    /// If This is Protect flow
    /// - Taken 2 fingers then submit to complete Upload flow
    /// - Else continue take second finger
    /// - Parameter photo: photo description
    private func onTakenFinger(photo: (blurScore: Float, image: UIImage)) {
        
        /// Verification
        if isVerificationFlow() {
            let confirmFingerView = FingerprintConfirmView()
            confirmFingerView.delegate = self
            confirmFingerView.blurScore = blurScore
            turnOffFlash()
            confirmFingerView.show(in: self, photo: photo.image)
            return
        }
        
        /// Protection
        fingerprintPhotos.append(photo)
        if fingerprintPhotos.count > 1 {
            self.delegate?.onTakenOverlayFingers(photos: fingerprintPhotos)
        } else {
            self.startCamera()
            self.cameraStreamView.removeShapeOverlay()
            self.setupFingerprintOverlay(photo: fingerprintPhotos.first?.image)
            self.showStatusLabel(message: Text.takeFingerOverlayStep2Message.localizedText)
        }
    }
    
    // MARK: - Action
    @IBAction func flashPressed(_ sender: Any) {
        let turnON = flashButton.isSelected
        flashButton.isSelected = !turnON
        
        if turnON {
            self.turnOnFlash()
        } else {
            self.turnOffFlash()
        }
    }
    
    @IBAction func snapPhotoPressed(_ sender: Any) {
        cameraStreamView.takePhoto()
    }
    
    private func showToastMessage(_ message: String, type: ToastType, position: ToastPosition) {
        if let toast = self.toastView {
            toast.hide()
        }
        let toast = AppToastView()
        self.toastView = toast
        toast.rightButton.addTarget(self, action: #selector(hideToast), for: .touchUpInside)
        toast.show(message: message, type: type, position: position, autoHiden: true)
    }
    
    @objc func hideToast() {
        self.toastView?.hide()
    }
    
    private func showStatusLabel(message: String) {
        let statusView = StatusView()
        statusView.show(in: cameraStreamView,
                        message: message,
                        position: .top)
    }
    
    @objc func updateLayout() {
        self.setupVerifyPhotoOverlay()
        self.setupRectOverlay()
        self.turnOnFlash()
        
        // Show message label
        if isVerificationFlow() {
            self.showStatusLabel(message: Text.takeFingerOverlayVerifyMessage.localizedText)
        } else {
            if AppManager.selectedVertical == .lpmPoc {
                self.showStatusLabel(message: Text.takeLPMFingerOverlayStep1Message.localizedText)
            } else {
                self.showStatusLabel(message: Text.takeFingerOverlayStep1Message.localizedText)
            }
        }
    }
    
    // MARK: - Setup
    private func setupView() {
        Bundle.main.loadNibNamed("TakeFingerprintOverlayView", owner: self, options: nil)
        addSubview(contentView)
        
        contentView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        
        cameraStreamView.delegate = self
        startCamera()
    }
    
    /// Overlay with Green Box only for LPM POC vertical on Protect flow
    private func setupRectOverlay() {
        guard AppManager.selectedVertical == .lpmPoc, !isVerificationFlow() else {
            return
        }
        
//        let width = cameraStreamView.bounds.width - 2*30
//        let height = cameraStreamView.bounds.height - 2*30
//        cameraStreamView.setupOverlay(CGSize(width: width, height: height), lineColor: AppColor.lightGreen1)
    }
    
    /// Only show overlay image photo overview in the take finger second time
    /// - Parameter overlayImage: overlayImage from crop overview photo
    private func setupFingerprintOverlay(photo overlayImage: UIImage?) {
        guard !isSmallFingerprint() else {
            return
        }
        
        let overlayImageView = UIImageView(image: overlayImage)
        self.overlayImageView = overlayImageView
        overlayImageView.alpha = 0.4
        
        insertSubview(overlayImageView, belowSubview: snapPhotoButton)
        overlayImageView.snp.makeConstraints { (make) in
            make.edges.equalTo(cameraStreamView)
        }
    }
    
    /// Show overlay photo for only Verification flow
    private func setupVerifyPhotoOverlay() {
        guard let verifyStream = verifyItemStream else {
            return
        }
        
        if let photo = verifyStream.overlayPhoto {
            setupFingerprintOverlay(photo: photo)
        } else {
            verifyStream.observerOverlayPhotoCallBack { [weak self] (photo) in
                self?.setupFingerprintOverlay(photo: photo)
            }
        }
    }
}

// MARK: - Camera Stream Delegate
extension TakeFingerprintOverlayView: CameraStreamDelegate {
    func didTakeImage(_ image: UIImage) {
        self.runBlurDetector(sourceImage: image)
    }
    
    func didFailedToTakeImage(_ error: Error) {
        errorLog(error.localizedDescription)
    }
}

// MARK: - FingerprintConfirmView Delegate
extension TakeFingerprintOverlayView: FingerprintConfirmViewDelegate {
    func confirmedFingerprintPhoto(_ photo: UIImage, blurScore: Double) {
        fingerprintPhotos.append((Float(blurScore), photo))
        self.delegate?.onTakenOverlayFingers(photos: fingerprintPhotos)
    }
    
    func retakeFinger() {
        self.startCamera()
    }
}
