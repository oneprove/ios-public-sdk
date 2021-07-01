//
//  ImagePersistence.swift
//  VeracitySDK
//
//  Created by Andrew on 16/04/2019.
//  Copyright © 2019 Veracity Protocol s.r.o. All rights reserved.
//

import Foundation
import UIKit

///Main class to persist taken images by user, eg. fingerprints, overview & thumbnail till they are successfully uploaded.
public class ImagePersistence {
    ///Returns absolute string of custom folder inside system's documents folder with .user domain.
    ///Contains all taken & not uploaded images.
    class var imagesLocalDirectoryPath: String {
        ///Important: Documents directory full path changes at each app launch
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let imagesDirectory: String = (paths.first ?? "") + "/takenImages"
        if !FileManager.default.fileExists(atPath: imagesDirectory) {
            try? FileManager.default.createDirectory(atPath: imagesDirectory, withIntermediateDirectories: false, attributes: nil)
        }
        return imagesDirectory
    }
    
    /**
     Writes given image data to disk, to custom folder with randomly generated filename.
     - Parameter imageData:         Image data to save to disk.
     - Parameter filenameSuffix:    Optional suffix that will be appended to filename.
     - Parameter fileExtension:     String extension of given filename. Should be "jpg" or "png". Default is "jpg".
     - Throws:                      Throws filename if write operation was successfull.
     */
    public class func saveImageToDisk(imageData: Data, filenameSuffix : String? = nil, fileExtension: String = "jpg") throws -> String {
        let imageName = NSUUID().uuidString + "\(filenameSuffix ?? "")" + "." + fileExtension
        let photoURL = URL(fileURLWithPath: imagesLocalDirectoryPath)
        let localUrl = photoURL.appendingPathComponent(imageName)
        
        try imageData.write(to: localUrl, options: Data.WritingOptions.atomic)
        
        return imageName
    }
    
    ///See also: `saveImageToDisk(imageData: Data, fileExtension: String)`
    public class func saveImageToDisk(imageData: Data, asJPEG jpg: Bool, filenameSuffix : String? = nil) throws -> String {
        return try saveImageToDisk(imageData: imageData, filenameSuffix: filenameSuffix, fileExtension: jpg ? "jpg" : "png")
    }
    
    //TODO: ⚠️ change path to filename
    ///Provides image by given filename.
    /// - Parameter path: Filename of desired image.
    /// - Returns: `UIImage` matching filename or `nil`.
    public class func imageAtDiskPath(path: String) -> UIImage? {
        let image = UIImage(contentsOfFile: imagesLocalDirectoryPath + "/" + path)
        return image
    }
    
    ///Provides image data by given filename.
    /// - Parameter path: Filename of desired image data.
    /// - Returns: Image `Data` matching filename or `nil`.
    public class func imageDataAtDiskPath(path: String) -> Data? {
        let data = FileManager.default.contents(atPath: imagesLocalDirectoryPath + "/" + path)
        return data
    }
    
    ///Tries to remove image file by given filename.
    /// - Parameter path: Filename of desired image.
    public class func removeImage(atPath path: String) {
        guard path != "" else { return }///empty string removes whole folder
        try? FileManager.default.removeItem(atPath: imagesLocalDirectoryPath + "/" + path)
    }
    
    ///Tries to remove whole folder with taken images.
    public class func removeAllTakenImages() {
        try? FileManager.default.removeItem(atPath: imagesLocalDirectoryPath)
    }
}
