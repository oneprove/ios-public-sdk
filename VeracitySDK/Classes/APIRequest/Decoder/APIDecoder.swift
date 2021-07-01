//
//  APIDecoder.swift
//  VeracitySDK
//
//  Created by Minh Chu on 12/3/20.
//


import Foundation

public protocol APIDecoder {
    
    /// Decode the input data as a T object
    /// - Parameters:
    ///   - data: The data to decode, provided by the API
    ///   - type: The type to decode to
    func decode<T>(from data: Data, as type: T.Type) -> T? where T: Decodable
    
}
