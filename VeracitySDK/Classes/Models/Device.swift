//
//  Device.swift
//  VeracitySDK
//
//  Created by Andrew on 13/06/2019.
//  Copyright © 2019 Veracity Protocol s.r.o. All rights reserved.
//

import UIKit
import RealmSwift

///Simple model that covers some `UIDevice` parameters.
class Device: Object {
    @objc dynamic var uuid: String = UIDevice.current.identifierForVendor!.uuidString + (Bundle.main.bundleIdentifier ?? "")
    @objc dynamic var model: String = UIDevice.current.modelCode
    @objc dynamic var osVersion: String = UIDevice.current.systemVersion
    @objc dynamic var name: String = UIDevice.current.name
    @objc dynamic var notificationToken: String?
    
    // MARK: - Lifecycle
    convenience init(uuid: String, notificationToken: String?) {
        self.init()
        self.uuid = uuid
        self.notificationToken = notificationToken
    }
    
    convenience init(notificationToken: String?) {
        self.init()
        self.notificationToken = notificationToken
    }
    
    override static func primaryKey() -> String {
        return "uuid"
    }
}

extension Device {
    override var description: String {
        return "Device: \n- uuid: \(self.uuid)\n- model: \(self.model)\n- version: \(self.osVersion)\n- name: \(self.name)\n- token: \(self.notificationToken ?? "")"
    }
}
