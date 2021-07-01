//
//  PublicProtectItem.swift
//  VeracitySDK
//
//  Created by Andrew on 16/04/2019.
//  Copyright © 2019 Veracity Protocol s.r.o. All rights reserved.
//

import Foundation


extension DTOPublicProtectItem: Entity {
    public var storable: PublicProtectItem {
        let realm = PublicProtectItem()
        realm.identifier = id ?? ""
        realm.jobID = lastJob?.job
        realm.name = name
        realm.artistID = author?.getID()
        realm.artistFirstName = author?.firstName
        realm.artistLastName = author?.lastName
        realm.overview = overviewURL
        realm.thumbnail = thumbnailURL
        realm.width = width ?? 0
        realm.height = height ?? 0
        realm.authorized = authorized ?? false
        realm.year = year ?? 0
        realm.createdAt = createdAt
//        realm.createdByID = createdBy?.getID()
        realm.publicID = publicID
        realm.errorMessage = error
        realm.statusMessage = status
        realm.firstTradingCode = firstTradingCode?.toStorable()
        realm.firstCreatedByRole = firstCreatedByRole
        realm.algorithmUsed = algorithmUsed
        realm.transferRequest = transferRequest?.state
        realm.transferedFrom = transferRequest?.from
        realm.transferedTo = transferRequest?.to
        realm.transferID = transferRequest?.id
        realm.metadataString = meta?.toString()
        realm.categories.append(objectsIn: categories ?? [])
        realm.styles.append(objectsIn: styles ?? [])
        realm.medius.append(objectsIn: mediums ?? [])
        
        return realm
    }
    
    public func toStorable() -> PublicProtectItem {
        return storable
    }
}


///Simple subclass with no diference agains parent class, to separate Public items.
public class PublicProtectItem : ProtectItem {
    
}
