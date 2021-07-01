//
//  FileUploadTrack.swift
//  VeracitySDK
//
//  Created by Minh Chu on 11/21/20.
//

import RealmSwift

public class FileUploadTrack: Object {
    @objc dynamic var referId: String?
    @objc dynamic var fileName: String = ""
    @objc dynamic var startTime: Int64 = 0
    @objc dynamic var endTime: Int64 = 0
    
    override public static func primaryKey() -> String { return "fileName" }
}

extension FileUploadTrack {
    func timeUpload() -> Int64 {
        guard startTime != 0, endTime != 0 else {
            return 0
        }
        
        return max(endTime - startTime, 0)
    }
}
