//
//  LocalProtectItem.swift
//  VeracitySDK
//
//  Created by Andrew on 16/04/2019.
//  Copyright © 2019 Veracity Protocol s.r.o. All rights reserved.
//

import Foundation
import RealmSwift

///Local artwork is created after meta data validation
///Designed to hold all user generated data when going thru protect flow
public class LocalProtectItem: Object {
    @objc dynamic public var identifier: String = LocalProtectItem.generateLocalID()
    ///To finish incomplete / failed protect flow
    @objc dynamic public var artwork : ProtectItem?
    public let height = RealmOptional<Double>()
    public let width = RealmOptional<Double>()
    @objc dynamic public var artist: Creator?
    @objc dynamic public var name: String?
    public let year = RealmOptional<Int>()
    @objc dynamic public var overviewImageFilename: String?
    @objc dynamic public var thumbnailImageFilename: String?
    @objc dynamic public var createdAt = Date()
    public var fingerprintImageFilenames = List<String>()
    @objc dynamic public var fingerprintImageFilenamesCount: Int = 0//Used in Protect filter & when taking fps with MAP.
    @objc dynamic public var fingerprintLocation : FingerprintLocation?
    public var filesUploadTracking = List<FileUploadTrack>()
    ///Metadata JSON string backup.
    @objc dynamic public var metadataString : String?
    @objc dynamic public var overlayGuideImageFilename : String?
    @objc dynamic public var algo : String?
    
    //MARK: Remote data
    @objc dynamic public var thumbnailImageUrl: String?
    @objc dynamic public var overviewImageUrl: String?
    public var fingerprintImageUrls = List<String>()
    @objc dynamic var createdArtist: Creator? = nil
    @objc dynamic public var createdArtworkID: String?
    @objc dynamic var overviewAdded = false
    @objc dynamic public var jobID : String?
    
    public var state : ItemState? {
        if artwork == nil, !(overviewImageFilename?.isEmpty ?? true), !(thumbnailImageFilename?.isEmpty ?? true), Array(fingerprintImageFilenames).count > 1 {
            if jobID != nil {
                return .analyzing
            }
            
            let id = UploadManager.shared.currentUploadIdentifier
            if id != nil && id != identifier {
                return .pending
            }
            return .uploading
        }else if artwork == nil, (overviewImageFilename?.isEmpty ?? true && overviewImageUrl != nil), Array(fingerprintImageFilenames).count > 1 {
            if jobID != nil {
                return .analyzing
            }
            
            let id = UploadManager.shared.currentUploadIdentifier
            if id != nil && id != identifier {
                return .pending
            }
            return .uploading
        }else if artwork != nil, Array(fingerprintImageFilenames).count > 1 {
            if jobID != nil, Array(fingerprintImageUrls).count == Array(fingerprintImageFilenames).count {
                return .analyzing
            }
            
            let id = UploadManager.shared.currentUploadIdentifier
            if id != nil && id != identifier {
                return .pending
            }
            return .uploading
        }
        return .incomplete
    }
    
    public var metadata : [String : AnyHashable]? {
        if let json = metadataString {
            return json.convertToDictionary() as? [String : AnyHashable]
        }
        return nil
    }
    
    public var canBeUploaded : Bool {
        if artwork == nil, jobID == nil, overviewImageFilename != nil, thumbnailImageFilename != nil, artist != nil, name != nil, height.value != nil, width.value != nil, fingerprintLocation != nil, Array(fingerprintImageFilenames).count > 1 {
            return true
        } else if artwork == nil, jobID == nil, overviewImageUrl != nil, thumbnailImageUrl != nil, artist != nil, name != nil, height.value != nil, width.value != nil, fingerprintLocation != nil, Array(fingerprintImageFilenames).count > 1 {
            return true
        } else if let artwork = artwork, (artwork.state == .failed || artwork.state == .incomplete), jobID == nil, Array(fingerprintImageFilenames).count > 1 {
            return true
        }
        return false
    }
    
    public var tooSmallItem : Bool {
        if let height = height.value, let width = width.value {
            if width <= 7.5 || height <= 10 {
                return true
            }
        }else if artwork?.height ?? 0 > 0, artwork?.width ?? 0 > 0 {
            if artwork?.width ?? 20 <= 7.5 || artwork?.height ?? 20 <= 10 {
                return true
            }
        }
        return false
    }
    
    public override class func shouldIncludeInDefaultSchema() -> Bool {
        return false
    }
    
    //MARK: - Lifecycle
    override public static func primaryKey() -> String {
        return "identifier"
    }
    
