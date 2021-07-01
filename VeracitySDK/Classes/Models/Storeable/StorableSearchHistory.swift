//
//  StorableSearchHistory.swift
//  Veracity Authenticator
//
//  Created by Minh Chu on 4/30/21.
//  Copyright © 2021 ONEPROVE s.r.o. All rights reserved.
//

import Realm
import RealmSwift

public class SearchHistory: Object {
    @objc dynamic public var identifier: String!
    @objc dynamic var createdAt = Date()
    @objc dynamic var item: ProtectItem!
    
    //MARK: Lifecycle
    override public static func primaryKey() -> String {
        return "identifier"
    }
    
    convenience public init(item: ProtectItem) {
        self.init()
        self.identifier = item.identifier
        self.item = item
    }
}
