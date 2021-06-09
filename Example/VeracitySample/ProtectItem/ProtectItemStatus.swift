//
//  CreateItemInstruction.swift
//  Veracity Authenticator
//
//  Created by Minh Chu on 2/6/21.
//  Copyright © 2021 ONEPROVE s.r.o. All rights reserved.
//

import UIKit
import VeracitySDK

enum ProtectItemStatus {
    case takeLPMOverviewPhoto
    case takeOverviewPhoto
    case cropBackground
    case takeFingerByAR
    case takeFingerByNormal
    
    var title: String? {
        switch self {
        case .takeLPMOverviewPhoto:
            return "Align item's edges with the edges of the green safe zone and take photo."
        case .takeOverviewPhoto:
            return "Take a photo when the entire document is in the frame"
        case .cropBackground:
            return "Adjust the corners and crop the background"
        case .takeFingerByAR:
            return "Fit the entire item into the frame"
        case .takeFingerByNormal:
            return "Move closer to the highlighted area"
        }
    }
}
