//
//  RealmHandler.swift
//  VeracitySDK
//
//  Created by Andrew on 16/04/2019.
//  Copyright © 2019 Veracity Protocol s.r.o. All rights reserved.
//

import Foundation
import RealmSwift

///Singelton. Main class to cover Realm database handling like get Objects of type, get Object by primary key, add Object to database, update parameters of Object, remove from database.
///By default `RealmHandler` can only work with SDK's predefined Object subclass types.
/// - Class `Object` is part of `Realm`.
public class RealmHandler : NSObject {
    ///Public singleton instance of `RealmHandler`.
    public static let shared = RealmHandler()
    var realm : Realm!
    public var defaultConfig : Realm.Configuration!
    
    public var isInWriteTransaction : Bool {
        return realm.isInWriteTransaction
    }
    
    private override init() {
        super.init()
        setupDefaultConfiguration()
    }
    
    public func getRealm() -> Realm {
        return self.realm
    }
    
    ///Create new instance on any thread
    public func createNewInstance() throws -> Realm? {
        return try Realm(configuration: defaultConfig)
    }
    
    ///Refresh data on main thread.
    public func refreshData() {
        DispatchQueue.main.async {
            self.realm.refresh()
        }
    }
    
    /**
     Add object to Realm.
     - Parameter modifiedUpdate: Performs update of only modified properties if set to `true`. Otherwise performs update of whole object. Use `true` if not sure.
     */
    public func add(_ object : Object, modifiedUpdate : Bool) {
        if self.realm.isInWriteTransaction {
            self.realm.add(object, update: .modified)
        }else {
            try! self.realm.write {
                self.realm.add(object, update: .modified)
            }
        }
    }
    
    /**
     Add array of objects to Realm.
     - Parameter modifiedUpdate: Performs update of only modified properties if set to `true`. Otherwise performs update of whole object array. Use `true` if not sure.
     */
    public func add(_ objects : [Object], modifiedUpdate : Bool) {
        if self.realm.isInWriteTransaction {
            self.realm.add(objects, update: .all)
        }else {
            try! self.realm.write {
                self.realm.add(objects, update: .all)
            }
        }
    }
    
    //MARK: - Update
    /**
     Persist Object parameters change in given block.
     - Parameter updates: update block will run inside realm write transaction to persist change of parameters.
     */
    public func persist(updates: () -> ()) {
        if self.realm.isInWriteTransaction {
            updates()
        }else {
            try! self.realm.write {
                updates()
            }
        }
    }
    
    //MARK: - Remove
    ///Pernamently delete given object from database.
    /// - Parameter object: Subclass of `Object` to be removed.
    public func remove(_ object : Object) {
        guard object.realm != nil else { return }
        if realm.isInWriteTransaction {
            realm.delete(object)
        }else {
            try! realm.write {
                realm.delete(object)
            }
        }
    }
    
    func removeProtectItems() {
        let results = getObjects(of: ProtectItem.self)
        if realm.isInWriteTransaction {
            realm.delete(results)
        }else {
            try! realm.write {
                realm.delete(results)
            }
        }
    }
    
    func removeJobItems() {
        let results = getObjects(of: Job.self)
        if realm.isInWriteTransaction {
            realm.delete(results)
        }else {
            try! realm.write {
                realm.delete(results)
            }
        }
    }
    
    func removeCreators() {
        let results = getObjects(of: Creator.self)
        if realm.isInWriteTransaction {
            realm.delete(results)
        }else {
            try! realm.write {
                realm.delete(results)
            }
        }
    }
    
    ///Custom remove method for LocalArtwork.
    //TODO: ⚠️ make internal - images must be removed too..
    public func remove(_ results : Results<LocalProtectItem>) {
        if realm.isInWriteTransaction {
            realm.delete(results)
        }else {
            try! realm.write {
                realm.delete(results)
            }
        }
    }
    
    public func remove(_ results : Results<SearchHistory>) {
        if realm.isInWriteTransaction {
            realm.delete(results)
        }else {
            try! realm.write {
                realm.delete(results)
            }
        }
    }
    
    ///Custom remove method for LocalJob.
    public func remove(_ results : Results<LocalJob>) {
        if realm.isInWriteTransaction {
            realm.delete(results)
        }else {
            try! realm.write {
                realm.delete(results)
            }
        }
    }
    
    func remove(_ list : List<Creator>) {
        if realm.isInWriteTransaction {
            realm.delete(list)
        }else {
            try! realm.write {
                realm.delete(list)
            }
        }
    }
    
    func remove(_ list : List<Job>) {
        if realm.isInWriteTransaction {
            realm.delete(list)
        }else {
            try! realm.write {
                realm.delete(list)
            }
        }
    }
    
    func remove(_ list : List<ProtectItem>) {
        if realm.isInWriteTransaction {
            realm.delete(list)
        }else {
            try! realm.write {
                realm.delete(list)
            }
        }
    }
    
    ///Removes from database everything.
    public func removeWholeDB() {
        if realm.isInWriteTransaction {
            realm.deleteAll()
        }else {
            try! realm.write {
                realm.deleteAll()
            }
        }
    }
    
    //MARK: - Get Objects
    /**
     Provides list of `Object`s of given type.
     - Parameter type: `Type` of `Object`s type.
     - Returns: `Results` object with `Object`s of given type. Can be empty.
     
     Import even `RealmSwift`, to get live-updates of any object change in `Results` list.
     - `Results` is part of `Realm` and it can be casted as `Array`.
     */
    public func getObjects<T : Object>(of type : T.Type) -> Results<T> {
        return realm.objects(type)
    }
    
    ///Provides `Object` subclass of given class type by primary key if exists.
    /// - Parameter type: `Type` of `Object` that will be returned.
    /// - Returns: `Object` of given type for primary key or `nil`.
    public func getObject<T : Object>(of type : T.Type, forKey key : String) -> T? {
        return realm.object(ofType: type, forPrimaryKey: key)
    }
    
    ///
    public func migrateUserData(_ user : User) {
        persist {
            realm.create(User.self, value: user, update: .all)
        }
    }
}

fileprivate extension RealmHandler {
    ///Setup shared `Realm` instance with custom file path, migration block & predefined object types which are the only types that can be handled by shared instance.
    func setupDefaultConfiguration() {
        ///Rename default realm file.
        let url = Realm.Configuration().fileURL?.deletingLastPathComponent().appendingPathComponent("veracity-sdk-default.realm")
        debugLog("Local DB: \(url)")
        ///Create default config.
        defaultConfig = Realm.Configuration(fileURL: url, schemaVersion: 33, migrationBlock: { migration, oldSchemaVersion in
            if (oldSchemaVersion < 2) {
                migration.enumerateObjects(ofType: User.className(), { (oldObject, newObject) in
                    newObject!["metricalUnits"] = Locale.current.usesMetricSystem
                })
            }
        }, objectTypes: [LocalJob.self, LocalProtectItem.self, User.self, Job.self, ProtectItem.self, PublicProtectItem.self, VerificationProtectItem.self, Fingerprint.self, Creator.self, TradingCode.self, FingerprintLocation.self, Device.self, ResultIndicatorValue.self, BatchJob.self, Wallet.self, FileUploadTrack.self, SearchHistory.self])
        realm = try! Realm(configuration: defaultConfig)
    }
}
