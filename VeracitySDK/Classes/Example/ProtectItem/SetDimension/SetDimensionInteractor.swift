//
//  SetDimensionInteractor.swift
//  Veracity Authenticator
//
//  Created by Minh Chu on 2/2/21.
//  Copyright © 2021 ONEPROVE s.r.o. All rights reserved.
//

import UIKit

protocol SetDimensionPresentable: class {
    var listener: SetDimensionPresentableListener? { get set }
    func gotCropPhoto(_ photo: UIImage)
}

final class SetDimensionInteractor: SetDimensionPresentableListener {
    private weak var presenter: SetDimensionPresentable?
    private let createItemStream: MutableProtectItemStream
    
    init(presenter: SetDimensionPresentable, createItemStream: MutableProtectItemStream) {
        self.presenter = presenter
        self.createItemStream = createItemStream
        self.presenter?.listener = self
        self.observerCropPhoto()
    }
    
    private func observerCropPhoto() {
        self.createItemStream.observerCroppedPhotoCallBack { [weak self] (photo) in
            self?.presenter?.gotCropPhoto(photo)
        }
    }
    
    func confirmedDimension(width: String, height: String, name: String?) {
        guard let w = width.doubleValue,
              let h = height.doubleValue,
              let name = name
        else { return }
        
        createItemStream.update(dimension: (w, h))
        createItemStream.update(itemName: name)
        createItemStream.change(step: .takeFingerprintPhotos)
    }
}
