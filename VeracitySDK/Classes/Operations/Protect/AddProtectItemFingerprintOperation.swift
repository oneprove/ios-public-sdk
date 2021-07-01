//
//  AddProtectItemFingerprintOperation.swift
//  VeracitySDK
//
//  Created by Andrew on 24/05/2019.
//

import Foundation
import RealmSwift

class AddProtectItemFingerprintsOperation: VPOperation {
    var artworkReference : ThreadSafeReference<LocalProtectItem>
    var jobID : String?
    var error : Error?
    
    init(artwork : ThreadSafeReference<LocalProtectItem>) {
        self.artworkReference = artwork
        super.init()
    }
    
    override func main() {
        guard isCancelled == false else {
            finish(true)
            return
        }
        
        executing(true)
        debugLog("start")
        NetworkClient.addItemFingerprints(artworkReference) { [weak self] (jobID, error) in
            debugLog("finish")
            self?.jobID = jobID
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
