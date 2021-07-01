//
//  JSONAPIEncoder.swift
//  VeracitySDK
//
//  Created by Minh Chu on 12/3/20.
//


import Foundation

public class JSONAPIEncoder: APIEncoder {
    
    /// Encode the object to JSON
    /// - Parameters:
    ///   - object: The object to Encode
    /// - Returns: The encoded data, or nil if an error occurs
    public func encode(from object: Encodable) -> Data? {
        return object.toJSONData()
    }
    
    /// Encode the dictionary to JSON
    /// - Parameters:
    ///   - object: The object to Encode
    /// - Returns: The encoded data, or nil if an error occurs
    public func encode(from dictionary: [String: Any]) -> Data? {
        return try? JSONSerialization.data(withJSONObject: dictionary, options: .prettyPrinted)
    }
    
}
