//
//  VPVerifyItemViewController.swift
//  VeracitySDK
//
//  Created by mbpro on 26/08/2021.
//  Copyright © 2021 Veracity Protocol s.r.o. All rights reserved.
//

import Foundation

public class VPVerifyItemViewController: UIViewController, TakeFingerprintViewControllerDelegate {
    private let verifyItemStream = VerifyItemStreamImpl()
    private let item: ProtectItem
    
    public init(item: ProtectItem) {
        self.item = item
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    public func startVerifyItemProcess() {
        verifyItemStream.updateItemToVerify(item)
        goToVerificationItem()
    }
    
    private func goToVerificationItem() {
        let fingerVC = TakeFingerprintViewController(verifyItemStream: verifyItemStream)
        fingerVC.delegate = self
        let nav = UINavigationController(rootViewController: fingerVC)
        nav.modalPresentationStyle = .fullScreen
        self.present(nav, animated: true, completion: nil)
    }
    
    
    private func gotoVerifyItemDetail() {
        guard let item = verifyItemStream.localJob else {
            print("Dont have any item verify!!")
            return
        }
        
        print("Local Job: \(item)")
        let vc = VerifyItemDetailViewController(item: item, verifyItemStream: verifyItemStream)
        let nav = UINavigationController(rootViewController: vc)
        nav.modalPresentationStyle = .fullScreen
        self.present(nav, animated: true, completion: nil)
    }
    
    
    public func onTakenFingerprint(_ photos: [(blurScore: Float, image: UIImage)]) {
        self.verifyItemStream.updateFingers(photos)
        self.dismiss(animated: true) { [weak self] in
            self?.gotoVerifyItemDetail()
        }
    }
}
