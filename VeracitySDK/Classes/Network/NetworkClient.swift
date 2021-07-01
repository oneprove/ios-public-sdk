//
//  NetworkClient.swift
//  VeracitySDK
//
//  Created by Andrew on 16/04/2019.
//  Copyright © 2019 Veracity Protocol s.r.o. All rights reserved.
//

import Foundation
import RealmSwift

///Main component to handle network requests.
///Minor logic for persist some response data in realm.
///Process network data as `JSON` then returned by async completion block (optional in most cases because of realm notification).
public class NetworkClient : NSObject {
    
    //MARK: - Authentication
    /**
     Creates login request with given credentials. If response contains `User` data, that data will be persisted to Realm and then handled by `UserManager`, otherwise completion should pass Error. With succesull response Device on API is updated.
     - Parameters:
        - email:        Login.
        - password:     Password.
        - completion:   Response callback handler.
        - success:      Returns true if login was successfull.
        - error:        Request error.
     */
    public static func login(email : String, password : String, completion : @escaping (_ success : Bool, _ error : Error?) -> ()) {
        let router = Router.login(email: email, password: password)
        REST.request(DTOLogin.self, router: router) { (data, error) in
            if let data = data, var user = data.user {
                user.token = data.token
                UserManager.shared.user = user
                AnyRepository().update(user)
                DeviceManager.shared.updateDevice()
                completion(true, nil)
            }else {
                completion(false, error)
            }
        }
    }
    
    /**
     Performs new registration request with given credentials.
     - Parameters:
        - email:        Email.
        - password:     Password.
        - completion:   Response callback handler.
        - success:      Returns true if registration was successfull.
        - error:        Request error.
     */
    public static func register(email : String, password : String, completion : @escaping (_ success : Bool, _ error : Error?) -> ()) {
        let router = Router.register(email: email, password: password)
        REST.request([String: AnyCodable].self, router: router) { (data, error) in
            if let dict = data, (dict["user"]?.value as? [String : Any])?.count ?? 0 > 0 {
                completion(true, nil)
            }
            else {
                completion(false, error)
            }
        }
    }
    
    ///Performs request to resent activation link for newly registered user by email.
    public static func resendActivationLink(forEmail email : String, completion : @escaping (_ success : Bool, _ error : Error?) -> ()) {
        REST.request([String: AnyCodable].self, router: .resendActivationLink(email: email)) { (data, error) in
            if let dict = data, let successParameter = dict["success"]?.value as? Bool {
                completion(successParameter, error)
            }
            else {
                completion(false, error)
            }
        }
    }
    
    /**
     Performs request to activate newly registered account.
     - Parameters:
         - email:       Email.
         - token:       Activating token from dynamic link.
         - completion:  Response callback handler.
         - success:     Returns true if activation was successfull.
         - error:       Request error.
     */
    public static func activateAccount(forEmail email : String, token : String, completion : @escaping (_ success : Bool, _ error : Error?) -> ()) {
        REST.request([String: AnyCodable].self, router: .activateAccount(token: token, email: email)) { (data, error) in
            if let dict = data, let successParameter = dict["success"]?.value as? Bool {
                completion(successParameter, error)
            }
            else {
                completion(false, error)
            }
        }
    }
    
    /**
     Performs request to get allowed verticals. Verticals are then updated with logged user model.
     - Parameters:
        - completion:   Response callback.
        - verticals:    Allowed vertical for current user. Empty array means all verticals.
        - error:        Request error.
     */
    public static func updateAllowedVerticals(completion : ((_ verticals : [String]?, _ error : Error?) -> ())?) {
        REST.request([String: AnyCodable].self, router: .myAccount) { (data, error) in
            if let dict = data, let verticals = dict["allowedVerticals"]?.value as? [String] {
                let verticalsList = List<String>()
                verticalsList.append(objectsIn: verticals)
                if let user = UserManager.shared.user?.toStorable() {
                    RealmHandler.shared.persist {
                        user.allowedVerticals.removeAll()
                        user.allowedVerticals.append(objectsIn: verticals)
                    }
                }
                completion?(verticals, nil)
            }
            else {
                completion?(nil, error)
            }
        }
    }
    
