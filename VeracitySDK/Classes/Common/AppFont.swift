//
//  Font.swift
//  ONEPROVE
//
//  Created by Minh Chu on 1/13/21.
//  Copyright © 2019 Minh Chudang. All rights reserved.
//

import UIKit

let kNBAkademie = "NBAkademie"

public enum FontStyle: String {
    case regular = "Regular"
    case bold = "Bold"
    case light = "Light"
    case medium = "Medium"
}

public enum FontName {
    case NBAkademie(style: FontStyle)
    
    public var name: String {
        switch self {
        case .NBAkademie(let style):
            return "\(kNBAkademie)\(style.rawValue)"
        }
    }
}

public enum AppFont {
    case NBAkademieBold(size: CGFloat)
    case NBAkademieRegular(size: CGFloat)
    case NBAkademieMedium(size: CGFloat)
    case NBAkademieLight(size: CGFloat)
    
    public var font: UIFont? {
        switch self {
        case .NBAkademieBold(let size):
            return UIFont(name: FontName.NBAkademie(style: .bold).name, size: size)
        case .NBAkademieRegular(let size):
            return UIFont(name: FontName.NBAkademie(style: .regular).name, size: size)
        case .NBAkademieLight(let size):
            return UIFont(name: FontName.NBAkademie(style: .light).name, size: size)
        case .NBAkademieMedium(let size):
            return UIFont(name: FontName.NBAkademie(style: .medium).name, size: size)
        }
    }
}

public struct Fonts {
    public static let headerFont = AppFont.NBAkademieBold(size: AppSize.s34).font
    public static let buttonFont = AppFont.NBAkademieBold(size: AppSize.s16).font
    public static let titleLabelFont = AppFont.NBAkademieBold(size: AppSize.s16).font
    public static let textNormalFont = AppFont.NBAkademieRegular(size: AppSize.s16).font
    public static let textSmallFont = AppFont.NBAkademieRegular(size: AppSize.s14).font
    public static let textMenuFont = AppFont.NBAkademieRegular(size: AppSize.s18).font
    public static let textMenuBoldFont = AppFont.NBAkademieBold(size: AppSize.s18).font
}

