//
//  Double+Extension.swift
//  ONEPROVE
//
//  Created by Andrew on 04/07/2019.
//  Copyright © 2019 ONEPROVE s.r.o. All rights reserved.
//

import Foundation

extension Double {
    ///Rounds the double to decimal places value.
    public func rounded(toPlaces places : Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
}