    //MARK: - Password
    /**
     Performs request to change password for given email adress.
     
     Completion handler only provides information if request was succesfully accepted. Password is then changed by deeplink in email that was generated by that request.
     
     - Parameters:
         - email:       Email.
         - completion:  Response callback block.
         - success:     Indicates that request was accepted.
         - error:       Request error.
     */
    public static func resetPassword(forEmail email : String, completion : @escaping (_ success : Bool, _ error : Error?) -> ()) {
        REST.request([String: AnyCodable].self, router: .resetPassword(email: email)) { (data, error) in
            if error == nil {
                completion(true, nil)
            }
            else {
                completion(false, error)
            }
        }
    }
    
    /**
     Performs request to check password reset token that came from deeplink.
     - Parameters:
         - token: Token that came typicaly with deeplink url.
         - completion: Response callback block.
         - email: Email adress for password change if success otherwise `nil`.
         - error: Response error.
     */
    public static func checkResetPassportToken(_ token : String, completion : @escaping (_ email : String?, _ error : Error?) -> ()) {
        REST.request([String: AnyCodable].self, router: .resetPasswordTokenCheck(token: token)) { (data, error) in
            if let dict = data, let userDict = dict["user"]?.value as? [String : Any], let email = userDict["email"] as? String {
                completion(email, nil)
            }else {
                completion(nil, error)
            }
        }
    }
    
    /**
     Performs final request to change password.
     - Parameters:
        - password: New password to set.
        - token: Checked reset token from deeplink.
        - completion: Response callback block.
        - email: Email adress of that account if success otherwise `nil`.
        - error: Response error.
     */
    public static func setNewPassword(_ password : String, resetToken token : String, completion : @escaping (_ email : String?, _ error : Error?) -> ()) {
        REST.request([String: AnyCodable].self, router: .setNewPassword(password: password, resetToken: token)) { (data, error) in
            if let dict = data, let email = dict["email"]?.value as? String {
                completion(email, nil)
            }
            else {
                completion(nil, error)
            }
        }
    }
    
    //MARK: - Credits
    /**
     Performs request to get current credits balance.
     - Parameters:
        - completion: Response handler callback block.
        - credits: `Credits` object or `nil`.
        - error: Response error.
     */
    public static func credits(completion : @escaping (_ credits : DTOCredits?, _ error : Error?) -> ()) {
        REST.request(DTOCredits.self, router: .credits) { (data, error) in
            if let credit = data {
                completion(credit, nil)
                NotificationCenter.default.post(name: NotificationsNames.creditsWasUpdated, object: nil)
            } else {
                completion(nil, error)
            }
        }
    }
    
    /**
     Performs request to charge up credits purchased by in-app purchase.
     - Parameters:
        - amount: Number of credits purchased.
        - signature: JSON signature string generated with purchase.
        - invoide: Invoice string given after succesfull purchase.
        - completion: Response handler callback block.
        - credit: `Credits` object with current balance after purchase.
        - error: Response error if any.
     */
    public static func creditsCharge(amount : UInt, signatue : String, invoice : String, completion : @escaping (_ credit : DTOCredits?, _ error : Error?) -> ()) {
        REST.request(DTOCredits.self, router: .creditsCharge(invoice: invoice, signature: signatue, credits: amount)) { (data, error) in
            if let credit = data {
                completion(credit, nil)
                NotificationCenter.default.post(name: NotificationsNames.creditsWasUpdated, object: nil)
            } else {
                completion(nil, error)
            }
        }
    }
    
    //MARK: - Artworks
    /**
     Request for protected items created by logged user. Items are by default persisted in to Realm.
     
     Used only for data for Protect table view.
     
     - Parameters:
        - completion: Optional response callback block.
        - items: `Array` of `ProtectItems`.
        - error: response error.
     */
    public static func myProtectedItems(clearCache : Bool = false, cacheResults : Bool = true, completion : ((_ items : [DTOProtectItem], _ error : Error?) -> ())?) {
        REST.request([DTOProtectItem].self, router: .myArtworks) { (data, error) in
            guard let data = data, !data.isEmpty else {
                completion?([], error)
                return
            }
            
            var protectedItems = [DTOProtectItem]()
            defer {
                if error == nil, clearCache {
                    DispatchQueue.main.async {
                        let persistedItems = RealmHandler.shared.getObjects(of: ProtectItem.self)
                        let removedItems = List<ProtectItem>()
                        persistedItems.forEach { (lclItem) in
                            if protectedItems.first(where: { $0.id == lclItem.identifier}) == nil {
                                removedItems.append(lclItem)
                            }
                        }
                        RealmHandler.shared.remove(removedItems)
                    }
                }
                if cacheResults {
                    RealmHandler.shared.add(protectedItems.map { $0.toStorable() }, modifiedUpdate: true)
                }
                completion?(protectedItems, error)
            }
            
            protectedItems.append(contentsOf: data)
        }
    }
    
