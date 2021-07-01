//
//  REST.swift
//  VeracitySDK
//
//  Created by Andrew on 16/04/2019.
//  Copyright © 2019 Veracity Protocol s.r.o. All rights reserved.
//

import Foundation
import Alamofire

enum HTTPMethod: String {
    case POST
    case GET
    case DELETE
    case PUT
}

enum Router {
    //Authentication
    case login(email : String, password : String)
    case register(email : String, password : String)
    case reauthenticate
    case resendActivationLink(email : String)
    case activateAccount(token : String, email : String)
    case myAccount
    //Password
    case resetPassword(email : String)
    case resetPasswordTokenCheck(token : String)
    case setNewPassword(password : String, resetToken : String)
    //Artists
    case artists
    case createArtist(firstName : String, lastName : String)
    //Artworks
    case myArtworks
    case publicArtworkByID(publicID : String)
    case searchResultsByIDs(artworkIDs : [String])
    case createArtwork(artistID : String, name : String, year : Int, width : Double, height : Double, metadata : String?)
    case addArtworkOverview(artworkID : String, overview : String, thumbnail : String)
    case removeArtwork(artworkID : String)
    case searchResultsByMetadata(json : String)
    //Transfers
    case emailPassport(artworkID : String)
    case transferArtwork(artworkID : String, email : String)
    case getTransferDetail(transferID: String)
    case acceptTransfer(transferID: String)
    case declineTransfer(transferID: String)
    //Fingerprints
    case addArtworkFingerprints(artworkID : String, images : [String], xLocation : Int, yLocation : Int, widthlocation : Int, heightLocation : Int, algo : String?)
    case artworkFingerprints(artworkID : String)
    case verifyFingerprint(url : String, fingerprintID : String, algo : String?, expectedResult : String?, webhookUrl : String?, metadata : String?)
    //Jobs
    case jobs
    case job(jobID : String)
    case removeAll
    //Batch Jobs
    case createNewBatchJob
    case addVerifyJobToBatchJob(jobID : String, queryURL : String, fingerprintID : String, algo: String)
    case startBatchJob(jobID : String)
    //Image Search
    case imageSearch(overview : String, thumbnail : String)
    //Image Upload
    case presignedImageUploadURL(filename : String)
    //Device
    case updateDevice(uuid: String, model: String, version: String, name: String, token: String?)
    case removeDevice(uuid: String)
    //Analytics
    case changeMonitoringAgreement(agreement : Bool, userID : String = "jkjk")
    //Credits
    case credits
    case creditsCharge(invoice : String, signature : String, credits : UInt)
    //Custom
    case verifyDeMarchiID(dmid : String)
    case verifyDeMarchiBlockchainCheck(dmid : String, vpid : String, hash : String)
    
