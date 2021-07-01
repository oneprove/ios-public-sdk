//
//  TakeFingerprintARView.swift
//  Veracity Authenticator
//
//  Created by Minh Chu on 2/9/21.
//  Copyright © 2021 ONEPROVE s.r.o. All rights reserved.
//

import UIKit
import ARCameraController
import FingerprintFinder


protocol TakeFingerprintARViewDelegate: AnyObject {
    func cameraSetupCompleted(status: ARInitializationStatus)
    func onTakenARFingerprint(photos: [ImageBlurrinessResult])
}

class TakeFingerprintARView: UIView {

    @IBOutlet var contentView: UIView!
    @IBOutlet weak var flashCoverView: UIView!
    @IBOutlet weak var cameraPreview: UIImageView!
    @IBOutlet weak var statusView: UIView!
    @IBOutlet weak var statusLabel: UILabel!
    
    private weak var delegate: TakeFingerprintARViewDelegate?
    public var cameraController: ARCameraController?
    private var lastCameraControllerState: ARCameraControllerState?
    
    init(delegate: TakeFingerprintARViewDelegate) {
        self.delegate = delegate
        super.init(frame: .zero)
        self.setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.setup()
    }
    
    public func start(in parentView: UIView) {
        self >>> parentView >>> {
            $0.snp.makeConstraints {
                $0.edges.equalToSuperview()
            }
        }
    }
    
    public func stop() {
        turnOffFlash()
        cameraController?.stop()
        cameraController = nil
        self.removeFromSuperview()
    }
    
    public func turnOnFlash() {
        guard
            let cameraController = cameraController,
            !cameraController.isTorchActive
        else { return }
        
        _ = cameraController.toggleTorch(level: 1.0)
    }
    
    public func turnOffFlash() {
        guard
            let cameraController = cameraController,
            cameraController.isTorchActive
        else { return }
        
        _ = cameraController.toggleTorch(level: 1.0)
    }
    
    private func setup() {
        let bundle = Bundle(for: TakeFingerprintARView.self)
        bundle.loadNibNamed("TakeFingerprintARView", owner: self, options: nil)
        addSubview(contentView)
        
        contentView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }
    
    func setProposal(_ rect: CGRect, sourceImage: UIImage, dimension: (width: Double, height: Double)) {
        setupCameraController(fingerprintRect: rect, sourceImage: sourceImage, dimension: dimension)
    }
    
    private func setupCameraController(fingerprintRect: CGRect, sourceImage: UIImage, dimension: (width: Double, height: Double)) {
        guard cameraController == nil else {
            return
        }
        
        var fingerprintCropOperation: FingerprintPreprocessingOperation?
        if ProtectItemHelper.isSmallFingerprint(dimension: dimension) {
            fingerprintCropOperation = { (fingerprint: UIImage) -> UIImage in
                return FingerprintFinder.cropped(fingerprint: fingerprint, overviewSize: CGSize(width: dimension.width, height: dimension.height))
            }
        }
        
        cameraController = ARCameraController(overviewImage: sourceImage, fingerprintRect: fingerprintRect, fingerprintPreprocessing: fingerprintCropOperation, completion: { [weak self] (status) in
            self?.delegate?.cameraSetupCompleted(status: status)
        })
        
        showPoitingGuideView()
        cameraController?.delegate = self
        cameraController?.previewView = cameraPreview
    }
    
    private func setupStatusLabel(_ state: ARCameraControllerState?) {
        lastCameraControllerState = state
        guard let state = state else {
            statusLabel.text = ""
            statusView.isHidden = true
            return
        }
        switch state {
        case .capturing:
            self.statusLabel.text = "Hold steady, taking pictures"
            self.statusView.isHidden = false
        case .tracking:
            hideGuidingAreaView()
        case .lost:
            animateTrackingLostState()
        case .tooClose:
            statusLabel.text = "Move back to fit the highlighted area in the view."
            statusView.isHidden = false
        default:
            break
        }
    }
    
    private func showPoitingGuideView() {
        let poitingGuideView = UIImageView(image: UIImage(named: "ar_pointing_onboard"))
        poitingGuideView.alpha = 0
        cameraPreview.addSubview(poitingGuideView)
        poitingGuideView.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
        }
        
        statusLabel.text = String.init(format: "Point the camera at the %@ at a straight angle", AppManager.itemName.lowercased())
        statusView.isHidden = false
        statusView.alpha = 0
        statusView.transform = CGAffineTransform(scaleX: 0.8, y: 1)
        
        let colorOverlayView = cameraPreview.subviews.first(where: { $0.tag == 1 })
        
