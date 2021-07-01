//
//  Credits.swift
//  VeracitySDK
//
//  Created by Andrew on 16/04/2019.
//  Copyright © 2019 Veracity Protocol s.r.o. All rights reserved.
//

import Foundation

public struct DTOCredits: Codable {
    public var credits : Int = 0
    public var invoiceBilling : Bool = false
    
    public var queryCredits : Int = 0 {
        didSet {
            credits = (credits - queryCredits)
        }
    }
    
    public init(credit : Int, queryCredit : Int) {
        if queryCredit > credit {
            self.credits = 0
        }else {
            self.credits = (credit - queryCredit)
        }
        self.queryCredits = queryCredit
    }
    
    enum CodingKeys: String, CodingKey {
        case credits = "credits"
        case invoiceBilling = "invoice_billing"
    }
}
