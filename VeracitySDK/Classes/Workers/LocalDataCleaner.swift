//
//  LocalDataCleaner.swift
//  VeracitySDK
//
//  Created by Andrew on 03/06/2019.
//  Copyright © 2019 Veracity Protocol s.r.o. All rights reserved.
//

import Foundation
import RealmSwift

///Internal class that monitors remote data updates for `ProtectItem` and `Job` and automaticaly removes local data duplicate based on ID.
class LocalDataCleaner {
    static let shared = LocalDataCleaner()
    
    var protectItems : Results<ProtectItem>?
    var protectItemsNotificationToken : NotificationToken?
    var jobItems : Results<Job>?
    var jobItemsNotificationToken : NotificationToken?
    
    func startObservingChanges() {
        protectItemsNotificationToken?.invalidate()
        protectItems = RealmHandler.shared.getObjects(of: ProtectItem.self)
        protectItemsNotificationToken = protectItems?.observe({ [weak self] (changes) in
            switch changes {
            case .initial:
                break
            case .update(_, _, let insertions, let modifications):
                //Get new items IDs
                var identifiers = [String]()
                var jobIdentifiers = [String]()
                
                insertions.forEach({ (index) in
                    if self?.protectItems?.count ?? 0 > index, let newItemID = self?.protectItems?[index].identifier {
                        identifiers.append(newItemID)
                        if let jobID = self?.protectItems?[index].jobID {
                            jobIdentifiers.append(jobID)
                        }
                    }
                })
                modifications.forEach({ (index) in
                    if self?.protectItems?.count ?? 0 > index, let newItemID = self?.protectItems?[index].identifier, !identifiers.contains(newItemID) {
                        identifiers.append(newItemID)
                        if let jobID = self?.protectItems?[index].jobID, !jobIdentifiers.contains(jobID) {
                            jobIdentifiers.append(jobID)
                        }
                    }
                })
                
                //Filter local artwork that aren't connected with added or modified items from above.
                let artworkIdPredicate = NSPredicate(format: "createdArtworkID IN %@", identifiers)
                let jobIdPredicate = NSPredicate(format: "jobID IN %@", jobIdentifiers)
                let predicate = NSCompoundPredicate(orPredicateWithSubpredicates: [artworkIdPredicate, jobIdPredicate])
                let localArtworksDuplicates = RealmHandler.shared.getObjects(of: LocalProtectItem.self).filter(predicate)
                
                //remove finished duplicates with all stored images
                if localArtworksDuplicates.count > 0 {
                    localArtworksDuplicates.forEach({ (localArtwork) in
                        localArtwork.removeAllLocalImages()
                    })
                    
                    RealmHandler.shared.remove(localArtworksDuplicates)
                }
                break
            case .error(let error):
                debugLog("\(error)")
            }
        })
        
        jobItemsNotificationToken?.invalidate()
        jobItems = RealmHandler.shared.getObjects(of: Job.self)
        jobItemsNotificationToken = jobItems?.observe({ [weak self] (changes) in
            switch changes {
            case .initial:
                break
            case .update(_, _, let insertions, let modifications):
                //Get new items IDs
                var identifiers = [String]()
                
                insertions.forEach({ (index) in
                    if self?.jobItems?.count ?? 0 > index, let newItemID = self?.jobItems?[index].identifier {
                        identifiers.append(newItemID)
                    }
                })
                modifications.forEach({ (index) in
                    if self?.jobItems?.count ?? 0 > index, let newItemID = self?.jobItems?[index].identifier, !identifiers.contains(newItemID) {
                        identifiers.append(newItemID)
                    }
                })
                
                //Filter local artwork by jobID that aren't connected with added or modified items from above.
                //TODO: - remove and rework in artworks update block to artwork's lastJobID when available on api.
                let predicate = NSPredicate(format: "jobID IN %@", identifiers)
                let localArtworksDuplicates = RealmHandler.shared.getObjects(of: LocalProtectItem.self).filter(predicate)
                
                //filter local jobs to remove
                let localJobsDuplicates = RealmHandler.shared.getObjects(of: LocalJob.self).filter(predicate)
                
                //remove finished duplicates with all stored images
                if localArtworksDuplicates.count > 0 {
                    localArtworksDuplicates.forEach({ (localArtwork) in
                        localArtwork.removeAllLocalImages()
                    })
                    RealmHandler.shared.remove(localArtworksDuplicates)
                }
                //remove finished jobs with all stored images
                if localJobsDuplicates.count > 0 {
                    localJobsDuplicates.forEach({ (localJob) in
                        localJob.removeAllLocalImages()
                    })
                    RealmHandler.shared.remove(localJobsDuplicates)
                }
                break
            case .error(let error):
                debugLog("\(error)")
            }
        })
    }
}
