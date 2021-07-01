//
//  DTOCreator.swift
//  VeracitySDK
//
//  Created by Minh Chu on 12/8/20.
//

import UIKit

public struct DTOCreator: Codable {
    let id: String?
    let _id: String?
    let firstName: String?
    let lastName: String?
    let email: String?

    enum CodingKeys: String, CodingKey {
        case id = "id"
        case _id = "_id"
        case firstName, lastName, email
    }
}

extension DTOCreator {
    func getID() -> String? {
        return id ?? _id
    }
}
