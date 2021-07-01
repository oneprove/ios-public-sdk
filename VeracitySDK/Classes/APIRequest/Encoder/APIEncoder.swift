//
//  APIEncoder.swift
//  VeracitySDK
//
//  Created by Minh Chu on 12/3/20.
//

import Foundation

public protocol APIEncoder {
    
    /// Encode the input object as data
    /// - Parameter object: The object to encode, provided by the request
    func encode(from object: Encodable) -> Data?
    
    /// Encode the input object as data
    /// - Parameter object: The object to encode, provided by the request
    func encode(from dictionary: [String: Any]) -> Data?
    
}
