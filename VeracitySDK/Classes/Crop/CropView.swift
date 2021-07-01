//
//  CropView.swift
//  VeracitySDK
//
//  Created by Andrew on 01/08/2019.
//  Copyright © 2019 Veracity Protocol s.r.o. All rights reserved.
//

import UIKit
import SnapKit

///Default callback completion to handle cropped image.
public typealias CroppedImageCallbackCompletion = (_ croppedImage : UIImage, _ points : [CGPoint]) -> ()

///Main component to handle crop feature.
///Must be in aspect ration 4:3.
public class CropView : UIView {
    let internalCropView = VPCropView()
    let magnifyingView = MagnifyingView()
    let imageView = UIImageView()
    
    var singlePointBeingDraged = false
    var applyForTwoCorners = false
    
    ///Image that will be cropped.
    ///Needs to be setup before view will load.
    public var sourceImage : UIImage! {
        didSet {
            imageView.image = sourceImage
        }
    }
    var croppedImage : UIImage?
    var originalImage : UIImage?
    
    //MARK: - Lifecycle
    public override func awakeFromNib() {
        super.awakeFromNib()
        selfSetup()
    }
    
    public init(_ applyForTwoCorners: Bool) {
        self.applyForTwoCorners = applyForTwoCorners
        super.init(frame: .zero)
        selfSetup()
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        selfSetup()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        selfSetup()
    }
    
    public convenience init(sourceImage : UIImage) {
        self.init()
        selfSetup()
        self.sourceImage = sourceImage
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        
        parentViewController?.navigationController?.interactivePopGestureRecognizer?.isEnabled = false
    }
    
    //MARK: - Internal Methods
    private func selfSetup() {
        setupGestureRecognizers()
        setupMagnifyingView()
        setupUI()
    }
    
    func setupUI() {
        imageView.contentMode = .scaleAspectFit
        
        addSubview(magnifyingView)
        magnifyingView.addSubview(imageView)
        magnifyingView.addSubview(internalCropView)
        
        magnifyingView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint(item: magnifyingView, attribute:  NSLayoutConstraint.Attribute.leading, relatedBy: NSLayoutConstraint.Relation.equal, toItem: self, attribute: NSLayoutConstraint.Attribute.leadingMargin, multiplier: 1.0, constant: 0.0).isActive = true
        NSLayoutConstraint(item: magnifyingView, attribute:  NSLayoutConstraint.Attribute.trailing, relatedBy: NSLayoutConstraint.Relation.equal, toItem: self, attribute: NSLayoutConstraint.Attribute.trailingMargin, multiplier: 1.0, constant: 0.0).isActive = true
        NSLayoutConstraint(item: magnifyingView, attribute:  NSLayoutConstraint.Attribute.top, relatedBy: NSLayoutConstraint.Relation.equal, toItem: self, attribute: NSLayoutConstraint.Attribute.topMargin, multiplier: 1.0, constant: 0.0).isActive = true
        NSLayoutConstraint(item: magnifyingView, attribute:  NSLayoutConstraint.Attribute.bottom, relatedBy: NSLayoutConstraint.Relation.equal, toItem: self, attribute: NSLayoutConstraint.Attribute.bottomMargin, multiplier: 1.0, constant: 0.0).isActive = true
        
        imageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint(item: imageView, attribute:  NSLayoutConstraint.Attribute.leading, relatedBy: NSLayoutConstraint.Relation.equal, toItem: self, attribute: NSLayoutConstraint.Attribute.leadingMargin, multiplier: 1.0, constant: 0.0).isActive = true
        NSLayoutConstraint(item: imageView, attribute:  NSLayoutConstraint.Attribute.trailing, relatedBy: NSLayoutConstraint.Relation.equal, toItem: self, attribute: NSLayoutConstraint.Attribute.trailingMargin, multiplier: 1.0, constant: 0.0).isActive = true
        NSLayoutConstraint(item: imageView, attribute:  NSLayoutConstraint.Attribute.top, relatedBy: NSLayoutConstraint.Relation.equal, toItem: self, attribute: NSLayoutConstraint.Attribute.topMargin, multiplier: 1.0, constant: 0.0).isActive = true
        NSLayoutConstraint(item: imageView, attribute:  NSLayoutConstraint.Attribute.bottom, relatedBy: NSLayoutConstraint.Relation.equal, toItem: self, attribute: NSLayoutConstraint.Attribute.bottomMargin, multiplier: 1.0, constant: 0.0).isActive = true
        
        
        internalCropView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint(item: internalCropView, attribute:  NSLayoutConstraint.Attribute.leading, relatedBy: NSLayoutConstraint.Relation.equal, toItem: self, attribute: NSLayoutConstraint.Attribute.leadingMargin, multiplier: 1.0, constant: 0.0).isActive = true
        NSLayoutConstraint(item: internalCropView, attribute:  NSLayoutConstraint.Attribute.trailing, relatedBy: NSLayoutConstraint.Relation.equal, toItem: self, attribute: NSLayoutConstraint.Attribute.trailingMargin, multiplier: 1.0, constant: 0.0).isActive = true
        NSLayoutConstraint(item: internalCropView, attribute:  NSLayoutConstraint.Attribute.top, relatedBy: NSLayoutConstraint.Relation.equal, toItem: self, attribute: NSLayoutConstraint.Attribute.topMargin, multiplier: 1.0, constant: 0.0).isActive = true
        NSLayoutConstraint(item: internalCropView, attribute:  NSLayoutConstraint.Attribute.bottom, relatedBy: NSLayoutConstraint.Relation.equal, toItem: self, attribute: NSLayoutConstraint.Attribute.bottomMargin, multiplier: 1.0, constant: 0.0).isActive = true
        
        if applyForTwoCorners {
            internalCropView.pointB.isHidden = true
            internalCropView.pointD.isHidden = true
        }
    }
    
