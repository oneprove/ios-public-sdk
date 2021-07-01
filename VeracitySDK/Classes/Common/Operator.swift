//
//  Operator.swift
//  ONEPROVE
//
//  Created by Minh Chu on 1/13/21.
//  Copyright © 2019 Minh Chu. All rights reserved.
//

import Foundation
import UIKit

infix operator >>>: Display
precedencegroup Display {
    associativity: left
    higherThan: AssignmentPrecedence
    lowerThan: AdditionPrecedence
}

@discardableResult
public func >>> <E: AnyObject>(lhs: E, block: (E) -> Void) -> E {
    block(lhs)
    return lhs
}

@discardableResult
public func >>> <E: AnyObject>(lhs: E?, block: (E?) -> Void) -> E? {
    block(lhs)
    return lhs
}

@discardableResult
public func >>> <E, F>(lhs: E, rhs: F) -> E where E: UIView, F: UIView {
    rhs.addSubview(lhs)
    return lhs
}

@discardableResult
public func >>> <E, F>(lhs: E, rhs: F?) -> E where E: UIView, F: UIView {
    rhs?.addSubview(lhs)
    return lhs
}
