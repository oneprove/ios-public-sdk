//
//  ResultIndicatorValue.swift
//  VeracitySDK
//
//  Created by Andrew on 16/04/2019.
//  Copyright © 2019 Veracity Protocol s.r.o. All rights reserved.
//

import Foundation
import RealmSwift

public enum ResultIndicatorType : String {
    case verify = "verification"
    case protect = "protection"
    case imageSearch = "imageSearch"
}

///Simple class to hold ID references to objects with unseen result.
public class ResultIndicatorValue : Object {
    @objc dynamic var identifier : String = ""
    @objc dynamic var typeString : String = ""
    @objc dynamic public var lastSeen = Date()
    
    var type : ResultIndicatorType? {
        return ResultIndicatorType(rawValue: typeString)
    }
    
    public override class func shouldIncludeInDefaultSchema() -> Bool {
        return false
    }
    
    //MARK: - Lifecycle
    convenience public init(identifier : String, type : ResultIndicatorType) {
        self.init()
        self.identifier = identifier
        self.typeString = type.rawValue
    }
    
    override public static func primaryKey() -> String {
        return "identifier"
    }
}
