//
//  VerifyItemStream.swift
//  Veracity Authenticator
//
//  Created by Minh Chu on 2/12/21.
//  Copyright © 2021 ONEPROVE s.r.o. All rights reserved.
//

import UIKit
import SDWebImage
import RealmSwift

public protocol VerifyItemStream: AnyObject {
    var takeFingerPrintType: TakeFingerprintType { get set }
    var verifyItem: VeracityItem? { get set }
    var overlayPhoto: UIImage? { get set }
    var fingerPhotos: [(blurScore: Float, image: UIImage)] { get set }
    var fingerRect: CGRect? { get set }
    var localJob: LocalJob? { get set }
}

public protocol MutableVerifyItemStream: VerifyItemStream {
    func changeTakeFingerprintType(_ type: TakeFingerprintType)
    func updateItemToVerify(_ item: VeracityItem)
    func updateOverlayPhoto(_ photo: UIImage)
    func updateFingers(_ photos: [(blurScore: Float, image: UIImage)])
    func updateFingerRect(_ rect: CGRect)
    func observerOverlayPhotoCallBack(_ callback: @escaping (UIImage) -> Void)
    func observerVerifyItemCallBack(_ callback: @escaping (VeracityItem) -> Void)
    func observerFingerRectCallBack(_ callback: @escaping (CGRect) -> Void)
    func observerItemStateChange(_ callback: @escaping (ItemState?) -> Void)
    func cleanUp()
}

public final class VerifyItemStreamImpl: MutableVerifyItemStream {
    public init() {}
    
    public func updateItemToVerify(_ item: VeracityItem) {
        self.cleanUp() // first
        self.verifyItem = item
        self.protectItemCallback?(item)
        self.fetchFingerprintInfo(for: item)
        self.fetchOverlayPhoto(item.overlayImageUrl)
    }

    public func changeTakeFingerprintType(_ type: TakeFingerprintType) {
        takeFingerPrintType = type
    }
    
    public func observerItemStateChange(_ callback: @escaping (ItemState?) -> Void) {
        self.itemStateCallback = callback
    }
    
    public func updateFingers(_ photos: [(blurScore: Float, image: UIImage)]) {
        self.fingerPhotos = photos
    }
    
    public func updateFingerRect(_ rect: CGRect) {
        self.fingerRect = rect
        self.fingerRectCallback?(rect)
    }
    
    public func updateOverlayPhoto(_ photo: UIImage) {
        self.overlayPhoto = photo
        self.overlayPhotoCallback?(photo)
    }
    
    public func observerVerifyItemCallBack(_ callback: @escaping (VeracityItem) -> Void) {
        self.protectItemCallback = callback
    }
    
    public func observerFingerRectCallBack(_ callback: @escaping (CGRect) -> Void) {
        self.fingerRectCallback = callback
    }
    
    public func observerOverlayPhotoCallBack(_ callback: @escaping (UIImage) -> Void) {
        self.overlayPhotoCallback = callback
    }
    
    public func cleanUp() {
        verifyItem = nil
        fingerRect = nil
        overlayPhoto = nil
        protectItemCallback = nil
        fingerRectCallback = nil
        overlayPhotoCallback = nil
        fingerPhotos.removeAll()
    }
    
    private func fetchFingerprintInfo(for item: VeracityItem) {
        guard let id = (item as? ProtectItem)?.identifier ?? (item as? Job)?.artwork?.identifier else {
            return
        }
        
        NetworkClient.protectItemFingerprint(itemID: id) { [weak self] (fingerprint, error) in
            guard let fingerprint = fingerprint else {
                return
            }
            
            let rect = CGRect(x: fingerprint.location?.x ?? 0,
                              y: fingerprint.location?.y ?? 0,
                              width: fingerprint.location?.width ?? 0,
                              height: fingerprint.location?.height ?? 0)
            self?.updateFingerRect(rect)
        }
    }
    
    private func fetchOverlayPhoto(_ urlString : String?) {
        guard let urlString = urlString, let url = URL(string: urlString) else {
            return
        }
        
        if let thumnailData = SDImageCache.shared.diskImageData(forKey: url.absoluteString), let cacheThumbail = UIImage(data: thumnailData) {
            self.updateOverlayPhoto(cacheThumbail)
        }
        else {
            _ = SDWebImageDownloader.shared.downloadImage(with: url, options: .continueInBackground, progress: nil, completed: { [weak self] (image, data, error, complete) in
                
                if complete, let image = image {
                    SDImageCache.shared.storeImageData(toDisk: data, forKey: url.absoluteString)
                    self?.updateOverlayPhoto(image)
                }
            })
        }
    }
    
    private func handleItemStateChange() {
        observingLocalToken?.invalidate()
        observingLocalToken = localJob?.observe({ [weak self] changes in
            switch changes {
            case .error(_):
                break
            case .change(let i, _):
                let item = i as? LocalJob
                if let id = item?.jobID {
                    self?.jobItemId = id
                }
                let state = item?.state
                self?.itemStateCallback?(state)
                break
            case .deleted:
                self?.getRemoteItem()
                break
            }
        })
    }
    
    private func getRemoteItem() {
        guard let id = jobItemId else {
            return
        }
        
        guard let item = RealmHandler.shared.getObject(of: Job.self, forKey: id) else {
            return
        }
        
        self.itemStateCallback?(item.state)
    }
    
    public var verifyItem: VeracityItem?
    public var localJob: LocalJob?
    public var fingerRect: CGRect?
    public var overlayPhoto: UIImage?
    public var fingerPhotos: [(blurScore: Float, image: UIImage)] = []
    public var takeFingerPrintType: TakeFingerprintType = .default
    private var protectItemCallback: ((VeracityItem) -> Void)?
    private var fingerRectCallback: ((CGRect) -> Void)?
    private var overlayPhotoCallback: ((UIImage) -> Void)?
    private var itemStateCallback: ((ItemState?) -> Void)?
    private var observingLocalToken: NotificationToken?
    private var jobItemId: String?
}

// MARK: - Logic verify item
extension VerifyItemStreamImpl {
    public func processVerifyItem() {
        self.jobItemId = nil
        self.localJob = nil
        
        let artwwork = (verifyItem as? ProtectItem) ?? (verifyItem as? Job)?.artwork
        let localJob = LocalJob(type: .verification, artwork: artwwork)
        self.localJob = localJob
        print("Local Job: \(localJob)")
        self.saveFingerPhotos(protectItem: localJob)
        RealmHandler.shared.add(localJob, modifiedUpdate: true)
        handleItemStateChange()
    }
    
    private func saveFingerPhotos(protectItem: LocalJob) {
        fingerPhotos.forEach { (result) in
            let suffix = Constants.imageFilenameSuffixWith(blurScore: Double(exactly: result.blurScore))
            let fingerprintImage = result.image
            
            guard
                let fingerprintImageData = fingerprintImage.pngData(),
                let fingerprintImageLocalPath = try? ImagePersistence.saveImageToDisk(imageData: fingerprintImageData, asJPEG: false, filenameSuffix: suffix)
            else { return }
            
            protectItem.fingerprintImageFilenames.append(fingerprintImageLocalPath)
            protectItem.fingerprintImageFilenamesCount += 1
        }
    }
}
