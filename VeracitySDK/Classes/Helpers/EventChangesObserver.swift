//
//  EventChangesObserver.swift
//  VeracitySDK
//
//  Created by Andrew on 31/10/2019.
//  Copyright © 2019 Veracity Protocol s.r.o. All rights reserved.
//

import Foundation
import RealmSwift

@objc public protocol EventListenerDelegate : AnyObject {
    @objc optional func onProtectUploadingFinished(protectItem : LocalProtectItem)
    @objc optional func onProtectUploadingStarted(protectItem : LocalProtectItem)
    @objc optional func onProtectUploadingProgress(progress: Int, protectItem : LocalProtectItem)
//  @objc optional func onProtectUploadingFailed(failReason : String, protectItems : [ProtectItem])
    @objc optional func onProtectAnalyzingFinished(protectItems : [ProtectItem])
    
    @objc optional func onVerifyUploadingStarted(jobItem : LocalJob)
//  @objc optional func onVerifyUploadingFailed(failReason: String, jobItems : [LocalJob])
    @objc optional func onVerifyUploadingProgress(progress: Int, jobItem : LocalJob)
    @objc optional func onVerifyUploadingFinished(jobItem : LocalJob)
    @objc optional func onVerifyAnalyzingFinished(jobItems : [Job])
}

public class EventChangesObserver {
    public weak var delegate : EventListenerDelegate?
    
    var localJobNotificationToken : NotificationToken?
    var localJobs : Results<LocalJob>?
    var jobsNotificationToken : NotificationToken?
    var jobs : Results<Job>?
    
    var localProtectItemsNotificationToken : NotificationToken?
    var localProtectItems : Results<LocalProtectItem>?
    var protectItemsNotificationToken : NotificationToken?
    var protectItems : Results<ProtectItem>?
    
    public init() {
        setupLocalProtectItems()
        setupProtectItems()
        
        setupLocalVerifyItems()
        setupVerifyItems()
        
        UploadManager.shared.startObserving()
    }
    
    //MARK: - Protect Items
    ///Get LocalProtectItem items from realm and setup live update callback block.
    func setupLocalProtectItems() {
        localProtectItems = RealmHandler.shared.getObjects(of: LocalProtectItem.self)
        localProtectItemsNotificationToken = localProtectItems?.observe { [weak self] (change) in
            switch change {
            case .initial(_):
                break
            case .update(_, let deletions, let insertions, let modifications):
                debugLog("LOCAL PROTECT ITEMS")
                debugLog("modified indexes: \(modifications)")
                debugLog("inserted indexes: \(insertions)")
                var modifiedItems = [LocalProtectItem]()
                modifications.forEach { (index) in
                    guard self?.localProtectItems?.count ?? 0 > index else { warningLog("invalid index: \(index)"); return }
                    if let item = self?.localProtectItems?[index] {
                        modifiedItems.append(item)
                    }
                }
                self?.handleLocalProtectItems(modified: modifiedItems)
                
                var insertedItems = [LocalProtectItem]()
                insertions.forEach { (index) in
                    guard self?.localProtectItems?.count ?? 0 > index else { warningLog("invalid index: \(index)"); return }
                    if let item = self?.localProtectItems?[index] {
                        insertedItems.append(item)
                    }
                }
                
                self?.handleLocalProtectItems(inserted: insertedItems)
            case .error(let error):
                debugLog(error)
            }
        }
    }
    
    ///Get ProtectItem items from realm and setup live update callback block.
    func setupProtectItems() {
        ///Sort by newest.
        protectItems = RealmHandler.shared.getObjects(of: ProtectItem.self).sorted(byKeyPath: "createdAt", ascending: false)
        protectItemsNotificationToken = protectItems?.observe({ [weak self] (change) in
            switch change {
            case .initial(_):
                break
            case .update(_, let deletions, let insertions, let modifications):
                debugLog("PROTECT ITEMS")
                debugLog("modified indexes: \(modifications)")
                debugLog("inserted indexes: \(insertions)")
                var modifiedItems = [ProtectItem]()
                modifications.forEach { (index) in
                    guard self?.protectItems?.count ?? 0 > index else { warningLog("invalid index: \(index)"); return }
                    if let item = self?.protectItems?[index] {
                        modifiedItems.append(item)
                    }
                }
                self?.handleProtectItems(modified: modifiedItems)
                
                var insertedItems = [ProtectItem]()
                insertions.forEach { (index) in
                    guard self?.protectItems?.count ?? 0 > index else { warningLog("invalid index: \(index)"); return }
                    if let item = self?.protectItems?[index] {
                        insertedItems.append(item)
                    }
                }
                self?.handleProtectItems(inserted: insertedItems)
            case .error(let error):
                debugLog(error)
            }
        })
    }
    
    //MARK: - Jobs
    ///Get LocalJob items from realm and setup live update callback block.
    func setupLocalVerifyItems() {
        localJobs = RealmHandler.shared.getObjects(of: LocalJob.self)
        localJobNotificationToken = localJobs?.observe { [weak self] (change) in
            switch change {
            case .initial(_):
                break
            case .update(_, let deletions, let insertions, let modifications):
                debugLog("LOCAL JOB ITEMS")
                debugLog("modified indexes: \(modifications)")
                debugLog("inserted indexes: \(insertions)")
                
                var modifiedItems = [LocalJob]()
                modifications.forEach { (index) in
                    guard self?.localJobs?.count ?? 0 > index else { warningLog("invalid index: \(index)"); return }
                    if let item = self?.localJobs?[index] {
                        modifiedItems.append(item)
                    }
                }
                self?.handleLocalJobs(modified: modifiedItems)
                
                var insertedItems = [LocalJob]()
                insertions.forEach { (index) in
                    guard self?.localJobs?.count ?? 0 > index else { warningLog("invalid index: \(index)"); return }
                    if let item = self?.localJobs?[index] {
                        insertedItems.append(item)
                    }
                }
                self?.handleLocalJobs(inserted: insertedItems)
            case .error(let error):
                debugLog(error)
            }
        }
    }
    
