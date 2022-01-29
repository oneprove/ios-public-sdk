//
//  APIRequest.swift
//  VeracitySDK
//
//  Created by Minh Chu on 12/3/20.
//

import Foundation

public class APIRequest: NSObject, URLSessionDelegate, URLSessionTaskDelegate {
    
    /// Completion handler of an APIRequest
    /// - Parameters:
    ///   - data: The decoded data from API
    ///   - status: The status of the request
    public typealias CompletionHandler<T> = (_ data: T?, _ error: DTOError?, _ status: APIResponseStatus) -> () where T: Decodable
    
    /// Upload progress handler of an APIRequest
    /// - Parameters:
    ///   - progress: The current upload progress, between 0 and 1
    public typealias UploadProgress = (_ progress: Progress) -> ()
    
    // Object properties
    private var method: String
    private var path: String
    private var configuration: APIConfiguration
    private var headers: [String: String]
    private var queryItems: [URLQueryItem]
    private var body: Data?
    private var uploadProgress: UploadProgress?
    private var customUrl: URL?
    
    /// Create a request to the API
    /// - Parameters:
    ///   - method: The request method (GET, POST, PUT, DELETE, ...)
    ///   - path: The path to the api. Always starts with a /
    ///   - configuration: The configuration of the API. Use the default one if not specified
    public init(_ method: String, path: String = "", customUrl: URL? = nil, configuration: APIConfiguration? = APIConfiguration.current) {
        // Check that a configuration is specified
        guard let configuration = configuration else {
            // Throw an error
            fatalError("APIConfiguration is nil! Try to set APIConfiguration.current at launch.")
        }
        
        // Get request parameters
        self.method = method
        self.path = path
        self.configuration = configuration
        self.queryItems = []
        self.headers = [:]
        self.customUrl = customUrl
    }
    
    /// Add a get parameter
    /// - Parameters:
    ///   - name: The name of the variable
    /// - Returns: The modified APIRequest
    public func with(name: String) -> APIRequest {
        queryItems.append(URLQueryItem(name: name, value: nil))
        return self
    }
    
    /// Add a get parameter
    /// - Parameters:
    ///   - name: The name of the variable
    ///   - value: The value of the variable
    /// - Returns: The modified APIRequest
    public func with<S>(name: String, value: S) -> APIRequest where S: LosslessStringConvertible {
        queryItems.append(URLQueryItem(name: name, value: String(value)))
        return self
    }
    
    /// Add a header to the request
    /// - Parameters:
    ///   - header: The name of the header
    ///   - value: The value of the header
    /// - Returns: The modified APIRequest
    public func with<S>(header: String, value: S) -> APIRequest where S: LosslessStringConvertible {
        headers[header] = String(value)
        return self
    }
    
    /// Add a body to the request (for POST or PUT requests)
    /// - Parameters:
    ///   - body: The body of the request
    /// - Returns: The modified APIRequest
    public func with(body: Data?) -> APIRequest {
        self.body = body
        return self
    }
    
    /// Add a body to the request (for POST or PUT requests)
    /// - Parameters:
    ///   - body: The body of the request
    /// - Returns: The modified APIRequest
    public func with(body: Encodable) -> APIRequest {
        self.body = configuration.encoder.encode(from: body)
        return self
    }
    
    /// Add a body to the request (for POST or PUT requests)
    /// - Parameters:
    ///   - body: The body of the request
    /// - Returns: The modified APIRequest
    public func with(body: [String: Any]) -> APIRequest {
        self.body = configuration.encoder.encode(from: body)
        return self
    }
    
    public func with(body: Data) -> APIRequest {
        self.body = body
        return self
    }
    
    /// Set a progress handler for upload
    /// - Parameter uploadProgress: The progress handler
    /// - Returns: The modified APIRequest
    public func with(uploadProgress: @escaping UploadProgress) -> APIRequest {
        self.uploadProgress = uploadProgress
        return self
    }
    
