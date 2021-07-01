//
//  Encodable.swift
//  VeracitySDK
//
//  Created by Minh Chu on 12/3/20.
//

import Foundation

public extension Encodable {
    
    func toJSONData() -> Data? { try? JSONEncoder().encode(self) }
    
    func toDictionary() throws -> [String: Any] {
        let data = try JSONEncoder().encode(self)
        guard let dictionary = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any] else {
          throw NSError()
        }
        return dictionary
    }
}
