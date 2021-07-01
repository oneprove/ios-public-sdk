//
//  ProtectItem.swift
//  VeracitySDK
//
//  Created by Andrew on 16/04/2019.
//  Copyright © 2019 Veracity Protocol s.r.o. All rights reserved.
//

import Foundation
import RealmSwift

public enum ItemState : String {
    case protected = "authorized"
    case verified = "verified"
    case failed = "authorization_failed"
    case doesntMatch = "doesnt_match"
    case inTransfer = "in_transfer"
    case incomplete = "new"
    case analyzing = "authorization_in_progress"
    case search = "search"
    case uploading = "uploading"
    case pending = "pendingUpload"
    case unknown = "unknown"
    
    public var title: String? {
        switch self {
        case .protected:
            return Text.protected.localizedText
        case .failed:
            return Text.notProtected.localizedText
        case .doesntMatch:
            return Text.doesntMatch.localizedText
        case .inTransfer:
            return Text.inTransfer.localizedText
        case .incomplete:
            return Text.cantBeTold.localizedText
        case .analyzing:
            return Text.analyzing.localizedText
        case .search:
            return Text.search.localizedText
        case .uploading:
            return Text.uploading.localizedText
        case .pending:
            return Text.pending.localizedText
        default:
            return nil
        }
    }
    
    public var titleVerify: String? {
        switch self {
        case .verified:
            return Text.verifiedSuccessTitle.localizedText
        case .failed, .doesntMatch:
            return Text.verifiedFailedTitle.localizedText
        case .inTransfer:
            return Text.inTransfer.localizedText
        case .incomplete:
            return Text.verifiedUnableToVerifyTitle.localizedText
        case .analyzing:
            return Text.analyzing.localizedText
        case .uploading:
            return Text.uploading.localizedText
        case .pending:
            return Text.pending.localizedText
        default:
            return nil
        }
    }
    
    public var messageVerify: String? {
        switch self {
        case .verified:
            return Text.verifiedSuccessMessage.localizedText
        case .failed, .doesntMatch:
            return Text.verifiedFailedMessage.localizedText
        case .incomplete:
            return Text.verifiedUnableToVerifyMessage.localizedText
        case .analyzing:
            return "\(Text.verifiedAnalyzingMessage.localizedText)..."
        case .uploading:
            return "\(Text.verifiedUploadingMessage.localizedText)..."
        case .pending:
            return Text.verifiedPendingMessage.localizedText
        default:
            return nil
        }
    }
    
    public var textColor: UIColor {
        switch self {
        case .failed:
            return AppColor.red
        case .doesntMatch:
            return AppColor.red
        case .pending:
            return AppColor.darkGray
        case .verified, .protected:
            return AppColor.darkGreen
        case .analyzing:
            return AppColor.green
        default:
            return AppColor.lightPrimary
        }
    }
    
    public var textBackgroundColor: UIColor {
        switch self {
        default:
            return textColor
        }
    }
    
    public var backgroundImg: UIImage? {
        switch self {
//        case .analyzing:
//            return #imageLiteral(resourceName: "bg-analyzing")
        default:
            return nil
        }
    }
    
    public var backgroudColor: UIColor? {
        switch self {
        case .failed, .doesntMatch:
            return AppColor.lightRed
        case .uploading, .pending, .incomplete:
            return AppColor.backgroundColor
        case .analyzing:
            return AppColor.lightBlue
        case .verified:
            return AppColor.lightGreen
        default:
            return nil
        }
    }
}

extension DTOProtectItem: Entity {
    public var storable: ProtectItem {
        let realm = ProtectItem()
        realm.identifier = id ?? ""
        realm.jobID = lastJob?.job
        realm.name = name
        realm.artistID = author?.getID()
        realm.artistFirstName = author?.firstName
        realm.artistLastName = author?.lastName
        realm.overview = overviewURL
        realm.thumbnail = thumbnailURL
        realm.width = width ?? 0
        realm.height = height ?? 0
        realm.authorized = authorized ?? false
        realm.year = year ?? 0
        realm.createdAt = createdAt
//        realm.createdByID = createdBy?.getID()
        realm.publicID = publicID
        realm.errorMessage = error
        realm.statusMessage = status
        realm.firstTradingCode = firstTradingCode?.toStorable()
        realm.firstCreatedByRole = firstCreatedByRole
        realm.algorithmUsed = algorithmUsed
        realm.transferRequest = transferRequest?.state
        realm.transferedFrom = transferRequest?.from
        realm.transferedTo = transferRequest?.to
        realm.transferID = transferRequest?.id
        realm.metadataString = meta?.toString()
        realm.categories.append(objectsIn: categories ?? [])
        realm.styles.append(objectsIn: styles ?? [])
        realm.medius.append(objectsIn: mediums ?? [])
        
        return realm
    }
    
    public func toStorable() -> ProtectItem {
        return storable
    }
}


