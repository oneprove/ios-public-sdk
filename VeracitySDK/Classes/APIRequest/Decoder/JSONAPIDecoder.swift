//
//  JSONAPIDecoder.swift
//  VeracitySDK
//
//  Created by Minh Chu on 12/3/20.
//

import Foundation

public class JSONAPIDecoder: APIDecoder {
    
    /// Decode the data from JSON
    /// - Parameters:
    ///   - data: The data to decode
    ///   - type: The type to decode to
    /// - Returns: The decoded data, or nil if an error occurs
    public func decode<T>(from data: Data, as type: T.Type) -> T? where T: Decodable {
        do {
            return try JSONDecoder().decode(type, from: data)
        } catch let jsonError {
            debugLog(jsonError)
            return nil
        }
    }
    
}
