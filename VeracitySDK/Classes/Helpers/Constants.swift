//
//  Constants.swift
//  VeracitySDK
//
//  Created by Andrew on 16/04/2019.
//  Copyright © 2019 Veracity Protocol s.r.o. All rights reserved.
//

import Foundation
import UIKit

public struct Size {
    //TableView cells
    public static let artworkDefaultTableViewCellHeight : CGFloat = 110
    public static let artistDefaultTableViewCellHeight : CGFloat = 50
    public static let chooseSpotDefaultCollectionViewCellHeight : CGFloat = 80
    public static let chooseVerticalCollectionViewCellHeight : CGFloat = 80
    public static let emptyProtectListTableViewCellHeight : CGFloat = 260
    public static let emptyVerifyListTableViewCellHeight : CGFloat = 200
    //TableView Supplementary View
    public static let statusLabelDefaultTableViewHeaderHeight : CGFloat = 60
    public static let addArtistDefaultTableViewFooterHeight : CGFloat = 50
    //Activity Indicator
    public static let activityIndicatorSize : CGFloat = 50
    //Filter option cell
    public static let filterOptionDefaultTableViewCellHeight : CGFloat = 60
    //Button
    public static let buttonMinSize : CGFloat = 44
}

public struct LottieAnimations {
    ///default activity indicator
    public static let activityIndicatorDefault : String = "loading_m_white"
    public static let activityIndicatorBlack : String = "loading_m_black"
    ///large. analyzing & uploading state in ArtworkDetailVC
    public static let activityIndicatorPassportDetailState : String = "loading_l_white"
    ///small. analyzing & uploading state in ArtworkTableViewCell
    public static let activityIndicatorArtworkCellState : String = "loading_s_white"
}

public struct AnimationDurations {
    public static let OPHUD : Double = 0.25
    public static let keyboard : Double = 0.3//backup option
}

public struct S3Constants {
    public static let baseURL = "https://oneprove.s3.eu-central-1.amazonaws.com/"
    public static let keyID = "AKIAJOSFTLPAIP4HBHQQ"
    public static let secretAccessKeyID = "3AtuyjJ9uqU4tgJYClwBbmM5ERAD43Gq/nQymMCG"
    public static let bucket = "oneprove"
    public static let maxRetryCount : UInt32 = 3
}

public struct Constants {
    public static let numberOfProposals : Int = 1
    public static let localIDPrefix = "_local"
    public static let compressThumbnailQuality : CGFloat = 0.3
    public static let compressOverviewQuality : CGFloat = 0.9
    public static let compressOverlayQuality : CGFloat = 0.5
    public static let thumbnailImageSize : CGSize = CGSize(width: 250, height: 250)
    public static let publicIDlength = 9
    public static let blurDetectScoreLimit : Double = 0.5
    public static let veracityEmail = Text.veracityEmail.localizedText
    public static let infoEmail = Text.infoEmail.localizedText
    
    public static func imageFilenameSuffixWith(blurScore : Double?) -> String? { return blurScore == nil ? nil : "_\(UIDevice.current.modelCode)_-_\(blurScore ?? 2)" }
}

extension Constants {
    public struct OPNotifications {
        static let defaultShowingTime : Int = 8
    }
}

public struct CreditPrice {
    public static let protection = 20
    public static let verification = 2
}

public struct UserDefaultsKeys {
    public static let credits = "credits"
    public static let invoiceBilling = "invoiceBilling"
    public static let selectedVertical = "selected_vertical"
    public static let verticalsSynced = "verticals_synced"
    public static let selectedAlgoType = "selected_algo_type"
    public static let bluerDetectionState = "blur_detection_state"
    public static let lastUsedItemNameCounter = "last_used_folder_name_counter"
    ///Apparel Origin ID's
    public static let labelsOriginID = "apparel_labelsOriginID"
    public static let labelsOriginPublicID = "apparel_labelsOriginPublicID"
    public static let waistbandsOriginID = "apparel_waistbandsOriginID"
    public static let waistbandsOriginPublicID = "apparel_waistbandsOriginPublicID"
}

public struct NotificationsNames {
    public static let verticalWasChanged = Notification.Name("com.veracityprotocol.verticalWasChanged")
    public static let creditsWasUpdated = Notification.Name("com.veracityprotocol.creditsWasUpdated")
    public static let downloadedRemoteItems = Notification.Name("com.veracityprotocol.downloadedRemoteItems")
    public static let uploadItemProcess = Notification.Name("com.veracityprotocol.uploadItemProcess")
}

public struct StringConstants {
    public static let doesntMatchError_0 = "Hash of image of original fingerprint doesnt match with input hash."
    public static let doesntMatchError_1 = "The item detail doesn not match the one in our database. Try to verify the item again or contact us."
    public static let doesntMatchError_2 = "The item does not match the protected item in our database. Try to verify the item again or contact us."
}

public struct ApparelOriginID {
    public let publicID : String
    public let identifier : String
    
    public static var label = { return ApparelOriginID(publicID: UserDefaults.standard.string(forKey: UserDefaultsKeys.labelsOriginPublicID) ?? "", identifier: UserDefaults.standard.string(forKey: UserDefaultsKeys.labelsOriginID) ?? "") }()
    public static let waistband = ApparelOriginID(publicID: UserDefaults.standard.string(forKey: UserDefaultsKeys.waistbandsOriginPublicID) ?? "", identifier: UserDefaults.standard.string(forKey: UserDefaultsKeys.waistbandsOriginID) ?? "")
    
    public static func setDefaults() {
        UserDefaults.standard.set("5d6771b148f3c9000402fd9c", forKey: UserDefaultsKeys.labelsOriginID)
        UserDefaults.standard.set("TA1XQDQAG", forKey: UserDefaultsKeys.labelsOriginPublicID)
        UserDefaults.standard.set("5d67753448f3c9000402fe28", forKey: UserDefaultsKeys.waistbandsOriginID)
        UserDefaults.standard.set("Z566HYSC1", forKey: UserDefaultsKeys.waistbandsOriginPublicID)
    }
}
