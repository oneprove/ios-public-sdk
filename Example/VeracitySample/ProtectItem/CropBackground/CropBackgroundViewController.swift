//
//  CropBackgroundViewController.swift
//  Veracity Authenticator
//
//  Created by Minh Chu on 2/2/21.
//  Copyright © 2021 ONEPROVE s.r.o. All rights reserved.
//

import UIKit
import VeracitySDK

protocol CropBackgroundPresentableListener: class {
    func confirmCropped(_ croppedPhoto: UIImage, points: [CGPoint])
}

protocol CropBackgroundViewControllerDelegate: class {
    
}

final class CropBackgroundViewController: UIViewController, CropBackgroundPresentable {
    var listener: CropBackgroundPresentableListener?
    private let createItemStream: MutableProtectItemStream
    private var croppedPhoto: UIImage?
    private var cropPoints: [CGPoint]?
    
    var cropView: CropView?
    @IBOutlet weak var cropButton: UIButton!
    private let confirmView = CropConfirmView()
    
    init(createItemStream: MutableProtectItemStream) {
        self.createItemStream = createItemStream
        super.init(nibName: nil, bundle: nil)
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
        
        self.setupCropView()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if let overviewPhoto = createItemStream.overviewPhoto {
            self.gotOverviewPhoto(overviewPhoto)
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        self.cropView?.removeFromSuperview()
        self.cropView = nil
        self.resetCrop()
    }
    
    @IBAction func cropPressed(_ sender: Any) {
        self.crop()
    }
    
    private func crop() {
        cropView?.crop { [weak self] (image, points) in
            guard let view = self?.view else {
                return
            }
            self?.cropPoints = points
            self?.croppedPhoto = image
            self?.confirmView.show(in: view, photo: image)
        }
    }
    
    @objc func resetCrop() {
        cropPoints?.removeAll()
        croppedPhoto = nil
        cropView?.redoCrop()
        confirmView.hide()
    }
    
    @objc func confirmCropped() {
        guard let croppedPhoto = self.croppedPhoto,
              let points = self.cropPoints
        else { return }
        
        self.listener?.confirmCropped(croppedPhoto, points: points)
    }
    
    // MARK: - Setup
    private func selfSetup() {
        let interactor = CropBackgroundInteractor(presenter: self, createItemStream: createItemStream)
        self.listener = interactor
    }
    
    private func setupView() {
        cropButton.setTitle("Crop".uppercased(), for: .normal)
        cropButton.backgroundColor = AppColor.lightBlue
        cropButton.setTitleColor(AppColor.primary, for: .normal)
        confirmView.redoButton.addTarget(self, action: #selector(resetCrop), for: .touchUpInside)
        confirmView.confirmButton.addTarget(self, action: #selector(confirmCropped), for: .touchUpInside)
    }
    
    private func setupCropView() {
        let cropView = CropView(false)
        self.cropView = cropView
        self.view.addSubview(cropView)
        cropView.snp.makeConstraints {
            $0.top.trailing.leading.equalToSuperview()
            $0.height.equalTo(cropView.snp.width).multipliedBy(4.0/3.0)
        }
    }
}

// MARK: - Interactor
extension CropBackgroundViewController {
    func gotOverviewPhoto(_ photo: UIImage) {
        guard let cropView = self.cropView else {
            return
        }
        cropView.sourceImage = photo
        cropView.detectEdges()
    }
}