    /**
     Performs request to get public protected item by given ID. Item isn't persisted to database and handled back as memory only object.
     - Parameters:
        - publicID: Identifier of desired public item.
        - completion: Response callback block.
        - publicItem: `PublicProtectItem` by given ID or `nil`.
        - error: Response error.
     */
    public static func publicProtectedItemBy(publicID : String, completion : @escaping (_ publicItem : PublicProtectItem?, _ error : Error?) -> ()) {
        REST.request(DTOPublicProtectItem.self, router: .publicArtworkByID(publicID: publicID)) { (data, error) in
            if let artwork = data?.toStorable() {
                completion(artwork, nil)
            }
            else {
                completion(nil, error)
            }
        }
    }
    
    /**
     Performs request to get public protected items by given array of ID's. Results are not persisted to database and handled back as memory only objects.
     
     Used to get all result items that came with image search.
     
     - Parameters:
        - itemIDs: `Array` of identifiers of desired items.
        - completion: Response callback block.
        - items: `Array` of items by given ID's or `nil`.
     */
    public static func searchResultsBy(itemIDs : [String], completion : @escaping (_ items : [PublicProtectItem]?) -> ()) {
        REST.request([DTOPublicProtectItem].self, router: .searchResultsByIDs(artworkIDs: itemIDs)) { (data, error) in
            let artworks = data?.map { $0.toStorable() }
            completion(artworks)
        }
    }
    
    public static func searchResultsBy(metadataJson json : String, completion : @escaping (_ items : [PublicProtectItem]?, _ error : Error?) -> ()) {
        REST.request([DTOPublicProtectItem].self, router: .searchResultsByMetadata(json: json)) { (data, error) in
            let items = data?.map { $0.toStorable() }
            completion(items, error)
        }
    }
    
    /**
     Performs a request to create protect item. Created protect item is handled back as memory only object.
     
     Internal part of upload flow.
     
     - Paramerets:
        - item: Filled `LocalProtectItem`.
        - completion: Response callback block.
        - protectItem: Newly created `ProtectItem` or `nil`.
        - erro: Response error.
     */
    static func createProtectItem(_ item : ThreadSafeReference<LocalProtectItem>, wallet: ThreadSafeReference<Wallet>?, completion : @escaping (_ protectItem : ProtectItem?, _ error : Error?) -> ()) {
        let realm = try! Realm(configuration: RealmHandler.shared.defaultConfig)
        guard let item = realm.resolve(item) else {
            completion(nil, nil)
            return
        }
        
        /// Meta data
        var meta = item.metadata
        meta?["upload_time"] = "\(item.getTimeUploadFiles())"
        meta?["fingerprintNames"] = item.fingerprintImageFilenames.joined(separator: ",")
        meta?["fingerprintUrls"] = item.fingerprintImageUrls.joined(separator: ",")
        if let wallet = wallet {
            let safeWallet = realm.resolve(wallet)
            meta?["walletAddress"] = safeWallet?.address
            meta?["blockchain"] = "arweave"
        }
        let metaString = meta?.convertToJSONString()
        realm.refresh()
        
        guard let artistID = item.createdArtist?.identifier, let name = item.name, let year = item.year.value, let width = item.width.value, let height = item.height.value else {
            completion(nil, nil)
            return
        }
        
        let router = Router.createArtwork(artistID: artistID, name: name, year: year, width: width, height: height, metadata: metaString)
        REST.request([String: AnyCodable].self, router: router) { (data, error) in
            if let dict = data, let artwork = ProtectItem(map: dict) {
                completion(artwork, nil)
            }else {
                completion(nil, error)
            }
        }
    }
    
