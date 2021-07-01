//
//  CreateProtectItemOperation.swift
//  VeracitySDK
//
//  Created by Andrew on 24/05/2019.
//

import Foundation
import RealmSwift

class CreateProtectItemOperation: VPOperation {
    var artworkReference : ThreadSafeReference<LocalProtectItem>
    var walletReference : ThreadSafeReference<Wallet>?
    var createdArtwork : ProtectItem?
    var error : Error?
    
    init(artwork : ThreadSafeReference<LocalProtectItem>, wallet: ThreadSafeReference<Wallet>?) {
        self.artworkReference = artwork
        self.walletReference = wallet
        super.init()
    }
    
    override func main() {
        guard isCancelled == false else {
            finish(true)
            return
        }
        
        executing(true)
        debugLog("start")
        NetworkClient.createProtectItem(artworkReference, wallet: walletReference) { [weak self] (artwork, error) in
            debugLog("finish")
            self?.createdArtwork = artwork
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
