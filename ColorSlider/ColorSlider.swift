//
//  ColorSlider.swift
//  ColorSlider
//
//  Created by Robert Hahn on 23.05.19.
//  Copyright © 2019 Robert Hahn. All rights reserved.
//

import Cocoa


@IBDesignable
public class ColorSlider: NSSlider {
    
    public enum ColorType: Int {
        case unknown = 0
        case color = 3
        case temperature = 4
    }
    
    // MARK: - Properties
    
    /// Setting for color slider
    public var colorType: ColorType = .color {  didSet { initLayer() } }
    
    /// Setting for saturation
    public var saturation: Float = 1.0 {  didSet { initLayer() } }
    
    /// Minimum color temperature value
    public var colorTemperatureMin: Int = 6500 {  didSet { initLayer() } }
    /// Maximum color temperature value
    public var colorTemperatureMax: Int = 2200 {  didSet { initLayer() } }
    
    @IBInspectable public var useAnimation: Bool = true

    public var selectedColor: NSColor {
        let amount: CGFloat = CGFloat(floatValue / Float(maxValue))
        return backgroundGradient.interpolatedColor(atLocation: amount)
    }
    
    
    /// Indicating that user is currently interacting with this control, e.g. mouse down
    fileprivate(set) public var isTracking: Bool = false {
        didSet {
            updateLayer()
            animateBackground()
        }
    }
    
    /// Indicating that user has dragged the knob of the control from A to B.
    fileprivate(set) public var isDragging: Bool = false {
        didSet {
            updateLayer()
        }
    }
    
    private let rootLayer = CALayer()
    private let backgroundLayer = CAShapeLayer()
    private let backgroundGradientLayer = CAGradientLayer()
    private let knobLayer = CAShapeLayer()
    
    
    // MARK: - Inits
    
    override public func awakeFromNib() {
        super.awakeFromNib()
        setupView()
    }
    