    convenience public init(artwork : ProtectItem?) {
        self.init()
        self.artwork = artwork
        self.metadataString = artwork?.metadata?.convertToJSONString()
        self.name = artwork?.name
        self.width.value = artwork?.width
        self.height.value = artwork?.height
        self.year.value = artwork?.year
        self.artist = Creator(firstName: artwork?.artistFirstName ?? "", lastName: artwork?.artistLastName ?? "")
    }
    
    ///Adds fingerprint filename to array and increase separate count of filenames and persist changes.
    ///Because Realm can't filter by @count.
    public func appendFingerprintFilename(_ filename : String, realm : Realm? = nil) {
        if let realm = realm {
            try! realm.write {
                self.fingerprintImageFilenames.append(filename)
                self.fingerprintImageFilenamesCount += 1
            }
            return
        }
        RealmHandler.shared.persist {
            self.fingerprintImageFilenames.append(filename)
            self.fingerprintImageFilenamesCount += 1
        }
    }
    
    public func updateMetadata(value : AnyHashable, forKey key : String) {
        if var metadataDict = metadata {
            metadataDict.updateValue(value, forKey: key)
            warningLog(metadataDict.convertToJSONString() ?? "-")
            RealmHandler.shared.persist {
                self.metadataString = metadataDict.convertToJSONString()
            }
        }else {
            let dict = [key : value]
            warningLog(dict.convertToJSONString() ?? "-")
            RealmHandler.shared.persist {
                self.metadataString = dict.convertToJSONString()
            }
        }
    }
    
    ///Removes fingerprint data from disk a resets the counter.
    public func clearFingerprints() {
        guard Array(fingerprintImageFilenames).count > 0, fingerprintImageFilenamesCount > 0 else { return }
        fingerprintImageFilenames.forEach({ ImagePersistence.removeImage(atPath: $0) })
        
        if let overlay = overlayGuideImageFilename {
            ImagePersistence.removeImage(atPath: overlay)
        }
        
        RealmHandler.shared.persist {
            self.fingerprintImageFilenames.removeAll()
            self.fingerprintImageFilenamesCount = 0
            self.overlayGuideImageFilename = nil
        }
    }
    
    public func clearOverview() {
        guard let overviewFilename = overviewImageFilename else { return }
        
        ImagePersistence.removeImage(atPath: overviewFilename)
        
        if let thumbFilename = thumbnailImageFilename {
            ImagePersistence.removeImage(atPath: thumbFilename)
        }
        
        RealmHandler.shared.persist {
            overviewImageFilename = nil
            thumbnailImageFilename = nil
        }
    }
    
    ///Removes taken fingerprints, overview & thumbnail images.
    ///Called before removing whole object from database.
    public func removeAllLocalImages() {
        fingerprintImageFilenames.forEach({ ImagePersistence.removeImage(atPath: $0) })
        if let overview = overviewImageFilename {
            ImagePersistence.removeImage(atPath: overview)
        }
        if let thumbnail = thumbnailImageFilename {
            ImagePersistence.removeImage(atPath: thumbnail)
        }
        if let overlay = overlayGuideImageFilename {
            ImagePersistence.removeImage(atPath: overlay)
        }
    }
}

extension LocalProtectItem {
    class func generateLocalID() -> String {
        return Constants.localIDPrefix + UUID().uuidString
    }
    
    class func isArtistIdLocal(artistId: String) -> Bool {
        return artistId.hasPrefix(Constants.localIDPrefix)
    }
    
    var hasLocalId: Bool {
        return identifier.hasPrefix(Constants.localIDPrefix)
    }
    
    func getTimeUploadFiles() -> Int64 {
        return self.filesUploadTracking.map { (track) -> Int64 in
            return track.timeUpload()
        }.reduce(0, +)
    }
}

extension LocalProtectItem: VeracityItem {
    public var id: String {
        return identifier
    }
    
    public var itemName: String? {
        return name
    }
    
    public var date: Date? {
        return createdAt
    }
    
    public var thumbImageUrl: String? {
        if let artwork = self.artwork {
            return artwork.thumbnail
        }
        else if let localImg = self.thumbnailImageFilename, !localImg.isEmpty {
            return localImg
        }
        else if let imgUrl = self.thumbnailImageUrl, !imgUrl.isEmpty {
            return imgUrl
        }
        return nil
    }
    
    public var overlayImageUrl: String? {
        if let artwork = self.artwork {
            return artwork.fingerprintUrls?.first
        }
        else if let localImg = Array(fingerprintImageUrls).first, !localImg.isEmpty {
            return localImg
        }
        else if let imgUrl = Array(fingerprintImageFilenames).first, !imgUrl.isEmpty {
            return imgUrl
        }
        return nil
    }
    
}
