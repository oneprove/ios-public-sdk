//
//  CreateBatchJobOperation.swift
//  Veracity Authenticator
//
//  Created by Minh Chu on 3/18/21.
//  Copyright © 2021 ONEPROVE s.r.o. All rights reserved.
//

import UIKit

class CreateBatchJobOperation: VPOperation {
    var batchJob : BatchJob?
    var error : Error?
    
    override func main() {
        guard isCancelled == false else {
            finish(true)
            return
        }
        
        executing(true)
        debugLog("start")
        NetworkClient.createNewBatchJob { [weak self] (batchJob, error) in
            debugLog("finish")
            self?.batchJob = batchJob
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
