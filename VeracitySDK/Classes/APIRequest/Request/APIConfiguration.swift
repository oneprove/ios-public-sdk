//
//  APIConfiguration.swift
//  VeracitySDK
//
//  Created by Minh Chu on 12/3/20.
//

import Foundation

public class APIConfiguration {
    
    // Default configuration
    public static var current: APIConfiguration?
    
    // Configuration variables
    public var host: String
    public var scheme: String
    public var port: Int?
    public var headers: () -> ([String: String])
    public var encoder: APIEncoder
    public var decoder: APIDecoder
    public var completionInMainThread: Bool = true
    public var allowsCellularAccess: Bool = true
    
    /// Initialize a configuration
    /// - Parameters:
    ///   - host: The server host
    ///   - protocol: The server protocol (http/https)
    ///   - port: The server port
    public init(host: String, scheme: String = "https", port: Int? = nil, headers: @escaping () -> ([String: String]) = { return [:] }) {
        self.host = host
        self.scheme = scheme
        self.port = port
        self.headers = headers
        self.encoder = JSONAPIEncoder()
        self.decoder = JSONAPIDecoder()
    }
    
    /// Set a custom encoder for data
    /// - Parameter encoder: The custom encoder
    /// - Returns: The new APIConfiguration
    public func with(encoder: APIEncoder) -> APIConfiguration {
        self.encoder = encoder
        return self
    }
    
    /// Set a custom decoder for data
    /// - Parameter decoder: The custom decoder
    /// - Returns: The new APIConfiguration
    public func with(decoder: APIDecoder) -> APIConfiguration {
        self.decoder = decoder
        return self
    }
    
    /// Set a if the completion handle executes in the main thread or not
    /// - Parameter completionInMainThread: Boolean if enabled
    /// - Returns: The new APIConfiguration
    public func with(completionInMainThread: Bool) -> APIConfiguration {
        self.completionInMainThread = completionInMainThread
        return self
    }
    
    /// Set a if the request is allowed to user cellular data
    /// - Parameter allowsCellularAccess: Boolean if enabled
    /// - Returns: The new APIConfiguration
    public func with(allowsCellularAccess: Bool) -> APIConfiguration {
        self.allowsCellularAccess = allowsCellularAccess
        return self
    }
    
}
