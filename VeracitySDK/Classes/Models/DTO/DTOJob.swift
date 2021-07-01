//
//  DTOJob.swift
//  VeracitySDK
//
//  Created by Minh Chu on 12/8/20.
//

import UIKit

public struct DTOJob: Codable {
    let id: String?
    let userID: String?
    let jobName: String?
    let artwork: DTOProtectItem?
    let searchQueryImageUrl: String?
    let searchQueryImageUrlThumbnail: String?
    let error: String?
    let completed: Bool?
    let createdAt: String?
    let tradingCode: DTOTradingCode?
    let blockchainVerified: Bool?
    let searchResults: [String]?
    
    enum CodingKeys: String, CodingKey {
        case id = "job"
        case userID = "user"
        case jobName = "jobName"
        case artwork = "artwork"
        case searchQueryImageUrl = "searchQueryImageUrl"
        case searchQueryImageUrlThumbnail = "searchQueryImageUrlThumbnail"
        case error = "error"
        case completed = "completed"
        case createdAt = "createdAt"
        case tradingCode = "tradingCode"
        case searchResults = "searchArtworkResult"
        case blockchainVerified = "blockchainVerified"
    }
}

extension DTOJob {
    var artworkID: String? {
        return artwork?.id
    }
}