    // Construct URL
    private func getURL() -> URL? {
        guard let customUrl = self.customUrl else {
            var components = URLComponents()
            components.scheme = configuration.scheme
            components.port = configuration.port
            components.host = configuration.host
            components.path = path
            
            if !queryItems.isEmpty {
                components.queryItems = queryItems
            }
            
            return components.url
        }
        
        return customUrl
    }
    
    /// Execute the APIRequest asynchronously
    /// - Parameters:
    ///   - type: The type to decode the received data
    ///   - completionHandler: The completion handler of the request
    public func execute<T>(_ type: T.Type, completionHandler: @escaping CompletionHandler<T>) where T: Decodable {
        // Check url validity
        if let url = getURL() {
            // Create the request based on give parameters
            var request = URLRequest(url: url)
            request.cachePolicy = URLRequest.CachePolicy.reloadIgnoringLocalCacheData
            request.httpMethod = method
            request.allowsCellularAccess = configuration.allowsCellularAccess
            
            // Get headers from configuration
            for (key, value) in configuration.headers() {
                request.addValue(value, forHTTPHeaderField: key)
            }
            
            // Get headers from request
            for (key, value) in headers {
                request.addValue(value, forHTTPHeaderField: key)
            }
            
            // Set body
            if let body = body {
                request.httpBody = body
            }
            
            // Create the session
            let session = URLSession(configuration: URLSessionConfiguration.default, delegate: self, delegateQueue: OperationQueue.main)
            
            
            debugLog("""
                ==============================================================
                [API] REQUEST
                - Path: \(url)
                - Method: \(method)
                - Body: \((try? JSONSerialization.jsonObject(with: body ?? Data(), options: []) ?? [:]))
                ==============================================================
                """)
            
            // Launch the request to server
            session.dataTask(with: request) { data, response, error in
                // Check if there is an error
                if let error = error {
                    self.end(data: nil, error: nil, status: .error, completionHandler: completionHandler)
                    return
                }
                
                // Get data and response
                if let data = data, let response = response as? HTTPURLResponse {
                    debugLog("""
                        [API] RESPONSE
                        - Request Url: \(response.url?.absoluteString ?? "")
                        - Status: \(response.statusCode)
                        - Data: \((try? JSONSerialization.jsonObject(with: data, options: []) ?? [:]))
                        ==============================================================
                        """)
                    
                    
                    // Decode the data with the specified decoder
                    if response.statusCode / 100 == APIResponseStatus.ok.rawValue / 100 {
                        let model = self.configuration.decoder.decode(from: data, as: type)
                        self.end(data: model, error: nil, status: APIResponseStatus.status(forCode: response.statusCode), completionHandler: completionHandler)
                    }
                    else {
                        let error = self.configuration.decoder.decode(from: data, as: DTOError.self)
                        self.end(data: nil, error: error, status: APIResponseStatus.status(forCode: response.statusCode), completionHandler: completionHandler)
                    }
                    
                } else {
                    // We consider we don't have a valid response
                    self.end(data: nil, error: nil, status: .offline, completionHandler: completionHandler)
                }
            }.resume()
        } else {
            // URL is not valid
            self.end(data: nil, error: nil, status: .error, completionHandler: completionHandler)
        }
    }
    
    // End the request and call completion handler
    private func end<T>(data: T?, error: DTOError?, status: APIResponseStatus, completionHandler: @escaping CompletionHandler<T>) where T: Decodable {
        if configuration.completionInMainThread {
            // Call main thread
            DispatchQueue.main.async {
                // And complete
                completionHandler(data, error, status)
            }
        } else {
            // Just complete
            completionHandler(data, error, status)
        }
    }
    
    /// Update the upload state for the request
    /// - Parameters:
    ///   - session: The session
    ///   - task: The task
    ///   - bytesSent: The bytes sent
    ///   - totalBytesSent: The total bytes sent
    ///   - totalBytesExpectedToSend: The total bytes expected to send
    public func urlSession(_ session: URLSession, task: URLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
        let progress = Progress()
        progress.totalUnitCount = totalBytesExpectedToSend
        progress.completedUnitCount = totalBytesSent
        // Call the upload progress (if specified)
        uploadProgress?(progress)
    }
    
    private func requestLog() {

    }
}