    // MARK: Request Properties
    var path: String {
        switch self {
        // Authentication
        case .login: return "/login"
        case .register: return "/registerUser"
        case .reauthenticate: return "/reauthenticate"
        case .resendActivationLink(_): return "/resendlink"
        case .activateAccount(_, _): return "/activateaccount"
        case .myAccount: return "/users/me"
        case .removeAll: return "/artworks/all"
        case .resetPassword(_): return "/reset"
        case .resetPasswordTokenCheck: return "/resetTokenCheck"
        case .setNewPassword: return "/change"
        case .artists: return "/myartists"
        case .createArtist(_, _): return "/artists"
        case .myArtworks: return "/users/me/artworks"
        case .publicArtworkByID(let publicID): return "/artworks/\(publicID)"
        case .searchResultsByIDs(_): return "/artworks/query"
        case .createArtwork(let artistID, _, _, _, _, _): return "/artists/\(artistID)/artworks"
        case .addArtworkOverview(let artworkID, _, _): return "/artworks/\(artworkID)/overview"
        case .removeArtwork(let artworkID): return "/artworks/\(artworkID)"
        case .searchResultsByMetadata(_): return "/artworks/searchByMeta"
        case .emailPassport(let artworkID): return "/artworks/\(artworkID)/email"
        case .transferArtwork(_, _): return "/transfers"
        case .getTransferDetail(let transferID): return "/transfers/\(transferID)"
        case .acceptTransfer(_): return "/transfers/accept"
        case .declineTransfer(_): return "/transfers/refuse"
        case .addArtworkFingerprints(let artworkID, _, _, _, _, _, _): return "/artworks/\(artworkID)/fingerprints"
        case .artworkFingerprints(let artworkID): return "/artworks/\(artworkID)/fingerprints"
        case .verifyFingerprint(_, let fingerprintID, _, _, _, _): return "/fingerprints/\(fingerprintID)/verify"
        case .jobs: return "/jobs"
        case .job(let jobID): return "/jobs/\(jobID)"
        case .createNewBatchJob: return "/verifications/batchVerify"
        case .addVerifyJobToBatchJob(_, _, _, _): return "/verifications/batchVerify"
        case .startBatchJob(_): return "/verifications/batchVerify/start"
        case .imageSearch(_, _): return "/artworks/search"
        case .presignedImageUploadURL(_): return "/artworks/s3_url"
        case .updateDevice(_, _, _, _, _): return "/devices"
        case .removeDevice(_): return "/removeDevice"
        case .changeMonitoringAgreement(_, let userID): return "/users/\(userID)/changemonitoring"
        case .credits: return "/credits"
        case .creditsCharge(_, _, _) : return "/credits/charge"
        case .verifyDeMarchiID(_): return "/fabric"
        case .verifyDeMarchiBlockchainCheck(_, _, _): return "/fabric"
        }
    }
    
    var method: HTTPMethod {
        switch self {
        case .login, .register, .searchResultsByIDs(_),
             .createArtist(_, _), .createArtwork(_),
             .addArtworkOverview(_), .addArtworkFingerprints(_),
             .verifyFingerprint(_, _, _, _, _, _), .imageSearch(_, _),
             .updateDevice(_, _, _, _, _), .removeDevice(_),
             .creditsCharge(_, _, _), .resetPassword(_),
             .transferArtwork(_, _), .emailPassport(_),
             .resetPasswordTokenCheck(_), .setNewPassword(_, _),
             .acceptTransfer(_), .declineTransfer(_),
             .presignedImageUploadURL(_), .searchResultsByMetadata(_),
             .activateAccount(_, _), .resendActivationLink(_),
             .createNewBatchJob, .startBatchJob(_),
             .changeMonitoringAgreement(_, _):
            return .POST
        case .removeArtwork(_), .removeAll:
            return .DELETE
        case .addVerifyJobToBatchJob(_, _, _, _):
            return .PUT
        default: return .GET
        }
    }
    