        UIView.animate(withDuration: 0.4, delay: 1, options: [], animations: {
            self.statusView.transform = .identity

            poitingGuideView.alpha = 1
            self.statusView.alpha = 1
        }) { (_) in
            UIView.animate(withDuration: 0.4, delay: 2, options: [], animations: {
                poitingGuideView.alpha = 0
                colorOverlayView?.alpha = 0
                self.statusView.alpha = 0
            }) { (_) in
                poitingGuideView.removeFromSuperview()
                colorOverlayView?.removeFromSuperview()

                self.showGuidingAreaFrame()
            }
        }
    }
    
    
    private func showGuidingAreaFrame() {
        guard lastCameraControllerState == .initialization || lastCameraControllerState == .lost
            && cameraPreview.subviews.first(where: { $0.tag == 2 }) == nil else { return }
        
        let guidingAreaView = UIImageView(image: UIImage(named: "ar_pointing_area"))
        guidingAreaView.tag = 2
        guidingAreaView.alpha = 0
        cameraPreview.addSubview(guidingAreaView)
        
        guidingAreaView.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
        }
        
        guidingAreaView.addOutsideBorder(width: 60, color: UIColor.black.withAlphaComponent(0.6))
        
        statusLabel.text = String(format: "Fit the entire %@ into the frame", AppManager.itemName.lowercased())
        statusView.transform = CGAffineTransform(scaleX: 0.8, y: 1)
        
        UIView.animateKeyframes(withDuration: 0.4, delay: 0, options: [], animations: {
            UIView.addKeyframe(withRelativeStartTime: 0, relativeDuration: 1) {
                self.statusView.transform = .identity
                guidingAreaView.alpha = 1
                self.statusView.alpha = 1
            }
        })
    }
    
    private func hideGuidingAreaView() {
        let guidingAreaView = cameraPreview.subviews.first(where: { $0.tag == 2 })
        
        UIView.animate(withDuration: 0.4, delay: 0, options: [], animations: {
            guidingAreaView?.alpha = 0
            self.statusView.alpha = 0
        }) { (_) in
            guidingAreaView?.removeFromSuperview()
            
            self.statusLabel.text = "Now move closer towards the red rectangle"
            self.statusView.transform = CGAffineTransform(scaleX: 0.8, y: 1)
            self.statusView.isHidden = false
            
            UIView.animate(withDuration: 0.4, delay: 0, options: [], animations: {
                self.statusView.transform = .identity
                self.statusView.alpha = 1
            }) { (_) in
                //completion
            }
        }
    }
    
    private func animateTrackingLostState() {
        guard cameraPreview.subviews.first(where: { $0.tag == 2 }) == nil else {
            return
        }
        
        self.statusLabel.text = "Tracking lost. Move back a little to resume tracking."
        self.statusView.isHidden = false
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            guard self.lastCameraControllerState == .lost else {
                return
            }
            
            self.showGuidingAreaFrame()
        }
    }
    
    private func flashView() {
        flashCoverView.alpha = 1
        UIView.animate(withDuration: 0.2, delay: 0.05, options: .curveEaseOut, animations: {
            self.flashCoverView.alpha = 0
        }, completion: nil)
    }
    
    @objc func resetCamera() {
//        cameraController?.reset()
    }
    
    private func showToastMessage(_ message: String) {
        guard let vc = self.parentViewController else {
            return
        }
        let alert = UIAlertController(title: message)
        vc.present(alert, animated: true, completion: nil)
    }
}

extension TakeFingerprintARView: ARCameraControllerDelegate {
    func cameraController(_ controller: ARCameraController, stateDidChange state: ARCameraControllerState) {
        DispatchQueue.main.async {
            if state != .success {
            }
            
            self.setupStatusLabel(state)
        }
    }
    
    func cameraController(_ controller: ARCameraController, willCapturePhotoWithProgress progress: Progress) {
        statusLabel.text = String(format: "Hold steady, taking pictures %@", "\(progress.completedUnitCount)/\(progress.totalUnitCount)")
        self.flashView()
    }
    
    func cameraController(_ controller: ARCameraController, didCapturePhoto photo: UIImage, withProgress progress: Progress) {
        //
    }
    
    func cameraController(_ controller: ARCameraController, didFindBestPhotos photos: [ImageBlurrinessResult]) {
        guard photos.count > 1 else { return }
        
        if photos.allSatisfy({ $0.score > 0.5 }) {
            statusLabel.text = "Bad quality photo may produce skewed results"
            
            let message = "\("Please retake the photo".uppercased())\n\n\("The photo you took is blurry and would not allow our system to work responsibly.")"
            self.showToastMessage(message)
            controller.reset()
            return
        }
        
        bestEvaluatedPhotos(photos: photos)
    }
    
    func cameraController(_ controller: ARCameraController, didLostAndNotRecoverFor interval: TimeInterval) {
        controller.reset()
    }
    
    func bestEvaluatedPhotos(photos: [ImageBlurrinessResult]) {
        guard photos.count > 1 else { return }
        
        self.delegate?.onTakenARFingerprint(photos: photos)
    }
}
