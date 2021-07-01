//
//  Date+Extension.swift
//  VeracitySDK
//
//  Created by Andrew on 16/04/2019.
//  Copyright © 2019 Veracity Protocol s.r.o. All rights reserved.
//

import Foundation

///Public extension.
public extension Date {
    ///Only the year value of date.
    var year: Int {
        let year = Calendar.current.component(Calendar.Component.year, from: self)
        return year
    }
    
    ///Yesterday date.
    var before24Hours : Date {
        return self.addingTimeInterval(-60 * 60 * 24)
    }
    
    func string(withFormat format: String = "dd/MM/yyyy HH:mm") -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = format
        return dateFormatter.string(from: self)
    }
}
