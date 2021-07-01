//
//  VeracitySDK.swift
//  VeracitySDK
//
//  Created by Andrew on 20/08/2019.
//  Copyright © 2019 Veracity Protocol s.r.o. All rights reserved.
//

import Foundation

public enum VeracitySdkType : Equatable {
    case art
    case jerseyProtector
    case jerseyVerifier
    case luxuryGoods
    case apparel
    case memorabilia
    case demo
    case trezorVerifier
    case goat
    case custom(endpoint : String, webhookUrl : String?)
    
    var endpoint : String {
        switch self {
        case .custom(let endpoint, _):
            return endpoint
        default:
            //⚠️
            return "api.veracityprotocol.org";
//            return "api-dev.veracityprotocol.org"

        }
    }
    
    var applicationHeaderValue : String? {
        switch self {
        case .art:
            return "com.oneprove.art"
        case .jerseyProtector, .jerseyVerifier:
            return "com.oneprove.blockstar"
        case .luxuryGoods:
            return "com.oneprove.luxury"
        case .apparel:
            return "com.oneprove.ck"
        case .memorabilia:
            return "com.oneprove.nfl"
        case .demo:
            return "com.oneprove.demo"
        case .trezorVerifier:
            return "com.veracity.trezor"
        case .goat:
            return "com.veracity.goat"
        default:
            return nil
        }
    }
    
    //⚠️
    var celeryBackend : Bool {
        switch self {
        default:
            return false
        }
    }
    
    var webhookUrl : String? {
        switch self {
        case .jerseyProtector:
            return "https://demarchi-blockstar.com/fabric?cmd=veracity"
        case .custom(_,let webhookUrl):
            return webhookUrl
        default:
            return nil
        }
    }
}

public class VeracitySDK {
    public static let configuration = VeracitySDK()
    public static let database = RealmHandler.shared
    
    public var type : VeracitySdkType = .art
    public var verificationShouldMatchProtectingAlgo = false
    public var customFingerprintUploadOperationProvider : CustomImageUploadOperationProvider?
    
    private init() { }
}
