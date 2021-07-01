//
//  TakeOverviewPhotoInteractor.swift
//  Veracity Authenticator
//
//  Created by Minh Chu on 2/2/21.
//  Copyright © 2021 ONEPROVE s.r.o. All rights reserved.
//

import BlurDetector
import RealmSwift
import UIKit

protocol TakeOverviewPhotoPresentable: class {
    var listener: TakeOverviewPhotoPresentableListener? { get set }
}

final class TakeOverviewPhotoInteractor: TakeOverviewPhotoPresentableListener {
    private weak var presenter: TakeOverviewPhotoPresentable?
    private let createItemStream: MutableProtectItemStream
    
    init(presenter: TakeOverviewPhotoPresentable, createItemStream: MutableProtectItemStream) {
        self.presenter = presenter
        self.createItemStream = createItemStream
        self.presenter?.listener = self
    }
    
    func didTakeImage(_ image: UIImage) {
        createItemStream.update(overviewPhoto: image)
        createItemStream.change(step: .cropBackground)
    }
}
