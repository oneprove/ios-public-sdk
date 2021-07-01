//
//  TakeFingerprintNormalView.swift
//  Veracity Authenticator
//
//  Created by Minh Chu on 2/9/21.
//  Copyright © 2021 ONEPROVE s.r.o. All rights reserved.
//

import UIKit
import AVFoundation
import MAPView
import CameraCapture
import BlurDetector
import FingerprintFinder


protocol TakeFingerprintNormalViewDelegate: class {
    func normalCameraSetupCompleted()
    func onTakenNormalFingers(photos: [(blurScore: Float, image: UIImage)])
}

class TakeFingerprintNormalView: UIView {
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var mapView: MAPView?
    @IBOutlet weak var flashCoverView: UIView!
    @IBOutlet weak var zoomLabel: UILabel!
    @IBOutlet weak var zoomSlider: UISlider!
    private weak var confirmFingerView: FingerprintConfirmView?
    
    private weak var delegate: TakeFingerprintNormalViewDelegate?
    private var createItemStream: MutableProtectItemStream?
    private var verifyItemStream: MutableVerifyItemStream?
    private var fingerprintPhotos: [(blurScore: Float, image: UIImage)] = []
    private var dimension: (width: Double, height: Double)?
    
    init(delegate: TakeFingerprintNormalViewDelegate,
         createItemStream: MutableProtectItemStream?,
         verifyItemStream: MutableVerifyItemStream?) {
        self.delegate = delegate
        self.createItemStream = createItemStream
        self.verifyItemStream = verifyItemStream
        super.init(frame: .zero)
        self.setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.setup()
    }
    
    public func start(in parentView: UIView) {
        parentView.addSubview(self)
        self.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        
        /// Delay to make sure view did layout then ready start camera
        Timer.scheduledTimer(timeInterval: 0.5,
                             target: self,
                             selector: #selector(startCamera),
                             userInfo: nil,
                             repeats: false)
    }
    
    public func stop() {
        turnOffFlash()
        mapView?.stop()
        confirmFingerView?.hide()
        confirmFingerView = nil
        self.removeFromSuperview()
    }
    
    @objc func startCamera() {
        mapView?.start()
    }
    
    public func turnOnFlash() {
        guard let mapView = mapView, !mapView.isTorchActive else {
            return
        }
        
        _ = mapView.toggleTorch()
    }
    
    public func turnOffFlash() {
        guard let mapView = mapView, mapView.isTorchActive else {
            return
        }
        
        _ = mapView.toggleTorch()
    }
    
    public func setupProposal(_ value: CGRect, sourceImage: UIImage?, dimension: (width: Double, height: Double)) {
        guard let overview = sourceImage, value != .zero else {
            debugLog("Overview photo or Finger rect is null")
            return
        }
        
        self.dimension = dimension
        mapView?.locateFingerprint(overviewImage: overview, fingerprintRect: value) { [weak self] in
            self?.delegate?.normalCameraSetupCompleted()
        }
        
        // visiable zoom slider
        checkZoomView(dimension: dimension)
    }
    
    private func checkZoomView(dimension: (width: Double, height: Double)) {
        let small = isSmallFingerprint(dimension: dimension)
        guard small else {
            visiableZoom(true)
            return
        }
        
        visiableZoom(false)
        zoomSlider.value = 1
        mapView?.changeZoom(value: 1)
    }
    
    private func visiableZoom(_ visiable: Bool) {
        zoomLabel.isHidden = !visiable
        zoomSlider.isHidden = !visiable
    }
    
    private func isSmallFingerprint(dimension: (width: Double, height: Double)) -> Bool {
        return ProtectItemHelper.isSmallFingerprint(dimension: dimension)
    }
    
    public func takeFingerprint() {
        flashView()
        mapView?.captureFingerprintPhoto()
    }
    
    private func flashView() {
        flashCoverView.alpha = 1
        UIView.animate(withDuration: 0.2, delay: 0.05, options: .curveEaseOut, animations: {
            self.flashCoverView.alpha = 0
        })
    }
    
    private func showToastMessage(_ message: String) {
        guard let vc = self.parentViewController else {
            return
        }
        let alert = UIAlertController(title: message)
        vc.present(alert, animated: true, completion: nil)
    }
    
    @IBAction func zoomDidChanged(_ sender: UISlider) {
        let value = CGFloat(sender.value)
        mapView?.changeZoom(value: value)
    }
    
    private func setup() {
        let bundle = Bundle(for: TakeFingerprintNormalView.self)
        bundle.loadNibNamed("TakeFingerprintNormalView", owner: self, options: nil)
        addSubview(contentView)
        
        mapView?.delegate = self
        
        contentView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }
}


//MARK: MAPView Delegate
extension TakeFingerprintNormalView: CameraCaptureDelegate {
    func cameraCapture(_ capture: CameraCapture, didCaptureVideoFrame frame: CMSampleBuffer) {
    }
    
    func cameraCapture(_ capture: CameraCapture, didCapturePhoto photo: CVPixelBuffer?, error: Error?) {
        debugLog(error?.localizedDescription ?? "")
        guard let pixelBuffer = photo, error == nil else {
            return
        }
        
        guard var photo = CameraCapture.convert(pixelBuffer: pixelBuffer) else {
            return
        }
        
        if let dimension = self.dimension, ProtectItemHelper.isSmallFingerprint(dimension: dimension) {
            photo = FingerprintFinder.cropped(fingerprint: photo, overviewSize: CGSize(width: dimension.width, height: dimension.height))
        }
        
        didCapturePhoto(photo, error: error)
    }
    
    private func didCapturePhoto(_ photo: UIImage?, error: Error?) {
        guard self.confirmFingerView == nil else {
            return
        }
        
        guard let photo = photo, let view = parentViewController?.view else {
            return
        }
        
        let confirmFingerView = FingerprintConfirmView()
        self.confirmFingerView = confirmFingerView
        confirmFingerView.delegate = self
        confirmFingerView.setCreateItemStream(createItemStream)
        confirmFingerView.show(in: view, photo: photo)
    }
    
    private func didFailedToTakeImage(_ error: Error) {
        debugLog(error.localizedDescription)
    }
}

// MARK: - FingerprintNormalConfirmView Delegate
extension TakeFingerprintNormalView: FingerprintConfirmViewDelegate {
    func confirmedFingerprintPhoto(_ photo: UIImage, blurScore: Double) {
        fingerprintPhotos.append((Float(blurScore), photo))
        
        if verifyItemStream != nil || fingerprintPhotos.count > 1 {
            self.delegate?.onTakenNormalFingers(photos: fingerprintPhotos)
        } else {
            self.showToastMessage("Please take a picture of the same fingerprint again")
        }
    }
    
    func retakeFinger() {
        
    }
}

