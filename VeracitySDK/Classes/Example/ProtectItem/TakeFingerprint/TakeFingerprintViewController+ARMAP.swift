//
//  TakeFingerprintViewController+ARMAP.swift
//  Veracity Authenticator
//
//  Created by Minh Chu on 3/11/21.
//  Copyright © 2021 ONEPROVE s.r.o. All rights reserved.
//

import UIKit
import ARCameraController


extension TakeFingerprintViewController {
    
    /// Button camera mode has 2 state
    /// - Selected: Normal Mode
    /// - Normal: AR mode
    /// - Returns: true if it is ar mode
    internal func isARMode() -> Bool {
        return !cameraModeButton.isSelected
    }
    
    internal func switchToNormalMode() {
        flashButton.isHidden = false
        cameraModeButton.isSelected = true
        snapPhotoButton.isHidden = false
        fingerprintARView?.stop()
        fingerprintNormalView?.stop()
        
        let fingerprintNormalView = TakeFingerprintNormalView(delegate: self, createItemStream: createItemStream, verifyItemStream: verifyItemStream)
        fingerprintNormalView.start(in: cameraContainerView)
        self.fingerprintNormalView = fingerprintNormalView
        
        if let fingerInfo = self.fingerInfo {
            fingerprintNormalView.setupProposal(fingerInfo.rect,
                                                 sourceImage: fingerInfo.overviewPhoto,
                                                 dimension: fingerInfo.dimension)
        }
    }
    
    internal func switchToARMode() {
        flashButton.isHidden = false
        cameraModeButton.isSelected = false
        snapPhotoButton.isHidden = true
        fingerprintARView?.stop()
        fingerprintNormalView?.stop()
        
        let fingerprintARView = TakeFingerprintARView(delegate: self)
        fingerprintARView.start(in: cameraContainerView)
        self.fingerprintARView = fingerprintARView
        
        if let fingerInfo = self.fingerInfo {
            fingerprintARView.setProposal(fingerInfo.rect,
                                           sourceImage: fingerInfo.overviewPhoto,
                                           dimension: fingerInfo.dimension)
        }
    }
    
    internal func flashLightHandle() {
        let isOff = flashButton.isSelected
        if isOff {
            turnOffFlashlight()
        } else {
            turnOnFlashlight()
        }
    }
    
    internal func turnOnFlashlight() {
        let isAR = isARMode()
        if isAR {
            fingerprintARView?.turnOnFlash()
        } else {
            fingerprintNormalView?.turnOnFlash()
        }
        
        flashButton.isSelected = false
    }
    
    internal func turnOffFlashlight() {
        let isAR = isARMode()
        if isAR {
            fingerprintARView?.turnOffFlash()
        } else {
            fingerprintNormalView?.turnOffFlash()
        }
        
        flashButton.isSelected = true
    }

}



// MARK: TakeFingerprintARView Delegate
extension TakeFingerprintViewController: TakeFingerprintARViewDelegate {
    func cameraSetupCompleted(status: ARInitializationStatus) {
        flashLightHandle()
        if let descriptorStatus = status.descriptor {
            checkDescriptorStatus(descriptorStatus)
        }
    }
    
    func onTakenARFingerprint(photos: [ImageBlurrinessResult]) {
        self.onTakenFingers(photos: photos.map{($0.score, $0.image)})
    }
    
    private func checkDescriptorStatus(_ status: DescriptorStatus) {
        switch status {
        case .suboptimal:
            break
        case .nonoptimal:
            flashLightHandle()
        default:
            break
        }
    }
}

// MARK: TakeFingerprintNormalView Delegate
extension TakeFingerprintViewController: TakeFingerprintNormalViewDelegate {
    func normalCameraSetupCompleted() {
        Timer.scheduledTimer(withTimeInterval: 1,
                             repeats: false) { [weak self] (_) in
                self?.flashLightHandle()
        }
    }
    
    func onTakenNormalFingers(photos: [(blurScore: Float, image: UIImage)]) {
        self.onTakenFingers(photos: photos)
    }
    
}
