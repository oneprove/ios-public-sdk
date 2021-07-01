//
//  CreateItemHeaderView.swift
//  Veracity Authenticator
//
//  Created by Minh Chu on 2/3/21.
//  Copyright © 2021 ONEPROVE s.r.o. All rights reserved.
//

import UIKit


class CreateItemHeaderView: UIView {

    @IBOutlet var contentView: UIView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var backButton: UIButton!
    
    init() {
        super.init(frame: .zero)
        self.setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.setup()
    }
    
    func setHeaderFor(step: ProtectItemStep) {
        titleLabel.text = step.name
        stackView.arrangedSubviews.forEach { $0.backgroundColor = AppColor.gray }
        stackView.arrangedSubviews[step.step-1].backgroundColor = AppColor.primary
    }
    
    private func setup() {
        let bunde = Bundle(for: CreateItemHeaderView.self)
        bunde.loadNibNamed("CreateItemHeaderView", owner:self, options:nil)
        
        addSubview(contentView)
        
        contentView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }
}
