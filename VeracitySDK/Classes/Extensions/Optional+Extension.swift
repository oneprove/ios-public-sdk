//
//  Optional+Extension.swift
//  ONEPROVE
//
//  Created by Minh Chu on 11/11/20.
//  Copyright © 2020 ONEPROVE s.r.o. All rights reserved.
//

import Foundation

public protocol OptionalProtocol {
    associatedtype Wrapped
    var optionalValue: Wrapped? { get }
}

extension Swift.Optional: OptionalProtocol {
    public var optionalValue: Wrapped? {
        return self
    }
    
    /// Cast instead of `??` operator, make the code cleaner.
    ///
    /// - Parameter default: value default if nil
    /// - Returns: value not optional
    public func orNil(default: @autoclosure () -> Wrapped) -> Wrapped {
        if case .some(let value) = self {
            return value
        }
        return `default`()
    }
    
}
