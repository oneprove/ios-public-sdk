//
//  TakeFingerprintViewController+Overlay.swift
//  Veracity Authenticator
//
//  Created by Minh Chu on 3/11/21.
//  Copyright © 2021 ONEPROVE s.r.o. All rights reserved.
//

import UIKit

// MARK: TakeFingerprintOverlayView Delegate
extension TakeFingerprintViewController: TakeFingerprintOverlayViewDelegate {
    func onTakenOverlayFingers(photos: [(blurScore: Float, image: UIImage)]) {
        self.onTakenFingers(photos: photos)
    }
}