    /**
     Performs a request to append overview & thumbnail photo url's.
     
     Internal part of upload flow.
     
     - Parameters:
        - item: Filled `LocalProtectItem`.
        - completion: Response callback block.
        - success: `Bool` value indicating request success.
        - error: Response error.
     */
    static func addItemOverview(_ item : ThreadSafeReference<LocalProtectItem>, completion : @escaping (_ success : Bool, _ error : Error?) -> ()) {
        let realm = try! Realm(configuration: RealmHandler.shared.defaultConfig)
        realm.refresh()
        guard let item = realm.resolve(item) else { completion(false, nil); return }
        guard let artwordID = item.createdArtworkID, let overview = item.overviewImageUrl, let thumbnail = item.thumbnailImageUrl else { completion(false, nil); return }
        
        let router = Router.addArtworkOverview(artworkID: artwordID, overview: overview, thumbnail: thumbnail)
        REST.request([String: AnyCodable].self, router: router) { (data, error) in
            let success = data != nil
            completion(success, error)
        }
    }
    
    /**
     Performs a request to remove `ProtectItem` on server by given identifier.
     - Parameters:
        - identifier: Identifier of item to remove.
        - competion: Response callback block.
        - succes: `Bool` value indicating that items was succesfully removed.
        - error: Response error.
     */
    public static func removeProtectedItem(byID identifier : String, completion : @escaping (_ succes : Bool, _ error : Error?) -> ()) {
        REST.request([String: AnyCodable].self, router: .removeArtwork(artworkID: identifier)) { (data, error) in
            if error == nil {
                completion(true, nil)
            }
            else {
                completion(false, error)
            }
        }
    }
    
    //MARK: Artwork Fingerprints
    /**
     Performs a request to append fingerprint photo url's & location.
     
     Internal part of upload flow.
     
     - Parameters:
        - item: Filled `LocalProtectItem`.
        - completion: Response callback block.
        - jobID: Identifier of new job if success otherwise `nil`.
        - error: Response error.
     */
    static func addItemFingerprints(_ item : ThreadSafeReference<LocalProtectItem>, completion : @escaping (_ jobID : String?, _ error : Error?) -> ()) {
        let realm = try! Realm(configuration: RealmHandler.shared.defaultConfig)
        guard let item = realm.resolve(item) else { completion(nil, nil); return }
        realm.refresh()
        guard let itemsID = item.createdArtworkID ?? item.artwork?.identifier, Array(item.fingerprintImageUrls).count > 1, let x = item.fingerprintLocation?.x, let y = item.fingerprintLocation?.y, let width = item.fingerprintLocation?.width, let height = item.fingerprintLocation?.height else { completion(nil, nil); return }
        let fingerprints = Array(item.fingerprintImageUrls)
        
        let router = Router.addArtworkFingerprints(artworkID: itemsID, images: fingerprints, xLocation: x, yLocation: y, widthlocation: width, heightLocation: height, algo: item.algo)
        
        REST.request([String: AnyCodable].self, router: router) { (data, error) in
            if let dict = data, let jobID = dict["job"]?.value as? String {
                completion(jobID, nil)
            }
            else {
                completion(nil, error)
            }
        }
    }
    
    /**
     Performs a request to get `Fingerprint` of item by his identifier.
     - Parameters:
        - itemID: Identifier of item.
        - completion: Response callback block.
        - fingerprint: `Fingerprint` object or `nil`.
        - error: Response error.
     */
    public static func protectItemFingerprint(itemID : String, completion : @escaping (_ fingerprint : Fingerprint?, _ error : Error?) -> ()) {
        REST.request([DTOFingerprint].self, router: .artworkFingerprints(artworkID: itemID)) { (data, error) in
            if let fingerprint = data?.first?.toStorable() {
                DispatchQueue.main.async {
                    RealmHandler.shared.add(fingerprint, modifiedUpdate: true)
                }
                completion(fingerprint, nil)
            }
            else {
                completion(nil, error)
            }
        }
    }
    
    /**
     Perform a wrapper request to get `FingerprintLocation` and hash.
     - Parameters:
         - artworkID: Identifier of item.
         - completion: Response callback block.
         - fpLocation: Fingerprint location or `nil`.
         - hash: Hash value of fingerprint.
         - error: Response error.
     
     - SeeAlso: `protectItemFingerprint(itemID, completion)`.
     */
    public static func getFingerprintInfoBy(artworkID : String, completion : @escaping (_ fpLocation : FingerprintLocation?, _ hash : String?, _ error : Error?) -> ()) {
        protectItemFingerprint(itemID: artworkID) { (fingerprint, error) in
            if let fingerprint = fingerprint {
                completion(fingerprint.location, fingerprint.fingerprintHash, nil)
            }else {
                completion(nil, nil, error)
            }
        }
    }
    
