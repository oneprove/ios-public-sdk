//
//  DTOFingerprint.swift
//  VeracitySDK
//
//  Created by Minh Chu on 12/8/20.
//

import UIKit

public struct DTOFingerprint: Codable {
    let location: DTOFingerprintLocation?
    let identifier: String?
    let name: String?
    let image1Url: String?
    let image2Url: String?
    let fingerprintHash: String?
    
    enum CodingKeys: String, CodingKey {
        case identifier = "_id"
        case name
        case image1Url = "image1"
        case image2Url = "image2"
        case location = "location"
        case fingerprintHash = "hash"
    }
}
