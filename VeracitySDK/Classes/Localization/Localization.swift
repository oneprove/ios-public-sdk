//
//  Localization.swift
//  ONEPROVE
//
//  Created by Minh Chu on 11/11/20.
//  Copyright © 2020 ONEPROVE s.r.o. All rights reserved.
//
import Foundation

final class Localization {
    /// Struct's public properties.
    var locale: String? {
        didSet {
            let userDefaults = UserDefaults.standard
            userDefaults.set(["en"], forKey: "AppleLanguages")
            userDefaults.synchronize()
        }
    }
    
    init(from bundle: Bundle = Bundle.main, locale: String = "en") {
        self.bundle = bundle
        self.locale = locale
    }
    
    // MARK: Struct's public methods

    func localized(forString s: String) -> String {
        return bundle.localizedString(forKey: s, value: s, table: nil)
    }

    func reset() {
        let languages = bundle.preferredLocalizations
        let next = languages.first.orNil(default: "en")

        guard locale != next else {
            return
        }
        locale = next
    }

    /// Struct's private properties.
    private var bundle: Bundle
}
