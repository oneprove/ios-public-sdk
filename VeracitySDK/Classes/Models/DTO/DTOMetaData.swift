//
//  DTOMetaData.swift
//  VeracitySDK
//
//  Created by Minh Chu on 12/8/20.
//

import UIKit

public struct DTOMetaData: Codable {
    let vertical: String?
    let torch: String?
    let overlayURL: String?
    let walletAddress: String?
    let blockchain: String?
    let uploadTime: Int?
    let metaUploadTime, arweaveTransactionID, fingerprintNames: String?
    let fingerprintUrls: String?

    enum CodingKeys: String, CodingKey {
        case vertical, torch
        case overlayURL = "overlay_url"
        case walletAddress, blockchain, uploadTime
        case metaUploadTime = "upload_time"
        case arweaveTransactionID = "arweaveTransactionId"
        case fingerprintNames, fingerprintUrls
    }
}

extension DTOMetaData {
    func toString() -> String? {
        return (try? toDictionary())?.convertToJSONString()
    }
}
