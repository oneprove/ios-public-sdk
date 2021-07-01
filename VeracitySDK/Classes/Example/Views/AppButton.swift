//
//  AppButton.swift
//  Veracity Authenticator
//
//  Created by Minh Chu on 1/14/21.
//  Copyright © 2021 ONEPROVE s.r.o. All rights reserved.
//

import UIKit


class AppButton: UIButton {
    init() {
        super.init(frame: .zero)
        self.setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.setup()
    }
    
    private func setup() {
        self.backgroundColor = AppColor.white
        self.layer.cornerRadius = AppSize.s4
        self.setTitleColor(AppColor.black, for: .normal)
        self.titleLabel?.font = Fonts.buttonFont
    }
}
