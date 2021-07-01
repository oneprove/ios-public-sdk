//
//  UserManager.swift
//  VeracitySDK
//
//  Created by Andrew on 16/04/2019.
//  Copyright © 2019 Veracity Protocol s.r.o. All rights reserved.
//

import Foundation
import RealmSwift
import Smartlook

let kProtectInstructionStep = "ProtectInstructionStep"

///Handle logged user
public class UserManager : NSObject {
    ///Public singleton instance of `UserManager`.
    public static let shared = UserManager()
    
    public var user : DTOUser? {
        didSet {
            self.token = user?.token
            self.userID = user?.id
            self.loginDate = user?.loginDate
            
            guard user?.email != nil else { return }
            Smartlook.setUserIdentifier(user?.email)
        }
    }
    
    ///Return false if database has no object of `User`.
    public var loggedUser : Bool {
        return user != nil
    }
    
    public var monitoringAgreement : Bool? {
        return user?.monitoringAgreement
    }
    
    /**
     In rare cases when users token is invalidated, all user data must be removed so this callback is for handling this situation within apps UI.
     In this callback, app should handle users logout byself, for example by presenting login screen.
    
     
     Manual logout by `logout()` method will not invoke this callback.
     Gets called on main queue.
    */
    public var userNeedsToBeReauthenticateCallback : (() -> ())?
    
    //Thread safe properties
    var token : String?
    public var userID : String?
    var loginDate : Date?
    
    fileprivate var users: Results<User>?
    fileprivate var usersNotificationToken : NotificationToken?
    
    override private init() {
        super.init()
        users = RealmHandler.shared.getObjects(of: User.self)
        user = users?.first?.model
        token = user?.token
        userID = user?.id
        usersNotificationToken = users?.observe({ [weak self] (change) in
            ///Manualy reset user to update thread safe properties thru setter.
            self?.user = RealmHandler.shared.getObjects(of: User.self).last?.model
            
            switch change {
            case .initial:
                break
            case .update(_, _, _, _):
                break
            case .error(let error):
                // An error occurred while opening the Realm file on the background worker thread
                debugLog("\(error)")
            }
        })
    }
    
    ///Update user token in database.
    func update(token : String) {
        if var user = user {
            user.token = token
            AnyRepository().update(user)
        }
    }
    
    public func updateARGuiding(isOn: Bool) {
        if var user = user {
            user.arGuidingON = isOn
            AnyRepository().update(user)
        }
    }
    
    public func updateShareAnalytic(isOn: Bool) {
        if var user = user {
            user.shareAnalyticON = isOn
            AnyRepository().update(user)
        }
    }
    
    public func updateMetricUnits(isOn: Bool) {
        if var user = user {
            user.metricalUnits = isOn
            AnyRepository().update(user)
        }
    }
    
    public func changeMonitoringAgreement(to agrees : Bool, completion : @escaping (_ success : Bool?, _ error : Error?) -> ()) {
        NetworkClient.changeMonitoringAgreement(to: agrees) { [weak self] (success, error) in
            debugLog(error)
            completion(success, error)
            
            if success, var user = self?.user {
                user.monitoringAgreement = agrees
                AnyRepository().update(user)
            }
        }
    }
    
    public func saveProtectInstructionCompleted(for step: Int) {
        UserDefaults.standard.set(true, forKey: "\(kProtectInstructionStep)-\(step)")
    }
    
    public func isProtectInstructionCompleted(for step: Int) -> Bool {
        guard let completed = UserDefaults.standard.value(forKey: "\(kProtectInstructionStep)-\(step)") as? Bool else {
            return false
        }
        return completed
    }
    
    public func logout() {
        DeviceManager.shared.removeDevice()
        ImagePersistence.removeAllTakenImages()
        RealmHandler.shared.removeWholeDB()
        user = nil
    }
}
