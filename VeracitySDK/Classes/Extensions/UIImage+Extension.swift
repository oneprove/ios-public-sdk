//
//  UIImage+Extension.swift
//  VeracitySDK
//
//  Created by Andrew on 31/05/2019.
//  Copyright © 2019 Veracity Protocol s.r.o. All rights reserved.
//

import Foundation
import UIKit

public extension UIImage {
    ///Resize image by given percentage.
    func resized(withPercentage percentage: CGFloat) -> UIImage? {
        let canvasSize = CGSize(width: size.width * percentage, height: size.height * percentage)
        UIGraphicsBeginImageContextWithOptions(canvasSize, false, scale)
        defer { UIGraphicsEndImageContext() }
        draw(in: CGRect(origin: .zero, size: canvasSize))
        return UIGraphicsGetImageFromCurrentImageContext()
    }
    
    ///Resize image to given size value.
    func resized(toSize newSize: CGSize) -> UIImage? {
        var width = newSize.width
        var height = newSize.height
        if size.width > size.height {
            height = CGFloat(ceil(width / size.width * size.height))
        } else {
            width = CGFloat(ceil(height / size.height * size.width))
        }
        let canvasSize = CGSize(width: width, height: height)
        UIGraphicsBeginImageContextWithOptions(canvasSize, false, scale)
        defer { UIGraphicsEndImageContext() }
        draw(in: CGRect(origin: .zero, size: canvasSize))
        return UIGraphicsGetImageFromCurrentImageContext()
    }
}
