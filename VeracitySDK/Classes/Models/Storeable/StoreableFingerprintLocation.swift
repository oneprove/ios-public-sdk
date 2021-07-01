//
//  FingerprintLocation.swift
//  VeracitySDK
//
//  Created by Andrew on 16/04/2019.
//  Copyright © 2019 Veracity Protocol s.r.o. All rights reserved.
//

import Foundation
import RealmSwift

extension DTOFingerprintLocation: Entity {
    public var storable: FingerprintLocation {
        let realm = FingerprintLocation()
        realm.x = x ?? 0
        realm.y = y ?? 0
        realm.width = width ?? 0
        realm.height = height ?? 0
        return realm
    }
    
    public func toStorable() -> FingerprintLocation {
        return storable
    }
}

public class FingerprintLocation : Object, Storable {
    @objc dynamic public var x: Int = 0
    @objc dynamic public var y: Int = 0
    @objc dynamic public var width: Int = 0
    @objc dynamic public var height: Int = 0
    
    public var cgRectValue : CGRect {
        return CGRect(x: x, y: y, width: width, height: height)
    }
    
    public override class func shouldIncludeInDefaultSchema() -> Bool {
        return false
    }
    
    public convenience init(rect: CGRect) {
        self.init()
        
        x = Int(rect.origin.x)
        y = Int(rect.origin.y)
        width = Int(rect.size.width)
        height = Int(rect.size.height)
    }
    
    convenience public init?(map: [String: Any]) {
        guard map["x"] != nil || map["y"] != nil || map["width"] != nil || map["height"] != nil else {
            return nil
        }
        self.init()
    }
    
    public var model: DTOFingerprintLocation {
        return DTOFingerprintLocation(x: x,
                                      width: width,
                                      height: height,
                                      y: y)
    }
}
