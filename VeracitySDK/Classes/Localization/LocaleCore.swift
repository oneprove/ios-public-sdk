//
//  Locale.swift
//  ONEPROVE
//
//  Created by Minh Chu on 11/11/20.
//  Copyright © 2020 ONEPROVE s.r.o. All rights reserved.
//

public struct LocaleCore {
    /// Struct's public static properties.
    public static var currentLocale: String {
        get {
            return shared.locale.orNil(default: "")
        }
        set(newLocale) {
            shared.locale = newLocale
        }
    }

    /// Localize string for string. The original string will be returned if a localized string could
    /// not be found.
    ///
    /// - Parameter string: an original string
    public static func localized(forString s: String?) -> String {
        guard let text = s, text.count > 0 else { return "" }
        return shared.localized(forString: text)
    }

    /// Reset current locale to english.
    public static func reset() {
        shared.reset()
    }

    /// Struct's private static properties.
    private static var shared = Localization()
}
