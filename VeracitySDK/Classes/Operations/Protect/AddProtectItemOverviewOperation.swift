//
//  AddProtectItemOverviewOperation.swift
//  VeracitySDK
//
//  Created by Andrew on 24/05/2019.
//

import Foundation
import RealmSwift

class AddProtectItemOverviewOperation: VPOperation {
    var artworkReference : ThreadSafeReference<LocalProtectItem>
    var success : Bool = false
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
        NetworkClient.addItemOverview(artworkReference) { [weak self] (success, error) in
            debugLog("finish")
            self?.success = success
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
