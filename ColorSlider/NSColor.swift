//
//  NSColor.swift
//  ColorSlider
//
//  Created by Robert Hahn on 11.06.19.
//  Copyright © 2019 Robert Hahn. All rights reserved.
//

import Cocoa


extension NSColor {
    func modify(saturation: CGFloat) -> NSColor {
        var currentHue: CGFloat = 0.0
        var currentSaturation: CGFloat = 0.0
        var currentBrightness: CGFloat = 0.0
        var currentAlpha: CGFloat = 0.0
        
        self.getHue(&currentHue, saturation: &currentSaturation, brightness: &currentBrightness, alpha: &currentAlpha)
        
        return NSColor(hue: currentHue, saturation: saturation, brightness: currentBrightness, alpha: currentAlpha)
    }
}
