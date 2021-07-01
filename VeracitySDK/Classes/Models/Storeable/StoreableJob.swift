//
//  Job.swift
//  VeracitySDK
//
//  Created by Andrew on 16/04/2019.
//  Copyright © 2019 Veracity Protocol s.r.o. All rights reserved.
//

import Foundation
import RealmSwift

public enum JobType : String {
    case verification = "verify"
    case batchVerification = "batchVerify"
    case imageSearch = "overviewSearch"
    case protection = "create"
}


extension DTOJob: Entity {
    public var storable: Job {
        let realm = Job()
        realm.identifier = id
        realm.userID = userID
        realm.jobName = jobName
        realm.artworkID = artworkID
        realm.artwork = artwork?.toStorable()
        realm.searchQueryImageUrl = searchQueryImageUrl
        realm.searchQueryImageUrlThumbnail = searchQueryImageUrlThumbnail
        realm.error = error
        realm.completed = completed ?? false
        realm.createdAt = createdAt
        realm.tradingCode = tradingCode?.toStorable()
        realm.blockchainVerified.value = blockchainVerified ?? false
        realm.searchResults.append(objectsIn: searchResults ?? [])
        return realm
    }
    
    public func toStorable() -> Job {
        return storable
    }
}

public class Job: Object, Storable {
    @objc dynamic public var identifier: String!
    @objc dynamic public var userID: String?
    @objc dynamic public var jobName: String?
    @objc dynamic public var artworkID: String?
    @objc dynamic public var artwork: ProtectItem?
    @objc dynamic public var searchQueryImageUrl: String?
    @objc dynamic public var searchQueryImageUrlThumbnail: String?
    @objc dynamic public var error: String?
    @objc dynamic public var completed: Bool = false
    @objc dynamic var createdAt: String?
    @objc dynamic public var tradingCode: TradingCode?
    public let blockchainVerified = RealmOptional<Bool>()
    public var searchResults = List<String>()
    public var childJobs = List<Job>()
    
    public var state : ItemState? {
        if completed, jobName == JobType.verification.rawValue, error == nil, tradingCode != nil {
            return .verified
        }else if !completed, error == nil {
            return .analyzing
        }else if jobName == JobType.imageSearch.rawValue {
            return .search
        }else if tradingCode == nil, let error = error {
            if error.contains(StringConstants.doesntMatchError_0) || error.contains(StringConstants.doesntMatchError_1) || error.contains(StringConstants.doesntMatchError_2) {
                return .doesntMatch
            }
            return .failed
        }
        return .incomplete
    }
    
    public var jobType : JobType? {
        if let jobName = jobName {
            return JobType(rawValue: jobName)
        }
        return nil
    }
    