    typealias VerifyFingerprintCompletion = (_ jobID : String?, _ error : Error?) -> ()
    ///Wrapper for upload operation. Gets called as part of verification upload process, when data doesn't have `fingerprint` already. For more info see `verifyFingerprint(url:)`
    static func verifyFingerprint(localJob : ThreadSafeReference<LocalJob>, completion : @escaping VerifyFingerprintCompletion) {
        let realm = try! Realm(configuration: RealmHandler.shared.defaultConfig)
        guard let job = realm.resolve(localJob) else {
            completion(nil, nil)
            return
        }
        
        /// Meta data
        var meta: [String : AnyHashable] = [:]
        meta["upload_time"] = "\(job.getTimeUploadFiles())"
        let metaString = meta.convertToJSONString()
        
        realm.refresh()
        
        guard let fingerprintID = job.fingerprint?.identifier, let url = Array(job.fingerprintImageUrls).first else {
            completion(nil, nil)
            return
        }
        
        let webhookUrl = job.publicArtwork?.webhookUrl
        verifyFingerprint(url: url, fingerprintID: fingerprintID, algo: job.algo, expectedResult: job.expectedResult, webhookUrl: webhookUrl, metadata: metaString, completion: completion)
    }
    
    /**
     Performs a request to verify fingerprint by given & url adress agains "master" fingerprint by given ID.
     Verification result is then provided by notification.
     - Parameters:
        - urlString: URL of taken fingerprint for verification.
        - fingerprintID: Identifier of "master" `Fingerprint` that is being verified.
        - algo: Algo switching parameter. Don't set if not sure what's doing. Default is `nil`.
        - expectedResult: Expected result of verification.
        - webhookUrl: Webhook URL. Don't set if not sure what's doing.
        - completion: Response callback block.
        - jobID: Identifier of new job if success otherwise `nil`.
        - error: Response error.
     */
    static func verifyFingerprint(url urlString : String, fingerprintID : String, algo : String?, expectedResult : String?, webhookUrl : String?, metadata: String?, completion : @escaping (_ jobID : String?, _ error : Error?) -> ()) {
        let router = Router.verifyFingerprint(url: urlString, fingerprintID: fingerprintID, algo: algo, expectedResult: expectedResult, webhookUrl: webhookUrl, metadata: metadata)
        
        REST.request([String: AnyCodable].self, router: router) { (data, error) in
            if let dict = data, let job = Job(map: dict) {
                completion(job.identifier, nil)
            }
            else {
                completion(nil, error)
            }
        }
    }
    
    //MARK: - Transfers
    /**
     Performs a request to send passport copy by email.
     - Parameters:
        - identifier: Passport / protect item identifier.
        - completion: Response callback block.
        - succes: `Bool` value indicating succes of request.
        - error: Response error.
     */
    public static func emailPassport(itemID identifier : String, completion : @escaping (_ succes : Bool, _ error : Error?) -> ()) {
        REST.request([String: AnyCodable].self, router: .emailPassport(artworkID: identifier)) { (data, error) in
            if error == nil {
                completion(true, nil)
            }
            else {
                completion(false, error)
            }
        }
    }
    
    /**
     Performs a request to transfer protect item by given identifier to another account by given email adress.
     New potencional owner can choose to accept, decline or ignore.
     - Parameters:
        - identifier: Identifier of `ProtectItem` that is being transfered.
        - email: Email adress of new owner.
        - completion: Response callback block.
        - transferID: Identifier of new transfer request if succes otherwise `nil`.
        - transferState: Raw server value indicating transfer state.
        - error: Response error.
     */
    public static func transferItem(byID identifier : String, toEmail email : String, completion : @escaping (_ transferID : String?, _ transferState : String?, _ error : Error?) -> ()) {
        REST.request([String: AnyCodable].self, router: .transferArtwork(artworkID: identifier, email: email)) { (data, error) in
            if let dict = data,
               let identifier = dict["id"]?.value as? String,
               let state = dict["state"]?.value as? String {
                completion(identifier, state, nil)
            }
            else {
                completion(nil, nil, error)
            }
        }
    }
    
