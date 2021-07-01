//
//  VeracityItem.swift
//  Veracity Authenticator
//
//  Created by Minh Chu on 1/25/21.
//  Copyright © 2021 ONEPROVE s.r.o. All rights reserved.
//

import UIKit

public protocol VeracityItem {
    var id: String { get }
    var state: ItemState? { get }
    var itemName: String? { get }
    var createdString: String? { get }
    var hourString: String? { get }
    var date: Date? { get }
    var thumbImageUrl: String? { get }
    var overlayImageUrl: String? { get }
}

extension VeracityItem {
    public var createdString: String? {
        return date?.string(withFormat: "MM/dd/yyyy")
    }
    
    public var hourString: String? {
        return date?.string(withFormat: "HH:mm")
    }
}