    ///Gestures used to show / update magnifying view. Long press gesture gets called immediately and later when pan gesture has moved enough to be considered a pan, then long press gesture is disabled.
    ///Long press gesture isn't designed to draging (during .end state especially) and pan gesture has to be moved enough to be considered a pan that makes delay before .began & .change states.
    func setupGestureRecognizers() {
        let singlePointTapGesture = UILongPressGestureRecognizer(target: self, action: #selector(singlePointTap(gesture:)))
        singlePointTapGesture.minimumPressDuration = 0
        singlePointTapGesture.delegate = self
        internalCropView.addGestureRecognizer(singlePointTapGesture)
        
        let singlePointPanGesture = UIPanGestureRecognizer(target: self, action: #selector(singlePointPan(gesture:)))
        singlePointPanGesture.minimumNumberOfTouches = 1
        singlePointPanGesture.delegate = self
        internalCropView.addGestureRecognizer(singlePointPanGesture)
    }
    
    func setupMagnifyingView() {
        let magnifyingGlassView = MagnifyingGlass(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        magnifyingGlassView.scale = 1.6
        magnifyingView.magnifyingGlass = magnifyingGlassView
    }
    
    //MARK: - Public Methods
    ///Resets the crop frame to default size & location.
//    public func resetCropFrame() {
//        internalCropView.resetFrame()
//    }
    
    ///Tries to detect biggest rectangle in 'sourceImage' and set cropView frame to that area automatically. Otherwise it shows cropView frame at default location.
    public func detectEdges(width: CGFloat = 0.0, height: CGFloat = 0.0) {
        internalCropView.resetFrame(width, height: height)
        
        let sortedPoints = OpenCVHelper.detectEdges(imageView)
        debugLog(sortedPoints)
        
        if let point0 = sortedPoints[0] {
            let value0 = point0.cgPointValue
            internalCropView.topLeftCorner(to: value0)
        }
        
        if let point1 = sortedPoints[1] {
            let value1 = point1.cgPointValue
            internalCropView.topRightCorner(to: value1)
        }
        
        if let point2 = sortedPoints[2] {
            let value2 = point2.cgPointValue
            internalCropView.bottomRightCorner(to: value2)
        }
        
        if let point3 = sortedPoints[3] {
            let value3 = point3.cgPointValue
            internalCropView.bottomLeftCorner(to: value3)
        }
    }
    
    ///Crops the 'sourceImage' by cropView's frame and shows new image.
    ///- Parameter completion: Optional completion callback with cropped image.
    public func crop(_ completion : CroppedImageCallbackCompletion? = nil) {
        guard let overviewImage = sourceImage else { warningLog("Overview image is nil"); return }
        originalImage = overviewImage
        
        if internalCropView.frameEdited {
            let scaleFactor: CGFloat = imageView.contentScale
            let points = internalCropView.pointsPosition(withScaleFactor: scaleFactor)
            let croppedImage = OpenCVHelper.cropImageView(overviewImage, points: points)
//            UIView.transition(with: imageView, duration: 0.3, options: .transitionCrossDissolve, animations: {
                //sourceImageView does not need to hold large raw BGRA image. Compressed and resized croppedImage should be enough.
                self.croppedImage = croppedImage
                self.sourceImage = croppedImage
//            }, completion: { (_) in
                self.internalCropView.isHidden = true
            completion?(croppedImage, points.map { $0 as! CGPoint })
//            })
        } else {
            warningLog("Invalid cropped rect")
        }
    }
    
    public func redoCrop() {
        guard let original = originalImage else { warningLog("no original") ;return }
        
//        UIView.transition(with: imageView, duration: 0.3, options: .transitionCrossDissolve, animations: {
            //sourceImageView does not need to hold large raw BGRA image. Compressed and resized croppedImage should be enough.
            self.croppedImage = nil
            self.sourceImage = original
//        }, completion: { (_) in
            self.internalCropView.isHidden = false
            self.originalImage = nil
//        })
    }
}


//MARK: - Gesture Recognizer Extension
extension CropView: UIGestureRecognizerDelegate {
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        for point in internalCropView.points {
            if touch.view?.isDescendant(of: point) == true {
                return true
            }
        }
        return false
    }
    
    ///User action for panning single points of cropView
    @objc func singlePointTap(gesture : UILongPressGestureRecognizer) {
        ///Skip if pan gesture is doing job with updating touch location.
        if singlePointBeingDraged { return }
        let location = gesture.location(in: internalCropView)
        switch gesture.state {
        case .possible:
            break
        case .began:
            internalCropView.findPoint(atLocation: location)
            guard internalCropView.activePoint != nil else { return }
            internalCropView.touchBegun(location)
            internalCropView.checkAngle(0)
            internalCropView.moveActivePoint(toLocation: location, onlyTwoCorners: applyForTwoCorners)
            magnifyingView.touchBegan(atLocation: location)
        case .changed:
            internalCropView.moveActivePoint(toLocation: location, onlyTwoCorners: applyForTwoCorners)
            magnifyingView.touchMoved(atLocation: location)
        case .ended, .cancelled, .failed:
            internalCropView.moveActivePoint(toLocation: location, onlyTwoCorners: applyForTwoCorners)
            internalCropView.resetActivePoint()
            internalCropView.checkAngle(0)
            magnifyingView.touchEnded(atLocation: location)
        @unknown default:
            break
        }
    }
    
    @objc func singlePointPan(gesture : UIPanGestureRecognizer) {
        let location = gesture.location(in: internalCropView)
        switch gesture.state {
        case .possible:
            break
        case .began:
            break
        case .changed:
            singlePointBeingDraged = true
            internalCropView.moveActivePoint(toLocation: location, onlyTwoCorners: applyForTwoCorners)
            magnifyingView.touchMoved(atLocation: location)
        case .ended, .cancelled, .failed:
            singlePointBeingDraged = false
            internalCropView.moveActivePoint(toLocation: location, onlyTwoCorners: applyForTwoCorners)
            internalCropView.resetActivePoint()
            internalCropView.checkAngle(0)
            magnifyingView.touchEnded(atLocation: location)
        @unknown default:
            break
        }
    }
}