public class ProtectItem: Object, Storable {
    @objc dynamic public var identifier: String = ""
    @objc dynamic var jobID : String?
    @objc dynamic var localIdentifierBackup : String?
    @objc dynamic public var name: String!
    @objc dynamic public var artistID: String!
    @objc dynamic public var artistFirstName: String?
    @objc dynamic public var artistLastName: String?
    @objc dynamic public var overview: String?
    @objc dynamic public var thumbnail: String?
    @objc dynamic public var width: Double = 0
    @objc dynamic public var height: Double = 0
    @objc dynamic public var authorized: Bool = false
    @objc dynamic public var year: Int = 0
    @objc dynamic var createdAt: String?
    @objc dynamic public var createdByID: String?
    @objc dynamic public var publicID: String?
    @objc dynamic public var errorMessage: String?
    @objc dynamic var statusMessage: String?
    @objc dynamic public var firstTradingCode : TradingCode?
    @objc dynamic var firstCreatedByRole : String?
    @objc dynamic var metadataString : String?
    @objc dynamic public var algorithmUsed : String?
    @objc dynamic public var webhookUrl : String?
    
    @objc dynamic public var transferRequest: String?
    @objc dynamic public var transferedFrom: String?
    @objc dynamic public var transferedTo: String?
    @objc dynamic public var transferID: String?
    
    var categories = List<Int>()
    var styles = List<Int>()
    var medius = List<Int>()
    
    public var state : ItemState? {
        if transferedTo != nil, transferRequest != nil {
            return .inTransfer
        }else if let status = statusMessage {
            return ItemState(rawValue: status)
        }
        return .unknown
    }
    
    public var createdAtDate : Date? {
        return DateManager.dateFrom(createdAt)
    }
    
    public var metadata : [String : AnyHashable]? {
        if let json = metadataString {
            return json.convertToDictionary() as? [String : AnyHashable]
        }
        return nil
    }
    
    public var fingerprintNames: [String]? {
        return (metadata?["fingerprintNames"] as? String)?.components(separatedBy: ",")
    }
    
    public var fingerprintUrls: [String]? {
        return (metadata?["fingerprintUrls"] as? String)?.components(separatedBy: ",")
    }
    
    public var createdByMe : Bool {
        if UserManager.shared.userID == createdByID {
            return true
        }
        return false
    }
    
    var creatorRole : CreatorRole? {
        return CreatorRole(rawValue: firstCreatedByRole ?? "")
    }
    
    public var authenticity : Bool {
        if let role = creatorRole {
            return role == .expert || role == .artist
        }
        return false
    }
    
    public var tooSmallItem : Bool {
        if VeracitySDK.configuration.type == .goat { return false }
        
        if height > 0, width > 0 {
            if width <= 7.5 || height <= 10 {
                return true
            }
        }
        return false
    }
    
    public var webhookURL : URL? {
        if let url = webhookUrl {
            return URL(string: url)
        }
        return nil
    }
    
    public var resultIndicator : Bool {
        guard let createdAtDate = createdAtDate, let loginDate = UserManager.shared.loginDate else { return false }
        guard createdAtDate.compare(Date().before24Hours) == .orderedDescending else { return false }
        
        if let lastTimeViewed = RealmHandler.shared.getObject(of: ResultIndicatorValue.self, forKey: identifier)?.lastSeen {
            return createdAtDate.compare(lastTimeViewed) == .orderedDescending
        }else if createdAtDate.compare(loginDate) == .orderedDescending {
            return true
        }
        
        return false
    }
    
    //MARK: - Lifecycle
    convenience public init?(map: [String: AnyCodable]) {
        self.init()
        
        if let id = map["id"] {
            self.identifier = (id.value as? String) ?? ""
        } else if let id = map["_id"] {
            self.identifier = (id.value  as? String) ?? ""
        }
        
        if let createdByID = map["createdBy"] {
            self.createdByID = (createdByID.value as? String) ?? ""
        } else if let createdByDict = map["createdBy"]?.value as? [String : AnyCodable], let createdByID = createdByDict["_id"] {
            self.createdByID = (createdByID.value as? String) ?? ""
        }
        
        if let metaDict = map["meta"]?.value as? [String : AnyCodable] {
            self.metadataString = metaDict.convertToJSONString()
        } else if let metaDict = map["metadata"]?.value as? [String : AnyCodable] {
            self.metadataString = metaDict.convertToJSONString()
        } else if let metaString = map["metadata"] {
            self.metadataString = (metaString.value as? String) ?? ""
        }
    }
    
