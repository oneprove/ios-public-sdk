//
//  UIView+Extension.swift
//  ONEPROVE
//
//  Created by Andrew on 12/02/2019.
//  Copyright © 2019 ONEPROVE s.r.o. All rights reserved.
//

import UIKit

extension UIView {
    //MARK: Shadow
    public func addShadow(withOffset offset : CGSize? = nil) {
        layer.masksToBounds = false
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = offset ?? CGSize(width: 3, height: 3)
        layer.shadowOpacity = 0.2
        layer.shadowPath = UIBezierPath(rect: bounds).cgPath
        layer.shadowRadius = 2
    }
    
    //MARK: Outside Border
    fileprivate struct Constants {
        static let ExternalBorderName = "externalBorder"
    }

    public func addOutsideBorder(width borderWidth: CGFloat, color borderColor: UIColor) {
        let externalBorder = CALayer()
        externalBorder.frame = CGRect(x: -borderWidth, y: -borderWidth, width: frame.size.width + 2 * borderWidth, height: frame.size.height + 2 * borderWidth)
        externalBorder.borderColor = borderColor.cgColor
        externalBorder.borderWidth = borderWidth
        externalBorder.name = Constants.ExternalBorderName

        layer.insertSublayer(externalBorder, at: 0)
        layer.masksToBounds = false
    }

    public func removeExternalBorders() {
        layer.sublayers?.filter() { $0.name == Constants.ExternalBorderName }.forEach() {
            $0.removeFromSuperlayer()
        }
    }
    
    public var parentViewController: UIViewController? {
        weak var parentResponder: UIResponder? = self
        while parentResponder != nil {
            parentResponder = parentResponder!.next
            if let viewController = parentResponder as? UIViewController {
                return viewController
            }
        }
        return nil
    }
}


extension UIButton {
    public func setTitleUnderline(_ text: String, for state: UIControl.State) {
        let titleString = NSMutableAttributedString(string: text)
        titleString.addAttribute(.underlineStyle,
                                 value: NSUnderlineStyle.single.rawValue,
                                 range: NSMakeRange(0, text.count))
        self.setAttributedTitle(titleString, for: state)
    }
}

extension UIButton: XIBLocalizable {
    @IBInspectable public var xibLocKey: String? {
        get { return nil }
        set(key) {
            setTitle(Text(rawValue: key ?? "")?.localizedText, for: .normal)
        }
    }
}
