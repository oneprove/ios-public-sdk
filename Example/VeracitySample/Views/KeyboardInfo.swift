//
//  KeyboardInfo.swift
//  ONEPROVE
//
//  Created by Minh Chu on 11/11/20.
//  Copyright © 2020 ONEPROVE s.r.o. All rights reserved.
//

import UIKit

public struct KeyboardInfo {
    public let duration: TimeInterval
    public let height: CGFloat
    public let hidden: Bool
    
    public init?(_ notification: Notification) {
        guard let userInfo = notification.userInfo else {
            return nil
        }
        
        let safeAreaBottomInset = UIApplication.shared.windows.first(where: { $0.isKeyWindow })?.safeAreaInsets.bottom ?? 0
        let keyboardHeight = ((userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue.height ?? 0) - safeAreaBottomInset
        duration = (userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval) ?? 0
        hidden = (notification.name == UIResponder.keyboardWillHideNotification)
        height = hidden ? 0 : max(keyboardHeight, 0)
    }
    
    public func animate(view: UIView?) {
        let transfrom = CGAffineTransform(translationX: 0, y: -height)
        
        UIView.animate(withDuration: duration) {
            guard let scrollView = view as? UIScrollView else {
                view?.transform = transfrom
                return
            }
            scrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: self.height, right: 0)
        }
    }
    
    public func update(scrollView: UIScrollView?) {
        UIView.animate(withDuration: duration) {
            scrollView?.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: self.height, right: 0)
        }
    }
}
