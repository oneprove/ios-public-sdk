//
//  ImageDownloadOperation.swift
//  VeracitySDK
//
//  Created by Andrew on 22/10/2019.
//  Copyright © 2019 Veracity Protocol s.r.o. All rights reserved.
//

import Foundation
import UIKit

public class ImageDownloadOperation : VPOperation {
    private var imageUrl : URL
    public var downloadedImage : UIImage?
    public var responseError : Error?
    
    public init(imageUrl : URL) {
        self.imageUrl = imageUrl
        super.init()
    }
    
    override public func main() {
        guard isCancelled == false else {
            finish(true)
            return
        }
        
        executing(true)
        URLSession.shared.dataTask(with: imageUrl) { [weak self] (data, response, error) in
            self?.responseError = error
            if let data = data, let image = UIImage(data: data) {
                self?.downloadedImage = image
            }
            debugLog(error)
            
            if let finishingBlock = self?.finishingBlock {
                finishingBlock()
            }else {
                self?.endOperation()
            }
        }.resume()
    }
}
