//
//  ColorSlider.swift
//  ColorSlider
//
//  Created by Robert Hahn on 23.05.19.
//  Copyright © 2019 Robert Hahn. All rights reserved.
//

import Cocoa


@IBDesignable
class ColorSlider: NSSlider {
    
    fileprivate(set) var tracking: Bool = false
    
    
    override func setNeedsDisplay(_ invalidRect: NSRect) {
        super.setNeedsDisplay(invalidRect)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupView()
    }
    
    
    override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
    }
    
    private func setupView() {
        if ((self.cell?.isKind(of: ColorSliderCell.self)) == false) {
            let cell = ColorSliderCell()
            self.cell = cell
        }
        
        self.alphaValue = 0.5
        self.floatValue = 0.4
    }
}



class ColorSliderCell: NSSliderCell {
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init() {
        super.init()
    }
    
    override func drawKnob(_ knobRect: NSRect) {
        
        return
    }
    
    override func startTracking(at startPoint: NSPoint, in controlView: NSView) -> Bool {
        var tracking = (self.controlView as? ColorSlider)?.tracking
        tracking = true
        print("Tracking: \(tracking)")
        return super.startTracking(at: startPoint, in: controlView)
    }
    
    override func stopTracking(last lastPoint: NSPoint, current stopPoint: NSPoint, in controlView: NSView, mouseIsUp flag: Bool) {
        super.stopTracking(last: lastPoint, current: stopPoint, in: controlView, mouseIsUp: flag)
        var tracking = (self.controlView as? ColorSlider)?.tracking
        tracking = false
        print("Tracking: \(tracking)")
    }
}
