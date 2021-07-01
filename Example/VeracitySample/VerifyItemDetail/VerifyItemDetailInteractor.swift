//
//  HistoryItemDetailInteractor.swift
//  Veracity Authenticator
//
//  Created by Minh Chu on 1/28/21.
//  Copyright © 2021 ONEPROVE s.r.o. All rights reserved.
//

import RealmSwift
import VeracitySDK

protocol VerifyItemDetailPresentable: AnyObject {
    var listener: VerifyItemDetailPresentableListener? { get set }
    func reloadData(item: VeracityItem)
}

final class VerifyItemDetailInteractor: VerifyItemDetailPresentableListener {
    private weak var presenter: VerifyItemDetailPresentable?
    private var localItemsNotificationToken: NotificationToken?
    private var localItems: Results<LocalJob>?
    private var remoteItemID: String?
    
    private var item: VeracityItem
    init(presenter: VerifyItemDetailPresentable, item: VeracityItem) {
        self.item = item
        self.presenter = presenter
        self.presenter?.listener = self
        
        self.observerItemInfoChanged()
    }
    
    private func observerItemInfoChanged() {
        guard let item = self.item as? LocalJob else {
            return
        }
        
        let predicate = NSPredicate(format: "identifier == %@", item.identifier)
        localItems = RealmHandler.shared.getObjects(of: LocalJob.self).filter(predicate)
        localItemsNotificationToken?.invalidate()
        localItemsNotificationToken = localItems?.observe({ [weak self] (changes) in
            switch changes {
            case .initial:
                // First stage, data are loaded.
                break
            case .error(let error):
                // Something went wrong.
                debugLog("error: \(error)")
            case .update(_,  let deletions, _, let modifiers):
                guard modifiers.count > 0 else {
                    if deletions.count > 0 {
                        self?.fetchRemoteItemInfo()
                    }
                    return
                }
                
                if !item.isInvalidated, let item = RealmHandler.shared.getObject(of: LocalJob.self, forKey: item.identifier) {
                    self?.item = item
                    self?.remoteItemID = item.jobID
                    self?.presenter?.reloadData(item: item)
                }
            }
        })
    }
    
    /// When completed => LocalJob will be deleted and new Job will be insert to DB
    /// This method fetch Job is inserted to DB to reload Layout
    private func fetchRemoteItemInfo() {
        guard !RealmHandler.shared.isInWriteTransaction,
              let identifier = remoteItemID
        else { return }
        
        guard let item = RealmHandler.shared.getObject(of: Job.self, forKey: identifier) else {
            return
        }
        
        self.item = item
        self.presenter?.reloadData(item: item)
    }
}
