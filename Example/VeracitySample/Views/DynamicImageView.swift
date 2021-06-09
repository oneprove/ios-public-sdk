//
//  DynamicImageView.swift
//  ONEPROVE
//
//  Created by Andrew on 09/07/2020.
//  Copyright © 2020 ONEPROVE s.r.o. All rights reserved.
//

import UIKit

@IBDesignable class DynamicImageView : UIImageView {
    @IBInspectable var fixedWidth : CGFloat = 0 {
        didSet {
            invalidateIntrinsicContentSize()
        }
    }
    @IBInspectable var fixedHeight : CGFloat = 0 {
        didSet {
            invalidateIntrinsicContentSize()
        }
    }

    override var intrinsicContentSize : CGSize {
        var size = CGSize.zero
        if fixedWidth > 0 && fixedHeight > 0 {
            size.width = fixedWidth
            size.height = fixedHeight
        }else if fixedWidth <= 0 && fixedHeight > 0 {
            size.height = fixedHeight
            if let image = image {
                let ratio = fixedHeight / image.size.height
                size.width = image.size.width * ratio
            }
        }else if fixedWidth > 0 && fixedHeight <= 0 {
            size.width = fixedWidth
            if let image = image {
                let ratio = fixedWidth / image.size.width
                size.height = image.size.height * ratio
            }
        }else {
            size = image?.size ?? .zero
        }
        return size
    }
}
