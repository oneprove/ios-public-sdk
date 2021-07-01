//
//  DTOProtectItem.swift
//  VeracitySDK
//
//  Created by Minh Chu on 12/8/20.
//

import UIKit

enum AlgorithmUsed: String, Codable {
    case celery = "celery"
}

protocol ProjectItemProtocol {
    var author: DTOCreator? { get set }
    var id: String? { get set }
    var name: String? { get set }
    var thumbnailURL: String? { get set }
    var overviewURL: String? { get set }
    var height: Double? { get set }
    var width: Double? { get set }
    var year: Int? { get set }
    var publicID: String? { get set }
    var category: String? { get set }
//    var createdBy: DTOCreator? { get set }
    var updatedAt: String? { get set }
    var createdAt: String? { get set }
    var firstCreatedByRole: String? { get set }
    var firstCreatedBy: DTOCreator? { get set }
    var mediums: [Int]? { get set }
    var styles: [Int]? { get set }
    var categories: [Int]? { get set }
    var meta: DTOMetaData? { get set }
    var transferRequest: TransferRequest? { get set }
    var firstTradingCode: DTOTradingCode? { get set }
    var status: String? { get set }
    var authorizedAt: String? { get set }
    var blockchainID: Int? { get set }
    var algorithmUsed: String? { get set }
    var applicationUsed: ApplicationUsed? { get set }
    var authorized: Bool? { get set }
    var fingerprint: DTOFingerprint? { get set }
    var lastJob: DTOBatchJob? { get set }
    var error: String? { get set }
}

public struct DTOProtectItem: Codable, ProjectItemProtocol {
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

public struct ApplicationUsed: Codable {
    let id: String?
    let name: String?
    let publicID: String?

    enum CodingKeys: String, CodingKey {
        case id, name
        case publicID = "publicId"
    }
}

public struct TransferRequest: Codable {
    let id: String?
    let to: String?
    let from: String?
    let state: String?

    enum CodingKeys: String, CodingKey {
        case state
        case id = "_id"
        case to = "new_owner_email"
        case from
    }
}
