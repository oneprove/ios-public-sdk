//
//  NotificationManager.swift
//  VeracitySDK
//
//  Created by Andrew on 13/06/2019.
//  Copyright © 2019 Veracity Protocol s.r.o. All rights reserved.
//

import Foundation
import UserNotifications
import UIKit

///Singelton. Main class to handle all notification related stuff.
public class NotificationManager: NSObject {
    //TODO: ⚠️ get rid of shared manager
    ///Public singleton instance of `NotificationManager`.
    public static let shared = NotificationManager()
    
    ///Requests access to local and remote notifications. Should be called after login.
    public func requestAccess() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { [weak self] (granted, error) in
            if granted {
                self?.registerForRemote()
            } else {
                warningLog("User denied notifications access! Updating device ...")
                DispatchQueue.main.async {
                    DeviceManager.shared.updateDevice(withToken: nil)
                }
            }
            DispatchQueue.main.async {
                JobResultChecker.shared.setupObserving()
            }
        }
    }
    
    ///
    public func didRegisterForFirebaseNotifications(withToken token: String) {
        checkNotificationSettings { (authStatus) in
            if authStatus == .denied {
                DeviceManager.shared.updateDevice(withToken: nil)
            }else if authStatus == .authorized {
                DeviceManager.shared.updateDevice(withToken: token)
            }
        }
    }
    
    ///
    public func didFailToRegisterForRemote() {
        DeviceManager.shared.updateDevice()
    }
    
    ///Notification arrive when app is in foreground.
    ///- Parameter userInfo: Push Notifications payload dictionary.
    public func processReceivedNotification(userInfo: [AnyHashable : Any]) {
        debugLog("Notification arrived with data: \(userInfo)")
        processNotification(data: userInfo)
    }
    
    ///Handle notifications in notification center that probably weren't processed.
    public func tryToHandleUnprocessedNotifications() {
        UNUserNotificationCenter.current().getDeliveredNotifications { (notifications) in
            debugLog("unprocessed notification count: \(notifications.count)")
            if notifications.count > 0 {
                notifications.forEach({ (notification) in
                    DispatchQueue.main.async {
                        self.processNotification(data: notification.request.content.userInfo)
                    }
                })
            }
        }
    }
    
    ///Check notifications setting by given async callback.
    /// - Parameter completion: Callback block that runs only once per call.
    /// - Parameter status: `UNAuthorizationStatus` representing current stuatus of notifications settings.
    public func checkNotificationSettings(_ completion : @escaping (_ status : UNAuthorizationStatus) -> ()) {
        UNUserNotificationCenter.current().getNotificationSettings(completionHandler: { (settings) in
            DispatchQueue.main.async {
                completion(settings.authorizationStatus)
            }
        })
    }
}

//MARK: - Private extension
fileprivate extension NotificationManager {
    func registerForRemote() {
        DispatchQueue.main.async {
            UIApplication.shared.registerForRemoteNotifications()
        }
    }
    
    func processNotification(data : [AnyHashable : Any]) {
        var data = data
        ///Firebase condition.
        if let jsonString = data["json"] as? String, let dict = jsonString.convertToDictionary() {
            data = dict
        }
        
        ///Batch Jobs handling
        if let jobData = data["jobData"] as? [AnyHashable : AnyCodable] {
            guard let childJobs = jobData["childJobs"]?.value as? [[String : AnyCodable]] else { return }
            
            childJobs.forEach { (dict) in
                if let job = Job(map: dict) {
                    if let artworkID = dict["artwork"]?.value as? String {
                        job.artworkID = artworkID
                        job.artwork = RealmHandler.shared.getObject(of: VerificationProtectItem.self, forKey: artworkID)
                    }
                    RealmHandler.shared.add(job, modifiedUpdate: true)
                }
            }
        }
        
        guard let jobName = data["jobName"] as? String,
            let jobID = data["job"] as? String
            else { return }
        let errorMessage = data["error"] as? String
        
        if jobName == JobType.imageSearch.rawValue {
            guard let queryImageUrl = data["queryImageUrl"] as? String, let results = data["results"] as? [String] else {
                return
            }
            let createdDate = RealmHandler.shared.getObject(of: Job.self, forKey: jobID)?.createdAtDate ?? Date()
            let job = Job(jobID: jobID, createdAt: createdDate, queryImageUrl: queryImageUrl, results: results)
            RealmHandler.shared.add(job, modifiedUpdate: true)
        }else if jobName == JobType.verification.rawValue {
            guard let artworkDict = data["artwork"] as? [String : AnyCodable], let artwork = VerificationProtectItem(map: artworkDict) else {
                return
            }
            artwork.metadataString = (artworkDict["meta"]?.value as? [String : AnyHashable])?.convertToJSONString()
            var tradingCode : TradingCode?
            if let tradingCodeDict = data["tradingCode"] as? [String : Any], let tradeCode = TradingCode(map: tradingCodeDict) {
                tradingCode = tradeCode
            }
            let createdDate = RealmHandler.shared.getObject(of: Job.self, forKey: jobID)?.createdAtDate ?? Date()
            let job = Job(jobID: jobID, artwork: artwork, createdAt: createdDate, error: errorMessage, tradingCode: tradingCode)
            RealmHandler.shared.add([artwork, job], modifiedUpdate: true)
        }else if jobName == JobType.protection.rawValue {
            guard let artworkDict = data["artwork"] as? [String : Any], let artwork = ProtectItem(json: artworkDict) else {
                return
            }
            
            artwork.errorMessage = errorMessage
            artwork.jobID = jobID
            artwork.createdByID = UserManager.shared.userID
            RealmHandler.shared.add(artwork, modifiedUpdate: true)
        }
    }
}
