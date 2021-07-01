//
//  KeyboardAnimationProtocol.swift
//  ONEPROVE
//
//  Created by Minh Chu on 11/11/20.
//  Copyright © 2020 ONEPROVE s.r.o. All rights reserved.
//

import UIKit

public protocol ContainerViewProtocol {
    var containerView: UIView? { get }
    var scrollView: UIScrollView? { get }
}

extension ContainerViewProtocol {
    var scrollView: UIScrollView? {
        return nil
    }
}

public protocol KeyboardAnimationProtocol: AnyObject, ContainerViewProtocol {}

public extension KeyboardAnimationProtocol {
    func setupKeyboardAnimation() {
        NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: nil) { [weak self] (notification) in
            KeyboardInfo(notification)?.animate(view: self?.containerView)
            KeyboardInfo(notification)?.update(scrollView: self?.scrollView)
        }
        NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: nil) { [weak self] (notification) in
            KeyboardInfo(notification)?.animate(view: self?.containerView)
            KeyboardInfo(notification)?.update(scrollView: self?.scrollView)
        }
    }
    
    func removeObservers() {
        NotificationCenter.default.removeObserver(self)
    }
}
