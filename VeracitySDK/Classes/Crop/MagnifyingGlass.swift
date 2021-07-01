//
//  MagnifyingGlass.swift
//  ONEPROVE
//
//  Created by Andrew on 12/11/2018.
//  Copyright © 2018 ONEPROVE s.r.o. All rights reserved.
//

import UIKit
import QuartzCore

class MagnifyingGlass: UIView {
    weak var viewToMagnify: UIView!
    var touchPoint: CGPoint! {
        didSet {
            self.center = CGPoint(x: touchPoint.x < (magnifierViewFrame.size.width / 2) ? magnifierViewFrame.size.width - 60.0 : 60.0, y: MagnifyingGlassDefaultTopSpace)
        }
    }
    
    var magnifierViewFrame: CGRect!
    var touchPointOffset: CGPoint!
    var scale: CGFloat!
    var scaleAtTouchPoint: Bool!
    
    var MagnifyingGlassDefaultTopSpace: CGFloat = 60.0
    var MagnifyingGlassDefaultOffset: CGFloat = -10.0
    var MagnifyingGlassDefaultScale: CGFloat = 1.6
    
    required convenience init(coder aDecoder: NSCoder) {
        self.init(coder: aDecoder)
    }
    
    required override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.layer.borderColor = UIColor.white.cgColor
        self.layer.borderWidth = 2
        self.layer.cornerRadius = frame.size.width / 2
        self.layer.masksToBounds = true
        self.touchPointOffset = CGPoint(x: 0, y: MagnifyingGlassDefaultOffset)
        self.scale = MagnifyingGlassDefaultScale
        self.viewToMagnify = nil
        self.scaleAtTouchPoint = true
    }
    
    private func setFrame(frame: CGRect) {
        super.frame = frame
        self.layer.cornerRadius = frame.size.width / 2
    }
    
    override func draw(_ layer: CALayer, in ctx: CGContext) {
        // FIXME: Memory leaking when redrawing magnifier
        UIColor.black.setFill()
        
        ctx.fill(self.bounds)
        ctx.translateBy(x: self.frame.size.width / 2, y: self.frame.size.height / 2)
        ctx.scaleBy(x: self.scale, y: self.scale)
        ctx.translateBy(x: -self.touchPoint.x, y: -self.touchPoint.y - 15)
        
        self.viewToMagnify.layer.render(in: ctx)
    }
}