    public var createdAtDate : Date? {
        return DateManager.dateFrom(createdAt)
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
    
    convenience public init?(map: [String: AnyCodable]) {
        self.init()
        
        if let id = map["job"]?.value as? String {
            self.identifier = id
        } else if let id = map["id"]?.value as? String {
            self.identifier = id
        }
        
        if let name = map["jobName"]?.value as? String {
            self.jobName = name
        }
        
        // step (*)
        if let artwork = map["artwork"]?.value as? [String: Any], let delete = artwork["deleted"] as? Bool, delete == false {
            self.artwork = ProtectItem(json: artwork)
            self.artwork?.jobID = self.identifier
        }
        
        if let dict = map["tradingCode"]?.value as? [String: Any],
           let data = dict.toData(),
           let trading = try? JSONDecoder().decode(DTOTradingCode.self, from: data) {
            self.tradingCode = trading.toStorable()
        }
        
        if let childsDict = map["childJobs"]?.value as? [AnyCodable], childsDict.count > 0 {
            let jobs = childsDict.map { (child) -> Job? in
                guard let dict = child.value as? [String: Any] else {
                    return nil
                }
                
                let child = Job(dict: dict)
                
                // If artwork in step (*) still nil, then check artwork in child
                if self.artwork == nil {
                    self.artwork = child?.artwork
                    self.artwork?.jobID = self.identifier
                }
                
                return child
            }.filter { $0 != nil } as? [Job]
            self.childJobs.append(objectsIn: jobs ?? [])
        }
        
        self.completed = map["completed"]?.value as? Bool ?? false
        self.userID = map["user"]?.value as? String
        self.error = map["error"]?.value as? String
        self.createdAt = map["createdAt"]?.value as? String
    }
    
    convenience public init?(dict: [String: Any]) {
        self.init()
        
        if let id = dict["job"] as? String {
            self.identifier = id
        } else if let id = dict["id"] as? String {
            self.identifier = id
        }
        
        if let name = dict["jobName"] as? String {
            self.jobName = name
        }
        
        // step (*)
        if let artwork = dict["artwork"] as? [String: Any], let delete = artwork["deleted"] as? Bool, delete == false {
            self.artwork = ProtectItem(json: artwork)
            self.artwork?.jobID = self.identifier
        }
        
        if let dict = dict["tradingCode"] as? [String: Any],
           let data = dict.toData(),
           let trading = try? JSONDecoder().decode(DTOTradingCode.self, from: data) {
            self.tradingCode = trading.toStorable()
        }
        
        if let childsDict = dict["childJobs"] as? [AnyCodable], childsDict.count > 0 {
            let jobs = childsDict.map { (child) -> Job? in
                guard let dict = child.value as? [String: Any] else {
                    return nil
                }
                
                let child = Job(dict: dict)
                
                // If artwork in step (*) still nil, then check artwork in child
                if self.artwork == nil {
                    self.artwork = child?.artwork
                    self.artwork?.jobID = self.identifier
                }
                
                return child
            }.filter { $0 != nil } as? [Job]
            self.childJobs.append(objectsIn: jobs ?? [])
        }
        
        self.completed = dict["completed"] as? Bool ?? false
        self.userID = dict["user"] as? String
        self.error = dict["error"] as? String
        self.createdAt = dict["createdAt"] as? String
    }
    
    ///Image search results notification init.
    convenience init(jobType : JobType = .imageSearch, jobID : String, createdAt date : Date, queryImageUrl : String, results : [String]) {
        self.init()
        self.jobName = jobType.rawValue
        self.identifier = jobID
        self.searchQueryImageUrl = queryImageUrl
        self.searchResults.append(objectsIn: results)
        self.createdAt = DateManager.utcFormatter.string(from: date)
        self.completed = true
        self.userID = UserManager.shared.userID
    }
    
    ///Verification result notification init.
    convenience init(jobType : JobType = .verification, jobID : String, artwork : VerificationProtectItem, createdAt date : Date, error : String?, tradingCode : TradingCode?) {
        self.init()
        self.identifier = jobID
        self.jobName = jobType.rawValue
        self.artwork = artwork
        self.artworkID = artwork.identifier
        self.createdAt = DateManager.utcFormatter.string(from: date)
        self.error = error
        self.completed = true
        self.tradingCode = tradingCode
        self.userID = UserManager.shared.userID
    }
    
    override public static func primaryKey() -> String {
        return "identifier"
    }
    
    override public static func ignoredProperties() -> [String] {
        return ["state"]
    }
    
    public override class func shouldIncludeInDefaultSchema() -> Bool {
        return false
    }
    
    public var model: DTOJob {
        get {
            return DTOJob(id: identifier,
                          userID: userID,
                          jobName: jobName,
                          artwork: artwork?.model,
                          searchQueryImageUrl: searchQueryImageUrl,
                          searchQueryImageUrlThumbnail: searchQueryImageUrlThumbnail,
                          error: error,
                          completed: completed,
                          createdAt: createdAt,
                          tradingCode: tradingCode?.model,
                          blockchainVerified: blockchainVerified.value,
                          searchResults: Array(searchResults))
        }
    }
}

// MARK: - VeracityItem
extension Job: VeracityItem {
    public var id: String {
        return identifier
    }
    
    public var itemName: String? {
        return artwork?.name
    }
    
    public var date: Date? {
        return createdAtDate
    }
    
    public var thumbImageUrl: String? {
        return artwork?.thumbnail
    }
    
    public var overlayImageUrl: String? {
        return artwork?.fingerprintUrls?.first
    }
    
}
