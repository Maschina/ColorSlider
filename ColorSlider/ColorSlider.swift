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
    
    // MARK: - Properties
    
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
    
    var backgroundColors: [NSColor] {
        return Array(0...10).map{
            NSColor.init(calibratedHue: CGFloat($0) / 10, saturation: 1.0, brightness: 1.0, alpha: 1.0)
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
