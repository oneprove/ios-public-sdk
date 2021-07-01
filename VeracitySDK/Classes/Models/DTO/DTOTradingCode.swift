//
//  DTOTradingCode.swift
//  VeracitySDK
//
//  Created by Minh Chu on 12/8/20.
//

import UIKit

public struct DTOTradingCode: Codable {
    let code: String?
    let expiration: Int?
    let id, artwork: String?
    let user: String?
    let createdAt, updatedAt: String?
    let v: Int?

    enum CodingKeys: String, CodingKey {
        case code, expiration
        case id = "_id"
        case artwork, user, createdAt, updatedAt
        case v = "__v"
    }
}
