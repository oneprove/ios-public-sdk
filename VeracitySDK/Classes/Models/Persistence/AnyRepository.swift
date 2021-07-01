//
//  AnyRepository.swift
//  VeracitySDK
//
//  Created by Minh Chu on 12/4/20.
//

import Foundation
import RealmSwift

class AnyRepository<RepositoryObject>: Repository
        where RepositoryObject: Entity,
        RepositoryObject.StoreType: Object {
    
    typealias RealmObject = RepositoryObject.StoreType
    
    private let realm: Realm

    init() {
        realm = try! RealmHandler.shared.getRealm()
    }

    func getAll(where predicate: NSPredicate?) -> [RepositoryObject] {
        var objects = realm.objects(RealmObject.self)

        if let predicate = predicate {
            objects = objects.filter(predicate)
        }
        return objects.compactMap{ ($0).model as? RepositoryObject }
    }

    func insert(item: RepositoryObject) throws {
        try realm.write {
            realm.add(item.toStorable())
        }
    }
    
    func update(_ item: RepositoryObject) {
        if self.realm.isInWriteTransaction {
            self.realm.add(item.toStorable(), update: .modified)
        } else {
            try! self.realm.write {
                self.realm.add(item.toStorable(), update: .modified)
            }
        }
    }
}

