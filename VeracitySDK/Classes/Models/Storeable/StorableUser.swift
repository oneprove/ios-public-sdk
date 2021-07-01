//
//  StorableArticle.swift
//  VeracitySDK
//
//  Created by Minh Chu on 12/4/20.
//

import Foundation
import RealmSwift

extension DTOUser: Entity {
    public var storable: User {
        let realm = User()
        realm.identifier = id ?? ""
        realm.email = email ?? ""
        realm.token = token ?? ""
        realm.invoiceBilling = invoiceBilling ?? false
        realm.arGuidingON = arGuidingON ?? true
        realm.shareAnalyticON = shareAnalyticON ?? false
        realm.loginDate = loginDate ?? Date()
        realm.flashlightOn = flashlightOn ?? false
        realm.metricalUnits = metricalUnits ??  Locale.current.usesMetricSystem
        realm.allowedVerticals.append(objectsIn: allowedVerticals)
        realm.monitoringAgreement.value = monitoringAgreement
        return realm
    }
    
    public func toStorable() -> User {
        return storable
    }
}

public class User: Object, Storable {
    @objc dynamic var identifier : String = ""
    @objc dynamic public var email : String = ""
    @objc dynamic var token : String = ""
    @objc dynamic public var invoiceBilling : Bool = false
    @objc dynamic public var arGuidingON : Bool = true
    @objc dynamic public var shareAnalyticON : Bool = false
    @objc dynamic var loginDate = Date()
    @objc dynamic public var flashlightOn : Bool = false
    @objc dynamic public var metricalUnits = Locale.current.usesMetricSystem
    public var allowedVerticals = List<String>()
    let monitoringAgreement = RealmOptional<Bool>()
    
    override public static func primaryKey() -> String {
        return "identifier"
    }
    
    public var model: DTOUser {
        get {
            return DTOUser(id: identifier,
                           email: email,
                           role: nil,
                           invoiceBilling: invoiceBilling,
                           allowedVerticals: [] ,//Array(allowedVerticals),
                           monitoringAgreement: monitoringAgreement.value,
                           token: token,
                           arGuidingON: arGuidingON,
                           shareAnalyticON: shareAnalyticON,
                           loginDate: loginDate,
                           flashlightOn: flashlightOn,
                           metricalUnits: metricalUnits)
        }
    }
}

extension User {
    public func getUserId() -> String {
        return self.identifier
    }
}
