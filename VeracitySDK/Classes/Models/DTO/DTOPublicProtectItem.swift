//
//  DTOPublicProtectItem.swift
//  VeracitySDK
//
//  Created by Minh Chu on 12/9/20.
//

import UIKit

public struct DTOPublicProtectItem: Codable, ProjectItemProtocol {
    var author: DTOCreator?
    var id, name: String?
    var overviewURL, thumbnailURL: String?
    var width, height: Double?
    var year: Int?
    var category, publicID: String?
//    var createdBy: DTOCreator?
    var createdAt, updatedAt: String?
    var firstCreatedByRole: String?
    var firstCreatedBy: DTOCreator?
    var mediums, styles, categories: [Int]?
    var meta: DTOMetaData?
    var transferRequest: TransferRequest?
    var firstTradingCode: DTOTradingCode?
    var status: String?
    var authorizedAt: String?
    var blockchainID: Int?
    var algorithmUsed: String?
    var applicationUsed: ApplicationUsed?
    var authorized: Bool?
    var fingerprint: DTOFingerprint?
    var lastJob: DTOBatchJob?
    var error: String?

    enum CodingKeys: String, CodingKey {
        case author, id, name
        case overviewURL = "overviewUrl"
        case thumbnailURL = "thumbnailUrl"
        case width, height, year, category
        case publicID = "publicId"
//        case createdBy
        case createdAt, updatedAt, firstCreatedByRole, firstCreatedBy, mediums, styles, categories, meta, transferRequest, firstTradingCode, status
        case authorizedAt = "authorized_at"
        case blockchainID = "blockchainId"
        case algorithmUsed, applicationUsed, authorized, fingerprint, lastJob, error
    }
}

