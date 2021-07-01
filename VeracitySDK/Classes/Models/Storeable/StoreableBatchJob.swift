//
//  BatchJob.swift
//  VeracitySDK
//
//  Created by Andrew on 14/11/2019.
//  Copyright © 2019 Veracity Protocol s.r.o. All rights reserved.
//

import Foundation
import RealmSwift

extension DTOBatchJob: Entity {
    public var storable: BatchJob {
        let realm = BatchJob()
        realm.identifier = id
        realm.completed = completed ?? false
        realm.jobName = jobName
        realm.createdAt = createdAt
        realm.userID = userId
        realm.childJobs.append(objectsIn: childJobs?.map { $0.toStorable() } ?? [])
        return realm
    }
    
    public func toStorable() -> BatchJob {
        return storable
    }
}

public class BatchJob : Object, Storable {
    @objc dynamic public var identifier : String!
    @objc dynamic public var completed = false
    @objc dynamic var jobName : String?
    @objc dynamic var createdAt : String?
    @objc dynamic var userID : String?
    public var childJobs = List<Job>()
    
    //MARK: Lifecycle
    override public static func primaryKey() -> String {
        return "identifier"
    }
    
    public override class func shouldIncludeInDefaultSchema() -> Bool {
        return false
    }
    
    ///
    static public func createBatchJob(_ completion : @escaping (_ batchJob : BatchJob?, _ error : Error?) -> ()) {
        NetworkClient.createNewBatchJob(completion: completion)
    }
    
    public var model: DTOBatchJob {
        return DTOBatchJob(id: identifier,
                           user: AnyCodable(userID),
                           job: nil,
                           jobName: jobName,
                           artwork: nil,
                           completed: completed,
                           createdAt: createdAt,
                           updatedAt: nil,
                           applicationUsed: nil,
                           childJobs: Array(childJobs.map { $0.model }),
                           error: nil,
                           errorCode: nil)
    }
}
