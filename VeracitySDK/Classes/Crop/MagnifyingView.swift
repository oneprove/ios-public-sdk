//
//  MagnifyingView.swift
//  ONEPROVE
//
//  Created by Andrew on 12/11/2018.
//  Copyright © 2018 ONEPROVE s.r.o. All rights reserved.
//

import UIKit

class MagnifyingView: UIView {
    private var xOffset: CGFloat = 20.0
    private var yOffset: CGFloat = 20.0
    
    var magnifyingGlass: MagnifyingGlass = MagnifyingGlass() {
        didSet {
            magnifyingGlass.magnifierViewFrame = frame
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        guard frame.size != magnifyingGlass.magnifierViewFrame.size else { return }
        magnifyingGlass.magnifierViewFrame = frame
    }
    
    func touchBegan(atLocation location: CGPoint) {
        addMagnifyingGlassAtPoint(point: location)
    }
    
    func touchMoved(atLocation location: CGPoint) {
        // Top Left Corner
        if location.x < (frame.origin.x + xOffset) && location.y < (frame.origin.y - yOffset) {
            self.updateMagnifyingGlassAtPoint(point: CGPoint(x: max(xOffset, location.x), y: max(yOffset, location.y)))
            return
        }
        
        // Bottom Right Corner
        if location.x < (frame.origin.x + xOffset) && location.y > (frame.size.height - yOffset) {
            self.updateMagnifyingGlassAtPoint(point: CGPoint(x: max(xOffset, location.x), y: min(location.y, frame.size.height - yOffset)))
            return
        }
        
        // Bottom Left Corner
        if location.x > (frame.size.width - xOffset) && location.y > (frame.size.height - yOffset) {
            self.updateMagnifyingGlassAtPoint(point: CGPoint(x: min(frame.size.width - xOffset, location.x), y: min(location.y, frame.size.height - yOffset)))
            return
        }
        
        // Top Right Corner
        if location.x > (frame.size.width - xOffset) && location.y < (frame.origin.y - yOffset) {
            self.updateMagnifyingGlassAtPoint(point: CGPoint(x: min(frame.size.width - xOffset, location.x), y: max(yOffset, location.y)))
            return
        }
        
        // Left Side
        if location.x < (frame.origin.x + xOffset) {
            self.updateMagnifyingGlassAtPoint(point: CGPoint(x: xOffset, y: location.y))
            return
        }
        
        // Top Side
        if location.y < (frame.origin.y - yOffset) {
            self.updateMagnifyingGlassAtPoint(point: CGPoint(x: location.x, y: location.y))
            return
        }
        
        // Right Side
        if location.x > (frame.size.width - xOffset) {
            self.updateMagnifyingGlassAtPoint(point: CGPoint(x: frame.size.width - xOffset, y: location.y))
            return
        }
        
        // Bottom Side
        if location.y > (frame.size.height - yOffset) {
            self.updateMagnifyingGlassAtPoint(point: CGPoint(x: location.x, y: frame.size.height - yOffset))
            return
        }
        
        self.updateMagnifyingGlassAtPoint(point: location)
    }
    
    func touchEnded(atLocation location: CGPoint) {
        self.removeMagnifyingGlass()
    }
    
    // MARK: - Private Functions
    private func addMagnifyingGlassAtPoint(point: CGPoint) {
        self.magnifyingGlass.viewToMagnify = self as UIView
        self.magnifyingGlass.touchPoint = point
        
        let selfView: UIView = self as UIView
        
        selfView.addSubview(self.magnifyingGlass)
        
        self.magnifyingGlass.layer.setNeedsDisplay()
    }
    
    private func removeMagnifyingGlass() {
        self.magnifyingGlass.removeFromSuperview()
    }
    
    private func updateMagnifyingGlassAtPoint(point: CGPoint) {
        self.magnifyingGlass.touchPoint = point
        self.magnifyingGlass.layer.setNeedsDisplay()
    }
}
