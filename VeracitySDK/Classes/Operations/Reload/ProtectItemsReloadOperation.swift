//
//  ProtectItemsReloadOperation.swift
//  VeracitySDK
//
//  Created by Andrew on 18/06/2019.
//  Copyright © 2019 Veracity Protocol s.r.o. All rights reserved.
//

import Foundation

///Simple custom operation that updates local `Artwork` data with remote data.
public class ProtectItemsReloadOperation: VPOperation {
    override public func main() {
        guard isCancelled == false else {
            finish(true)
            return
        }
        
        executing(true)
        NetworkClient.myProtectedItems(clearCache: true) { [weak self] (_, _) in
            NotificationCenter.default.post(name: NotificationsNames.downloadedRemoteItems, object: nil)
            self?.executing(false)
            self?.finish(true)
        }
    }
}
