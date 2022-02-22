# iOS VeracitySDK

Veracity SDK covers almost all the heavy work for the Veracity Apps. It can provide, persist and upload data, make API requests, and more.

## Table of Contents  
1. [Run Example App](#Example)  
2. [Instalation](#Instalation)  
3. [SDK Configuration](#Configuration)  
4. [API Token](#API_Token)
5. [API data](#API_data)
    1. [Verifications](#Verifications)
    2. [Protections](#Protections)
6. [Crop](#Crop)
    1. [Initial](#Initial) 
    2. [Usage](#Usage)
7. [Input data](#Input_data)
    1. [Taken images](#Taken_images) 
    2. [Verification](#Verification)
    3. [Protection](#Protection)
8. [Upload](#Upload)
9. [Events & Database change](#Events_Database_change)
    1. [Example Local Jobs](#Example_Local_Jobs) 
    2. [Example Local Protect](#Example_Local_Protect)
10. [Item State](#Item_State)
11. [Notifications](#Notifications)
12. [Example Explain](#Example_Explain)
    1. [Example Protect Item](#Example_protect_item)
    2. [Example Verify Item](#Example_verify_item)


<a name="Example"></a>
### 1. Run Example App
Run `pod instal` on example app folder and run....


<a name="Instalation"></a>
### 2. Instalation
Before run ```pod install``` make sure install ```git-lfs``` tools. Run this commands to install:
```
brew install git-lfs
git lfs install
```


pod 'VeracitySDK', :git => 'https://github.com/oneprove/ios-public-sdk.git'
```

Usage
```import VeracitySDK```

<a name="Configuration"></a>
### 3. SDK Configuration
VeracitySDK works with predefined server side configuration config. You can change this config when app is launching.
```swift
// Use predefined config.
VeracitySDK.configuration.type = .luxuryGoods


// Or use of custom config.
VeracitySDK.configuration.type = .custom(endpoint: "https://api.com/api", webhookUrl: "https://webhookURL.com/fabric?cmd=veracity")
```

<a name="API_Token"></a>
### 4. API Token
Veracity SDK works only with a logged-in user. Therefore, you need to allow the user to register and log in.
```swift
// Login.
NetworkClient.login(email: "loginEmail", password: "password") { (success, error) in
    if success {
        debugLog("user was logged")
    }else {
        debugLog(error?.localizedDescription)
    }
}
```

<a name="API_data"></a>
### 5. API data
Allows you to download data from our database. API includes automatic download, caching and data parsing.

<a name="Verifications"></a>
#### 1. Verifications
To get or refresh verification data.
```swift
NetworkClient.jobs { (jobs, error) in
    debugLog(jobs.count)
}
```

or use `JobsReloadOperation`.

```swift
let operationQueue = OperationQueue()
let jobOP = JobsReloadOperation()
operationQueue.addOperation(jobOP)
```

<a name="Protections"></a>
#### 2. Protections:
To get or refresh protect data.
```swift
NetworkClient.myProtectedItems { (items, error) in
    debugLog(items.count)
}
```

or use `ProtectItemsReloadOperation`.
```swift
let operationQueue = OperationQueue()
let protectItemsOP = ProtectItemsReloadOperation()
operationQueue.addOperation(protectItemsOP)
```

<a name="Crop"></a>
### 6. Crop
Crop feature is presented as `UIView` subclass called `CropView`.

<a name="Initial"></a>
#### 1. Initial
```swift
// CropView can be used as reference from storyboard.
@IBOutlet weak var cropView: CropView!
// You'll need to add overview image as source image.
cropView.sourceImage = UIImage(named: "overview_image_0")!


// Or direcly.
var cropView = CropView(sourceImage: UIImage(named: "overview_image_0")!)
```

<a name="Usage"></a>
#### 2. Usage
Detect edges
```swift
// After viewDidLoad you have to call `detectEdges` func for full functionality.
cropView.detectEdges()
```

Croping
```swift
// Croped image is obtained by given callback completion block.
cropView.crop { (image) in
    // process croped image here.
}
```


<a name="Input_data"></a>
### 7. Input data
<a name="Taken_images"></a>
#### 1. Taken images
Any taken image can be persisted and obtained by `ImagePersistenceManager`.
```swift
// Create data from taken image you wan't to persist.
let imageData = takenImage.pngData()
// Persist image data and get filename.
let imageFilename = try? ImagePersistence.saveImageToDisk(imageData: imageData, asJPEG: false)
```

```swift
// Obtain persisted image or data by filename.
let image = ImagePersistence.imageAtDiskPath(path: "file_image_name")
let imageData = ImagePersistence.imageDataAtDiskPath(path: "file_image_name")
```

<a name="Verification"></a>
#### 2. Verification
To create new verification of item, create new `LocalJob` with `.verification` and type item you wan't to verify, then append fingerprint filename a persist to database.
```swift
// Create new verification job with item agains you wan't to verify taken fingerprint images.
let newVerification = LocalJob(type: .verification, item: verifingItem)
// Append fingerprint.
protectItem.fingerprintImageFilenames.append(fingerprintImageLocalPath)
protectItem.fingerprintImageFilenamesCount += 1
// Save to database.
RealmHandler.shared.add(newVerification, modifiedUpdate: true)
// Upload start.
```


<a name="Protection"></a>
#### 3. Protection
To create new protection, create and fill `LocalProtectItem` and persist to database.
```swift
// Create new protect item.
let newProtect = LocalProtectItem()
newProtect.overviewImageFilename = "overview_filename"
newProtect.thumbnailImageFilename = "thumbnail_filename"
newProtect.width.value = 20
newProtect.height.value = 30
newProtect.name = "Item's name"
newProtect.year.value = 2019
newProtect.artist = Creator(firstName: "First", lastName: "Last")
newProtect.fingerprintLocation = FingerprintLocation(rect: CGRect(x: 20, y: 20, width: 300, height: 500))
newProtect.appendFingerprintFilename("fingerprintImageFilename1")
newProtect.appendFingerprintFilename("fingerprintImageFilename2")
// Upload start.
RealmHandler.shared.add(newProtect, modifiedUpdate: true)
```

<a name="Upload"></a>
### 8. Upload
Upload is handled automatically by the `UploadManager`. Local item upload starts when there are filled all the required properties. All you need to do is setup the manager observing after app launch.
```swift
UploadManager.shared.startObserving()
```

<a name="Events_Database_change"></a>
### 9. Events & Database change
Events are now provided only by observing for a database change on one item, or whole array of items, as a `Realm` feature.
To observe a database change for any internal object stored in, simply get data by `RealmHandler.shared.getObjects(ofType:)` and create a notification token by `observe(changes:)` to setup observing.

Don't forget to `import RealmSwift`.

<a name="Example_Local_Jobs"></a>
#### 1. Example Local Jobs
Example how to setup changes observing on filtered local jobs data.
```swift
var observingToken : NotificationToken?
var verifications : Results<Job>?

// Get filtered & sorted LocalJobs data.
verifications = RealmHandler.shared.getObjects(of: LocalJob.self).filter("jobName == verify OR jobName == overviewSearch").sorted(byKeyPath: "createdAt", ascending: false)
observingToken = verifications?.observe({ [weak self] (changes) in
    guard let tableView = self?.tableView else { return }
    switch changes {
    case .initial:
        // First stage, data are loaded.
    case .update(_, let deletions, let insertions, let modifications):
        // Something has changed. There are passed arrays of indexes of items that were changed somehow. 
    case .error(let error):
        // Something went wrong.
        debugLog("error: \(error)")
    }
    // Reload table view data every change.
    tableView.reloadData()
}

// When obseving is not needed anymore.
observingToken?.invalidate()
```

<a name="Example_Local_Protect"></a>
#### 2. Example Local Protect
Example of how to setup changes observing on filtered local protectItems data.
```swift
var observingToken : NotificationToken?
var protectItems : Results<LocalProtectItem>?

// Get sorted protectItems data.
protectItems = RealmHandler.shared.getObjects(of: LocalProtectItem.self).sorted(byKeyPath: "createdAt", ascending: false)
observingToken = protectItems?.observe({ [weak self] (changes) in
    guard let tableView = self?.tableView else { return }
    switch changes {
    case .initial:
        // First stage, data are loaded.
        print("Initial")
    case .update(let updates, let deletions, let insertions, let modifications):
        if !updates.isEmpty {
            updates.forEach { item in
                self?.handleItemState(item.state)
            }
        } 
    case .error(let error):
        // Something went wrong.
        print("error: \(error)")
    }
}

// When obseving is not needed anymore.
observingToken?.invalidate()
```

<a name="Item_State"></a>
### 10. Item State
We can check Item status by using this property

```var state: ItemState?``` 

in

```protocol VeracityItem```

Example of how to check item state event. After receive item data change in above step (```Events & Database change```), call this func to check item's state
```swift
func handleItemState(_ state: ItemState?) {
    switch state {
    case .failed, .doesntMatch:
        // Item protect or verify failed
    case .uploading:
        // Item is uploading
    case .analyzing:
        // Item is analyzing
    case .protected:
        // Item is protected
    case .pending:
        // Item is pending to protect or verify
    }
}
```

<a name="Notifications"></a>
### 11. Notifications
By default, notification are serviced by Firebase. To setup the Firebase notifications follow up [official tutorial](https://firebase.google.com/docs/ios/setup).

To request user access to notifications.
```swift
NotificationManager.shared.requestAccess()
```

To register notification token, pass token every app launch / login & token change to `NotificationManager`. 
```swift
func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    if let fcmToken = Messaging.messaging().fcmToken {
        NotificationManager.shared.didRegisterForFirebaseNotifications(withToken: fcmToken)
    }
}

// Messaging delegate method to get updated token.
func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String) {
    NotificationManager.shared.didRegisterForFirebaseNotifications(withToken: fcmToken)
}
```
And to process received notification, pass it's payload to `NotificationManager`.
```swift
NotificationManager.shared.processReceivedNotification(userInfo: ["key" : "value"])
```


<a name="Example_Explain"></a>
### 12.Example Explain

In example app there is simple way to take protection and verification fingerprints.

<a name="Example_protect_item"></a>
#### 1. Example Protect Item

Start simple protect item flow
```swift
let createItemStream = ProtectItemStreamImpl()

/// Replace your item info before start take fingerprint
createItemStream.update(itemName: "<item_name>")
createItemStream.update(dimension: <your_item_dimension>)
createItemStream.update(croppedPhoto: <your_item_cropped_image>)
createItemStream.update(algo: <your_algo>)
createItemStream.observerItemStateChange { state in
    // Handle item state change (see 10. Item State)
}

/// Set your takefinger type (.default or .overlay)
/// Overlay only show if dimension > (7.5x10)
createItemStream.changeTakeFingerprintType(<your type>)

/// Start take fingerprints
let vc = TakeFingerprintViewController(createItemStream: createItemStream)

/// Assign delegate to listener fingers taken
vc.delegate = self

self.present(vc, animated: true, completion: nil)
```

Implement ```TakeFingerprintViewControllerDelegate``` to handle fingers are taken
```swift
func onTakenFingerprint(_ fingers: [(blurScore: Float, image: UIImage)]) {
    // TODO something with fingerprints were taken
    
    /// Protect item
    createItemStream.addMore(fingerPhotos: fingers)
    createItemStream.processProtectItem()
}
```
    
<a name="Example_verify_item"></a>
#### 2. Example Verify Item

Make sure exist a ```ProtectItem``` before we can start take finger to verify

```swift
let verifyItemStream = VerifyItemStreamImpl()

/// Replace your item that you would like to verify
verifyItemStream.updateItemToVerify(<item_to_verify>)
verifyItemStream.observerItemStateChange { state in
    // handle item's state change here
}

/// Set your takefinger type (.default or .overlay)
self.verifyItemStream.changeTakeFingerprintType(<type>)
self.verifyItemStream.updateOverlayPhoto(<overlay photo>)
            
/// Start ```TakeFingerprintViewController``` to take fingerprints 
let vc = TakeFingerprintViewController(verifyItemStream: verifyItemStream)

/// Assign delegate to listener fingers taken
vc.delegate = self

self.present(vc, animated: true, completion: nil)
```

Implement ```TakeFingerprintViewControllerDelegate``` to handle fingers are taken
```swift
func onTakenFingerprint(_ fingers: [(blurScore: Float, image: UIImage)]) {
    // TODO: Start verify item with fingerprints were taken
    
    verifyItemStream.updateFingers(fingers)
    verifyItemStream.processVerifyItem()
}
```

