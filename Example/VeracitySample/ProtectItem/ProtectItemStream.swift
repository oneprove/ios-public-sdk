//
//  CreateItemStream.swift
//  Veracity Authenticator
//
//  Created by Minh Chu on 2/4/21.
//  Copyright © 2021 ONEPROVE s.r.o. All rights reserved.
//

import FingerprintFinder
import VeracitySDK

protocol ProtectItemStream {
    var currentStep: ProtectItemStep { get set }
    var overviewPhoto: UIImage? { get set }
    var croppedPhoto: UIImage? { get set }
    var cropPoints: [CGPoint]? { get set }
    var itemName: String? { get set }
    var retakeItem: ProtectItem? { get set }
    var unitType: UnitType { get set }
    var dimension: (width: Double, height: Double)? { get set }
    var fingerPhotos: [(blurScore: Float, image: UIImage)] { get set }
}

protocol MutableProtectItemStream: ProtectItemStream {
    func change(step: ProtectItemStep)
    func update(overviewPhoto: UIImage)
    func update(croppedPhoto: UIImage, points: [CGPoint])
    func update(dimension: (width: Double, height: Double))
    func update(itemName: String)
    func update(unitType: UnitType)
    func addMore(fingerPhotos: [(blurScore: Float, image: UIImage)])
    func updateRetakeItem(_ item: ProtectItem)
    
    func observerStepChange(_ stepCallback: @escaping (ProtectItemStep) -> Void)
    func observerOverPhotoCallBack(_ overPhotoCallback: @escaping (UIImage) -> Void)
    func observerCroppedPhotoCallBack(_ croppedPhotoCallback: @escaping (UIImage) -> Void)
    func observerDimensionCallBack(_ dimensionCallback: @escaping (_ width: Double, _ height: Double) -> Void)
    
    func cleanUp()
}

final class ProtectItemStreamImpl: MutableProtectItemStream {
    var unitType: UnitType = .cm
    var currentStep: ProtectItemStep = .takeOverviewPhoto
    var overviewPhoto: UIImage?
    var croppedPhoto: UIImage?
    var cropPoints: [CGPoint]?
    var dimension: (width: Double, height: Double)?
    var fingerPhotos: [(blurScore: Float, image: UIImage)] = []
    var itemName: String?
    var protectItem: LocalProtectItem?
    var retakeItem: ProtectItem?
    private var stepCallback: ((ProtectItemStep) -> Void)?
    private var overPhotoCallback: ((UIImage) -> Void)?
    private var croppedPhotoCallback: ((UIImage) -> Void)?
    private var dimensionCallBack: ((_ width: Double, _ height: Double) -> Void)?
    
    func observerStepChange(_ stepCallback: @escaping (ProtectItemStep) -> Void) {
        self.stepCallback = stepCallback
    }
    
    func observerOverPhotoCallBack(_ overPhotoCallback: @escaping (UIImage) -> Void) {
        self.overPhotoCallback = overPhotoCallback
    }
    
    func observerCroppedPhotoCallBack(_ croppedPhotoCallback: @escaping (UIImage) -> Void) {
        self.croppedPhotoCallback = croppedPhotoCallback
    }
    
    func observerDimensionCallBack(_ dimensionCallback: @escaping (Double, Double) -> Void) {
        self.dimensionCallBack = dimensionCallback
    }
    
    func change(step: ProtectItemStep) {
        if step == .completed {
            self.processItem()
        }
        
        currentStep = step
        self.stepCallback?(step)
    }
    
    func update(overviewPhoto: UIImage) {
        self.overviewPhoto = overviewPhoto
        self.overPhotoCallback?(overviewPhoto)
    }
    
    func update(croppedPhoto: UIImage, points: [CGPoint] = []) {
        self.croppedPhoto = croppedPhoto
        self.cropPoints = points
        self.croppedPhotoCallback?(croppedPhoto)
    }
    
    func update(dimension: (width: Double, height: Double)) {
        let dimension = ProtectItemHelper.dimentionToCm(dimension, unit: unitType)
        debugLog("Dimension = \(dimension)")
        self.dimension = dimension
        self.dimensionCallBack?(dimension.width, dimension.height)
    }
    
    func update(itemName: String) {
        self.itemName = itemName
    }
    
    
    func update(unitType: UnitType) {
        self.unitType = unitType
    }
    
    func addMore(fingerPhotos: [(blurScore: Float, image: UIImage)]) {
        self.fingerPhotos.append(contentsOf: fingerPhotos)
    }
    
    func updateRetakeItem(_ item: ProtectItem) {
        self.retakeItem = item
        
        // item name
        update(itemName: item.name)
        
        // dimension
        update(dimension: (item.width, item.height))
        
        // overview cropped photo
        if let overviewUrl = item.overview, let url = URL(string: overviewUrl) {
            ImageManager.provideImage(for: url) { [weak self] (image) in
                guard let photo = image else {
                    return
                }
                self?.update(croppedPhoto: photo)
            }
        }
    }
    
    func cleanUp() {
        currentStep = .takeOverviewPhoto
        overviewPhoto = nil
        croppedPhoto = nil
        cropPoints?.removeAll()
        dimension = nil
        protectItem = nil
        fingerPhotos.removeAll()
    }
}

// MARK: - Logic complete item
extension ProtectItemStreamImpl {
    private func processItem() {
        
        let item = LocalProtectItem()
        self.protectItem = item
        item.name = itemName
        item.year.value = Date().year
        item.algo = AppManager.selectedVertical.defaultProtectAlgo
        item.artist = Creator(firstName: "Veracity", lastName: "Demo")
        
        // Update dimention
        if let width = dimension?.width, let height = dimension?.height {
            item.width.value = width
            item.height.value = height
        }
        
        // Metadata
        let metadata: [String: Any] = ["Vertical".lowercased():  AppManager.selectedVertical.rawValue]
        item.metadataString = metadata.convertToJSONString()
        
        if let item = self.protectItem {
            saveFingerprintLocation(protectItem: item)
            saveOverviewPhoto(protectItem: item)
            saveFingerPhotos(protectItem: item)
            
            RealmHandler.shared.add(item, modifiedUpdate: true)
        }
    }
    
    private func saveFingerprintLocation(protectItem: LocalProtectItem) {
        guard let image = croppedPhoto,
              let dimension = dimension
        else { return }
        
        let overviewSize = CGSize(width: dimension.width, height: dimension.height)
        let result = FingerprintFinder.find(overview: image, overviewSize: overviewSize)
        
        if let location = result.fingerprints.first as? CGRect {
            protectItem.fingerprintLocation = FingerprintLocation(rect: location)
        } else {
            debugLog("cannot create fingerprint location")
        }
    }
    
    private func saveOverviewPhoto(protectItem: LocalProtectItem) {
        guard
            let image = croppedPhoto,
            let overviewImageData = image.jpegData(compressionQuality: Constants.compressOverviewQuality),
            let overviewImageLocalPath = try? ImagePersistence.saveImageToDisk(imageData: overviewImageData)
        else { return }
        
        guard
            let thumbnailImage = image.resized(toSize: Constants.thumbnailImageSize),
            let thumbnailImageData = thumbnailImage.jpegData(compressionQuality: Constants.compressThumbnailQuality),
            let thumbnailImageLocalPath = try? ImagePersistence.saveImageToDisk(imageData: thumbnailImageData)
        else { return }
        
        protectItem.overviewImageFilename = overviewImageLocalPath
        protectItem.thumbnailImageFilename = thumbnailImageLocalPath
    }
    
    private func saveFingerPhotos(protectItem: LocalProtectItem) {
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
