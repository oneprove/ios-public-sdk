//
//  DTOBatchJob.swift
//  VeracitySDK
//
//  Created by Minh Chu on 12/8/20.
//

import UIKit

public struct DTOBatchJob: Codable {
    let id: String?
    let user: AnyCodable?
    let job: String?
    let jobName: String?
    let artwork: String?
    let completed: Bool?
    let createdAt, updatedAt: String?
    let applicationUsed: String?
    let childJobs: [DTOJob]?
    let error, errorCode: String?
}

extension DTOBatchJob {
    var userId: String? {
        if let id = user?.value as? String {
            return id
        }
        
        if let u = user?.value as? DTOCreator {
            return u.id
        }
        
        return nil
    }
}
