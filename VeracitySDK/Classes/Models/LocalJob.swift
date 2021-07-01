//
//  LocalJob.swift
//  VeracitySDK
//
//  Created by Andrew on 16/04/2019.
//  Copyright © 2019 Veracity Protocol s.r.o. All rights reserved.
//

import Foundation
import RealmSwift

public enum ExpectedJobResult : String {
    case verified = "verified"
    case failed = "failed"
}

///Represents local variation of server `Job` represented by `type`.
public class LocalJob: Object {
    //MARK: Shared properties
    @objc dynamic public var identifier: String = LocalProtectItem.generateLocalID()
    @objc dynamic var createdAt = Date()
    @objc private dynamic var jobType : String?
    ///Refenrece to existing job on server. Used to remove after upload complete
    @objc dynamic public var jobID : String?
    
    //MARK: Image Search unique properties
    @objc dynamic public var overviewImageFilename: String?
    @objc dynamic public var thumbnailImageFilename: String?
    //remote data
    @objc dynamic public var overviewImageUrl : String?
    @objc dynamic public var thumbnailImageUrl : String?
    
    //MARK: Verification unique properties
    @objc dynamic public var publicArtwork : PublicProtectItem?
    @objc dynamic public var verificationArtwork : VerificationProtectItem?
    @objc dynamic public var artwork : ProtectItem?
    public var fingerprintImageFilenames = List<String>()
    @objc dynamic public var fingerprintImageFilenamesCount: Int = 0//Used in filter & when taking fps with MAP.
    @objc dynamic public var algo : String?
    @objc dynamic private(set) public var expectedResult : String?
    //remote data
    public var fingerprintImageUrls = List<String>()
    ///fingerprint is loaded before verification flow, or later when uploading.
    @objc dynamic public var fingerprint : Fingerprint?
    @objc dynamic public var batchJobID : String?
    public var filesUploadTracking = List<FileUploadTrack>()
    
    public var type : JobType? {
        get {
            if let jobType = jobType {
                return JobType(rawValue: jobType)
            }
            return nil
        }
        set {
            jobType = newValue?.rawValue
        }
    }
    
    public var state : ItemState? {
        if jobID != nil {
            return .analyzing
        }else {
            if UploadManager.shared.currentUploadIdentifier != identifier { return .pending }
            return .uploading
        }
    }
    
    public var canBeUploaded : Bool {
        if type == .verification, jobID == nil, anyArtwork != nil, Array(fingerprintImageFilenames).count > 0 {
            return true
        }else if type == .imageSearch, jobID == nil, overviewImageFilename != nil, thumbnailImageFilename != nil {
            return true
        }
        return false
    }
    
    ///Used to get data from any of stored Artwork (`Artwork`, `VerificationArtwork`, `PublicArtwork`).
    ///Simplify getting overview, width, height, artist etc.
    public var anyArtwork : ProtectItem? {
        return artwork ?? verificationArtwork ?? publicArtwork
    }
    
    override public static func primaryKey() -> String {
        return "identifier"
    }
    
    override public class func shouldIncludeInDefaultSchema() -> Bool {
        return false
    }
    
    //MARK: - Lifecycle
    public convenience init(type : JobType, artwork : ProtectItem?) {
        self.init()
        self.type = type
        if let publicArtwork = artwork as? PublicProtectItem {
            self.publicArtwork = publicArtwork
        }else if let verificationArtwork = artwork as? VerificationProtectItem {
            self.verificationArtwork = verificationArtwork
        }else if let artwork = artwork {
            self.artwork = artwork
        }
        
        if VeracitySDK.configuration.verificationShouldMatchProtectingAlgo {
            updateVerificationAlgoToMatchProtectedAlgo()
        }
    }
    
    //MARK: - Verification unique methods
    ///Adds fingerprint filename to array and increase separate count of filenames and persist changes
    ///Because Realm can't filter by @count
    public func appendFingerprintFilename(_ filename : String) {
        RealmHandler.shared.persist {
            self.fingerprintImageFilenames.append(filename)
            self.fingerprintImageFilenamesCount += 1
        }
    }
    
    ///Removes fingerprint data from disk a resets the counter.
    public func clearFingerprints() {
        guard Array(fingerprintImageFilenames).count > 0, fingerprintImageFilenamesCount > 0 else { return }
        fingerprintImageFilenames.forEach({ ImagePersistence.removeImage(atPath: $0) })
        
        RealmHandler.shared.persist {
            self.fingerprintImageFilenames.removeAll()
            self.fingerprintImageFilenamesCount = 0
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
    }
    
    public func updateVerificationAlgoToMatchProtectedAlgo() {
        if let protectingAlgo = anyArtwork?.algorithmUsed {
            algo = protectingAlgo
        }
    }
    
    ///Trezor verifier unique func. Sets expected job result before verification begins to handle false positive results on backend.
    public func setExpectedResult(_ expectation : ExpectedJobResult) {
        expectedResult = expectation.rawValue
    }
    
    public func getTimeUploadFiles() -> Int64 {
        return self.filesUploadTracking.map { (track) -> Int64 in
            return track.timeUpload()
        }.reduce(0, +)
    }
}

// MARK: - VeracityItem
extension LocalJob: VeracityItem {
    public var id: String {
        return identifier
    }
    
    public var itemName: String? {
        return anyArtwork?.name
    }
    
    public var date: Date? {
        return createdAt
    }
    
    public var thumbImageUrl: String? {
        return anyArtwork?.thumbnail ?? thumbnailImageUrl
    }
    
    
    public var overlayImageUrl: String? {
        return Array(anyArtwork?.fingerprintUrls ?? []).first ?? Array(fingerprintImageUrls).first
    }
    
}
