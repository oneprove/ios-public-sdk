//
//  CreateItemStep.swift
//  Veracity Authenticator
//
//  Created by Minh Chu on 2/2/21.
//  Copyright © 2021 ONEPROVE s.r.o. All rights reserved.
//


public enum ProtectItemStep: Int, CaseIterable {
    case takeOverviewPhoto
    case cropBackground
    case setDimension
    case takeFingerprintPhotos
    case completed
    
    var name: String {
        switch self {
        case .takeOverviewPhoto:
            return "Take overview photo".uppercased()
        case .cropBackground:
            return "Crop background".uppercased()
        case .setDimension:
            return "Set dimensions".uppercased()
        case .takeFingerprintPhotos:
            return "Take close-up photos".uppercased()
        default:
            return ""
        }
    }
    
    var step: Int {
        switch self {
        case .takeOverviewPhoto:
            return 1
        case .cropBackground:
            return 2
        case .setDimension:
            return 3
        case .takeFingerprintPhotos:
            return 4
        default:
            return 0
        }
    }
    
    static var steps: [ProtectItemStep] {
        return [.takeOverviewPhoto, .cropBackground, .setDimension, .takeFingerprintPhotos, .completed]
    }
}

struct CreateItemStepHelp {
    let title: String
    let description: String
    let animation: String?
    let image: UIImage?
}
