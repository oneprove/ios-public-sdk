//
//  TakePhotoViewController.swift
//  Veracity Authenticator
//
//  Created by Minh Chu on 2/2/21.
//  Copyright © 2021 ONEPROVE s.r.o. All rights reserved.
//

import UIKit
import BlurDetector

protocol TakePhotoViewControllerDelegate: AnyObject {
    func didTakeImage(_ image: UIImage)
}

final class TakePhotoViewController: UIViewController {
    weak var delegate: TakePhotoViewControllerDelegate?
    
    @IBOutlet weak var cameraStreamPreview: CameraView!
    @IBOutlet weak var flashCoverView: UIView!
    @IBOutlet weak var snapPhotoButton: UIButton!
    @IBOutlet weak var indicator: UIActivityIndicatorView!
    
    public let blurDetectScoreLimit : Double = 0.5
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setupView()
        self.hideActivityIndicator()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        activeCamera()
    }
    
    private func activeCamera() {
        guard !cameraStreamPreview.isSessionRunning() else {
            return
        }
        
        cameraStreamPreview.activateSession()
    }
    
    private func runBlurDetector(sourceImage: UIImage) {
        showActivityIndicator()
        let maskFactor = BlurDetector.defaultMaskFactor
        BlurDetector.evaluate(image: sourceImage, maskFactor: maskFactor) { [weak self] (score, _) in
            DispatchQueue.main.async {
                self?.hideActivityIndicator()
                self?.handleBlurDetectResult(score, sourceImg: sourceImage)
            }
        }
    }
    
    private func handleBlurDetectResult(_ blurScore: Double, sourceImg: UIImage) {
        if blurScore > blurDetectScoreLimit {
            let message = "\( "Please retake the photo".uppercased())\n\n\("The photo you took is blurry and would not allow our system to work responsibly.")"
            self.showAlert(message)
            
        } else {
            self.delegate?.didTakeImage(sourceImg)
        }
    }
    
    private func showAlert(_ message: String) {
        let vc = self
        let alert = UIAlertController(
            title: message,
            message: "",
            preferredStyle: UIAlertController.Style.alert
        )
        alert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: { [weak self] _ in
            self?.cameraStreamPreview.activateSession()
        }))
        vc.present(alert, animated: true, completion: nil)
    }
    
    private func showActivityIndicator() {
        indicator.isHidden = false
        indicator.startAnimating()
    }
    
    private func hideActivityIndicator() {
        indicator.isHidden = true
        indicator.stopAnimating()
    }
    
    // MARK: - IBActions
    @IBAction func takeOverview(_ sender: UIButton) {
        cameraStreamPreview.takePhoto()
    }
    
    // MARK: - Setup
    private func setupView() {
        cameraStreamPreview.delegate = self
        activeCamera()
    }
}

// MARK: - Camera Stream Delegate
extension TakePhotoViewController: CameraViewDelegate {
    func didTakeImage(_ image: UIImage) {
        self.runBlurDetector(sourceImage: image)
    }
    
    func didFailedToTakeImage(_ error: Error) {
        print(error.localizedDescription)
    }
}
