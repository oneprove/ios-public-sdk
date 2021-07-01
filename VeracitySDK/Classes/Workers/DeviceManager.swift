//
//  DeviceManager.swift
//  VeracitySDK
//
//  Created by Andrew on 13/06/2019.
//  Copyright © 2019 Veracity Protocol s.r.o. All rights reserved.
//

import Foundation
import RealmSwift
import AVFoundation.AVCaptureDevice

///Callback block, that passes `UIDeviceOrientation` object as parameter.
public typealias DeviceChangeOrientationBlock = (_ orientation : UIDeviceOrientation) -> ()

///Singelton. Hold device info, updates device info on API, handles updates of notification token and even flashlight for camera stream preview.
public class DeviceManager: NSObject {
    ///Public singleton instance of `DeviceManager`.
    public static let shared = DeviceManager()
    
    var device = Device()
    
    fileprivate var devices : Results<Device>?
    fileprivate var devicesNotificationToken : NotificationToken?
    
    fileprivate var deviceOrientationChangeCallback : DeviceChangeOrientationBlock?
    
    fileprivate var backgroundTaskID : UIBackgroundTaskIdentifier = .invalid
    
    //MARK: - Lifecycle
    override init() {
        super.init()
        devices = RealmHandler.shared.getObjects(of: Device.self)
        if let device = devices?.first {
            self.device = device
        }else {
            RealmHandler.shared.add(device, modifiedUpdate: true)
        }
        devicesNotificationToken = devices?.observe({ [weak self] (change) in
            if let device = RealmHandler.shared.getObjects(of: Device.self).first {
                self?.device = device
            }
        })
    }
    
    ///Sends an update request with currently saved device object.
    func updateDevice() {
        if !UserManager.shared.loggedUser { return }
        let device = DeviceManager.shared.device
        debugLog(device)
        beginBackgroundTask()
        
        let router = Router.updateDevice(uuid: device.uuid, model: device.model, version: device.osVersion, name: device.name, token: device.notificationToken)
        REST.request([String: AnyCodable].self, router: router) { [weak self] (data, error) in
            if let error = error {
                debugLog("Error updating device: \(error)")
            }
            self?.endBackgroundTaks()
        }
    }
    
    ///This function will set passed token parameter as new firebase token for currently saved device object and will send update request.
    ///- Parameter token: firebase Device Token
    func updateDevice(withToken token: String?) {
        let device = DeviceManager.shared.device
        if device.isInvalidated {
            let device = Device(notificationToken: token)
            self.device = device
            RealmHandler.shared.add(device, modifiedUpdate: true)
        }else {
            RealmHandler.shared.persist {
                device.notificationToken = token
            }
        }
        DeviceManager.shared.updateDevice()
    }
    
    ///Removes current device from API.
    public func removeDevice() {
        let bgTaskID = UIApplication.shared.beginBackgroundTask(expirationHandler: nil)
        let device = DeviceManager.shared.device
        
        REST.request([String: AnyCodable].self, router: .removeDevice(uuid: device.uuid)) { (data, error) in
            if let error = error {
                debugLog("Error removing device: \(error)")
            }
            DeviceManager.shared.device = Device()
            UIApplication.shared.endBackgroundTask(bgTaskID)
        }
    }
}

//MARK: - Background task
fileprivate extension DeviceManager {
    func beginBackgroundTask() {
        if backgroundTaskID != .invalid { return }
        
        backgroundTaskID = UIApplication.shared.beginBackgroundTask(expirationHandler: { [weak self] in
            self?.endBackgroundTaks()
        })
    }
    
    func endBackgroundTaks() {
        UIApplication.shared.endBackgroundTask(backgroundTaskID)
        backgroundTaskID = .invalid
    }
}

//MARK: - Flashlight Public Extension
public extension DeviceManager {
    ///Checks if current device has flasthlight / torch available to use with camera stream preview.
    /// - Returns: `Bool` value indicating if current device has flashlight available.
    func flashlightAvailable() -> Bool {
        return AVCaptureDevice.default(for: AVMediaType.video)?.hasTorch ?? false
    }
    
    /**
     Tries to turn on device's flashlight when it's off and vice versa.
     
     - Parameters:
        - turnOn: Set `true` for turning on.
        - device: `AVCaptureDevice` to use with flashlight.
        - brightness: `Float` value of max flasthlight brightnes. Can be betwen 0...1.0.
     - Returns: `Bool` indicating flashlight status after toogling.
     */
    func toggleFlashlight(turnOn : Bool? = nil, for device : AVCaptureDevice, _ brightness : Float) -> Bool {
        if (device.hasTorch) {
            do {
                let torchOn = device.isTorchActive
                guard torchOn != turnOn else { return torchOn }
                
                try device.lockForConfiguration()
                if torchOn {
                    device.torchMode = .off
                } else {
                    try device.setTorchModeOn(level: brightness)
                }
                device.unlockForConfiguration()
                return !torchOn
            } catch {
                debugLog(error.localizedDescription)
            }
        }
        return false
    }
}

//MARK: - Orientation Change Extension
extension DeviceManager {
    /**
     Starts observing for device's orientation changes. Primary used to detect landscape orientation but all orientation changes are handled back thru given callback block till the end of observing.
     
     - Parameter changesCallback: Callback block with current orientation as the only passed parameter.
     
     Callers must call to end observing (`endObservingLandscapeOrientationChanges`) manualy when it's no longer necessary to observe orientation changes.
     */
    public func startObservingLandscapeOrientationChanges(_ changesCallback : @escaping DeviceChangeOrientationBlock) {
        UIDevice.current.beginGeneratingDeviceOrientationNotifications()
        NotificationCenter.default.addObserver(self, selector: #selector(orientationChanged(notification:)), name: UIDevice.orientationDidChangeNotification, object: nil)
        deviceOrientationChangeCallback = changesCallback
    }
    
    ///Ends obseving for orientation changes if there was any.
    public func endObservingLandscapeOrientationChanges() {
        NotificationCenter.default.removeObserver(self)
        UIDevice.current.endGeneratingDeviceOrientationNotifications()
        deviceOrientationChangeCallback = nil
    }
    
    ///Private method to handle orientation changes.
    @objc fileprivate func orientationChanged(notification : NSNotification) {
        deviceOrientationChangeCallback?(UIDevice.current.orientation)
    }
}
