//
//  VerifyItemStream.swift
//  Veracity Authenticator
//
//  Created by Minh Chu on 2/12/21.
//  Copyright © 2021 ONEPROVE s.r.o. All rights reserved.
//

import UIKit
import SDWebImage
import VeracitySDK

protocol VerifyItemStream: class {
    var verifyItem: VeracityItem? { get set }
    var overlayPhoto: UIImage? { get set }
    var fingerPhotos: [(blurScore: Float, image: UIImage)] { get set }
    var fingerRect: CGRect? { get set }
    var localJob: LocalJob? { get set }
}

protocol MutableVerifyItemStream: VerifyItemStream {
    func updateVerifyItem(_ item: VeracityItem)
    func updateOverlayPhoto(_ photo: UIImage)
    func updateFingers(_ photos: [(blurScore: Float, image: UIImage)])
    func updateFingerRect(_ rect: CGRect)
    func observerOverlayPhotoCallBack(_ callback: @escaping (UIImage) -> Void)
    func observerVerifyItemCallBack(_ callback: @escaping (VeracityItem) -> Void)
    func observerFingerRectCallBack(_ callback: @escaping (CGRect) -> Void)
    func cleanUp()
}

final class VerifyItemStreamImpl: MutableVerifyItemStream {
    func updateVerifyItem(_ item: VeracityItem) {
        self.cleanUp() // first
        self.verifyItem = item
        self.protectItemCallback?(item)
        self.fetchFingerprintInfo(for: item)
        self.fetchOverlayPhoto(item.overlayImageUrl)
    }
    
    func updateFingers(_ photos: [(blurScore: Float, image: UIImage)]) {
        self.fingerPhotos = photos
        self.processVerifyItem()
    }
    
    func updateFingerRect(_ rect: CGRect) {
        self.fingerRect = rect
        self.fingerRectCallback?(rect)
    }
    
    func updateOverlayPhoto(_ photo: UIImage) {
        self.overlayPhoto = photo
        self.overlayPhotoCallback?(photo)
    }
    
    func observerVerifyItemCallBack(_ callback: @escaping (VeracityItem) -> Void) {
        self.protectItemCallback = callback
    }
    
    func observerFingerRectCallBack(_ callback: @escaping (CGRect) -> Void) {
        self.fingerRectCallback = callback
    }
    
    func observerOverlayPhotoCallBack(_ callback: @escaping (UIImage) -> Void) {
        self.overlayPhotoCallback = callback
    }
    
    func cleanUp() {
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
    
    var verifyItem: VeracityItem?
    var localJob: LocalJob?
    var fingerRect: CGRect?
    var overlayPhoto: UIImage?
    var fingerPhotos: [(blurScore: Float, image: UIImage)] = []
    private var protectItemCallback: ((VeracityItem) -> Void)?
    private var fingerRectCallback: ((CGRect) -> Void)?
    private var overlayPhotoCallback: ((UIImage) -> Void)?
}

// MARK: - Logic verify item
extension VerifyItemStreamImpl {
    private func processVerifyItem() {
        let artwwork = (verifyItem as? ProtectItem) ?? (verifyItem as? Job)?.artwork
        let localJob = LocalJob(type: .verification, artwork: artwwork)
        self.localJob = localJob
        print("Local Job: \(localJob)")
        self.saveFingerPhotos(protectItem: localJob)
        RealmHandler.shared.add(localJob, modifiedUpdate: true)
        self.cleanUp()
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
