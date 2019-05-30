//
//  ExtensionNSBezierPath.swift
//  ColorSlider
//
//  Created by Robert Hahn on 30.05.19.
//  Copyright © 2019 Robert Hahn. All rights reserved.
//

import Cocoa

extension NSBezierPath {
    var cgPath: CGPath {
        return self.transformToCGPath()
    }
    
    /// Transforms the NSBezierPath into a CGPathRef
    ///
    /// - Returns: The transformed NSBezierPath
    private func transformToCGPath() -> CGPath {
        // Create path
        let path = CGMutablePath()
        let points = UnsafeMutablePointer<NSPoint>.allocate(capacity: 3)
        let numElements = self.elementCount
        
        if numElements > 0 {
            for index in 0..<numElements {
                
                let pathType = self.element(at: index, associatedPoints: points)
                
                switch pathType {
                    
                case .moveTo:
                    path.move(to: points[0])
                case .lineTo:
                    path.addLine(to: points[0])
                case .curveTo:
                    path.addCurve(to: points[2], control1: points[0], control2: points[1])
                case .closePath:
                    path.closeSubpath()
                @unknown default:
                    continue
                }
            }
        }
        points.deallocate()
        return path
    }
}