    /**
     Performs a request to get details about transfer request by given identifier.
     - Parameters:
        - identifier: ID of transfer.
        - completion: Response callback block.
        - item: Memory only instance of `ProtectItem` if succes otherwise `nil`.
        - error: Response error.
     */
    public static func getTransferDetail(byID identifier : String, completion : @escaping (_ item : ProtectItem?, _ error : Error?) -> ()) {
        REST.request(DTOProtectItem.self, router: .getTransferDetail(transferID: identifier)) { (data, error) in
            if let item = data?.toStorable() {
                let dict = try? data?.toDictionary()
                item.transferRequest = dict?["state"] as? String
                item.transferedFrom = (dict?["owner"] as? [String : Any])?["email"] as? String
                item.transferID = identifier
                item.authorized = true
                item.createdByID = UserManager.shared.userID
                completion(item, nil)
            }
            else {
                completion(nil, error)
            }
        }
    }
    
    /**
     Performs a request to accept transfer by given identifier.
     - Parameters:
        - identifier: ID of transfer to accept.
        - completion: Response callback block.
        - succes: `Bool` value indicating succes.
        - error: Response error.
     */
    public static func acceptTransfer(ID identifier : String, completion : @escaping (_ succes : Bool, _ error : Error?) -> ()) {
        REST.request([String: AnyCodable].self, router: .acceptTransfer(transferID: identifier)) { (data, error) in
            if let error = error {
                completion(false, error)
            }
            else {
                completion(true, nil)
            }
        }
    }
    
    /**
     Performs a request to decline transfer by given identifier.
     - Parameters:
         - identifier: ID of transfer to decline.
         - completion: Response callback block.
         - succes: `Bool` value indicating succes.
         - error: Response error.
     */
    public static func declineTransfer(ID identifier : String, completion : @escaping (_ succes : Bool, _ error : Error?) -> ()) {
        REST.request([String: AnyCodable].self, router: .declineTransfer(transferID: identifier)) { (data, error) in
            if let error = error {
                completion(false, error)
            }
            else {
                completion(true, nil)
            }
        }
    }
    
    //MARK: - Jobs
    ///Request for all remote jobs. Jobs are by default persisted in to Realm.
    public static func jobs(clearCache : Bool = false, cacheResults : Bool = true, completion : ((_ jobs : [Job], _ error : Error?) -> ())?) {
        REST.request([[String: AnyCodable]].self, router: .jobs) { (data, error) in
            guard let data = data, !data.isEmpty else {
                completion?([], error)
                return
            }
            
            var jobs = [Job]()
            defer {
                if error == nil, clearCache {
                    DispatchQueue.main.async {
                        let persistedJobs = RealmHandler.shared.getObjects(of: Job.self)
                        let removedJobs = List<Job>()
                        persistedJobs.forEach { (lclJob) in
                            if jobs.first(where: { $0.identifier == lclJob.identifier}) == nil {
                                removedJobs.append(lclJob)
                            }
                        }
                        RealmHandler.shared.remove(removedJobs)
                    }
                }
                
                if cacheResults {
                    RealmHandler.shared.add(jobs, modifiedUpdate: true)
                }
                completion?(jobs, error)
            }
            
            for jobData in data {
                if let job = Job(map: jobData) {
                    jobs.append(job)
                }
            }
        }
    }
    
    /**
    Performs a request to get job by given identifier.
    - Parameters:
        - identifier: ID of desired job.
        - completion: Response callback block.
        - job: `Job` matching given ID or nil.
        - error: Response error.
    */
    public static func job(byID identifier : String, completion : @escaping (_ job : Job?, _ error : Error?) -> ()) {
        REST.request([String: AnyCodable].self, router: .job(jobID: identifier)) { (data, error) in
            if let dict = data, let job = Job(map: dict) {
                completion(job, nil)
            }
            else {
                completion(nil, error)
            }
        }
    }
    
    public static func removeAllData(completion : @escaping (_ suuccess : Bool) -> ()) {
        REST.request([String: AnyCodable].self, router: .removeAll) { (data, error) in
            completion(error != nil)
        }
    }
    
