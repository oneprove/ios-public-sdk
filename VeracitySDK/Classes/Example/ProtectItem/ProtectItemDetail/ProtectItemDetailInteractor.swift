//
//  ItemDetailInteractor.swift
//  Veracity Authenticator
//
//  Created by Minh Chu on 1/24/21.
//  Copyright © 2021 ONEPROVE s.r.o. All rights reserved.
//

import RealmSwift


protocol ProtectItemDetailPresentable: class {
    var listener: ProtectItemDetailPresentableListener? { get set }
    func reloadData(itemDetail: VeracityItem)
}

final class ProtectItemDetailInteractor: ProtectItemDetailPresentableListener {
    private weak var presenter: ProtectItemDetailPresentable?
    private let createItemStream: MutableProtectItemStream
    private let verifyItemStream: MutableVerifyItemStream
    
    private var localItemsNotificationToken: NotificationToken?
    private var localItems: Results<LocalProtectItem>?
    private var item: VeracityItem
    private let itemName: String?
    
    private var protectItemsNotificationToken: NotificationToken?
    private var localArtworksNotificationToken: NotificationToken?
    
    // Remote ID of item which protection (This is Identifier of ProtectItem)
    private var remoteItemID: String?
    
    init(presenter: ProtectItemDetailPresentable,
         item: VeracityItem,
         createItemStream: MutableProtectItemStream,
         verifyItemStream: MutableVerifyItemStream) {
        self.item = item
        self.itemName = item.itemName
        self.presenter = presenter
        self.createItemStream = createItemStream
        self.verifyItemStream = verifyItemStream
        self.presenter?.listener = self
        
        self.reloadData()
        self.observerLocalItemInfo()
    }
    
    func onVerifyItem(photos: [(blurScore: Float, image: UIImage)]) {
        self.verifyItemStream.updateFingers(photos)
    }
    
    private func reloadData() {
        self.presenter?.reloadData(itemDetail: item)
    }
    
    private func observerLocalItemInfo() {
        guard let item = self.item as? LocalProtectItem else {
            return
        }
        
        let predicate = NSPredicate(format: "identifier == %@", item.identifier)
        localItems = RealmHandler.shared.getObjects(of: LocalProtectItem.self).filter(predicate)
        localItemsNotificationToken?.invalidate()
        localItemsNotificationToken = localItems?.observe({ [weak self] (changes) in
            switch changes {
            case .initial:
                // First stage, data are loaded.
                break
            case .error(let error):
                // Something went wrong.
                debugLog("error: \(error)")
            case .update(_, let deletions, _, let modifiers):
                guard modifiers.count > 0 else {
                    if deletions.count > 0 {
                        self?.fetchRemoteItemInfo()
                    }
                    return
                }
                
                if !item.isInvalidated, let item = RealmHandler.shared.getObject(of: LocalProtectItem.self, forKey: item.identifier) {
                    self?.item = item
                    self?.remoteItemID = item.createdArtworkID
                    self?.presenter?.reloadData(itemDetail: item)
                }
            }
        })
    }
    
    
    /// In case Protection
    /// When completed => LocalProtectItem will be deleted and new ProtectItem will be insert to DB
    /// This method fetch ProtectItem is inserted to DB to reload Layout
    private func fetchRemoteItemInfo() {
        guard !RealmHandler.shared.isInWriteTransaction,
              let identifier = remoteItemID
        else { return }
        
        guard let item = RealmHandler.shared.getObject(of: ProtectItem.self, forKey: identifier) else {
            return
        }
        
        self.item = item
        self.presenter?.reloadData(itemDetail: item)
    }
    
}
