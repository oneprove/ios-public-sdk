//
//  ConnectionManager.swift
//  VeracitySDK
//
//  Created by Andrew on 24/05/2019.
//

import Foundation
import CoreTelephony
import Network

///Callback block that passes `Bool` value as parameter, when connection seems to be active.
public typealias ReachabilityChangeBlock = (_ reachable : Bool) -> ()

///Singelton. Handles network reachability changes so `shared` always has actual state.
public class ConnectionManager {
    ///Public singleton instance of `ConnectionManager`.
    public static let shared = ConnectionManager()
    
    fileprivate let reachability = NWPathMonitor()
    
    ///Reachability change callback, that's get called every reachability change.
    public var reachabilityChangeCallback : ReachabilityChangeBlock?
    
    //MARK: - LifeCycle
    private init() {
    }
    
    deinit {
        stopObserver()
    }
    
    //MARK: - Observe Changes
    ///Starts network reachability change observing. Called internaly by `UploaderManager`.
    public func startObservingChanges() {
        reachability.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                if path.status == .satisfied {
                    debugLog("isOnGoodConnection")
                    UploadManager.shared.tryToStartUpload()
                    DeviceManager.shared.updateDevice()
                    self?.reachabilityChangeCallback?(true)
                } else {
                    print("No connection.")
                    self?.reachabilityChangeCallback?(false)
                }

                print(path.isExpensive)
            }
        }
        
        let queue = DispatchQueue(label: "Monitor")
        reachability.start(queue: queue)
    }
    
    public func stopObserver() {
        
    }
    
    //MARK: - Reachability
    /// - Returns: `true` if internet connection is active othetwise `false`.
    public func isConnected() -> Bool {
        if reachability.currentPath.status != .satisfied {
            debugLog("isConnected false")
            return false
        }
        debugLog("isConnected true")
        return true
    }
    
    ///Checks current connection type and simply determines if it's fast connection. Wifi, 3G and above is determined as fast connection and Edge and bellow is determined as slow connection.
    /// - Returns: `true` if there should be good connection.
    public func isOnGoodConnection() -> Bool {
        if isConnected() {
            debugLog("isOnGoodConnection true")
            return true
        }
        
        //⚠️
        if let currentTechnology = CTTelephonyNetworkInfo().currentRadioAccessTechnology {
            if currentTechnology == CTRadioAccessTechnologyCDMA1x ||
                currentTechnology == CTRadioAccessTechnologyGPRS ||
                currentTechnology == CTRadioAccessTechnologyEdge {
                debugLog("isOnGoodConnection false")
                return false
            }else {
                debugLog("isOnGoodConnection true")
                return true
            }
        }
        debugLog("isOnGoodConnection false")
        return false
    }
}
