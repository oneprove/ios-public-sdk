//
//  JobsReloadOperation.swift
//  VeracitySDK
//
//  Created by Andrew on 18/06/2019.
//  Copyright © 2019 Veracity Protocol s.r.o. All rights reserved.
//

import Foundation

///Simple custom operation that updates local `Job` data with remote data.
public class JobsReloadOperation: VPOperation {
    override public func main() {
        guard isCancelled == false else {
            finish(true)
            return
        }
        
        executing(true)
        NetworkClient.jobs(clearCache: true) { [weak self] (_, _) in
            self?.executing(false)
            self?.finish(true)
        }
    }
}
