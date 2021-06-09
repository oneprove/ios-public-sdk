//
//  CropConfirmView.swift
//  Veracity Authenticator
//
//  Created by Minh Chu on 2/6/21.
//  Copyright © 2021 ONEPROVE s.r.o. All rights reserved.
//

import UIKit
import VeracitySDK

class CropConfirmView: UIView {

    @IBOutlet var contentView: UIView!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var confirmButton: AppButton!
    @IBOutlet weak var redoButton: UIButton!
    @IBOutlet weak var cropImageView: UIImageView!
    
    init() {
        super.init(frame: .zero)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    func show(in parent: UIView, photo: UIImage) {
        self.alpha = 1
        self >>> parent >>> {
            $0.snp.makeConstraints {
                $0.edges.equalToSuperview()
            }
        }
        
        cropImageView.image = photo
        showMessageLabel()
    }
    
    func hide() {
        UIView.animate(withDuration: 0.35) {
            self.alpha = 0
        } completion: { (_) in
            self.removeFromSuperview()
        }
    }
    
    private func showMessageLabel() {
        messageLabel.text = "Please confirm you can clearly see the entire item without any borders."
    }
    
    private func setup() {
        Bundle.main.loadNibNamed("CropConfirmView", owner: self, options: nil)
        addSubview(contentView)
        contentView >>> self >>> {
            $0.snp.makeConstraints {
                $0.edges.equalToSuperview()
                $0.height.greaterThanOrEqualTo(AppSize.s56)
            }
        }
        
        redoButton.setTitleUnderline("Redo", for: .normal)
        redoButton.setTitleColor(AppColor.darkGreen, for: .normal)
        confirmButton.setTitle("Confirm".uppercased(), for: .normal)
        confirmButton.backgroundColor = AppColor.lightBlue
    }
}
