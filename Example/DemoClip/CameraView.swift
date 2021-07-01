//
//  CameraView.swift
//  DemoClip
//
//  Created by mbpro on 25/07/2021.
//

import UIKit
import AVFoundation
import ImageIO

public protocol CameraViewDelegate: AnyObject {
    func didTakeImage(_ image: UIImage)
    func didFailedToTakeImage(_ error: Error)
}

public class CameraView: UIView {
    fileprivate var captureVideoPreviewLayer: AVCaptureVideoPreviewLayer?
    fileprivate let shapeOverlayLayer = CAShapeLayer()
    fileprivate let maskLayer = CAShapeLayer()
    fileprivate lazy var captureSession: AVCaptureSession = AVCaptureSession()
    public private(set) lazy var captureDevice: AVCaptureDevice? = AVCaptureDevice.default(for: AVMediaType.video)
    fileprivate lazy var stillImageOutput: AVCapturePhotoOutput = AVCapturePhotoOutput()
    
    public weak var delegate: CameraViewDelegate?
    
    // MARK: - Lifecycle
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setupLayout()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        setupLayout()
    }
    
    deinit {
        deactivateSession()
    }
    
    override public func layoutSubviews() {
        super.layoutSubviews()
        
        CATransaction.begin()
        CATransaction.setValue(kCFBooleanTrue, forKey: kCATransactionDisableActions)
        
        captureVideoPreviewLayer?.bounds = bounds
        captureVideoPreviewLayer?.position = CGPoint(x: bounds.midX, y: bounds.midY)
        CATransaction.commit()
    }
    
    // MARK: - Public Methods
    public func takePhoto() {
        let pixelFormatType = NSNumber(value: kCVPixelFormatType_32BGRA)
        
        guard stillImageOutput.availablePhotoPixelFormatTypes.contains(OSType(truncating: pixelFormatType)) else { return }
        
        let photoSettings = AVCapturePhotoSettings(format: [
            kCVPixelBufferPixelFormatTypeKey as String : pixelFormatType
            ])
        photoSettings.isHighResolutionPhotoEnabled = true
        
        stillImageOutput.capturePhoto(with: photoSettings, delegate: self)
    }
    
    public func activateSession() {
        #if IOS_SIMULATOR
        return
        #else
        stillImageOutput.isHighResolutionCaptureEnabled = true
        captureSession.startRunning()
        #endif
    }
    
    public func isSessionRunning() -> Bool {
        return captureSession.isRunning
    }
    
    public func deactivateSession() {
        if captureSession.isRunning {
            captureSession.stopRunning()
        }
    }
}

extension CameraView: AVCapturePhotoCaptureDelegate {
    public func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        self.deactivateSession()
        
        if let error = error {
            print("Failed to capture jpg photo \(error)!")
            delegate?.didFailedToTakeImage(error)
            return
        }
        
        guard let pixelBuffer = photo.pixelBuffer else {
            print("Failed to acquire pixelBuffer!")
            return
        }
        
        let orientationMap: [AVCaptureVideoOrientation : CGImagePropertyOrientation] = [
            .portrait           : .right,
            .portraitUpsideDown : .left,
            .landscapeLeft      : .down,
            .landscapeRight     : .up,
        ]
        guard let videoOrientation = captureVideoPreviewLayer?.connection?.videoOrientation else {
            print("Failed to acquire videoOrientation!")
            return
        }
        let imageOrientation = Int32(orientationMap[videoOrientation]!.rawValue)
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer).oriented(forExifOrientation: imageOrientation)
        guard let cgImage = CIContext().createCGImage(ciImage, from: ciImage.extent) else {
            print("Couldn't create image from ")
            return
        }
        let image = UIImage(cgImage: cgImage)
        
        self.delegate?.didTakeImage(image)
    }
}

