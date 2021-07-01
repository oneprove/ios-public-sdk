//
//  VPError.swift
//  VeracitySDK
//
//  Created by Andrew on 16/04/2019.
//  Copyright © 2019 Veracity Protocol s.r.o. All rights reserved.
//

import Foundation

enum VPErrorCode: String, Error {
    case expiredToken = "E_EXPIRED_TOKEN"
    case reauthenticateUser = "E_UNAUTHORIZED"
}

class VPError: NSError {
    // MARK: - Lifecycle
    convenience init(errorMessage: String?, code : Int = 0) {
        self.init(domain: "com.veracityprotocol.VeracitySDK", code: code, userInfo: [NSLocalizedDescriptionKey : errorMessage])
    }
    
    override init(domain: String, code: Int, userInfo dict: [String : Any]? = nil) {
        super.init(domain: domain, code: code, userInfo: dict)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    // MARK: - Errors
    static let generic: VPError = VPError(errorMessage: "An unknow error occured")
}

extension Error {
    var code: Int { return (self as NSError).code }
    var domain: String { return (self as NSError).domain }
}