    convenience public init?(json: [String: Any]) {
        self.init()
        
        self.identifier = json["id"] as? String ?? json["_id"] as? String ?? ""
        
        if let algorithmUsed = json["algorithmUsed"] as? String {
            self.algorithmUsed = algorithmUsed
        }
        
        if let author = json["author"] as? [String: Any]{
            self.artistID = author["id"] as? String ?? author["_id"] as? String
            self.artistFirstName = author["firstName"] as? String
            self.artistLastName = author["lastName"] as? String
        }
        
        if let categories = json["categories"] as? [Int] {
            self.categories.append(objectsIn: categories)
        }
        
        if let createdAt = json["createdAt"] as? String {
            self.createdAt = createdAt
        }
        
        if let createdByID = json["createdBy"] as? String {
            self.createdByID = createdByID
        } else if let createdByDict = json["createdBy"] as? [String : AnyCodable], let createdByID = createdByDict["_id"] {
            self.createdByID = (createdByID.value as? String) ?? ""
        }

        if let firstCreatedByRole = json["firstCreatedByRole"] as? String {
            self.firstCreatedByRole = firstCreatedByRole
        }
        
        if let mediums = json["mediums"] as? [Int] {
            self.medius.append(objectsIn: mediums)
        }

        if let name = json["name"] as? String {
            self.name = name
        }
        
        if let overviewUrl = json["overviewUrl"] as? String {
            self.overview = overviewUrl
        }
        
        if let publicId = json["publicId"] as? String {
            self.publicID = publicId
        }
        
        if let status = json["status"] as? String {
            self.statusMessage = status
        }
        
        if let styles = json["styles"] as? [Int] {
            self.styles.append(objectsIn: styles)
        }
        
        if let thumbnailUrl = json["thumbnailUrl"] as? String {
            self.thumbnail = thumbnailUrl
        }
        
        if let width = json["width"] {
            self.width = width as? Double ?? Double(width as? Int ?? 0)
        }
        
        if let height = json["height"] {
            self.height = height as? Double ?? Double(height as? Int ?? 0)
        }

        if let year = json["year"] as? Int {
            self.year = year
        }
        
        if let metaDict = json["meta"] as? [String : Any] {
            // Cheating
            var data: [String: Any] = [:]
            metaDict.forEach({ (key, value) in
                if (key != "car") {
                    data[key] = value
                }
            })
            self.metadataString = data.convertToJSONString()
        } else if let metaDict = json["metadata"] as? [String : Any] {
            // Cheating
            var data: [String: Any] = [:]
            metaDict.forEach({ (key, value) in
                if (key != "car") {
                    data[key] = value
                }
            })
            self.metadataString = metaDict.convertToJSONString()
        } else if let metaString = json["metadata"] {
            self.metadataString = (metaString as? String) ?? ""
        }
        
        if let transferRequest = json["transferRequest"] as? [String: Any] {
            self.transferRequest = transferRequest["state"] as? String
            self.transferedFrom = transferRequest["from"] as? String
            self.transferedTo = transferRequest["to"] as? String
            self.transferID = transferRequest["id"] as? String
        }
    }
    
    override public static func primaryKey() -> String {
        return "identifier"
    }
    
    override public static func ignoredProperties() -> [String] {
        return ["state"]
    }
    
    override public class func shouldIncludeInDefaultSchema() -> Bool {
        return false
    }
    
    public var model: DTOProtectItem {
        let author = DTOCreator(id: artistID,
                                _id: artistID,
                                firstName: artistFirstName,
                                lastName: artistLastName,
                                email: nil)
        
        let createBy = DTOCreator(id: createdByID,
                                  _id: createdByID,
                                  firstName: nil,
                                  lastName: nil,
                                  email: nil)
        
        let transfer = TransferRequest(id: transferID,
                                       to: transferedTo,
                                       from: transferedFrom,
                                       state: transferRequest)
        
        return DTOProtectItem(author: author,
                              id: identifier,
                              name: name,
                              overviewURL: overview,
                              thumbnailURL: thumbnail,
                              width: width,
                              height: height,
                              year: year,
                              category: nil,
                              publicID: publicID,
//                              createdBy: createBy,
                              createdAt: createdAt,
                              updatedAt: nil,
                              firstCreatedByRole: firstCreatedByRole,
                              firstCreatedBy: nil,
                              mediums: Array(medius),
                              styles: Array(styles),
                              categories: Array(categories),
                              meta: APIConfiguration.current?.decoder.decode(from: metadata?.toData() ?? Data(), as: DTOMetaData.self),
                              transferRequest: transfer,
                              firstTradingCode: firstTradingCode?.model,
                              status: statusMessage,
                              authorizedAt: nil,
                              blockchainID: nil,
                              algorithmUsed: algorithmUsed ?? "",
                              applicationUsed: nil,
                              authorized: authorized,
                              fingerprint: nil,
                              lastJob: nil,
                              error: errorMessage)
    }
}

extension ProtectItem: VeracityItem {
    public var id: String {
        return identifier
    }
    
    public var itemName: String? {
        return name
    }
    
    public var date: Date? {
        return createdAtDate
    }
    
    public var thumbImageUrl: String? {
        return thumbnail
    }
    
    public var overlayImageUrl: String? {
        return fingerprintUrls?.first
    }
}
