//
//  StatusView.swift
//  Veracity Authenticator
//
//  Created by Minh Chu on 2/6/21.
//  Copyright © 2021 ONEPROVE s.r.o. All rights reserved.
//

import UIKit
import SnapKit

enum StatusPosition {
    case top
    case bottom
    case center
}

class StatusView: UIView {
    @IBOutlet weak var textLabel: UILabel!
    @IBOutlet var contentView: UIView!
    
    init() {
        super.init(frame: .zero)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    func show(in parent: UIView?,
              message: String?,
              position: StatusPosition = .center) {
        
        self.alpha = 1
        self >>> parent >>> {
            $0.snp.makeConstraints {
                switch position {
                case .center:
                    $0.centerY.equalToSuperview()
                case .top:
                    $0.top.equalToSuperview().offset(AppSize.s20)
                case .bottom:
                    $0.bottom.equalToSuperview().offset(-AppSize.s20)
                }
                
                $0.leading.trailing.equalToSuperview().inset(AppSize.s20)
                $0.height.greaterThanOrEqualTo(64)
            }
        }
        
        self.textLabel.text = message
        
        // disable touch
        self.disableTouch()
        
        // auto hide
        self.autoHide()
    }
    
    @objc func hide() {
        UIView.animate(withDuration: 0.35) {
            self.alpha = 0
        } completion: { (_) in
            self.removeFromSuperview()
        }
    }
    
    private func disableTouch() {
        self.isUserInteractionEnabled = false
        self.subviews.forEach {
            $0.isUserInteractionEnabled = false
        }
    }
    
    private func autoHide() {
        Timer.scheduledTimer(timeInterval: 4, target: self, selector: #selector(hide), userInfo: nil, repeats: false)
    }
    
    private func setup() {
        let bundle = Bundle(for: StatusView.self)
        bundle.loadNibNamed("StatusView", owner: self, options: nil)
        
        addSubview(contentView)
        contentView >>> self >>> {
            $0.snp.makeConstraints {
                $0.edges.equalToSuperview()
                $0.height.greaterThanOrEqualTo(AppSize.s56)
            }
        }
    }
}
