//
//  Dictionary+Extension.swift
//  VeracitySDK
//
//  Created by Andrew on 14/08/2019.
//  Copyright © 2019 Veracity Protocol s.r.o. All rights reserved.
//

import Foundation

public extension Dictionary {
    func convertToJSONString() -> String? {
        if let jsonData = try? JSONSerialization.data(withJSONObject: self, options: []), let jsonStringRepresentation = String(data: jsonData, encoding: .utf8) {
            return jsonStringRepresentation
        }
        return nil
    }
    
    func toData() -> Data? {
        return try? JSONSerialization.data(withJSONObject: self, options: [])
    }
}
