//
//  Logger.swift
//  VeracitySDK
//
//  Created by Andrew on 16/04/2019.
//  Copyright © 2019 Veracity Protocol s.r.o. All rights reserved.
//

import Foundation
import Smartlook

public func debugLog(_ message: Any, filename: String = #file, function: String = #function, line: Int = #line) {
    debugPrint("▶️ – [\(URL(fileURLWithPath: filename).lastPathComponent):\(line)] func \(function) $ \(message)")
    Smartlook.trackCustomEvent(name: "WARNING LOG", props: ["filename" : URL(fileURLWithPath: filename).lastPathComponent, "line" : "\(line)", "message log" : "\(message)"])
}

public func warningLog(_ message: Any, filename: String = #file, function: String = #function, line: Int = #line) {
    debugPrint("⚠️ – [\(URL(fileURLWithPath: filename).lastPathComponent):\(line)] func \(function) $ \(message)")
    Smartlook.trackCustomEvent(name: "WARNING LOG", props: ["filename" : URL(fileURLWithPath: filename).lastPathComponent, "line" : "\(line)", "message log" : "\(message)"])
}

///Shows console error message if first parameter is != nil.
public func errorLog(_ message: Any?, filename: String = #file, function: String = #function, line: Int = #line) {
    guard let message = message else { return }
    debugPrint("❌ – [\(URL(fileURLWithPath: filename).lastPathComponent):\(line)] func \(function) $ \(message)")
    Smartlook.trackCustomEvent(name: "ERROR LOG", props: ["filename" : URL(fileURLWithPath: filename).lastPathComponent, "line" : "\(line)", "message log" : "\(message)"])
}