fileprivate extension CameraView {
    func setupLayout() {
        DispatchQueue.main.async {
            #if IOS_SIMULATOR
            warningLog("Capture session is not working in simulator")
            self.backgroundColor = UIColor.black
            #else
            do {
                let input = try AVCaptureDeviceInput(device: self.captureDevice!)
                self.captureSession.addInput(input)
                
                if self.captureSession.canAddOutput(self.stillImageOutput) {
                    self.captureSession.addOutput(self.stillImageOutput)
                }
                self.captureSession.sessionPreset = AVCaptureSession.Preset.photo
            } catch let error {
                print("Capture session failed with error: \(error.localizedDescription)")
            }
            #endif
            
            if self.captureVideoPreviewLayer == nil {
                let previewLayer = AVCaptureVideoPreviewLayer(session: self.captureSession)
                previewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
                previewLayer.frame = self.bounds
                self.captureVideoPreviewLayer = previewLayer
                DispatchQueue.main.async {
                    self.layer.addSublayer(previewLayer)
                    self.activateSession()
                }
            }
        }
    }
    
    func setupOverlay(_ maskSize: CGSize = CGSize(width: 300, height: 400),
                             lineColor: UIColor = .green,
                             lineWidth: CGFloat = 10,
                             lineCap: CAShapeLayerLineCap = .round) {
        let cornerLengthHeight: CGFloat = maskSize.height / 2
        let cornerLengthWidth: CGFloat = maskSize.width / 2
        let cornerRadius: CGFloat = 10
        var maskContainer: CGRect {
            CGRect(x: (bounds.width / 2) - (maskSize.width / 2),
                   y: (bounds.height / 2) - (maskSize.height / 2),
                   width: maskSize.width,
                   height: maskSize.height)
        }
        
        let path = CGMutablePath()
        path.addRect(bounds)
        path.addRoundedRect(in: maskContainer, cornerWidth: cornerRadius, cornerHeight: cornerRadius)

        maskLayer.path = path
        maskLayer.fillColor = captureVideoPreviewLayer?.backgroundColor
        maskLayer.fillRule = .evenOdd

        captureVideoPreviewLayer?.addSublayer(maskLayer)

        // MARK: - Edged Corners

        let upperLeftPoint = CGPoint(x: maskContainer.minX, y: maskContainer.minY)
        let upperRightPoint = CGPoint(x: maskContainer.maxX, y: maskContainer.minY)
        let lowerRightPoint = CGPoint(x: maskContainer.maxX, y: maskContainer.maxY)
        let lowerLeftPoint = CGPoint(x: maskContainer.minX, y: maskContainer.maxY)

        let upperLeftCorner = UIBezierPath()
        upperLeftCorner.move(to: upperLeftPoint.offsetBy(dx: 0, dy: cornerLengthHeight))
        upperLeftCorner.addArc(withCenter: upperLeftPoint.offsetBy(dx: cornerRadius, dy: cornerRadius),
                         radius: cornerRadius, startAngle: .pi, endAngle: 3 * .pi / 2, clockwise: true)
        upperLeftCorner.addLine(to: upperLeftPoint.offsetBy(dx: cornerLengthWidth, dy: 0))

        let upperRightCorner = UIBezierPath()
        upperRightCorner.move(to: upperRightPoint.offsetBy(dx: -cornerLengthWidth, dy: 0))
        upperRightCorner.addArc(withCenter: upperRightPoint.offsetBy(dx: -cornerRadius, dy: cornerRadius),
                              radius: cornerRadius, startAngle: 3 * .pi / 2, endAngle: 0, clockwise: true)
        upperRightCorner.addLine(to: upperRightPoint.offsetBy(dx: 0, dy: cornerLengthHeight))

        let lowerRightCorner = UIBezierPath()
        lowerRightCorner.move(to: lowerRightPoint.offsetBy(dx: 0, dy: -cornerLengthHeight))
        lowerRightCorner.addArc(withCenter: lowerRightPoint.offsetBy(dx: -cornerRadius, dy: -cornerRadius),
                                 radius: cornerRadius, startAngle: 0, endAngle: .pi / 2, clockwise: true)
        lowerRightCorner.addLine(to: lowerRightPoint.offsetBy(dx: -cornerLengthWidth, dy: 0))

        let bottomLeftCorner = UIBezierPath()
        bottomLeftCorner.move(to: lowerLeftPoint.offsetBy(dx: cornerLengthWidth, dy: 0))
        bottomLeftCorner.addArc(withCenter: lowerLeftPoint.offsetBy(dx: cornerRadius, dy: -cornerRadius),
                                radius: cornerRadius, startAngle: .pi / 2, endAngle: .pi, clockwise: true)
        bottomLeftCorner.addLine(to: lowerLeftPoint.offsetBy(dx: 0, dy: -cornerLengthHeight))

        let combinedPath = CGMutablePath()
        combinedPath.addPath(upperLeftCorner.cgPath)
        combinedPath.addPath(upperRightCorner.cgPath)
        combinedPath.addPath(lowerRightCorner.cgPath)
        combinedPath.addPath(bottomLeftCorner.cgPath)

        shapeOverlayLayer.path = combinedPath
        shapeOverlayLayer.strokeColor = lineColor.cgColor
        shapeOverlayLayer.fillColor = UIColor.clear.cgColor
        shapeOverlayLayer.lineWidth = lineWidth
        shapeOverlayLayer.lineCap = lineCap

        captureVideoPreviewLayer?.addSublayer(shapeOverlayLayer)
    }
    
    func removeShapeOverlay() {
        shapeOverlayLayer.isHidden = true
        maskLayer.isHidden = true
        shapeOverlayLayer.removeFromSuperlayer()
        maskLayer.removeFromSuperlayer()
    }
}

internal extension CGPoint {

    // MARK: - CGPoint+offsetBy
    func offsetBy(dx: CGFloat, dy: CGFloat) -> CGPoint {
        var point = self
        point.x += dx
        point.y += dy
        return point
    }
}
