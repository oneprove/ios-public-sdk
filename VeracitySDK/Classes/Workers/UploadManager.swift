//
//  UploadManager.swift
//  VeracitySDK
//
//  Created by Andrew on 24/05/2019.
//

import Foundation
import RealmSwift

///Used on all upload operations to handle upload progress.
public typealias UploadProgressHandlerBlock = (_ progress : Progress?, _ continious : Bool, _ completed : Bool) -> ()
///Used to get current progress in any class.
public typealias UploadProgressCallbackBlock = (_ progress : Int, _ identifier : String?) -> ()
///provide custom operation
public typealias CustomImageUploadOperationProvider = (_ filename : String) -> (VPImageUploadOperation?)

/**
 Singelton. Mostly internal class that automaticaly handles all the uploading process and can report upload progress. Each `LocalJob` or `LocalProtectItem` change in database is observed and when any item (protect item have biggest upload priority) report itself as upload-ready, then uploading starts.
 Uploading of any item is made of several parts - mostly combination of direct image upload and some regular requests. `UploadManager` will handle automaticaly any upload part fail and try to make request again later in right order, skipping the completed ones.
 
 Upload runs on background thread that can run in background for unspecified amount of time.
 There can be only one item at all to be uploaded at once.
 */
public class UploadManager : NSObject {
    ///Public singleton instance of `UploadManager`.
    public static let shared = UploadManager()
    
    fileprivate let operationQueue = OperationQueue()
    fileprivate var backgroundTaskID : UIBackgroundTaskIdentifier = .invalid
    
    fileprivate var artworks : Results<LocalProtectItem>?
    fileprivate var artworksNotificationToken : NotificationToken?
    fileprivate var jobs : Results<LocalJob>?
    fileprivate var jobsNotificationToken : NotificationToken?
    
    private(set) public var currentUploadIdentifier : String?
    public var currentUploadProgressCallBack : UploadProgressCallbackBlock?
    public var lastKnownUploadProgressValue : Int?
    
    fileprivate var uploading : Bool {
        if RealmHandler.shared.isInWriteTransaction {
            return true
        }
        debugLog("Operation count: \(operationQueue.operationCount)")
        return operationQueue.operationCount > 0
    }
    
    private override init() {
        super.init()
        operationQueue.maxConcurrentOperationCount = 1
        LocalDataCleaner.shared.startObservingChanges()
        ConnectionManager.shared.startObservingChanges()
    }
    
    //TODO: maybe make internal & get called by some internal class
    ///Starts internal observing of any changes in local data.
    ///Must be called on main thread.
    public func startObserving() {
        artworksNotificationToken?.invalidate()
        artworks = RealmHandler.shared.getObjects(of: LocalProtectItem.self)
        artworksNotificationToken = artworks?.observe({ [weak self] (change) in
            guard let _ = self else { return }
            switch change {
            case .initial:
                self?.tryToStartUpload()
                break
            case .update(_, _, _, _):
                self?.tryToStartUpload()
                break
            case .error(let error):
                // An error occurred while opening the Realm file on the background worker thread
                debugLog("\(error)")
            }
        })
        
        jobsNotificationToken?.invalidate()
        jobs = RealmHandler.shared.getObjects(of: LocalJob.self)
        jobsNotificationToken = jobs?.observe({ [weak self] (change) in
            switch change {
            case .initial:
//                self?.tryToStartUpload()
                break
            case .update(_, _, _, _):
                self?.tryToStartUpload()
                break
            case .error(let error):
                // An error occurred while opening the Realm file on the background worker thread
                debugLog("\(error)")
            }
        })
    }
    
    func tryToStartUpload() {
        if !uploading, ConnectionManager.shared.isOnGoodConnection() {
            if let operations = operationsForUploadTask() {
                beginBackgroundTask()
                operationQueue.addOperations(operations, waitUntilFinished: false)
            }
        }else if RealmHandler.shared.isInWriteTransaction {
            warningLog("upload cannot be started")
            Timer.scheduledTimer(withTimeInterval: 2, repeats: false) { [weak self] (_) in
                warningLog("restarting upload")
                self?.tryToStartUpload()
            }
        }
    }
}

