//
//  VPProtectItemViewController.swift
//  VeracitySDK
//
//  Created by mbpro on 25/08/2021.
//

import Foundation
import UIKit
import AVFoundation

public class VPProtectItemViewController: UIViewController {
    public override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    public func startProtectItemProcess() {
        let vc = ProtectItemViewController()
        vc.modalPresentationStyle = .fullScreen
        vc.delegate = self
        self.present(vc, animated: true, completion: nil)
    }
}

extension VPProtectItemViewController: ProtectItemViewControllerDelegate, ProtectItemDetailViewControllerDelegate {
    func completedPrepareItemData(item: VeracityItem) {
        self.dismiss(animated: true) {
            self.gotoItemDetail(item)
        }
    }
    
    func startProtectNewItem() {
        self.dismiss(animated: true) {
            self.startProtectItemProcess()
        }
    }
    
    private func gotoItemDetail(_ item: VeracityItem) {
        let vc = ProtectItemDetailViewController(item: item, verifyItemStream: VerifyItemStreamImpl())
        vc.delegate = self
        let nav = UINavigationController(rootViewController: vc)
        nav.modalPresentationStyle = .fullScreen
        self.present(nav, animated: true, completion: nil)
    }
}

