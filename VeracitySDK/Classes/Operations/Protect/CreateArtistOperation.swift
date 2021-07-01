//
//  CreateArtistOperation.swift
//  VeracitySDK
//
//  Created by Andrew on 24/05/2019.
//

import Foundation

class CreateArtistOperation: VPOperation {
    var artistFirstName : String
    var artistLastName : String
    var createdArtist : Creator?
    var error : Error?
    
    init(artistFirstName : String, artistLastName : String) {
        self.artistFirstName = artistFirstName
        self.artistLastName = artistLastName
        super.init()
    }
    
    override func main() {
        guard isCancelled == false else {
            finish(true)
            return
        }
        
        executing(true)
        debugLog("start")
        NetworkClient.createArtist(artistFirstName, lastName: artistLastName) { [weak self] (artist, error) in
            debugLog("finish")
            self?.createdArtist = artist
            self?.error = error
            self?.progressCallback?(Progress(totalUnitCount: 1000), false, true)
            if let finishingBlock = self?.finishingBlock {
                finishingBlock()
            }else {
                self?.endOperation()
            }
        }
    }
}
