//
//  StartBatchJobOperation.swift
//  VeracitySDK
//
//  Created by Andrew on 15/11/2019.
//  Copyright © 2019 Veracity Protocol s.r.o. All rights reserved.
//

import Foundation

class StartBatchJobOperation : VPOperation {
    var batchJobID : String
    var batchJob : Job?
    var error : Error?
    
    init(batchJobID : String) {
        self.batchJobID = batchJobID
        super.init()
    }
    
    override func main() {
        guard isCancelled == false else {
            finish(true)
            return
        }
        
        executing(true)
        debugLog("start")
        NetworkClient.startBatchJob(identifier: batchJobID) { [weak self] (jobs, error) in
            debugLog("finish")
            self?.batchJob = jobs
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
