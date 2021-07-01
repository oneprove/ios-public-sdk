//
//  VPImageUploadOperation.swift
//  VeracitySDK
//
//  Created by Andrew on 05/11/2020.
//  Copyright © 2020 Veracity Protocol s.r.o. All rights reserved.
//

import Foundation

public protocol VPImageUploadOperation : VPOperation {
    var filename : String { get set }
    var referId: String? { get set }
    var imageUrlString : String? { get }
    var error : Error? { get }
    var lastProgressValue : Progress? { get }
    var trackingUpload: FileUploadTrack? { get set }
}

extension VPImageUploadOperation {
    public func startTrackTimeUpload() {
        guard let track = self.trackingUpload else {
            return
        }
        
        DispatchQueue.main.async {
            RealmHandler.shared.persist(updates: { [unowned track] in
                track.startTime = Int64(Date().timeIntervalSince1970)
            })
        }
    }
    
    public func endTrackTimeUpload() {
        guard let track = self.trackingUpload else {
            return
        }
        
        DispatchQueue.main.async {
            RealmHandler.shared.persist(updates: { [unowned track] in
                track.endTime = Int64(Date().timeIntervalSince1970)
            })
        }
    }
    
    public func getFileUploadTracked() -> FileUploadTrack {
        let trackFile = RealmHandler.shared.getObject(of: FileUploadTrack.self, forKey: filename) ?? createTrackFile()
        return trackFile
    }
    
    private func createTrackFile() -> FileUploadTrack {
        let file = FileUploadTrack()
        file.fileName = filename
        file.referId = referId
        return file
    }
}
