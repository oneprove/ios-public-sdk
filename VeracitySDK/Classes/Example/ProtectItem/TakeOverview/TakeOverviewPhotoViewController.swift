//
//  TakeOverviewPhotoViewController.swift
//  Veracity Authenticator
//
//  Created by Minh Chu on 2/2/21.
//  Copyright © 2021 ONEPROVE s.r.o. All rights reserved.
//

import UIKit


protocol TakeOverviewPhotoPresentableListener: AnyObject {
    func didTakeImage(_ image: UIImage)
}

protocol TakeOverviewPhotoViewControllerDelegate: AnyObject {
    
}

final class TakeOverviewPhotoViewController: UIViewController, TakeOverviewPhotoPresentable {
    var listener: TakeOverviewPhotoPresentableListener?
    private let createItemStream: MutableProtectItemStream
    
    @IBOutlet weak var cameraStreamPreview: CameraStreamPreview!
    @IBOutlet weak var flashCoverView: UIView!
    @IBOutlet weak var snapPhotoButton: UIButton!
    
    init(createItemStream: MutableProtectItemStream) {
        self.createItemStream = createItemStream
        
        let bundle = Bundle(for: TakeOverviewPhotoViewController.self)
        super.init(nibName: "TakeOverviewPhotoViewController", bundle: bundle)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setupView()
        self.selfSetup()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        activeCamera()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        setupCameraOverlay()
    }
    
    private func activeCamera() {
        guard !cameraStreamPreview.isSessionRunning() else {
            return
        }
        
        cameraStreamPreview.activateSession()
    }
    
    private func setupCameraOverlay() {
        let width = cameraStreamPreview.bounds.width / 3.0
        let height = width * 2.2
        cameraStreamPreview.setupOverlay(CGSize(width: width, height: height),
                                         lineColor: AppColor.lightGreen1,
                                         lineWidth: 6)
    }
    
    // MARK: - IBActions
    @IBAction func takeOverview(_ sender: UIButton) {
        cameraStreamPreview.takePhoto()
    }
    
    // MARK: - Setup
    private func selfSetup() {
        let interactor = TakeOverviewPhotoInteractor(presenter: self, createItemStream: self.createItemStream)
        self.listener = interactor
    }
    
    private func setupView() {
        cameraStreamPreview.delegate = self
        activeCamera()
    }
}

// MARK: - Camera Stream Delegate
extension TakeOverviewPhotoViewController: CameraStreamDelegate {
    func didTakeImage(_ image: UIImage) {
        self.listener?.didTakeImage(image)
    }
    
    func didFailedToTakeImage(_ error: Error) {
        debugLog(error.localizedDescription)
    }
}
