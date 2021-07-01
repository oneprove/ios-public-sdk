//
//  DateManager.swift
//  VeracitySDK
//
//  Created by Andrew on 16/04/2019.
//  Copyright © 2019 Veracity Protocol s.r.o. All rights reserved.
//

import Foundation

//Simple class that holds some date formatters.
public class DateManager {
    static let iso8601Formatter : DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()
    
    ///Default date formatter.
    public static let utcFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
        dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        return dateFormatter
    }()
    
    static let testUTCFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
        dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        return dateFormatter
    }()
    
    ///Custom short date formatter.
    public static let shortFullDateFormatter : DateFormatter = {
        let formatter = DateFormatter()
        if Locale.current.identifier == "en" {
            formatter.dateStyle = .short
            formatter.timeStyle = .none
        }else {
            formatter.dateFormat = "d'.' M'.' yyyy"
        }
        formatter.timeZone = TimeZone.current
        formatter.locale = Locale.current
        return formatter
    }()
    
    ///Covers dates from Job & ProtectItem.
    static func dateFrom(_ timestamp : String?) -> Date? {
        if let timestamp = timestamp {
            return utcFormatter.date(from: timestamp) ?? testUTCFormatter.date(from: timestamp) ?? iso8601Formatter.date(from: timestamp) ?? ISO8601DateFormatter().date(from: timestamp)
        }
        return nil
    }
}
