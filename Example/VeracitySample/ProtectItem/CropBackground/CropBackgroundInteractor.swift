//
//  CropBackgroundInteractor.swift
//  Veracity Authenticator
//
//  Created by Minh Chu on 2/2/21.
//  Copyright © 2021 ONEPROVE s.r.o. All rights reserved.
//

import UIKit
import VeracitySDK

protocol CropBackgroundPresentable: class {
    var listener: CropBackgroundPresentableListener? { get set }
    func gotOverviewPhoto(_ photo: UIImage)
}

final class CropBackgroundInteractor: CropBackgroundPresentableListener {
    private weak var presenter: CropBackgroundPresentable?
    private let createItemStream: MutableProtectItemStream
    
    init(presenter: CropBackgroundPresentable, createItemStream: MutableProtectItemStream) {
        self.presenter = presenter
        self.createItemStream = createItemStream
        self.presenter?.listener = self
        
        self.observerOverViewPhoto()
    }
    
    private func observerOverViewPhoto() {
        self.createItemStream.observerOverPhotoCallBack { [weak self] (photo) in
            self?.presenter?.gotOverviewPhoto(photo)
        }
    }
    
    func confirmCropped(_ croppedPhoto: UIImage, points: [CGPoint]) {
        self.createItemStream.update(croppedPhoto: croppedPhoto, points: points)
        self.createItemStream.change(step: .setDimension)
    }
}
