//
//  MyItemInfoView.swift
//  Veracity Authenticator
//
//  Created by Minh Chu on 1/27/21.
//  Copyright © 2021 ONEPROVE s.r.o. All rights reserved.
//

import UIKit
import SDWebImage


class VerifyItemInfoView: UIView {
    @IBOutlet var contentView: UIView!
    
    @IBOutlet weak var messageView: UIView!
    @IBOutlet weak var animationView: UIView!
    @IBOutlet weak var iconWidth: NSLayoutConstraint!
    @IBOutlet weak var iconLeading: NSLayoutConstraint!
    @IBOutlet weak var messageTitleLabel: UILabel!
    @IBOutlet weak var messageDescLabel: UILabel!
    
    @IBOutlet weak var itemImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var dateCreateLabel: UILabel!
    @IBOutlet weak var publicIDLabel: UILabel!
    @IBOutlet weak var publicIdView: UIView!
    @IBOutlet weak var verifyDateLabel: UILabel!
    
    
    private var downloadToken : SDWebImageDownloadToken?
    
    init() {
        super.init(frame: .zero)
        self.setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.setup()
    }
    
    func setItemData(_ item: VeracityItem) {
        if (item as? LocalJob)?.isInvalidated == true {
            return
        }
        nameLabel.text = item.itemName
        loadThumbnail(item.thumbImageUrl)
        
        setProtectDate(item)
        setItemState(item.state, item: item)
        let publicId = (item as? Job)?.artwork?.publicID
        publicIDLabel.text = publicId
        publicIdView.isHidden = publicId == nil
    }
    
    private func setProtectDate(_ item: VeracityItem) {
        verifyDateLabel.text = [item.createdString ?? "", item.hourString ?? ""].filter { !$0.isEmpty }.joined(separator: ", ")
        dateCreateLabel.text = (item as? Job)?.artwork?.createdString ?? (item as? LocalJob)?.anyArtwork?.createdString
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
        animationView.isHidden = state != .analyzing
        switch state {
        case .failed, .doesntMatch:
            messageTitleLabel.text = "Not Verified"
            messageDescLabel.text = (item as? Job)?.artwork?.errorMessage ?? (item as? LocalJob)?.anyArtwork?.errorMessage ?? "Item doesn't match the original."
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
        case .verified:
            messageTitleLabel.text = "Verified as Authentic"
            messageDescLabel.text = "Scanned Item matches the original."
        case .incomplete:
            messageTitleLabel.text = "Can’t be told"
            messageDescLabel.text = "The system cannot provide a reliable verification result as the taken photo is of a low quality. Please try again."
        default:
            messageTitleLabel.text = nil
            messageDescLabel.text = nil
            break
        }
    }
    
    private func setup() {
        let bundle = Bundle(for: VerifyItemInfoView.self)
        bundle.loadNibNamed("VerifyItemInfoView", owner: self, options: nil)
        addSubview(contentView)
        
        contentView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }
    
    private func loadThumbnail(_ urlString : String?) {
        guard let urlString = urlString, let url = URL(string: urlString) else {
            itemImageView.image = nil
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
    
    private func observerUploadingProcess() {
        if let lastKnownProgress = UploadManager.shared.lastKnownUploadProgressValue {
            self.setStateUploadingProcess(lastKnownProgress)
        }
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(uploadProcessCallback(_:)),
                                               name: NotificationsNames.uploadItemProcess,
                                               object: nil)
    }
    
    private func setStateUploadingProcess(_ process: Int) {
        messageTitleLabel.attributedText = NSAttributedString(string: "Uploading \(process)%",
                                                       attributes: [.kern : 1.25])
    }
    
    @objc func uploadProcessCallback(_ notification: NSNotification) {
        guard let data = notification.object as? (process: Int, identifier: String?) else {
            return
        }
        
        let progress = data.process
        self.setStateUploadingProcess(progress)
    }
}
