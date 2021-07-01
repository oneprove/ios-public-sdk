//
//  Fingerprint.swift
//  VeracitySDK
//
//  Created by Andrew on 16/04/2019.
//  Copyright © 2019 Veracity Protocol s.r.o. All rights reserved.
//

import Foundation
import RealmSwift

extension DTOFingerprint: Entity {
    public var storable: Fingerprint {
        let realm = Fingerprint()
        realm.identifier = identifier
        realm.name = name
        realm.image1Url = image1Url
        realm.image2Url = image2Url
        realm.fingerprintHash = fingerprintHash
        realm.location = location?.toStorable()
        return realm
    }
    
    public func toStorable() -> Fingerprint {
        return storable
    }
}

public class Fingerprint: Object, Storable {
    @objc dynamic public var identifier: String!
    @objc dynamic public var name: String!
    @objc dynamic public var image1Url: String!
    @objc dynamic public var image2Url: String!
    @objc dynamic public var fingerprintHash: String?
    @objc dynamic public var location: FingerprintLocation?
    
    override public static func primaryKey() -> String {
        return "identifier"
    }
    
    public override class func shouldIncludeInDefaultSchema() -> Bool {
        return false
    }
    
    required convenience public init?(map: [String: Any]) {
        guard map["id"] != nil || map["name"] != nil || map["image1Url"] != nil || map["image2Url"] != nil || map["location"] != nil else {
            return nil
        }
        self.init()
    }
    
    public var model: DTOFingerprint {
        return DTOFingerprint(location: location?.model,
                              identifier: identifier,
                              name: name,
                              image1Url: image1Url,
                              image2Url: image2Url,
                              fingerprintHash: fingerprintHash)
    }
}
