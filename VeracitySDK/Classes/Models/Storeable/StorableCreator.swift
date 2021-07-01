//
//  Creator.swift
//  VeracitySDK
//
//  Created by Andrew on 16/04/2019.
//  Copyright © 2019 Veracity Protocol s.r.o. All rights reserved.
//

import Foundation
import RealmSwift

public enum CreatorRole : String {
    case expert = "expert"
    case artist = "artist"
    case trader = "trader"
}

extension DTOCreator: Entity {
    public var storable: Creator {
        let realm = Creator()
        realm.identifier = getID() ?? ""
        realm.firstName = firstName
        realm.lastName = lastName
        return realm
    }
    
    public func toStorable() -> Creator {
        return storable
    }
}

public class Creator: Object, Storable {
    @objc dynamic public var identifier : String = ""
    @objc dynamic public var firstName : String?
    @objc dynamic public var lastName : String?
    
    override public static func primaryKey() -> String {
        return "identifier"
    }
    
    public override class func shouldIncludeInDefaultSchema() -> Bool {
        return false
    }
    
    convenience public init(firstName: String, lastName: String) {
        self.init()
        self.firstName = firstName
        self.lastName = lastName
        self.identifier = Creator.generateLocalId()
    }
    
    convenience public init?(map: [String: Any]) {
        guard map["identifier"] != nil else {
            return nil
        }
        self.init()
    }
    
    public var model: DTOCreator {
        return DTOCreator(id: identifier,
                          _id: identifier,
                          firstName: firstName,
                          lastName: lastName,
                          email: nil)
    }
}

extension Creator {
    class func generateLocalId() -> String {
        return Constants.localIDPrefix + UUID().uuidString
    }
    
    class func isArtistIdLocal(artistId: String) -> Bool {
        return artistId.hasPrefix(Constants.localIDPrefix)
    }
    
    var hasLocalId: Bool {
        return identifier.hasPrefix(Constants.localIDPrefix)
    }
}
