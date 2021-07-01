//
//  VPConfigure.swift
//  VeracitySDK
//
//  Created by mbpro on 26/08/2021.
//  Copyright © 2021 Veracity Protocol s.r.o. All rights reserved.
//

import Foundation
import AVFoundation
import UIKit
    
public class VPConfigure {
    private let username: String
    private let password: String
    private var completed: ((Bool) -> Void)?
    private let parentVC: UIViewController
    
    public init(parentVC: UIViewController, username: String, password: String) {
        self.username = username
        self.password = password
        self.parentVC = parentVC
    }
    
    public func configure(completed: @escaping (Bool) -> Void) {
        self.completed = completed
        VeracitySDK.configuration.type = .demo
        UploadManager.shared.startObserving()
        self.start()
    }
    
    
    private func start() {
        checkCameraAuthorizationStatus(from: parentVC) { [weak self] (granted) in
            guard granted else { return }
            self?.login()
        }
    }

    private func login() {
        NetworkClient.login(email: username, password: password) { (success, error) in
            if success {
                self.completed?(true)
                JobResultChecker.shared.setupObserving()
            } else {
                self.completed?(false)
                UIAlertController(title: "Login failed. Please try again.").show()
            }
        }
    }
    
    private func requestCameraPermission(_ block: @escaping (Bool) -> Void) {
        AVCaptureDevice.requestAccess(for: .video, completionHandler: { accessGranted in
            DispatchQueue.main.async {
                block(accessGranted)
            }
        })
    }
    
    private func checkCameraAuthorizationStatus(from viewController: UIViewController, _ block: @escaping (Bool) -> Void) {
        let cameraAuthorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
        switch cameraAuthorizationStatus {
            case .notDetermined:
                requestCameraPermission(block)
            case .authorized:
                block(true)
            case .restricted, .denied:
                block(false)
                alertCameraAccessNeeded(from: viewController)
        default:
            break
        }
    }
    
    fileprivate func alertCameraAccessNeeded(from viewController: UIViewController) {
        let settingsAppURL = URL(string: UIApplication.openSettingsURLString)!
     
        let alert = UIAlertController(
            title: "Need Camera Access",
            message: "Camera access is required to make full use of this app.",
            preferredStyle: UIAlertController.Style.alert
        )
     
        alert.addAction(UIAlertAction(title: "Cancel", style: .default, handler: nil))
        alert.addAction(UIAlertAction(title: "Allow Camera", style: .cancel, handler: { (alert) -> Void in
            UIApplication.shared.open(settingsAppURL, options: [:], completionHandler: nil)
        }))

        viewController.present(alert, animated: true, completion: nil)
    }
}
