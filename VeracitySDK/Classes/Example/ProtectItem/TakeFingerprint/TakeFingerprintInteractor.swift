//
//  TakeFingerprintInteractor.swift
//  Veracity Authenticator
//
//  Created by Minh Chu on 2/2/21.
//  Copyright © 2021 ONEPROVE s.r.o. All rights reserved.
//

import FingerprintFinder
import ARCameraController


protocol TakeFingerprintPresentable: class {
    var listener: TakeFingerprintPresentableListener? { get set }
    func loading(_ show: Bool)
    func gotItemDimension(_ dimension: (width: Double, height: Double))
    func gotFingerprintRect(_ rect: CGRect, overviewPhoto: UIImage, dimension: (width: Double, height: Double))
}

final class TakeFingerprintInteractor: TakeFingerprintPresentableListener {
    private weak var presenter: TakeFingerprintPresentable?
    private let createItemStream: MutableProtectItemStream?
    private let verifyItemStream: MutableVerifyItemStream?
    
    private var sourcePhoto: UIImage?
    private var dimension: (Double, Double)?
    
    init(presenter: TakeFingerprintPresentable,
         createItemStream: MutableProtectItemStream?,
         verifyItemStream: MutableVerifyItemStream?) {
        self.presenter = presenter
        self.createItemStream = createItemStream
        self.verifyItemStream = verifyItemStream
        self.presenter?.listener = self
        
        self.observerVerifyItem()
    }
    
    func startTakeFinger() {
        let dimension = createItemStream?.dimension
        let sourcePhoto = createItemStream?.croppedPhoto
        self.loadFingerprint(sourcePhoto: sourcePhoto, dimension: dimension)
    }
    
    /// Incase verify item
    private func observerVerifyItem() {
        self.presenter?.loading(verifyItemStream != nil)
        verifyItemStream?.observerVerifyItemCallBack({ [weak self] (verifyItem) in
            self?.checkVerifyItemDimension(verifyItem)
        })
        
        verifyItemStream?.observerFingerRectCallBack({ [weak self] (rect) in
            self?.fetchVerifyItemInfo(rect)
        })
    }
    
    func checkVerifyItemDimension(_ item: VeracityItem) {
        if let item = item as? ProtectItem {
            self.presenter?.gotItemDimension((item.width, item.height))
        } else if let item = (item as? Job)?.artwork {
            self.presenter?.gotItemDimension((item.width, item.height))
        }
    }
    
    private func fetchVerifyItemInfo(_ fingerRect: CGRect) {
        guard
            let item = (self.verifyItemStream?.verifyItem as? ProtectItem) ??  (self.verifyItemStream?.verifyItem as? Job)?.artwork,
            let url = URL(string: item.overview ?? "")
        else { return }
        
        ImageManager.provideImage(for: url) { [weak self] (image) in
            self?.presenter?.loading(false)
            guard let photo = image else {
                return
            }
            
            self?.presenter?.gotFingerprintRect(fingerRect, overviewPhoto: photo, dimension: (item.width, item.height))
        }
    }
    
    internal func loadFingerprint(sourcePhoto: UIImage?, dimension: (width: Double, height: Double)?) {
        guard let image = sourcePhoto,
              let dimension = dimension
        else { return }
        
        let itemSize = CGSize(width: dimension.width, height: dimension.height)
        FingerprintFinder.find(overview: image, overviewSize: itemSize) { [weak self] (status, fingerprintRect) in
            if status != .regular, status != .small {
                self?.checkFingerprintStatus(status)
                return
            }
            
            /// Delay to make sure view did load to layout load more smoothy
            Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { (_) in
                self?.presenter?.gotFingerprintRect(fingerprintRect, overviewPhoto: image, dimension: dimension)
            }
        }
    }
    
    func takenFingers(photos: [(blurScore: Float, image: UIImage)]) {
        createItemStream?.addMore(fingerPhotos: photos)
        createItemStream?.change(step: .completed)
    }
    
    private func didFailToLoadFingerprints(_ error: Error) {
        debugLog("Did fail to load fingerprints: \(error.localizedDescription)")
    }
    
    private func checkFingerprintStatus(_ status: FingerprintFinderStatus) {
        var error: Error?
        
        switch (status) {
        case .emptyInput:
            error = NSError(domain: "FingerEmptyInput", code: 300,
                            userInfo: [NSLocalizedDescriptionKey: "Empty image, try to take new image."])
        case .notFound, .insufficientScore:
            error = NSError(domain: "FingerNotFound", code: 301,
                            userInfo: [NSLocalizedDescriptionKey: "No fingerprint found in image, try to take new image."])
        default:
            break
        }
        
        if let error = error {
            didFailToLoadFingerprints(error)
        }
    }
}
