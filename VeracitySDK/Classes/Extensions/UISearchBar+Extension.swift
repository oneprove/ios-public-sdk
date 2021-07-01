//
//  UISearchBar+Extension.swift
//  Veracity Authenticator
//
//  Created by Minh Chu on 5/3/21.
//  Copyright © 2021 ONEPROVE s.r.o. All rights reserved.
//

import UIKit

extension UISearchBar {
    func setIconColor(_ color: UIColor) {
        for subView in self.subviews {
            for subSubView in subView.subviews {
                let view = subSubView as? UITextInputTraits
                if view != nil {
                    let textField = view as? UITextField
                    let glassIconView = textField?.leftView as? UIImageView
                    glassIconView?.image = glassIconView?.image?.withRenderingMode(.alwaysTemplate)
                    glassIconView?.tintColor = color
                    break
                }
            }
        }
    }
}
