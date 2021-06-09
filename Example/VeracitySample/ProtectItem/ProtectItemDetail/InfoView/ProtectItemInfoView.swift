//
//  MyItemInfoView.swift
//  Veracity Authenticator
//
//  Created by Minh Chu on 1/27/21.
//  Copyright © 2021 ONEPROVE s.r.o. All rights reserved.
//

import UIKit
import SDWebImage
import VeracitySDK

class ProtectItemInfoView: UIView {
    @IBOutlet var contentView: UIView!
    @IBOutlet weak var stackView: UIStackView!
    
    @IBOutlet weak var messageView: UIView!
    @IBOutlet weak var messageTitleLabel: UILabel!
    @IBOutlet weak var messageDescLabel: UILabel!
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var itemImageView: UIImageView!
    @IBOutlet weak var dimensionLabel: UILabel!
    @IBOutlet weak var dateView: UIView!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var publicIDLabel: UILabel!
    @IBOutlet weak var publicIDView: UIView!
    
    private var downloadToken : SDWebImageDownloadToken?
    private var item: VeracityItem?
    
    init() {
        super.init(frame: .zero)
        self.setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.setup()
    }
    
    func setItemData(_ item: VeracityItem) {
        self.item = item
        nameLabel.text = item.itemName
        if let _ = item as? LocalProtectItem {
            loadThumbnailFromDisk()
        } else {
            loadThumbnail(item.thumbImageUrl)
        }
        
        setProtectDate(item)
        setItemDimensionUnit(item)
        setItemState(item.state, item: item)
    }
    
    private func setProtectDate(_ item: VeracityItem) {
        guard let state = item.state, state == .protected else {
            dateView.isHidden = true
            return
        }
        
        dateLabel.text = item.createdString
    }
    
    private func setItemDimensionUnit(_ item: VeracityItem) {
        let publicID = (item as? ProtectItem)?.publicID
        let width = (item as? ProtectItem)?.width ?? (item as? LocalProtectItem)?.width.value ?? 0
        let height = (item as? ProtectItem)?.height ?? (item as? LocalProtectItem)?.height.value ?? 0
        publicIDLabel.text = publicID
        if UserManager.shared.user?.metricalUnits ?? true {
            dimensionLabel.text = "\(width) x \(height) \(Text.cm.localizedText.lowercased())"
        } else {
            let lclHeiht = Measurement(value: height, unit: UnitLength.centimeters)
            let lclWidth = Measurement(value: width, unit: UnitLength.centimeters)
            
            let inchHeight = lclHeiht.converted(to: UnitLength.inches).value
            let inchWidth = lclWidth.converted(to: UnitLength.inches).value
            
            let heightVal = String(format: "%.1f", inchHeight)
            let widthVal = String(format: "%.1f", inchWidth)
            dimensionLabel.text = "\(widthVal) x \(heightVal) \(Text.in.localizedText.lowercased())"
        }
    }
    
    private func setItemState(_ state: ItemState?, item: VeracityItem) {
        guard let state = state else {
            messageView.isHidden = true
            return
        }
        
        messageView.isHidden = false
        messageTitleLabel.textColor = state.textColor
        messageDescLabel.textColor = state.textColor
        messageView.backgroundColor = state.backgroudColor
        
        switch state {
        case .failed:
            messageTitleLabel.text = "Unable to protect item"
            messageDescLabel.text = (item as? ProtectItem)?.errorMessage
        case .uploading:
            messageTitleLabel.text = "Uploading..."
            messageDescLabel.text = "The photos are now being uploaded to our servers."
            observerUploadingProcess()
        case .pending:
            messageTitleLabel.text = "Pending"
            messageDescLabel.text = "Waiting until upload of the other item is finished."
        case .analyzing:
            messageTitleLabel.text = "Analyzing..."
            messageDescLabel.text = "You'll be notified once the system is done analyzing the photos."
        default:
            messageView.isHidden = true
        }
    }
    
    private func setup() {
        Bundle.main.loadNibNamed("ProtectItemInfoView", owner: self, options: nil)
        addSubview(contentView)
        
        contentView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }
    
    private func loadThumbnail(_ urlString : String?) {
        guard let urlString = urlString, let url = URL(string: urlString) else {
            return
        }
        
        if let thumnailData = SDImageCache.shared.diskImageData(forKey: url.absoluteString), let cacheThumbail = UIImage(data: thumnailData) {
            itemImageView.image = cacheThumbail
        }
        else {
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                self?.downloadToken = SDWebImageDownloader.shared.downloadImage(with: url, options: .continueInBackground, progress: nil, completed: { [weak self] (image, data, error, complete) in
        
                    guard let strongSelf = self else {
                        return
                    }
                    
                    if complete, let image = image {
                        DispatchQueue.main.async {
                            UIView.transition(with: strongSelf.itemImageView, duration: 0.2, options: .transitionCrossDissolve, animations: {
                                strongSelf.itemImageView.image = image
                                SDImageCache.shared.storeImageData(toDisk: data, forKey: url.absoluteString)
                            }, completion: { succes in
                                //TODO: remove
                            })
                        }
                    }
                })
            }
        }
    }
    
    private func loadThumbnailFromDisk() {
        guard
            let item = self.item as? LocalProtectItem,
            let path = item.thumbnailImageFilename, !path.isEmpty,
            let image = ImagePersistence.imageAtDiskPath(path: path)
        else {
            itemImageView.image = nil
            return
        }
        
        itemImageView.image = image
    }
    
    private func observerUploadingProcess() {
        if let lastKnownProgress = UploadManager.shared.lastKnownUploadProgressValue {
            self.setStateUploadingProcess(lastKnownProgress)
        }
        
        UploadManager.shared.currentUploadProgressCallBack = { [weak self] (progress, identifier) in
            DispatchQueue.main.async {
                self?.setStateUploadingProcess(progress)
            }
        }
    }
    
    private func setStateUploadingProcess(_ process: Int) {
        messageTitleLabel.attributedText = NSAttributedString(string: "Uploading \(process)%",
                                                       attributes: [.kern : 1.25])
    }
}
