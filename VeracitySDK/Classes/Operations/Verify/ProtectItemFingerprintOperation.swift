//
//  ProtectItemFingerprintOperation.swift
//  VeracitySDK
//
//  Created by Andrew on 24/05/2019.
//

import Foundation

class ArtworkFingerprintOperation: VPOperation {
    var artworkID : String
    var fingerprint : Fingerprint?
    var error : Error?
    
    init(artworkID : String) {
        self.artworkID = artworkID
        super.init()
    }
    
    override func main() {
        guard isCancelled == false else {
            finish(true)
            return
        }
        
        executing(true)
        debugLog("start")
        NetworkClient.protectItemFingerprint(itemID: artworkID) { [weak self] (fingerprint, error) in
            debugLog("finish")
            self?.fingerprint = fingerprint
            self?.error = error
            self?.progressCallback?(Progress(totalUnitCount: 1000), false, true)
            if let finishingBlock = self?.finishingBlock {
                finishingBlock()
            }else {
                self?.endOperation()
            }
        }
    }
}

