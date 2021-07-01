//
//  TradingCode.swift
//  VeracitySDK
//
//  Created by Andrew on 16/04/2019.
//  Copyright © 2019 Veracity Protocol s.r.o. All rights reserved.
//

import Foundation
import RealmSwift


extension DTOTradingCode: Entity {
    public var storable: TradingCode {
        let realm = TradingCode()
        realm.code = code
        realm.expiration = Date(timeIntervalSince1970: TimeInterval(expiration ?? 0))
        return realm
    }
    
    public func toStorable() -> TradingCode {
        return storable
    }
}

public class TradingCode: Object, Storable {
    @objc dynamic public var code: String!
    @objc dynamic public var expiration: Date!
    
    public override class func shouldIncludeInDefaultSchema() -> Bool {
        return false
    }
    
    // MARK: - Init
    convenience public init?(map: [String: Any]) { self.init() }
    
    convenience init(code: String, expiration: Date) {
        self.init()
        self.code = code
        self.expiration = expiration
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        guard let code = aDecoder.decodeObject(forKey: "code") as? String,
            let expiration = aDecoder.decodeObject(forKey: "expiration") as? Date
            else { return nil }
        
        self.init(code: code, expiration: expiration)
    }
    
    public var model: DTOTradingCode {
        return DTOTradingCode(code: code,
                              expiration: Int(expiration.timeIntervalSince1970),
                              id: nil,
                              artwork: nil,
                              user: nil,
                              createdAt: nil,
                              updatedAt: nil,
                              v: nil)
    }
}
