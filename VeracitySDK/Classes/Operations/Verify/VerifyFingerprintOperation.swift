//
//  VerifyFingerprintOperation.swift
//  VeracitySDK
//
//  Created by Andrew on 24/05/2019.
//

import Foundation
import RealmSwift

class VerifyFingerprintOperation: VPOperation {
    var localJobReference : ThreadSafeReference<LocalJob>
    var localJobCoinReference : ThreadSafeReference<LocalJob>?
    var batchJobID : String?
    var jobID : String?
    var error : Error?
    
    init(localJob: ThreadSafeReference<LocalJob>, localJobCoin: ThreadSafeReference<LocalJob>? = nil, batchJob : String? = nil) {
        self.localJobReference = localJob
        self.localJobCoinReference = localJobCoin
        self.batchJobID = batchJob
        super.init()
    }
    
    override func main() {
        guard isCancelled == false else {
            finish(true)
            return
        }
        
        executing(true)
        debugLog("start - batchJob: \(batchJobID != nil)")
        if batchJobID == nil {
            NetworkClient.verifyFingerprint(localJob: localJobReference) { [weak self] (jobID, error) in
                debugLog("finish")
                self?.jobID = jobID
                self?.error = error
                self?.progressCallback?(Progress(totalUnitCount: 1000), false, true)
                if let finishingBlock = self?.finishingBlock {
                    finishingBlock()
                } else {
                    self?.endOperation()
                }
            }
        } else if let batchJobID = batchJobID {
            if AppManager.selectedVertical == .lpmPoc {
                addVerifyLPMLabelToBatchJob(batchJobID)
            } else {
                NetworkClient.addVerifyJobToBatchJob(verifyJob: localJobReference, batchJobID: batchJobID) { [weak self] (jobID, error) in
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
    }
    
    private func addVerifyLPMLabelToBatchJob(_ batchJobID: String) {
        NetworkClient.addVerifyJobToBatchJob(verifyJob: localJobReference, batchJobID: batchJobID, algo: "com.veracity.lpm") { [weak self] (jobID, error) in
            debugLog("finish")
            self?.jobID = jobID
            self?.error = error
            
            if let _ = jobID {
                self?.addVerifyLPMCoinToBatchJob(batchJobID)
            }
        }
    }
    
    private func addVerifyLPMCoinToBatchJob(_ batchJobID: String) {
        guard let jobCoin = localJobCoinReference else {
            return
        }
        
        NetworkClient.addVerifyJobToBatchJob(verifyJob: jobCoin, batchJobID: batchJobID, algo: "com.veracity.lpm.coin") { [weak self] (jobID, error) in
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