    ///Get Job items from realm and setup live update callback block.
    func setupVerifyItems() {
        ///Filter out protection type.
        let defaultSearchQuery = "jobName == '\(JobType.imageSearch.rawValue)' OR jobName == '\(JobType.verification.rawValue)'"
        ///Sort by newest.
        jobs = RealmHandler.shared.getObjects(of: Job.self).filter(defaultSearchQuery).sorted(byKeyPath: "createdAt", ascending: false)
        jobsNotificationToken = jobs?.observe({ [weak self] (change) in
            switch change {
            case .initial(_):
                break
            case .update(_, let deletions, let insertions, let modifications):
                debugLog("JOB ITEMS")
                debugLog("modified indexes: \(modifications)")
                debugLog("inserted indexes: \(insertions)")
                
                var modifiedItems = [Job]()
                modifications.forEach { (index) in
                    guard self?.jobs?.count ?? 0 > index else { warningLog("invalid index: \(index)"); return }
                    if let item = self?.jobs?[index] {
                        modifiedItems.append(item)
                    }
                }
                self?.handleJobs(modified: modifiedItems)
                
                var insertedItems = [Job]()
                insertions.forEach { (index) in
                    guard self?.jobs?.count ?? 0 > index else { warningLog("invalid index: \(index)"); return }
                    if let item = self?.jobs?[index] {
                        insertedItems.append(item)
                    }
                }
                self?.handleJobs(inserted: insertedItems)
            case .error(let error):
                debugLog(error)
            }
        })
    }
    
    
    //MARK: - Handle Items
    //MARK: Jobs
    func handleLocalJobs(modified : [LocalJob]) {
        let analyzingItems = modified.filter({ $0.state == .analyzing })
        guard analyzingItems.count > 0 else { return }
        debugLog("analyzing local job items: \(analyzingItems.map({ return $0.identifier }))")
        delegate?.onVerifyUploadingFinished?(jobItem: analyzingItems.first!)
    }
    
    func handleLocalJobs(inserted : [LocalJob]) {
        let uploadingItems = inserted.filter({ $0.canBeUploaded })
        guard uploadingItems.count > 0 else { return }
        debugLog("uploading local job items: \(uploadingItems.map({ return $0.identifier }))")
        delegate?.onVerifyUploadingStarted?(jobItem: uploadingItems.first!)
        
        UploadManager.shared.currentUploadProgressCallBack = { [weak self] (progress, identifier) in
            guard let id = identifier, let item = RealmHandler.shared.getObject(of: LocalJob.self, forKey: id) else { return }
            self?.delegate?.onVerifyUploadingProgress?(progress: progress, jobItem: item)
        }
    }
    
    func handleJobs(modified : [Job]) {
        guard modified.count > 0 else { return }
        debugLog("modified jobs: \(modified)")
    }
    
    func handleJobs(inserted : [Job]) {
        guard inserted.count > 0 else { return }
        debugLog("inserted jobs: \(inserted)")
        delegate?.onVerifyAnalyzingFinished?(jobItems: inserted)
    }
    
    //MARK: Protect Items
    func handleLocalProtectItems(modified : [LocalProtectItem]) {
        let analyzingItems = modified.filter({ $0.state == .analyzing })
        guard analyzingItems.count > 0 else { return }
        debugLog("analyzing local protect items: \(analyzingItems.map({ return $0.identifier }))")
        delegate?.onProtectUploadingFinished?(protectItem: analyzingItems.first!)
    }
    
    func handleLocalProtectItems(inserted : [LocalProtectItem]) {
        let uploadingItems = inserted.filter({ $0.canBeUploaded })
        guard uploadingItems.count > 0 else { return }
        debugLog("uploading local protect items: \(uploadingItems.map({ return $0.identifier }))")
        delegate?.onProtectUploadingStarted?(protectItem: uploadingItems.first!)
        
        UploadManager.shared.currentUploadProgressCallBack = { [weak self] (progress, identifier) in
            guard let id = identifier, let item = RealmHandler.shared.getObject(of: LocalProtectItem.self, forKey: id) else { return }
            self?.delegate?.onProtectUploadingProgress?(progress: progress, protectItem: item)
        }
    }
    
    func handleProtectItems(modified : [ProtectItem]) {
        guard modified.count > 0 else { return }
        debugLog("protect items modified: \(modified.map({ return "\($0.identifier) – \($0.state)"}))")
    }
    
    func handleProtectItems(inserted : [ProtectItem]) {
        let inserted = inserted.filter({ $0.state != .unknown })
        guard inserted.count > 0 else { return }
        debugLog("new protect items inserted: \(inserted.map({ return "\($0.identifier) – \($0.state)"}))")
        delegate?.onProtectAnalyzingFinished?(protectItems: inserted)
    }
}