    required public init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override public init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
    }
    
    private func setupView() {
        if self.cell?.isKind(of: ColorSliderCell.self) == false {
            let cell = ColorSliderCell(parent: self)
            self.cell = cell
        }
        
        wantsLayer = true
        layer = rootLayer
        rootLayer.addSublayer(backgroundLayer)
        rootLayer.addSublayer(backgroundGradientLayer)
        rootLayer.addSublayer(knobLayer)
        
        initLayer()
    }
    
    override public var acceptsFirstResponder: Bool {
        return true
    }
    
    override public func becomeFirstResponder() -> Bool {
        return true
    }
    
    
    // MARK: - Coloring
    
    var frameColor: NSColor {
        return NSColor.systemGray
    }
    
    /// Calculate RGB values from color temperature
    ///
    /// - Parameter fromCt: Color temperature value in [K]
    /// - Returns: Calculated value, shifted by an offset
    private func getRGB(fromCt: Int, offset: Int = 2000) -> NSColor {
        // All calculations require tmpKelvin \ 100, so only do the conversion once
        let temperature = Float(fromCt + offset) / 100.0
        var red: Int
        var green: Int
        var blue: Int
        
        // Calculate Red:
        if temperature <= 66 {
            red = 255
        } else {
            red = Int(329.698727446 * (pow((temperature - 60.0), -0.1332047592)))
            if red < 0 { red = 0 }
            if red > 255 { red = 255 }
        }
        
        // Calculate Green:
        if temperature <= 66 {
            green = Int(99.4708025861 * logf(temperature) - 161.1195681661)
        } else {
            green = Int(288.1221695283 * (pow((temperature - 60.0), -0.0755148492)))
        }
        if green < 0 { green = 0 }
        if green > 255 { green = 255 }
        
        // Calculate Blue:
        if temperature >= 66 {
            blue = 255
        } else {
            if temperature <= 19 {
                blue = 0
            } else {
                blue = Int(138.5177312231 * logf(temperature - 10) - 305.0447927307)
                if blue < 0 { blue = 0 }
                if blue > 255 { blue = 255 }
            }
        }
        
        return NSColor(red: CGFloat(red)/255, green: CGFloat(green)/255, blue: CGFloat(blue)/255, alpha: 1)
    }
    
    var backgroundColors: [NSColor] {
        switch colorType {
            
        case .color:
            return Array(0...10).map{
                NSColor.init(calibratedHue: CGFloat($0) / 10, saturation: CGFloat(saturation), brightness: 1.0, alpha: 1.0)
            }
            
        case .temperature:
            let fromValue = colorTemperatureMin
            let toValue = colorTemperatureMax + (colorTemperatureMax - colorTemperatureMin) / 10
            return stride(from: fromValue, to: toValue, by: (toValue - fromValue) / 10).map{
                getRGB(fromCt: $0, offset: 500)
            }
            
        default:
            return [NSColor.black]
        }
        
    }
    
    var backgroundGradient: NSGradient {
        return NSGradient.init(colors: backgroundColors)!
    }
    
    var shadowColor: NSColor {
        return NSColor(white: 0.3, alpha: 0.3)
    }
    
    var knobColor: NSColor {
        return selectedColor
    }
    
    
    // MARK: - UI Sizing
    
    var knobX: CGFloat {
        let innerRect = bounds.insetBy(dx: bounds.height / 2, dy: 0)
        if maxValue - minValue == 0 { return innerRect.minX }
        return innerRect.minX + CGFloat((doubleValue - minValue) / maxValue) * innerRect.width
    }
    
    lazy var backgroundLinedRect: NSBezierPath = {
        let bezelMargin: CGFloat = 8
        let bezelFrame = bounds.insetBy(dx: bezelMargin / 2, dy: bezelMargin)
        return NSBezierPath(roundedRect: bezelFrame, xRadius: bezelFrame.height * 0.5, yRadius: bezelFrame.height * 0.5)
    }()
    
    lazy var backgroundFilledRect: NSBezierPath = {
        let bezelMargin: CGFloat = 0
        let bezelFrame = bounds.insetBy(dx: bezelMargin / 2, dy: bezelMargin)
        return NSBezierPath(roundedRect: bezelFrame, xRadius: bezelFrame.height * 0.5, yRadius: bezelFrame.height * 0.5)
    }()
    
    var knobRect: NSBezierPath {
        return NSBezierPath(ovalIn: NSRect(x: knobX - bounds.height * 0.5, y: 0, width: bounds.height, height: bounds.height).insetBy(dx: 2, dy: 2))
    }
    
    
    // MARK: - Drawing
    
    override public func draw(_ dirtyRect: NSRect) {
        return
    }
    
    private func initLayer() {
        noteFocusRingMaskChanged()
        
        // Background
        backgroundLayer.frame = bounds
        backgroundLayer.path = backgroundLinedRect.cgPath
        backgroundGradientLayer.frame = bounds
        backgroundGradientLayer.colors = backgroundColors.map({ $0.cgColor })
        backgroundGradientLayer.startPoint = CGPoint(x: 0, y: 0)
        backgroundGradientLayer.endPoint = CGPoint(x: 1, y: 0)
        backgroundGradientLayer.mask = backgroundLayer
        
        // Knob
        knobLayer.frame = bounds
        knobLayer.path = knobRect.cgPath
        knobLayer.strokeColor = shadowColor.cgColor
        knobLayer.lineWidth = 0.5
        knobLayer.fillColor = knobColor.cgColor
        knobLayer.shadowColor = NSColor.shadowColor.cgColor
        knobLayer.shadowOpacity = 0.35
        knobLayer.shadowOffset = CGSize(width: 0, height: 0.5)
        knobLayer.shadowRadius = 1
    }
    
    override public func updateLayer() {
        noteFocusRingMaskChanged()
        
        // Knob
        knobLayer.path = knobRect.cgPath
        knobLayer.fillColor = knobColor.cgColor
    }
    
    private func animateBackground() {
        if useAnimation {
            let backgroundPathAnim = CABasicAnimation(keyPath: "path")
            backgroundPathAnim.fromValue = isTracking ? backgroundLinedRect.cgPath : backgroundFilledRect.cgPath
            backgroundPathAnim.toValue = isTracking ? backgroundFilledRect.cgPath : backgroundLinedRect.cgPath
            backgroundPathAnim.duration = isTracking ? 0.05 : 1.0
            backgroundLayer.add(backgroundPathAnim, forKey: "animateBackgroundHeight")
            backgroundLayer.path = isTracking ? backgroundFilledRect.cgPath : backgroundLinedRect.cgPath
        }
    }
    
    override public func drawFocusRingMask() {
        knobRect.fill()
    }
    
    override public var focusRingMaskBounds: NSRect {
        return bounds.insetBy(dx: 1, dy: 1)
    }
}


@IBDesignable
class ColorSliderCell: NSSliderCell {
    // MARK: - Inits
    
    private var parent: ColorSlider?
    
    required init(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    init(parent: ColorSlider) {
        super.init()
        self.parent = parent
    }
    
    
    // MARK: - Events
    
    override func startTracking(at startPoint: NSPoint, in controlView: NSView) -> Bool {
        parent?.isTracking = true
        return super.startTracking(at: startPoint, in: controlView)
    }
    
    override func continueTracking(last lastPoint: NSPoint, current currentPoint: NSPoint, in controlView: NSView) -> Bool {
        parent?.isDragging = true
        return super.continueTracking(last: lastPoint, current: currentPoint, in: controlView)
    }
    
    override func stopTracking(last lastPoint: NSPoint, current stopPoint: NSPoint, in controlView: NSView, mouseIsUp flag: Bool) {
        super.stopTracking(last: lastPoint, current: stopPoint, in: controlView, mouseIsUp: flag)
        parent?.isTracking = false
    }
}
