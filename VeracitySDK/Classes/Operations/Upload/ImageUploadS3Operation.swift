//
//  ImageUploadS3Operation.swift
//  VeracitySDK
//
//  Created by Andrew on 24/05/2019.
//

import Foundation

///Custom operation that wraps image from disk, makes request to presigned url to upload and then uploads image data to that url.
///Can handle upload progress value by `progressCallback` block.
class ImageUploadS3Operation: VPOperation, VPImageUploadOperation {
    var filename : String
    var referId: String?
    var imageUrlString : String?
    var error : Error?
    var lastProgressValue : Progress?
    var trackingUpload: FileUploadTrack?
    
    init(filename: String, referId: String? = nil) {
        self.filename = filename
        self.referId = referId
        super.init()
        self.trackingUpload = self.getFileUploadTracked()
    }
    
    override func main() {
        guard isCancelled == false else {
            finish(true)
            return
        }
        
        executing(true)
        debugLog("start")
        
        guard let imageData = ImagePersistence.imageDataAtDiskPath(path: filename) else {
            debugLog("no image data")
            finishOperation()
            return
        }
        
        self.startTrackTimeUpload()
        NetworkClient.presignedImageUploadURL(forFilename: filename) { [weak self] (presignedURL, error) in
            if let presignedURL = presignedURL {
                NetworkClient.uploadImage(image: imageData, toPresignedURL: presignedURL, completion: { [weak self] (publicURL, error) in
                    debugLog(error)
                    if let url = publicURL {
                        self?.imageUrlString = url
                    }else if let error = error {
                        self?.error = error
                    }else { warningLog("image upload failed") }
                    
                    self?.progressCallback?(self?.lastProgressValue, true, true)
                    
                    self?.finishOperation()
                    debugLog("end")
                    self?.endTrackTimeUpload()
                    }, progressCallback: { [weak self] progress in
                        //check last progress agains current ⚠️
                        self?.progressCallback?(self?.lastProgressValue, true, false)
                        self?.lastProgressValue = progress
                })
            }else {
                debugLog(error)
                warningLog("get presigned url request failed")
                self?.error = error
                self?.finishOperation()
            }
        }
    }
}
