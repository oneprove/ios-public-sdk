//
//  AppToastView.swift
//  Veracity Authenticator
//
//  Created by Minh Chu on 1/29/21.
//  Copyright © 2021 ONEPROVE s.r.o. All rights reserved.
//

import UIKit

enum ToastType {
    case success
    case error
    
    var leftIcon: UIImage? {
        switch self {
        default:
            return nil
        }
    }
    
    var rightIcon: UIImage? {
        switch self {
        default:
            return nil
        }
    }
}

enum ToastPosition {
    case top
    case bottom
}

class AppToastView: UIView {
    
    @IBOutlet var contentView: UIView!
    @IBOutlet weak var leftIcon: UIImageView!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var rightButton: UIButton!
    private var backgroundView: UIView?
    
    init() {
        super.init(frame: .zero)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    @IBAction func rightActionPressed(_ sender: Any) {
        self.hide()
    }
    
    func show(in parent: UIView? = UIApplication.shared.windows.first(where: { $0.isKeyWindow }),
              message: String,
              type: ToastType = .success,
              position: ToastPosition = .top,
              autoHiden: Bool = true,
              touchable: Bool = true) {
        
        if !touchable {
            let bgView = UIView()
            backgroundView = bgView
            bgView >>> parent >>> {
                $0.isUserInteractionEnabled = true
                $0.backgroundColor = .clear
                $0.snp.makeConstraints {
                    $0.edges.equalToSuperview()
                }
            }
        }
        
        var offset: CGFloat = 0
        var buffer: CGFloat = 0
        switch position {
        case .top:
            offset = -AppSize.s96
            self >>> parent >>> {
                $0.snp.makeConstraints {
                    $0.top.equalTo(parent!.safeAreaLayoutGuide.snp.top).offset(offset)
                    $0.leading.trailing.equalToSuperview().inset(AppSize.s20)
                    $0.height.greaterThanOrEqualTo(AppSize.s56)
                }
            }
        case .bottom:
            offset = AppSize.s96
            buffer = AppSize.s20
            self >>> parent >>> {
                $0.snp.makeConstraints {
                    $0.bottom.equalTo(parent!.safeAreaLayoutGuide.snp.bottom).offset(offset)
                    $0.leading.trailing.equalToSuperview().inset(AppSize.s20)
                    $0.height.greaterThanOrEqualTo(AppSize.s56)
                }
            }
        }
        
        self.leftIcon.isHidden = type.leftIcon == nil
        self.rightButton.isHidden = type.rightIcon == nil
        self.rightButton.setImage(type.rightIcon, for: .normal)
        self.rightButton.titleLabel?.font = AppFont.NBAkademieRegular(size: AppSize.s12).font
        self.messageLabel.text = message
        
        UIView.animate(withDuration: 0.35) {
            self.alpha = 1
            let transfrom = CGAffineTransform(translationX: 0, y: -(offset + buffer))
            self.transform = transfrom
        }
        
        if autoHiden {
            let _ = Timer.scheduledTimer(timeInterval: 5,
                                         target: self,
                                         selector: #selector(hide),
                                         userInfo: nil,
                                         repeats: false)
        }
    }
    
    @objc func hide() {
        backgroundView?.removeFromSuperview()
        UIView.animate(withDuration: 0.35) {
            let transfrom = CGAffineTransform(translationX: 0, y: 0)
            self.transform = transfrom
            self.alpha = 0
        } completion: { (_) in
            self.removeFromSuperview()
        }
    }
    
    private func setup() {
        let bundle = Bundle(for: AppToastView.self)
        bundle.loadNibNamed("AppToastView", owner: self, options: nil)
        
        addSubview(contentView)
        contentView >>> self >>> {
            $0.snp.makeConstraints {
                $0.edges.equalToSuperview()
                $0.height.greaterThanOrEqualTo(AppSize.s56)
            }
        }
        
        leftIcon.isHidden = true
        rightButton.isHidden = true
        messageLabel.text = nil
    }
}
