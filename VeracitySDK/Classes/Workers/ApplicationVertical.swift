//
//  ApplicationVertical.swift
//  ONEPROVE
//
//  Created by Andrew on 20/02/2020.
//  Copyright © 2020 ONEPROVE s.r.o. All rights reserved.
//

import Foundation

public enum AlgoType: String, CaseIterable {
    case celery = "celery"
    case luxury = "com.oneprove.luxury"
    
    var title : String {
        switch self {
        case .celery:
            return Text.tradingCard.localizedText
        case .luxury:
            return Text.helmetOrFootball.localizedText
        }
    }
}

public enum ApplicationVertical : String {
    case identityDocuments = "vertical_documents"
    case packaging = "vertical_packaging"
    case apparel = "vertical_apparel"
    case labels = "vertical_labels"
    case art = "vertical_art"
    case lpmPoc = "lpm_poc_pilot"
    case sicpa = "vertical_sicpa"
    
    public var title : String {
        switch self {
        case .identityDocuments:
            return Text.identityDocuments.localizedText
        case .packaging:
            return Text.packaging.localizedText
        case .apparel:
            return Text.apparel.localizedText
        case .labels:
            return Text.labels.localizedText
        case .art:
            return Text.art.localizedText
        case .lpmPoc:
            return Text.lpmPoc.localizedText
        case .sicpa:
            return Text.sicpa.localizedText
        }
    }
    
    public var algoSwitchingSupported : Bool {
        switch self {
        default:
            return false
        }
    }
    
    public var allowedAlgosByDefault : [AlgoType]? {
        switch self {
        default:
            return nil
        }
    }
    
    public var defaultProtectAlgo : String? {
        switch self {
        case .identityDocuments, .packaging, .art:
            return "celery"
        case .apparel, .labels:
            return "com.oneprove.luxury"
        case .lpmPoc:
            return "com.veracity.lpm"
        case .sicpa:
            return "com.veracity.sicpa.label"
        }
    }
}