    //MARK: - Batch Jobs
    ///Performs request to create new batch job.
    static func createNewBatchJob(completion : @escaping (_ batchJob : BatchJob?, _ error : Error?) -> ()) {
        REST.request(DTOBatchJob.self, router: .createNewBatchJob) { (data, error) in
            completion(data?.toStorable(), error)
        }
    }
    
    ///Add job to batch job
    static func addVerifyJobToBatchJob(verifyJob : ThreadSafeReference<LocalJob>, batchJobID : String, algo: String? = nil, completion : @escaping (_ jobID : String?, _ error : Error?) -> ()) {
        let realm = try! Realm(configuration: RealmHandler.shared.defaultConfig)
        guard let job = realm.resolve(verifyJob) else { completion(nil, nil); return }
        realm.refresh()
        guard let fingerprintID = job.fingerprint?.identifier, let url = Array(job.fingerprintImageUrls).first else { completion(nil, nil); return }
        
        let algo = algo ?? job.algo ?? ""
        let router = Router.addVerifyJobToBatchJob(jobID: batchJobID, queryURL: url, fingerprintID: fingerprintID, algo: algo)
        REST.request([String: AnyCodable].self, router: router) { (data, error) in
            if let dict = data, let jobID = dict["job"]?.value as? String {
                completion(jobID, nil)
            }
            else {
                completion(nil, error)
            }
        }
    }
    
    ///Perfors request to start batch job by given identifier.
    static func startBatchJob(identifier : String, completion : @escaping (_ job : Job?, _ error : Error?) -> ()) {
        REST.request([String: AnyCodable].self, router: .startBatchJob(jobID: identifier)) { (data, error) in
            guard let jobData = data else {
                completion(nil, error)
                return
            }
            
            let batchJob = Job(map: jobData)
            if let job = batchJob {
                RealmHandler.shared.add(job, modifiedUpdate: true)
            }
            completion(batchJob, error)
        }
    }
    
    //MARK: - Image Search
    typealias ImageSearchCompletion = (_ jobID : String?, _ error : Error?) -> ()
    ///Wrapper for upload operation. For more info see `imageSearch(overview:)`.
    static func imageSearch(localJob : ThreadSafeReference<LocalJob>, completion : @escaping ImageSearchCompletion) {
        let realm = try! Realm(configuration: RealmHandler.shared.defaultConfig)
        guard let job = realm.resolve(localJob) else { completion(nil, nil); return }
        realm.refresh()
        guard let overview = job.overviewImageUrl, let thumbnail = job.thumbnailImageUrl else { completion(nil, nil); return }
        imageSearch(overview: overview, thumbnail: thumbnail, completion: completion)
    }
    
    /**
     Perform a request to make image search with given urls.
     - Parameters:
         - overview: Overview image url.
         - thumbnail: Thumbnail image url.
         - completion: Response callback block.
         - jobID: Identifier of new job if success otherwise `nil`.
         - error: Response error.
     */
    static func imageSearch(overview : String, thumbnail : String, completion : @escaping (_ jobID : String?, _ error : Error?) -> ()) {
        REST.request([String: AnyCodable].self, router: .imageSearch(overview: overview, thumbnail: thumbnail)) { (data, error) in
            if let dict = data, let jobID = dict["job"]?.value as? String {
                completion(jobID, nil)
            }
            else {
                completion(nil, error)
            }
        }
    }
    
    //MARK: Image Upload
    /**
     Performs a request to get presigned image upload URL.
     
     Presigned URL expires after some time and filenames should be the same.
     
     - Parameters:
         - filename: Filename of image to upload.
         - completion: Response callback block.
         - presignedURL: Final URL for upload image.
         - error: Response error.
     */
    static func presignedImageUploadURL(forFilename filename : String, completion : @escaping (_ presignedURL : String?, _ error : Error?) -> ()) {
        REST.request([String: AnyCodable].self, router: .presignedImageUploadURL(filename: filename)) { (data, error) in
            if let json = data, let presignedURL = json["url"]?.value as? String {
                completion(presignedURL, nil)
            }
            else {
                completion(nil, error)
            }
        }
    }
    
