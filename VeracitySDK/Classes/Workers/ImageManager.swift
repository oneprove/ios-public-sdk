//
//  ImageManager.swift
//  ONEPROVE
//
//  Created by Andrew on 27/11/2018.
//  Copyright © 2018 ONEPROVE s.r.o. All rights reserved.
//

import Foundation
import SDWebImage

public typealias ImageCallback = (_ image : UIImage?) -> ()

///Primary used for downloading and caching remote images data to disk.
public class ImageManager {
    
    /**
     Downloads image from network by given URL.
     Returns cached image af any by default.
     Image response is cached to disk by default.
     - Parameter url: URL used as image remote path or as key for cache
     - Parameter ignoreCache: try to return only local cache result if `false`
     - Parameter cacheResult: try to save image data response if `true`
     */
    public static func provideImage(for url : URL, ignoreCache : Bool = false, cacheResult : Bool = true , completion : @escaping ImageCallback) {
        let imageKey = url.absoluteString
        if !ignoreCache, let cacheImageData = SDImageCache.shared.diskImageData(forKey: imageKey), let cacheImage = UIImage(data: cacheImageData) {
            completion(cacheImage)
            return
        }
        DispatchQueue.global(qos: .userInitiated).async {
            SDWebImageDownloader.shared.downloadImage(with: url, options: .continueInBackground, progress: nil) {(image, data, error, complete) in
                if complete, let image = image, error == nil {
                    if cacheResult {
                        SDImageCache.shared.storeImageData(toDisk: image.sd_imageData(), forKey: imageKey)
                    }
                    DispatchQueue.main.async {
                        completion(image)
                    }
                }else {
                    debugLog("error: \(error?.localizedDescription ?? "?")")
                    DispatchQueue.main.async {
                        completion(nil)
                    }
                }
            }
        }
    }
    
    public static func provideCachedImage(for url : URL) -> UIImage? {
        let imageKey = url.absoluteString
        if let cacheImageData = SDImageCache.shared.diskImageData(forKey: imageKey), let cacheImage = UIImage(data: cacheImageData) {
            return cacheImage
        }
        return nil
    }
    
    ///Remove memory & disk cache.
    public static func removeCache() {
        SDImageCache.shared.clearMemory()
        SDImageCache.shared.clearDisk(onCompletion: nil)
    }
}
