//
//  NSColor.swift
//  ColorSlider
//
//  Created by Robert Hahn on 11.06.19.
//  Copyright © 2019 Robert Hahn. All rights reserved.
//

import Cocoa


extension NSColor {
    func modified(saturation: CGFloat) -> NSColor {
        var currentHue: CGFloat = 0.0
        var currentSaturation: CGFloat = 0.0
        var currentBrigthness: CGFloat = 0.0
        var currentAlpha: CGFloat = 0.0
        
        self.getHue(&currentHue, saturation: &currentSaturation, brightness: &currentBrigthness, alpha: &currentAlpha)
        
        return NSColor(hue: currentHue, saturation: saturation, brightness: currentBrigthness, alpha: currentAlpha)
    }
}
