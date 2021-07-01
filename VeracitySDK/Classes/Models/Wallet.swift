//
//  Wal@objc dynamic var.swift
//  VeracitySDK
//
//  Created by Minh Chu on 11/17/20.
//
import Foundation
import RealmSwift

public class Wallet: Object {
    @objc dynamic var kty: String? = nil
    @objc dynamic var n: String? = nil
    @objc dynamic var e: String? = nil
    @objc dynamic var d: String? = nil
    @objc dynamic var p: String? = nil
    @objc dynamic var q: String? = nil
    @objc dynamic var dp: String? = nil
    @objc dynamic var dq: String? = nil
    @objc dynamic var qi: String? = nil

    @objc dynamic var address: String? = nil
    @objc dynamic var userId: String? = nil
    @objc dynamic var active: Bool = false

    override public static func primaryKey() -> String { return "userId" }
    
    convenience public init(user: User,
                            address: String,
                            active: Bool,
                            kty: String,
                            n: String,
                            e: String,
                            d: String,
                            p: String,
                            q: String,
                            dp: String,
                            dq: String,
                            qi: String) {
        self.init()
        
        self.userId = user.identifier
        self.address = address
        self.active = active
        
        self.kty = kty
        self.n = n
        self.e = e
        self.d = d
        self.p = p
        self.q = q
        self.dp = dp
        self.dq = dq
        self.qi = qi
    }
}

extension Wallet {
    public func updateActive(_ active: Bool) {
        RealmHandler.shared.persist { [weak self] in
            self?.active = active
        }
    }
    
    public func isActive() -> Bool {
        return self.active
    }
    
    public func getAddress() -> String {
        return self.address ?? ""
    }
    
    public func getKty() -> String {
        return self.kty ?? ""
    }
    
    public func getN() -> String {
        return self.n ?? ""
    }
    
    public func getE() -> String {
        return self.e ?? ""
    }
    
    public func getD() -> String {
        return self.d ?? ""
    }
    
    public func getP() -> String {
        return self.p ?? ""
    }
    
    public func getQ() -> String {
        return self.q ?? ""
    }
    
    public func getDP() -> String {
        return self.dp ?? ""
    }
    
    public func getDQ() -> String {
        return self.dq ?? ""
    }
    
    public func getQI() -> String {
        return self.qi ?? ""
    }
}