//MARK: - Background task
fileprivate extension UploadManager {
    func beginBackgroundTask() {
        if backgroundTaskID != .invalid { return }
        
        backgroundTaskID = UIApplication.shared.beginBackgroundTask(expirationHandler: { [weak self] in
            self?.endBackgroundTaks()
        })
    }
    
    func endBackgroundTaks() {
        UIApplication.shared.endBackgroundTask(backgroundTaskID)
        backgroundTaskID = .invalid
    }
}

//MARK: - Upload stuff
fileprivate extension UploadManager {
    func uploadTaskByPriority() -> Object? {
        let artworkResult : LocalProtectItem? = artworks?.first(where: { $0.canBeUploaded })
        let jobResult : LocalJob? = jobs?.first(where: { $0.canBeUploaded })
        return artworkResult ?? jobResult
    }
    
    func setupProgressHandler(_ operations: [Operation]) {
        let uploadTotalDataUnitCount = countDataUnitCount(for: operations)
        var uploadCompletedDataUnitCount = 0.0
        
        operations.forEach { (operation) in
            if let customOperation = operation as? VPOperation {
                customOperation.progressCallback = { [weak self] (progress, continious, completed) in
                    guard let progress = progress else { return }
                    let sendedUnitCount = uploadCompletedDataUnitCount + Double(progress.completedUnitCount)
                    let result = (sendedUnitCount / uploadTotalDataUnitCount) * 100
                    
                    if completed {
                        uploadCompletedDataUnitCount += Double(progress.totalUnitCount)
                    }
                    self?.lastKnownUploadProgressValue = Int(result)
                    
                    DispatchQueue.main.async {
                        self?.currentUploadProgressCallBack?(Int(result), self?.currentUploadIdentifier)
                        NotificationCenter.default.post(name: NotificationsNames.uploadItemProcess,
                                                        object: (process: Int(result), identifier: self?.currentUploadIdentifier))
                    }
                }
            }
        }
    }
    
    func countDataUnitCount(for operations : [Operation]) -> Double {
        var resultCount = 0
        operations.forEach { (operation) in
            if let uploadOperation = operation as? VPImageUploadOperation {
                if let unitCount = ImagePersistence.imageDataAtDiskPath(path: uploadOperation.filename)?.count {
                    resultCount += unitCount
                }
            }else {
                resultCount += 1000
            }
        }
        return Double(resultCount)
    }
    
    func operationsForUploadTask() -> [Operation]? {
        if let task = uploadTaskByPriority() {
            var operations = [Operation]()
            if let artwork = task as? LocalProtectItem {
                operations = uploadOperationsFor(artwork: artwork)
                currentUploadIdentifier = artwork.identifier
            }else if let job = task as? LocalJob {
                operations = uploadOperationsFor(job: job)
                currentUploadIdentifier = job.identifier
            }
            
            ///Append progress handler block to all operations.
            setupProgressHandler(operations)
            
            ///Append finish operation
            operations.append(BlockOperation(block: { [weak self] in
                debugLog("last operation")
                DispatchQueue.main.async {
                    if self?.uploadTaskByPriority() == nil {
                        debugLog("removing uploadingg id")
                        self?.endBackgroundTaks()
                        self?.currentUploadIdentifier = nil
                        self?.currentUploadProgressCallBack = nil
                        self?.lastKnownUploadProgressValue = nil
                    }
                }
            }))
            
            return operations
        }
        return nil
    }
    
    //MARK: - Protect flow operations
    func uploadOperationsFor(artwork : LocalProtectItem) -> [Operation] {
        var operations = [Operation]()
        
        if artwork.artwork == nil {
            //full flow
            ///thumbnail image upload
            if artwork.thumbnailImageUrl == nil, let thumbnail = artwork.thumbnailImageFilename {
                let thumbnailOperation = ImageUploadS3Operation(filename: thumbnail, referId: artwork.identifier)
                thumbnailOperation.finishingBlock = {
                    DispatchQueue.main.async {
                        if let imageUrl = thumbnailOperation.imageUrlString {
                            RealmHandler.shared.persist(updates: {
                                artwork.thumbnailImageUrl = imageUrl
                                if let track = thumbnailOperation.trackingUpload {
                                    artwork.filesUploadTracking.append(track)
                                }
                                thumbnailOperation.endOperation()
                            })
                        }else { thumbnailOperation.endOperation() }
                    }
                }
                operations.append(thumbnailOperation)
            }
            
            ///overview image upload
            if artwork.overviewImageUrl == nil, let overview = artwork.overviewImageFilename {
                let overviewOperation = ImageUploadS3Operation(filename: overview, referId: artwork.identifier)
                overviewOperation.finishingBlock = {
                    DispatchQueue.main.async {
                        if let imageUrl = overviewOperation.imageUrlString {
                            RealmHandler.shared.persist(updates: {
                                artwork.overviewImageUrl = imageUrl
                                if let track = overviewOperation.trackingUpload {
                                    artwork.filesUploadTracking.append(track)
                                }
                                overviewOperation.endOperation()
                            })
                        }else { overviewOperation.endOperation() }
                    }
                }
                operations.append(overviewOperation)
            }
            
            ///overlay image upload
            if artwork.metadata?["overlay_url"] as? String == nil, let overlay = artwork.overlayGuideImageFilename {
                let overlayOperation = ImageUploadS3Operation(filename: overlay, referId: artwork.identifier)
                overlayOperation.finishingBlock = {
                    DispatchQueue.main.async {
                        if let imageUrl = overlayOperation.imageUrlString {
                            artwork.updateMetadata(value: imageUrl, forKey: "overlay_url")
                            RealmHandler.shared.persist(updates: {
                                if let track = overlayOperation.trackingUpload {
                                    artwork.filesUploadTracking.append(track)
                                }
                            })
                            overlayOperation.endOperation()
                        }else {
                            overlayOperation.endOperation()
                        }
                    }
                }
                operations.append(overlayOperation)
            }
            
            ///first fingerprint image upload
            if Array(artwork.fingerprintImageUrls).first == nil, let fingerprint_0 = Array(artwork.fingerprintImageFilenames).first {
                var fingerprintOperation_0 : VPImageUploadOperation?
                if let customUpload = VeracitySDK.configuration.customFingerprintUploadOperationProvider?(fingerprint_0) { fingerprintOperation_0 = customUpload }
                else {
                    fingerprintOperation_0 = ImageUploadS3Operation(filename: fingerprint_0, referId: artwork.identifier)
                }
                
                if let fingerprintOperation = fingerprintOperation_0 {
                    fingerprintOperation.finishingBlock = {
                        DispatchQueue.main.async {
                            if let imageUrl = fingerprintOperation.imageUrlString {
                                RealmHandler.shared.persist(updates: {
                                    artwork.fingerprintImageUrls.append(imageUrl)
                                    if let track = fingerprintOperation.trackingUpload {
                                        artwork.filesUploadTracking.append(track)
                                    }
                                    fingerprintOperation.endOperation()
                                })
                            }else { fingerprintOperation.endOperation() }
                        }
                    }
                    operations.append(fingerprintOperation)
                }
            }
            
            ///second fingerprint image upload
            if Array(artwork.fingerprintImageUrls).count < 2, Array(artwork.fingerprintImageFilenames).count > 1 {
                let fingerprint_1 = Array(artwork.fingerprintImageFilenames)[1]
                var fingerprintOperation_1 : VPImageUploadOperation?
                if let customUpload = VeracitySDK.configuration.customFingerprintUploadOperationProvider?(fingerprint_1) { fingerprintOperation_1 = customUpload }
                else {
                    fingerprintOperation_1 = ImageUploadS3Operation(filename: fingerprint_1, referId: artwork.identifier)
                }
                
                if let fingerprintOperation = fingerprintOperation_1 {
                    fingerprintOperation.finishingBlock = {
                        DispatchQueue.main.async {
                            if let imageUrl = fingerprintOperation.imageUrlString {
                                RealmHandler.shared.persist(updates: {
                                    artwork.fingerprintImageUrls.append(imageUrl)
                                    if let track = fingerprintOperation.trackingUpload {
                                        artwork.filesUploadTracking.append(track)
                                    }
                                    fingerprintOperation.endOperation()
                                })
                            }else { fingerprintOperation.endOperation() }
                        }
                    }
                    operations.append(fingerprintOperation)
                }
            }
            
            ///create artist
            if artwork.createdArtist == nil, let firstName = artwork.artist?.firstName, let lastName = artwork.artist?.lastName {
                let artistOperation = CreateArtistOperation(artistFirstName: firstName, artistLastName: lastName)
                artistOperation.finishingBlock = {
                    DispatchQueue.main.async {
                        if let createdArtist = artistOperation.createdArtist {
                            RealmHandler.shared.persist(updates: {
                                artwork.createdArtist = createdArtist
                                artistOperation.endOperation()
                            })
                        }else { artistOperation.endOperation() }
                    }
                }
                operations.append(artistOperation)
            }
            
            ///create artwork
            if artwork.createdArtworkID == nil, Array(artwork.filesUploadTracking).count > 0, Array(artwork.fingerprintImageUrls).count == Array(artwork.fingerprintImageFilenames).count {
                let artworkOperation = CreateProtectItemOperation(artwork: ThreadSafeReference(to: artwork), wallet: nil)
                artworkOperation.finishingBlock = {
                    DispatchQueue.main.async {
                        if let createdID = artworkOperation.createdArtwork?.identifier {
                            RealmHandler.shared.persist(updates: {
                                artwork.createdArtworkID = createdID
                                artworkOperation.endOperation()
                            })
                        }else { artworkOperation.endOperation() }
                    }
                }
                operations.append(artworkOperation)
            }
            
            ///add overview & thumbnail url
            if !artwork.overviewAdded {
                let addOverviewOperation = AddProtectItemOverviewOperation(artwork: ThreadSafeReference(to: artwork))
                addOverviewOperation.finishingBlock = {
                    DispatchQueue.main.async {
                        RealmHandler.shared.persist(updates: {
                            artwork.overviewAdded = addOverviewOperation.success
                            addOverviewOperation.endOperation()
                        })
                    }
                }
                operations.append(addOverviewOperation)
            }
            
            ///add fingerprint urls
            if artwork.jobID == nil, artwork.overviewAdded {
                let addFingerprintsOperation = AddProtectItemFingerprintsOperation(artwork: ThreadSafeReference(to: artwork))
                addFingerprintsOperation.finishingBlock = {
                    //cover rare cases when notification arive sooner than response.
                    guard !artwork.isInvalidated else {
                        addFingerprintsOperation.endOperation()
                        return
                    }
                    DispatchQueue.main.async {
                        if let jobID = addFingerprintsOperation.jobID {
                            RealmHandler.shared.persist(updates: {
                                artwork.jobID = jobID
                                addFingerprintsOperation.endOperation()
                            })
                        }else { addFingerprintsOperation.endOperation() }
                    }
                }
                operations.append(addFingerprintsOperation)
            }
        } else if artwork.artwork != nil {
            //failed or incomplete finishing flow
            ///first fingerprint image upload
            if Array(artwork.fingerprintImageUrls).first == nil, let fingerprint_0 = Array(artwork.fingerprintImageFilenames).first {
                let fingerprintOperation_0 = ImageUploadS3Operation(filename: fingerprint_0, referId: artwork.identifier)
                fingerprintOperation_0.finishingBlock = {
                    DispatchQueue.main.async {
                        if let imageUrl = fingerprintOperation_0.imageUrlString {
                            RealmHandler.shared.persist(updates: {
                                artwork.fingerprintImageUrls.append(imageUrl)
                                if let track = fingerprintOperation_0.trackingUpload {
                                    artwork.filesUploadTracking.append(track)
                                }
                                fingerprintOperation_0.endOperation()
                            })
                        }else { fingerprintOperation_0.endOperation() }
                    }
                }
                operations.append(fingerprintOperation_0)
            }
            
            ///second fingerprint image upload
            if Array(artwork.fingerprintImageUrls).count < 2, Array(artwork.fingerprintImageFilenames).count > 1 {
                let fingerprintOperation_1 = ImageUploadS3Operation(filename: Array(artwork.fingerprintImageFilenames)[1], referId: artwork.identifier)
                fingerprintOperation_1.finishingBlock = {
                    DispatchQueue.main.async {
                        if let imageUrl = fingerprintOperation_1.imageUrlString {
                            RealmHandler.shared.persist(updates: {
                                artwork.fingerprintImageUrls.append(imageUrl)
                                if let track = fingerprintOperation_1.trackingUpload {
                                    artwork.filesUploadTracking.append(track)
                                }
                                fingerprintOperation_1.endOperation()
                            })
                        }else { fingerprintOperation_1.endOperation() }
                    }
                }
                operations.append(fingerprintOperation_1)
            }
            
            ///add fingerprint urls
            if artwork.jobID == nil {
                let addFingerprintsOperation = AddProtectItemFingerprintsOperation(artwork: ThreadSafeReference(to: artwork))
                addFingerprintsOperation.finishingBlock = {
                    DispatchQueue.main.async {
                        if let jobID = addFingerprintsOperation.jobID {
                            debugLog(jobID)
                            RealmHandler.shared.persist(updates: {
                                artwork.jobID = jobID
                                addFingerprintsOperation.endOperation()
                            })
                        }else { addFingerprintsOperation.endOperation() }
                    }
                }
                operations.append(addFingerprintsOperation)
            }
        }
        return operations
    }
    
    //MARK: - Verify & Image Search flow operations
    func uploadOperationsFor(job : LocalJob) -> [Operation] {
        var operations = [Operation]()
        if job.type == .verification {
            ///fingerprint image upload
            if Array(job.fingerprintImageUrls).first == nil, let fingerprint = Array(job.fingerprintImageFilenames).first {
                let fingerprintOperation = ImageUploadS3Operation(filename: fingerprint, referId: job.identifier)
                fingerprintOperation.finishingBlock = {
                    DispatchQueue.main.async {
                        if let imageUrl = fingerprintOperation.imageUrlString {
                            RealmHandler.shared.persist(updates: {
                                job.fingerprintImageUrls.append(imageUrl)
                                if let track = fingerprintOperation.trackingUpload {
                                    job.filesUploadTracking.append(track)
                                }
                                fingerprintOperation.endOperation()
                            })
                        }else { fingerprintOperation.endOperation() }
                    }
                }
                operations.append(fingerprintOperation)
            }
            
            ///get fingerprint
            if job.fingerprint == nil, let artworkID = job.anyArtwork?.identifier {
                let fingerprintOperation = ArtworkFingerprintOperation(artworkID: artworkID)
                fingerprintOperation.finishingBlock = {
                    DispatchQueue.main.async {
                        if let fingerprint = fingerprintOperation.fingerprint {
                            RealmHandler.shared.persist(updates: {
                                job.fingerprint = fingerprint
                                fingerprintOperation.endOperation()
                            })
                        } else {
                            fingerprintOperation.endOperation()
                        }
                    }
                }
                operations.append(fingerprintOperation)
            }
            
            ///create batchjob
            if AppManager.selectedVertical == .lpmPoc, job.batchJobID == nil {
                let createBatchJobOperation = CreateBatchJobOperation()
                createBatchJobOperation.finishingBlock = {
                    DispatchQueue.main.async {
                        if let batchJobID = createBatchJobOperation.batchJob?.identifier {
                            RealmHandler.shared.persist(updates: {
                                job.batchJobID = batchJobID
                                createBatchJobOperation.endOperation()
                            })
                        } else {
                            createBatchJobOperation.endOperation()
                        }
                    }
                }
                operations.append(createBatchJobOperation)
            }
            
            
            ///verify uploaded image and create verifying job
            if job.jobID == nil, job.batchJobID == nil, Array(job.filesUploadTracking).count > 0 {
                let verifyFingerprintOperation = VerifyFingerprintOperation(localJob: ThreadSafeReference(to: job))
                verifyFingerprintOperation.finishingBlock = {
                    DispatchQueue.main.async {
                        if let jobID = verifyFingerprintOperation.jobID {
                            RealmHandler.shared.persist(updates: {
                                job.jobID = jobID
                                verifyFingerprintOperation.endOperation()
                            })
                        } else {
                            verifyFingerprintOperation.endOperation()
                        }
                    }
                }
                operations.append(verifyFingerprintOperation)
            } else if job.jobID == nil, let batchJobID = job.batchJobID, Array(job.filesUploadTracking).count > 0 {
                
                if job.jobID == nil {
                    let verifyFingerprintOperation = VerifyFingerprintOperation(localJob: ThreadSafeReference(to: job),
                                                                                localJobCoin: ThreadSafeReference(to: job),
                                                                                batchJob: batchJobID)
                    verifyFingerprintOperation.finishingBlock = {
                        DispatchQueue.main.async {
                            if let jobID = verifyFingerprintOperation.jobID {
                                RealmHandler.shared.persist(updates: {
//                                    job.jobID = jobID
                                    verifyFingerprintOperation.endOperation()
                                })
                            } else {
                                verifyFingerprintOperation.endOperation()
                            }
                        }
                    }
                    operations.append(verifyFingerprintOperation)
                }
                
                if jobs?.first(where: { ($0.canBeUploaded && $0.identifier != job.identifier && $0.batchJobID == batchJobID) }) == nil {
                    let startBatchJobOperation = StartBatchJobOperation(batchJobID: batchJobID)
                    startBatchJobOperation.finishingBlock = {
                        DispatchQueue.main.async {
                            if let batchJob = startBatchJobOperation.batchJob {
                                debugLog(batchJob)
                                RealmHandler.shared.persist(updates: {
                                    job.jobID = batchJob.id
                                    startBatchJobOperation.endOperation()
                                })
                            } else {
                                startBatchJobOperation.endOperation()
                            }
                        }
                    }
                    operations.append(startBatchJobOperation)
                }
            }
        }
        else if job.type == .imageSearch {
            //image search flow
            ///thumbnail image upload
            if job.thumbnailImageUrl == nil, let thumbnail = job.thumbnailImageFilename {
                let thumbnailOperation = ImageUploadS3Operation(filename: thumbnail, referId: job.identifier)
                thumbnailOperation.finishingBlock = {
                    DispatchQueue.main.async {
                        if let imageUrl = thumbnailOperation.imageUrlString {
                            RealmHandler.shared.persist(updates: {
                                job.thumbnailImageUrl = imageUrl
                                if let track = thumbnailOperation.trackingUpload {
                                    job.filesUploadTracking.append(track)
                                }
                                thumbnailOperation.endOperation()
                            })
                        }else { thumbnailOperation.endOperation() }
                    }
                }
                operations.append(thumbnailOperation)
            }
            
            ///overview image upload
            if job.overviewImageUrl == nil, let overview = job.overviewImageFilename {
                let overviewOperation = ImageUploadS3Operation(filename: overview, referId: job.identifier)
                overviewOperation.finishingBlock = {
                    DispatchQueue.main.async {
                        if let imageUrl = overviewOperation.imageUrlString {
                            RealmHandler.shared.persist(updates: {
                                job.overviewImageUrl = imageUrl
                                if let track = overviewOperation.trackingUpload {
                                    job.filesUploadTracking.append(track)
                                }
                                overviewOperation.endOperation()
                            })
                        }else { overviewOperation.endOperation() }
                    }
                }
                operations.append(overviewOperation)
            }
            
            ///image search request
            if job.jobID == nil {
                let imageSearchOperation = ImageSearchOperation(localJob: ThreadSafeReference(to: job))
                imageSearchOperation.finishingBlock = {
                    DispatchQueue.main.async {
                        if let jobID = imageSearchOperation.jobID {
                            RealmHandler.shared.persist(updates: {
                                job.jobID = jobID
                                imageSearchOperation.endOperation()
                            })
                        }else { imageSearchOperation.endOperation() }
                    }
                }
                operations.append(imageSearchOperation)
            }
        }
        
        return operations
    }
}