    var parameters: [String : Any]? {
        switch self {
        case let .login(email, password):
            return ["email":email, "password":password]
        case let .register(email, password):
            return ["email":email, "password":password]
        case let .resendActivationLink(email: email):
            return ["email" : email]
        case let .activateAccount(token: token, email: email):
            return ["token" : token, "email" : email]
        case let .resetPassword(email):
            return ["email" : email]
        case let .resetPasswordTokenCheck(token):
            return ["resetToken" : token]
        case let .setNewPassword(password, resetToken):
            return ["newPassword" : password, "resetToken" : resetToken]
        case let .searchResultsByIDs(artworkIDs: ids):
            return ["ids" : ids]
        case let .createArtist(firstName: first, lastName: last):
            return ["firstName" : first, "lastName" : last]
        case let .createArtwork(_, name: name, year: year, width: width, height: height, metadata: metadata):
            var dict = ["name" : name, "year" : year, "width" : width, "height" : height] as [String : Any]
            if let metadataValue = metadata { dict.updateValue(metadataValue, forKey: "meta") }
            if let webhookUrl = VeracitySDK.configuration.type.webhookUrl { dict.updateValue(webhookUrl, forKey: "webhookUrl") }
            return dict
        case let .addArtworkOverview(_, overview: overview, thumbnail: thumbnail):
            var dict = ["overviewUrl" : overview, "thumbnailUrl" : thumbnail]
            if VeracitySDK.configuration.type.celeryBackend {
                dict.updateValue("celery", forKey: "queue")
            }
            return dict
        case let .addArtworkFingerprints(_, images: fingerprints, xLocation: x, yLocation: y, widthlocation: width, heightLocation: height, algo : protectAlgo):
            var dict : [String : Any] = ["image1" : fingerprints[0], "image2" : fingerprints[1], "name" : "FP", "location" : ["x" : x, "y" : y, "width" : width, "height" : height]]
            if VeracitySDK.configuration.type.celeryBackend {
                dict.updateValue("celery", forKey: "queue")
            }
            if let algo = protectAlgo {
                dict.updateValue(algo, forKey: "algo")
            }
            return dict
        case let .searchResultsByMetadata(json):
            return ["meta" : json]
        case let .verifyFingerprint(url: urlString, _, algo: algo, expectedResult: expectedResult, webhookUrl: webhookUrl, metadata: metadata):
            var dict = ["queryUrl" : urlString]
            if VeracitySDK.configuration.type.celeryBackend {
                dict.updateValue("celery", forKey: "queue")
            }
            if let algo = algo {
                warningLog("using algo: \(algo)")
                dict.updateValue(algo, forKey: "algo")
            }
            if let expectedJobResult = expectedResult {
                dict.updateValue(expectedJobResult, forKey: "expectedResult")
            }
            if let webhookUrl = webhookUrl {
                dict.updateValue(webhookUrl, forKey: "webhookUrl")
            }
            if let metadataValue = metadata {
                dict.updateValue(metadataValue, forKey: "meta")
            }
            return dict
        case let .imageSearch(overview: overview, thumbnail: thumbnail):
            var dict = ["queryImageUrl" : overview, "queryImageUrlThumbnail" : thumbnail]
            if VeracitySDK.configuration.type.celeryBackend {
                dict.updateValue("celery", forKey: "queue")
            }
            return dict
        case let .presignedImageUploadURL(filename):
            return ["filename" : filename]
        case let .updateDevice(uuid, model, version, name, token):
            var body = ["uuid":uuid, "type": model, "osVersion":version, "name": name, "notification_service" : "firebase"]
            if let token = token {
                body["token"] = token
            }
            if let applicationIdentifier = Bundle.main.bundleIdentifier {
                body["application"] = applicationIdentifier
            }
            return body
        case let .removeDevice(uuid):
            return ["uuid" : uuid]
        case let .changeMonitoringAgreement(agreement, _):
            return ["monitoringAgreement" : agreement]
        case let .creditsCharge(invoiceData, signature, credits):
            return ["data" : invoiceData, "signature" : signature, "credits" : credits, "type" : "ios"]
        case let .transferArtwork(artworkID, email):
            return ["artwork_id" : artworkID, "email" : email]
        case let .acceptTransfer(transferID):
            return ["request_code" : transferID]
        case let .declineTransfer(transferID):
            return ["request_code" : transferID]
        case let .startBatchJob(jobID):
            return ["jobId" : jobID]
        case let .addVerifyJobToBatchJob(jobID, queryURL, fingerprintID, algo):
            return ["jobId" : jobID,
                    "queryUrl" : queryURL,
                    "fingerprintId" : fingerprintID,
                    "algo": algo]
        case .publicArtworkByID(_):
            return ["public": true]
            
        case .verifyDeMarchiID(let dmid):
            return ["cmd": "veracityInfo",
                    "dmid": dmid]
            
        case .verifyDeMarchiBlockchainCheck(let dmid, let vpid, let hash):
            return ["cmd": "veracityCheck",
                    "dmid": dmid,
                    "vpid": vpid,
                    "phash": hash]
            
        default: return nil
        }
    }
    
