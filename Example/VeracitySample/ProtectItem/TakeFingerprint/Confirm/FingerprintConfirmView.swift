//
//  NormalConfirmView.swift
//  Veracity Authenticator
//
//  Created by Minh Chu on 2/10/21.
//  Copyright © 2021 ONEPROVE s.r.o. All rights reserved.
//

import UIKit
import BlurDetector
import VeracitySDK

protocol FingerprintConfirmViewDelegate: class {
    func retakeFinger()
    func confirmedFingerprintPhoto(_ photo: UIImage, blurScore: Double)
}

class FingerprintConfirmView: UIView {
    @IBOutlet var contentView: UIView!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var cropImageView: UIImageView!
    @IBOutlet weak var confirmButton: AppButton!
    @IBOutlet weak var redoButton: UIButton!
    public weak var delegate: FingerprintConfirmViewDelegate?
    private var createItemStream: MutableProtectItemStream?
    public var blurScore : Double?
    
    init() {
        super.init(frame: .zero)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    public func setCreateItemStream(_ stream: MutableProtectItemStream?) {
        self.createItemStream = stream
    }
    
    func show(in parent: UIView, photo: UIImage) {
        self.alpha = 0
        parent.addSubview(self)
        self.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        
        cropImageView.image = photo
        setMesasageLabel()
        show()
        
        runBlurDetector(sourceImage: photo)
    }
    
    private func show() {
        UIView.animate(withDuration: 0.35) {
            self.alpha = 1
        }
    }
    
    @objc func hide() {
        self.blurScore = nil
        UIView.animate(withDuration: 0.35) {
            self.alpha = 0
        } completion: { (_) in
            self.removeFromSuperview()
        }
    }
    
    private func setMesasageLabel() {
        messageLabel.text = "If the photo is not sharp, please go back and retake it"
    }
    
    private func showAlert(_ message: String) {
        guard let vc = self.parentViewController else {
            return
        }
        
        let alert = UIAlertController(
            title: message,
            message: "",
            preferredStyle: UIAlertController.Style.alert
        )
     
        alert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: { [weak self] (alert) -> Void in
            self?.gobackPressed(nil)
        }))

        vc.present(alert, animated: true, completion: nil)
    }
    
    private func isSmallFingerprint() -> Bool {
        return ProtectItemHelper.isSmallFingerprint(dimension: createItemStream?.dimension)
    }
    
    private func runBlurDetector(sourceImage: UIImage) {
        Indicator.shared.showActivityIndicator()
        let maskFactor = isSmallFingerprint() ? 1 : BlurDetector.defaultMaskFactor
        BlurDetector.evaluate(image: sourceImage, maskFactor: maskFactor) { [weak self] (score, _) in
            DispatchQueue.main.async {
                Indicator.shared.hideActivityIndicator()
                self?.handleBlurDetectResult(score)
            }
        }
    }
    
    private func handleBlurDetectResult(_ blurScore: Double) {
        self.blurScore = blurScore
        if blurScore > Constants.blurDetectScoreLimit {
            let message = "\( "Please retake the photo".uppercased())\n\n\("The photo you took is blurry and would not allow our system to work responsibly.")"
            self.showAlert(message)
            
            // disable continue button when blur is too large
            self.confirmButton.isEnabled = false
        } else {
            self.confirmButton.isEnabled = true
        }
    }
    
    @IBAction func gobackPressed(_ sender: Any?) {
        self.delegate?.retakeFinger()
        self.hide()
    }
    
    @IBAction func continuePressed(_ sender: Any) {
        guard let photo = cropImageView.image, let blurScore = self.blurScore else {
            return
        }
        self.delegate?.confirmedFingerprintPhoto(photo, blurScore: blurScore)
        self.hide()
    }
    
    private func setup() {
        Bundle.main.loadNibNamed("FingerprintConfirmView", owner: self, options: nil)
        addSubview(contentView)
        contentView >>> self >>> {
            $0.snp.makeConstraints {
                $0.edges.equalToSuperview()
                $0.height.greaterThanOrEqualTo(AppSize.s56)
            }
        }
        
        redoButton.setTitleUnderline("Back", for: .normal)
        redoButton.setTitleColor(AppColor.darkGreen, for: .normal)
        confirmButton.setTitle("Continue".uppercased(), for: .normal)
        confirmButton.backgroundColor = AppColor.lightBlue
    }

}
