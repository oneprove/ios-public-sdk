//
//  JobResultChecker.swift
//  VeracitySDK
//
//  Created by Andrew on 19/09/2019.
//  Copyright © 2019 Veracity Protocol s.r.o. All rights reserved.
//

import Foundation
import RealmSwift

///Class that replaces notifications. It can monitore finished upload tasks and wait for analyzing result.
public class JobResultChecker : NSObject {
    public static let shared = JobResultChecker()
    
    fileprivate var protectItems : Results<LocalProtectItem>?
    fileprivate var protectItemsNotificationToken : NotificationToken?
    fileprivate var jobs : Results<LocalJob>?
    fileprivate var jobsNotificationToken : NotificationToken?
    
    private var monitoringID : String?
    private var cycleCount : Int = 0
    
    private override init() {
        super.init()
    }
    
    ///Starts automaticaly observing remote results on local items that finished upload and started analyzing state.
    ///When observing item is complete then the result is persisted to database.
    public func setupObserving() {
        protectItemsNotificationToken?.invalidate()
        protectItems = RealmHandler.shared.getObjects(of: LocalProtectItem.self).filter("jobID != nil")
        protectItemsNotificationToken = protectItems?.observe({ (change) in
            self.tryToStartPulling()
        })
        
        jobsNotificationToken?.invalidate()
        jobs = RealmHandler.shared.getObjects(of: LocalJob.self).filter("jobID != nil")
        jobsNotificationToken = jobs?.observe({ (change) in
            self.tryToStartPulling()
        })
    }
}

private extension JobResultChecker {
    func tryToGetJobID() -> String? {
        return jobs?.first?.jobID ?? protectItems?.first?.jobID
    }
    
    func tryToStartPulling() {
        guard monitoringID == nil else { return }
        if let jobID = tryToGetJobID() {
            updateJob(jobID)
        }
    }
    
    func updateJob(_ identifier : String?) {
        monitoringID = identifier
        guard let identifier = identifier else { return }
        
        NetworkClient.job(byID: identifier) { [weak self] (job, error) in
            self?.handleUpdatedJob(job)
        }
    }
    
    func handleUpdatedJob(_ job : Job?) {
        func reset() {
            monitoringID = nil
            cycleCount = 0
        }
        
        if let job = job, job.jobType == .verification, job.completed {
            reset()
            DispatchQueue.main.async {
                RealmHandler.shared.add(job, modifiedUpdate: true)
            }
        } else if let job = job,
                  job.jobType == .batchVerification,
                  // Make sure all childs are completed
                  job.childJobs.first(where: { !$0.completed }) == nil {
            reset()
            DispatchQueue.main.async {
                RealmHandler.shared.add(job, modifiedUpdate: true)
            }
        } else if job?.jobType == .protection, let artwork = job?.artwork, artwork.state != .analyzing {
            reset()
            DispatchQueue.main.async {
                debugLog(job?.error)
                debugLog(artwork.errorMessage)
                if let lclArtwork = job?.artwork {
                    lclArtwork.createdByID = artwork.createdByID
                    lclArtwork.jobID = job?.identifier
                    lclArtwork.errorMessage = job?.error
                    lclArtwork.metadataString = artwork.metadataString
                    RealmHandler.shared.add(lclArtwork, modifiedUpdate: true)
                }
            }
        } else {
            if ConnectionManager.shared.isConnected() {
                cycleCount += 1
            }else {
                cycleCount = 0
            }
            guard cycleCount <= 30 else { reset(); return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                self.updateJob(self.monitoringID)
            }
        }
    }
}
