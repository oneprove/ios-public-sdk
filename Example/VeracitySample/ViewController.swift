//
//  ViewController.swift
//  VeracitySample
//
//  Created by Tony on 5/24/21.
//

import UIKit
import AVFoundation
import VeracitySDK

class ViewController: UIViewController {
    @IBOutlet weak var startButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        VeracitySDK.configuration.type = .demo
        ConnectionManager.shared.startObservingChanges()
        self.requestCameraPermission { (_) in }
    }
    
    @IBAction func startPressed(_ sender: Any) {
        guard ConnectionManager.shared.isConnected() else {
            UIAlertController(title: "You are offline. Please connect to the internet and try again.").show()
            return
        }
        
        checkCameraAuthorizationStatus(from: self) { [weak self] (granted) in
            guard granted else { return }
            self?.login()
        }
    }
    
    private func login() {
        // TODO: replace your email and pass
        var yourEmail: String? = "minh@veracityprotocol.org"
        var yourPassword: String? = "testing"
        guard let email = yourEmail, let password = yourPassword else {
            UIAlertController(title: "Replay your email and password to start").show()
            return
        }
        
        Indicator.shared.showActivityIndicator()
        NetworkClient.login(email: email, password: password) { [weak self] (success, error) in
            Indicator.shared.hideActivityIndicator()
            if success {
                self?.moveToProtectItem()
                JobResultChecker.shared.setupObserving()
            } else {
                UIAlertController(title: "Login failed. Please try again.").show()
            }
        }
    }
    
    private func moveToProtectItem() {
        let vc = ProtectItemViewController(delegate: self)
        vc.modalPresentationStyle = .fullScreen
        self.present(vc, animated: true, completion: nil)
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

extension ViewController: ProtectItemViewControllerDelegate, ProtectItemDetailViewControllerDelegate {
    func completedPrepareItemData(item: VeracityItem) {
        self.dismiss(animated: true) {
            self.gotoItemDetail(item)
        }
    }
    
    func startProtectNewItem() {
        self.dismiss(animated: true) {
            self.moveToProtectItem()
        }
    }
    
    private func gotoItemDetail(_ item: VeracityItem) {
        let vc = ProtectItemDetailViewController(item: item, verifyItemStream: VerifyItemStreamImpl())
        vc.delegate = self
        let nav = UINavigationController(rootViewController: vc)
        nav.modalPresentationStyle = .fullScreen
        self.present(nav, animated: true, completion: nil)
    }
}
