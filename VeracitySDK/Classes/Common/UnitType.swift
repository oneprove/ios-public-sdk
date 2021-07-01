//
//  UnitType.swift
//  Veracity Authenticator
//
//  Created by Minh Chu on 5/12/21.
//  Copyright © 2021 ONEPROVE s.r.o. All rights reserved.
//

public enum UnitType: Int {
    case cm
    case inch
    
    public var name: String {
        switch self {
        case .cm:
            return Text.cm.localizedText.lowercased()
        case .inch:
            return Text.in.localizedText.lowercased()
        }
    }
}
