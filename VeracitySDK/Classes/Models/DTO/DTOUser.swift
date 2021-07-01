//
//  DTOUser.swift
//  VeracitySDK
//
//  Created by Minh Chu on 12/3/20.
//

import UIKit

public struct DTOLogin: Codable {
    let token: String?
    let user: DTOUser?
}

// MARK: - User
public struct DTOUser: Codable {
    public var id, email, role: String?
    public var invoiceBilling: Bool?
    public var allowedVerticals = [String]()
    public var monitoringAgreement: Bool?
    public var token: String?
    public var arGuidingON: Bool?
    public var shareAnalyticON: Bool?
    public var loginDate: Date?
    public var flashlightOn: Bool?
    public var metricalUnits: Bool?
    
    enum CodingKeys: String, CodingKey {
        case id, email, role
        case token, arGuidingON, loginDate, flashlightOn, metricalUnits
        case invoiceBilling = "invoice_billing"
        case allowedVerticals, monitoringAgreement
        case shareAnalyticON
    }
}