    /**
     Performs a upload request with given image data to given presigned URL.
     - Parameters:
         - completion: Response callback block.
         - publicURL: Uploaded image new public image url if succes otherwise `nil`.
         - error: Response error.
         - progressCallback: Optional image upload progress callback block.
         - progress: Current upload progress value.
     */
    static func uploadImage(image : Data, toPresignedURL url : String, completion : @escaping (_ publicURL : String?, _ error : Error?) -> (), progressCallback : ((_ progress : Progress) -> ())?) {
        REST.uploadImage(data: image, toPresignedS3URL: url, completion: { (publicURL, error) in
            completion(publicURL, error)
        }, progressHandler: progressCallback)
    }
    
    //MARK: - Creators
    /**
     Performs a request to refresh `Creator`'s inside database.
     - Parameters:
         - completion: optional response callback block.
         - creators: `Array` of refreshed creators.
         - error: Response error.
     */
    public static func creators(completion : ((_ creators : [Creator], _ error : Error?) -> ())?) {
        REST.request([DTOCreator].self, router: .artists) { (data, error) in
            let artists = data?.map { $0.toStorable() }
            if error == nil {
                DispatchQueue.main.async {
                    let persistedCreators = RealmHandler.shared.getObjects(of: Creator.self)
                    let removedCreators = List<Creator>()
                    persistedCreators.forEach { (lclCreator) in
                        if artists?.first(where: { $0.identifier == lclCreator.identifier}) == nil {
                            removedCreators.append(lclCreator)
                        }
                    }
                    RealmHandler.shared.remove(removedCreators)
                }
            }
            
            if let artists = artists {
                RealmHandler.shared.add(artists, modifiedUpdate: true)
                completion?(artists, error)
            }
        }
    }
    
    /**
     Performs a request to create new `Creator` or get existing one.
     - Parameters:
         - firstName: Creator's first name.
         - lastName: Creator's last name.
         - completion: Response callback block.
         - creator: `Creator` object if succes otherwise `nil`.
         - error: Response error.
     */
    public static func createArtist(_ firstName : String, lastName : String, completion : @escaping (_ creator : Creator?, _ error : Error?) -> ()) {
        REST.request(DTOCreator.self, router: .createArtist(firstName: firstName, lastName: lastName)) { (data, error) in
            if let artist = data?.toStorable() {
                DispatchQueue.main.async {
                    RealmHandler.shared.add(artist, modifiedUpdate: true)
                }
                completion(artist, nil)
            }
            else {
                completion(nil, error)
            }
        }
    }
    
    public static func changeMonitoringAgreement(to agreement : Bool, completion : @escaping (_ success : Bool, _ error : Error?) -> ()) {
        guard let userID = UserManager.shared.userID else {
            debugLog("no user")
            return
        }
        
        let router = Router.changeMonitoringAgreement(agreement: agreement, userID: userID)
        REST.request([String: AnyCodable].self, router: router) { (data, error) in
            completion(error == nil, error)
        }
    }
    
    //MARK: - Custom Requests
    /**
     Performs a custom request to verify given ID by DM.
     - Parameters:
         - identifier: DM's identifier.
         - completion: Response callback block.
         - overviewUrl: Product overview image url or `nil`.
         - name: Product name or `nil`.
         - error: Response error.
     */
    public static func verify(dmid identifier : String, completion : @escaping (_ overviewUrl : String?, _ name : String?, _ error : Error?) -> ()) {
        REST.request([String: AnyCodable].self, router: .verifyDeMarchiID(dmid: identifier)) { (data, error) in
            if let product = data?["product"]?.value as? [String: Any],
               let overviewUrl = product["url"] as? String,
               let name = product["name"] as? String {
                completion(overviewUrl, name, nil)
            }
            else {
                completion(nil, nil, error)
            }
        }
    }
    
    /**
     Performs custom request to verify blockchain status.
     - Parameters:
         - dmid: DM's identifer.
         - vpID: VP's public ID.
         - hash: Hash value of fingerprint.
         - completion: Response callback block.
         - success: `Bool` value indicating succes.
         - error: Response error.
     */
    public static func verifyBlockchainCheck(forDMID dmid : String, vpID : String, hash : String, completion : @escaping (_ success : Bool, _ error : Error?) -> ()) {
        let router = Router.verifyDeMarchiBlockchainCheck(dmid: dmid, vpid: vpID, hash: hash)
        REST.request([String: AnyCodable].self, router: router) { (data, error) in
            if error == nil {
                completion(true, nil)
            }
            else {
                completion(false, error)
            }
        }
    }
}

