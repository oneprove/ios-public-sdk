//
//  AppManager.swift
//  ONEPROVE
//
//  Created by Andrew on 14/03/2019.
//  Copyright © 2019 ONEPROVE s.r.o. All rights reserved.
//

import UIKit


enum VeracityAppType {
    case authenticator
}

public class AppManager {
    private(set) static var appType : VeracityAppType = {
        return .authenticator
    }()
    
    private(set) static var appName : String = {
        return "Veracity Authenticator"
    }()
    
    public static var shorAppName : String? {
        return "Authenticator"
    }
    
    public static var itemName : String {
        if selectedVertical == .identityDocuments {
            return "Document"
        }else if selectedVertical == .art {
            return "Artwork"
        }
        return "Item"
    }
    
    public static var itemsName : String {
        return itemName + "s"
    }
    
    private(set) static var appstoreID : String? = {
        return "1471341151"
    }()
    
    public static var buildNumberRemoteConfigKey : String? {
        switch appType {
        case .authenticator:
            return "force_update_ios_appstore_authenticator_build_version"
        }
    }
    
    public static func showAppSettings() {
        if let url = URL(string : UIApplication.openSettingsURLString) {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
        }
    }
}

extension AppManager {
    
    ///First fingerprint is then used as overlay to take second fingerprint.
    public static var usesOverlayFingerprintTake : Bool {
        if selectedVertical == .apparel {
            return true
        }
        return false
    }
    
    ///Used instead of item detail VC to determine which fingerprint part is captured.
    ///For app logic that can take fingerprint from two or more fingerprints area at one item.
    public static var usesSpotSelectionFingerprintTake : Bool {
        return false
    }
    
    public static var usesAlgoSwitching : Bool {
        return false
    }
    
    public static var usesBlurDetectorMode : Bool { return false }
    
    public static var usesARSmallFingerprintTake : Bool {
        return (AppManager.selectedVertical == .identityDocuments || AppManager.selectedVertical == .packaging || AppManager.selectedVertical == .labels || AppManager.selectedVertical == .art)
    }
    
    public static var longFlowProtection : Bool { return !(selectedVertical == .apparel) }
}

//MARK: - Verticals
extension AppManager {
    public static var allVerticals : [ApplicationVertical] { return [.identityDocuments, .art, .packaging, .apparel, .sicpa, .labels, .lpmPoc] }
    
    public static var allowedVerticalsWasSynced : Bool {
        return UserDefaults.standard.bool(forKey: UserDefaultsKeys.verticalsSynced)
    }
    
    public static var allowedVerticals : [ApplicationVertical]? {
        if allowedVerticalsWasSynced, let allowedVerticals = UserManager.shared.user?.allowedVerticals/*.map( { return $0 })*/ {
            var verticals = [ApplicationVertical]()
            allowedVerticals.forEach { (verticalID) in
                if let lclVertical = ApplicationVertical(rawValue: verticalID) {
                    verticals.append(lclVertical)
                }
            }
            if verticals.count == 0 {
                return allVerticals
            }else {
                return verticals
            }
        }
        return nil
    }
    
    public static func updateAllowedVerticals(completion : ((_ success : Bool) -> ())?) {
        NetworkClient.updateAllowedVerticals { (verticals, error) in
            let result = verticals != nil
            UserDefaults.standard.set(result, forKey: UserDefaultsKeys.verticalsSynced)
            completion?(result)
        }
    }
    
    public static func change(vertical : ApplicationVertical) {
        UserDefaults.standard.set(vertical.rawValue, forKey: UserDefaultsKeys.selectedVertical)
        NotificationCenter.default.post(name: NotificationsNames.verticalWasChanged, object: nil)
    }
    
    public static var selectedVertical : ApplicationVertical {
        if let backup = UserDefaults.standard.string(forKey: UserDefaultsKeys.selectedVertical), let backupType = ApplicationVertical(rawValue: backup) {
            return backupType
        }
        return allowedVerticals?.first ?? .identityDocuments
    }
    
    public static func change(selectedAlgo algo : AlgoType) {
        UserDefaults.standard.set(algo.rawValue, forKey: UserDefaultsKeys.selectedAlgoType)
    }
    
    public static var selectedAlgo : AlgoType? {
        if let backup = UserDefaults.standard.string(forKey: UserDefaultsKeys.selectedAlgoType), let backupType = AlgoType(rawValue: backup) {
            return backupType
        }
        return nil
    }
    
    public static func resetVerticals() {
        UserDefaults.standard.set(false, forKey: UserDefaultsKeys.verticalsSynced)
        UserDefaults.standard.set(nil, forKey: UserDefaultsKeys.selectedVertical)
        UserDefaults.standard.set(nil, forKey: UserDefaultsKeys.selectedAlgoType)
        UserDefaults.standard.set(nil, forKey: UserDefaultsKeys.lastUsedItemNameCounter)
    }
    
    public static var dimensionWidth: Double?
    public static var dimensionHeight: Double?
}