    var customBaseEndpoint : String? {
        switch self {
        case .verifyDeMarchiID(_), .verifyDeMarchiBlockchainCheck(_, _, _):
            return "demarchi-blockstar.com"
        default:
            return nil
        }
    }
}

// MARK: -
class REST {
    ///PUT image data to given presigned URL.
    static func uploadImage(data : Data, toPresignedS3URL url : String, completion : @escaping (_ publicURL: String?, _ error: Error?) -> (), progressHandler : ((_ progress : Progress) -> ())?) {
        AF.upload(data, to: url, method: .put, headers: ["Content-Type" : "image/png"]).responseData { response in
            guard let uploadResponse = response.response else { completion(nil, response.error); return }
            
            guard uploadResponse.statusCode == 200, let publicUrl = url.components(separatedBy: "?").first else { completion(nil, response.error); return }
            
            completion(publicUrl, nil)
            }.uploadProgress { (progress) in
                progressHandler?(progress)
        }
    }
    
    private static func configuration(router: Router) -> APIRequest {
        let host = router.customBaseEndpoint ?? VeracitySDK.configuration.type.endpoint
        let path = router.customBaseEndpoint != nil ? router.path : "/api\(router.path)"
        let headers = { () -> [String : String] in
            var headers = [String: String]()
            headers["Content-Type"] = "application/json"
            
            if router.customBaseEndpoint == nil, let token = UserManager.shared.token {
                headers["Authorization"] = "Bearer \(token)"
            }
            
            if let appHeaderValue = VeracitySDK.configuration.type.applicationHeaderValue {
                headers["Application"] = appHeaderValue
            }
            return headers
        }
        APIConfiguration.current = APIConfiguration(host: host, headers: headers)
        
        var request = APIRequest(router.method.rawValue, path: path)
        if let params = router.parameters {
            if router.method == .GET {
                params.forEach({ (data) in
                    request = request.with(name: data.key, value: "\(data.value)")
                })
            } else {
                request = request.with(body: params)
            }
        }
        
        return request
    }
    
    static func request<T>(_ type: T.Type, router: Router, completionHandler: @escaping (_ data: T?, _ error: Error?) -> ()) where T: Decodable {
        let request = REST.configuration(router: router)
        request.execute(type) { (data, error, status) in
            if let d = data {
                DispatchQueue.main.async {
                    completionHandler(d, nil)
                }
            }
            else if let e = error {
                REST.handleError(error: e, statusCode: status.rawValue, type: type, router: router, completionHandler: completionHandler)
                debugLog(e)
            }
            else {
                DispatchQueue.main.async {
                    completionHandler(nil, nil)
                }
            }
        }
    }
    
    private static func handleError<T>(error: DTOError?, statusCode: Int, type: T.Type, router: Router, completionHandler: @escaping (_ data: T?, _ error: Error?) -> ()) where T: Decodable {
    
        let errorType = VPErrorCode(rawValue: error?.type ?? "")
        switch errorType {
        case .expiredToken:
            /// Token is expired
            /// 1. Refresh new one
            /// 2. Retry current request
            REST.refreshToken(completion: { data, err in
                if let dict = data, let token = dict["token"] {
                    UserManager.shared.update(token: token)
                    REST.request(type, router: router, completionHandler: completionHandler)
                } else {
                    DispatchQueue.main.async {
                        completionHandler(nil, err)
                    }
                }
            })
            
        case .reauthenticateUser:
            let error = VPError(errorMessage: error?.message, code: statusCode)
            DispatchQueue.main.async {
                UserManager.shared.logout()
                completionHandler(nil, error)
//                UserManager.shared.userNeedsToBeReauthenticateCallback?()
            }
            
        default:
            let error = VPError(errorMessage: error?.message, code: statusCode)
            DispatchQueue.main.async {
                completionHandler(nil, error)
            }
        }
    }
}

fileprivate extension REST {
    static func refreshToken(completion: @escaping (_ data: [String: String]?, _ error: Error?) -> ()) {
        REST.request([String: String].self, router: .reauthenticate, completionHandler: completion)
    }
}
