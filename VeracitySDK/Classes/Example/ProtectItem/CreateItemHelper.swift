//
//  CreateItemHelper.swift
//  Veracity Authenticator
//
//  Created by Minh Chu on 2/10/21.
//  Copyright © 2021 ONEPROVE s.r.o. All rights reserved.
//

import UIKit

struct CreateItemHelper {
    static func isSmallFingerprint(dimension: (width: Double, height: Double)?) -> Bool {
        guard let dimension = dimension else {
            return false
        }
        
        let height = dimension.height
        let width = dimension.width
        
        if width < 7.5 || height < 10 {
            return true
        }
        return false
    }
    
    
    static func dimentionToCm(_ input: (width: Double, height: Double), unit: UnitType? = .cm) -> (width: Double, height: Double) {
        var dimension = input
        if unit == .inch {
            let w = Measurement(value: dimension.width, unit: UnitLength.inches).converted(to: UnitLength.centimeters).value.rounded(toPlaces: 1)
            let h = Measurement(value: dimension.height, unit: UnitLength.inches).converted(to: UnitLength.centimeters).value.rounded(toPlaces: 1)
            dimension = (w, h)
        }
        return dimension
    }
}
