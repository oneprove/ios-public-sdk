//
//  TakeFingerprintViewController.swift
//  Veracity Authenticator
//
//  Created by Minh Chu on 2/2/21.
//  Copyright © 2021 ONEPROVE s.r.o. All rights reserved.
//

import UIKit
import ARCameraController


protocol TakeFingerprintPresentableListener: AnyObject {
    func loadFingerprint(sourcePhoto: UIImage?, dimension: (width: Double, height: Double)?)
    func takenFingers(photos: [(blurScore: Float, image: UIImage)])
    func checkVerifyItemDimension(_ item: VeracityItem)
    func startTakeFinger()
}

public protocol TakeFingerprintViewControllerDelegate: AnyObject {
    func onTakenFingerprint(_ fingers: [(blurScore: Float, image: UIImage)])
}

public final class TakeFingerprintViewController: UIViewController, TakeFingerprintPresentable {
    
    var listener: TakeFingerprintPresentableListener?
    public weak var delegate: TakeFingerprintViewControllerDelegate?
    internal let createItemStream: MutableProtectItemStream?
    internal let verifyItemStream: MutableVerifyItemStream?
    internal var fingerInfo: (rect: CGRect, overviewPhoto: UIImage, dimension: (width: Double, height: Double))?
    
    
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var cameraContainerView: UIView!
    @IBOutlet weak var cameraModeButton: UIButton!
    @IBOutlet weak var snapPhotoButton: UIButton!
    @IBOutlet weak var flashButton: UIButton!
    internal weak var fingerprintNormalView: TakeFingerprintNormalView?
    internal weak var fingerprintARView: TakeFingerprintARView?
    internal weak var cameraOverlayView: TakeFingerprintOverlayView?
    
    public init(createItemStream: MutableProtectItemStream? = nil,
         verifyItemStream: MutableVerifyItemStream? = nil) {
        self.createItemStream = createItemStream
        self.verifyItemStream = verifyItemStream
        
        let bundle = Bundle(for: TakeFingerprintViewController.self)
        super.init(nibName: "TakeFingerprintViewController", bundle: bundle)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setupView()
        self.selfSetup()
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Loading incase verify item to wait api fetch finger info
        if verifyItemStream != nil {
            self.loading(true)
        }
        
        // Loading incase retake item to wait download overview photo
        if createItemStream?.retakeItem != nil {
            self.loading(true)
        }
        
        // Check dimension for create
        if let _ = self.createItemStream {
            self.listener?.startTakeFinger()
        }
        
        // Check dimension for verify
        if let verifyItem = verifyItemStream?.verifyItem {
            self.listener?.checkVerifyItemDimension(verifyItem)
        }
        
        // Check Camera style view
        self.setupCameraStyle()
    }
    
    public override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        self.fingerprintNormalView?.stop()
        self.fingerprintARView?.stop()
        self.cameraOverlayView?.stopCamera()
    }
    
    // MARK: -
    func onTakenFingers(photos: [(blurScore: Float, image: UIImage)]) {
        self.delegate?.onTakenFingerprint(photos)
    }
    
    private func isVerifyItemFlow() -> Bool {
        guard let _ = verifyItemStream else {
            return false
        }
        return true
    }
    
    // MARK: - AR and MAP Camera Actions
    @IBAction func snapPhotoPressed(_ sender: Any) {
        fingerprintNormalView?.takeFingerprint()
    }
    
    @IBAction func fingerprintModePressed(_ sender: Any) {
        let isNormalMode = !(cameraModeButton.isSelected)
        
        if isNormalMode {
            switchToNormalMode()
        } else {
            switchToARMode()
        }
        
        flashLightHandle()
    }
    
    @IBAction func flashLightPressed(_ sender: UIButton) {
        flashButton.isSelected = !flashButton.isSelected
        flashLightHandle()
    }
    
    @objc func moveBack() {
        self.dismiss(animated: true, completion: nil)
    }
    
    // MARK: - Setup
    private func selfSetup() {
        let interactor = TakeFingerprintInteractor(presenter: self,
                                                   createItemStream: self.createItemStream,
                                                   verifyItemStream: self.verifyItemStream)
        self.listener = interactor
    }
    
    private func setupView() {
        
        // Invisible some UI
        self.snapPhotoButton.isHidden = true
        self.cameraModeButton.isHidden = true
        self.flashButton.isHidden = true
        
        if let _ = self.navigationController {
            navigationController?.navigationBar.barTintColor = AppColor.white
            navigationItem.title = "Verify item".uppercased()
            navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "arrow-left"), style: .plain, target: self, action: #selector(moveBack))
            navigationItem.leftBarButtonItem?.tintColor = AppColor.primary
            let textAttributes = [NSAttributedString.Key.foregroundColor: AppColor.primary]
            navigationController?.navigationBar.largeTitleTextAttributes = textAttributes
            navigationController?.navigationBar.titleTextAttributes = textAttributes
        }
    }
    
    private func setupCameraStyle() {
        let type = getCameraStyle()
        if type == .overlay {
            self.containerView.isHidden = true
            let cameraOverlayView = TakeFingerprintOverlayView(createItemStream: createItemStream,
                                                               verifyItemStream: verifyItemStream)
            self.cameraOverlayView = cameraOverlayView
            cameraOverlayView.delegate = self
            cameraOverlayView >>> view >>> {
                $0.snp.makeConstraints {
                    $0.edges.equalToSuperview()
                }
            }
        }
    }
    
    private func getCameraStyle() -> TakeFingerprintType {
        let type = self.createItemStream?.takeFingerPrintType ?? self.verifyItemStream?.takeFingerPrintType ?? .default
        return type
    }
}

// MARK: - Interactor
extension TakeFingerprintViewController {
    func gotFingerprintRect(_ rect: CGRect, overviewPhoto: UIImage, dimension: (width: Double, height: Double)) {
        let type = getCameraStyle()
        guard type == .default else {
            return
        }
        
        self.fingerInfo = (rect, overviewPhoto, dimension)
        self.checkItemDimension(dimension)
    }
    
    func gotItemDimension(_ dimension: (width: Double, height: Double)) {
        self.fingerInfo?.dimension = dimension
    }
    
    private func isSmallDimension(width: Double, height: Double) -> Bool {
        return width < 4 || height < 4
    }
    
    private func checkItemDimension(_ dimension: (width: Double, height: Double)) {
        self.fingerInfo?.dimension = dimension
        let enableCameraSwitch = !isSmallDimension(width: dimension.width, height: dimension.height)
        
        if enableCameraSwitch {
            self.switchToARMode()
        } else {
            self.switchToNormalMode()
        }
        
        // check disable switch camera mode
        self.cameraModeButton.isHidden = !enableCameraSwitch

    }
    
    func loading(_ show: Bool) {
    }
}
