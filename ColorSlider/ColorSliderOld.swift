import Cocoa

let verticalShadowPadding: CGFloat = 3.0
let barTrailingMargin: CGFloat = 1.0
let disabledControlDimmingRatio: CGFloat = 0.1

struct SelectionRange {
    var start: Double
    var end: Double
}

enum RangeSliderKnobStyle {
    case square
    case circular
}

enum ColorType: Int {
    case dimmable = 2
    case color = 3
    case temperature = 4
    case extendedColor = 5
}


@IBDesignable
class ColorSliderOld: NSControl {
    
    // MARK: - Public Inspectables
    
    /** Optional action block, called when the control's start or end values change. */
    var onControlChanged: ((ColorSliderOld) -> Void)?
    
    /** The start of the selected span in the slider. */
    @IBInspectable var current: Double {
        get {
            return (selection.start * (maximum - minimum)) + minimum
        }
        
        set {
            let fractionalStart = (newValue - minimum) / (maximum - minimum)
            selection = SelectionRange(start: fractionalStart, end: selection.end)
            updateLayersOnDrag()
        }
    }
    @IBInspectable var minimum: Double = 0.0
    @IBInspectable var maximum: Double = 1.0
    
    
    /** Defaults is false (off). If set to true, the slider
     will snap to whole integer values for both sliders. */
    @IBInspectable var snapToValue: Bool = false
    
    /** Defaults to true, and makes the length property
     inclusive when snapsToIntegers is enabled. */
    var inclusiveLengthForSnapTo: Bool = true
    
    /** Defaults to true, allows clicks off of the slider knobs
     to reposition the bars. */
    @IBInspectable var allowClicksOnBarToMoveSliders: Bool = true
    
    @IBInspectable var frameGradientStart: NSColor = NSColor(white: 1.0, alpha: 1.0)
    @IBInspectable var frameGradientEnd: NSColor = NSColor(white: 1.0, alpha: 1.0)
    @IBInspectable var frameRadius: CGFloat = 0
    @IBInspectable var frameRainbow: Bool = false
    
    @IBInspectable var backgroundGradientStart: NSColor = NSColor(white: 1.0, alpha: 1.0)
    @IBInspectable var backgroundGradientEnd: NSColor = NSColor(white: 1.0, alpha: 1.0)
    @IBInspectable var backgroundFillUp: Bool = false
    @IBInspectable var backgroundRainbow: Bool = false
    @IBInspectable var backgroundRainbowAlpha: CGFloat = 1
    @IBInspectable var backgroundRadius: CGFloat = 0
    @IBInspectable var backgroundGradientDegrees: CGFloat = 90.0
    
    @IBInspectable var barColor: NSColor = NSColor(white: 0.8, alpha: 1.0)
    @IBInspectable var barStrokeColor: NSColor = NSColor(white: 1.0, alpha: 0.0)
    @IBInspectable var barWidth: CGFloat = 8.0
    @IBInspectable var barRadius: CGFloat = 0
    
    @IBInspectable var ColorizeBarToBackgroundPosition: Bool = false
    @IBInspectable var barShadow: Bool = true
    @IBInspectable var barGlow: Bool = false
    @IBInspectable var showFillOnDragging: Bool = true
    @IBInspectable var showFillAfterDragging: Bool = true
    
    
    /** The shape style of the slider knobs. Defaults to square. */
    var knobStyle: RangeSliderKnobStyle = .square
    
    
    // MARK: - Properties
    
    override public var isEnabled: Bool {
        didSet {
            updateLayerOnDisable()
        }
    }
    
    public var colorType: ColorType = .Color {
        didSet { drawLayers() }
    }
    
    private var isDragging: Bool = false
    
    private var hideBackground: Bool = true
    
    private var selection: SelectionRange = SelectionRange(start: 0.0, end: 1.0) {
        willSet {
            if newValue.start != selection.start {
                self.willChangeValue(forKey: "start")
            }
            
            if newValue.end != selection.end {
                self.willChangeValue(forKey: "end")
            }
            
            if (newValue.end - newValue.start) != (selection.end - selection.start) {
                self.willChangeValue(forKey: "length")
            }
        }
        
        didSet {
            var valuesChanged: Bool = false
            
            if oldValue.start != selection.start {
                self.didChangeValue(forKey: "start")
                valuesChanged = true
            }
            
            if oldValue.end != selection.end {
                self.didChangeValue(forKey: "end")
                valuesChanged = true
            }
            
            if (oldValue.end - oldValue.start) != (selection.end - selection.start) {
                self.didChangeValue(forKey: "length")
            }
            
            if valuesChanged {
                if let block = onControlChanged {
                    block(self)
                }
            }
        }
    }
    
    
    // MARK: - Inits
    
    private let rootLayer = CALayer()
    private let frameLayer = CAShapeLayer()
    private let frameGradientLayer = CAGradientLayer()
    private let barLayer = CAShapeLayer()
    private let backgroundLayer = CAShapeLayer()
    private let backgroundGradientLayer = CAGradientLayer()
    
    
    override public init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        commonInit()
    }
    
    public required init?(coder decoder: NSCoder) {
        super.init(coder: decoder)
        commonInit()
    }
    
    private func commonInit() {
        if showFillAfterDragging { hideBackground = false }
        isEnabled = true
        wantsLayer = true
        layer = rootLayer
        rootLayer.addSublayer(frameLayer)
        rootLayer.addSublayer(backgroundGradientLayer)
        rootLayer.addSublayer(backgroundLayer)
        rootLayer.addSublayer(barLayer)
    }
    
    override var acceptsFirstResponder: Bool {
        return true
    }
    
    override func becomeFirstResponder() -> Bool {
        return true
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        drawLayers()
    }
    
    override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        drawLayers()
    }
    
    
    // MARK: - Events
    
    
    override func keyDown(with event: NSEvent) {
        super.keyDown(with: event)
        
        if event.keyCode == 0x7C {
            let newTarget = current + (maximum - minimum) / 20
            current = (newTarget > maximum) ? maximum : newTarget
        } else if event.keyCode == 0x7B {
            let newTarget = current - (maximum - minimum) / 20
            current = (newTarget < minimum) ? minimum : newTarget
        }
    }
    
    override func mouseDown(with event: NSEvent) {
        if isEnabled {
            isDragging = true
            
            //            if (showFillOnDragging) { hideBackground = false } else { hideBackground = true }
            
            let point = convert(event.locationInWindow, from: nil)
            
            if allowClicksOnBarToMoveSliders {
                updateForClick(atPoint: point)
                updateLayersOnDrag()
            }
        }
    }
    
    
    override func mouseUp(with event: NSEvent) {
        if isEnabled {
            isDragging = false
            
            //            if (showFillAfterDragging) { hideBackground = false } else { hideBackground = true }
            updateLayersOnDrag()
        }
    }
    
    
    override func mouseDragged(with event: NSEvent) {
        if isEnabled {
            isDragging = true
            
            let point = convert(event.locationInWindow, from: nil)
            updateForClick(atPoint: point)
            updateLayersOnDrag()
        }
    }
    
    
    private func updateForClick(atPoint point: NSPoint) {
        var pointX = Double(point.x / NSWidth(bounds))
        pointX = max(min(1.0, pointX), 0.0)
        
        if snapToValue {
            let steps = maximum - minimum
            pointX = round(pointX * steps) / steps
        }
        
        selection = SelectionRange(start: pointX, end: max(selection.end, pointX))
        //        selection = SelectionRange(start: min(selection.start, x), end: x)
    }
    
    
    // MARK: - Utility
    
    private func crispLineRect(_ rect: NSRect) -> NSRect {
        /*  Floor the rect values here, rather than use NSIntegralRect etc. */
        var newRect = NSMakeRect(floor(rect.origin.x),
                                 floor(rect.origin.y),
                                 floor(rect.size.width),
                                 floor(rect.size.height))
        newRect.origin.x += 0.5
        newRect.origin.y += 0.5
        
        return newRect
    }
    
    
    // MARK: - Appearance
    
    private func getBarColor() -> NSColor? {
        if ColorizeBarToBackgroundPosition {
            let currentPosition = CGFloat(current / (maximum - minimum))
            let colorInterpolated = getBackgroundGradient()?.interpolatedColor(atLocation: currentPosition).withAlphaComponent(1)
            guard let color = colorInterpolated?.usingColorSpace(NSColorSpace.sRGB) else { return nil }
            return isEnabled ? color : color.colorByDesaturating(disabledControlDimmingRatio)
            
        } else {
            return isEnabled ? barColor : barColor.colorByDesaturating(disabledControlDimmingRatio)
        }
    }
    
    
    private func getBarStrokeColor() -> NSColor {
        let color = barStrokeColor.usingColorSpace(NSColorSpace.sRGB) ?? barStrokeColor
        return isEnabled ? color : color.colorByDesaturating(disabledControlDimmingRatio)
    }
    
    
    private func getBarShadowColor() -> NSColor? {
        if barShadow { return NSColor(white: 0.0, alpha: 0.12) }
        if barGlow { return getBarColor() }
        return nil
    }
    
    
    private func getFrameColors() -> [NSColor] {
        if frameRainbow {
            return [
                NSColor(red: 1, green: 0, blue: 0, alpha: 1),
                NSColor(red: 1, green: 1, blue: 0, alpha: 1),
                NSColor(red: 0, green: 1, blue: 0, alpha: 1),
                NSColor(red: 0, green: 1, blue: 1, alpha: 1),
                NSColor(red: 0, green: 0, blue: 1, alpha: 1),
                NSColor(red: 1, green: 0, blue: 1, alpha: 1),
                NSColor(red: 1, green: 0, blue: 0, alpha: 1)
                ].map({ $0.usingColorSpace(NSColorSpace.sRGB) ?? $0 })
        }
        return [frameGradientStart, frameGradientEnd]
    }
    
    
    private var _backgroundColors: [NSColor] {
        switch colorType {
            
        case .dimmable:
            let colors = [
                NSColor.systemGray.usingColorSpace(NSColorSpace.sRGB) ?? NSColor.tertiaryLabelColor,
                NSColor(red: 0.8, green: 0.8, blue: 0.8, alpha: backgroundRainbowAlpha),
                NSColor(red: 1, green: 1, blue: 1, alpha: backgroundRainbowAlpha)
            ]
            return isEnabled ? colors : colors.map({ $0.colorByDesaturating(disabledControlDimmingRatio) })
            
        case .color:
            let colors = [
                NSColor(red: 1, green: 0, blue: 0, alpha: backgroundRainbowAlpha),
                NSColor(red: 1, green: 1, blue: 0, alpha: backgroundRainbowAlpha),
                NSColor(red: 0, green: 1, blue: 0, alpha: backgroundRainbowAlpha),
                NSColor(red: 0, green: 1, blue: 1, alpha: backgroundRainbowAlpha),
                NSColor(red: 0, green: 0, blue: 1, alpha: backgroundRainbowAlpha),
                NSColor(red: 1, green: 0, blue: 1, alpha: backgroundRainbowAlpha),
                NSColor(red: 1, green: 0, blue: 0, alpha: backgroundRainbowAlpha)
            ]
            return isEnabled ? colors : colors.map({ $0.colorByDesaturating(disabledControlDimmingRatio) })
            
        default:
            let colors = [backgroundGradientStart, backgroundGradientEnd]
            return isEnabled ? colors : colors.map({ $0.colorByDesaturating(disabledControlDimmingRatio) })
        }
    }
    
    
    private func getBackgroundColors() -> [NSColor] {
        return _backgroundColors.map({ $0.usingColorSpace(NSColorSpace.sRGB) ?? $0 })
    }
    
    
    private func getBackgroundGradient() -> NSGradient? {
        return NSGradient(colors: _backgroundColors.map({ $0.usingColorSpace(NSColorSpace.sRGB) ?? $0 }))
    }
    
    
    private var getSelectedStrokeColor: NSColor {
        get {
            var colorForStyle = NSColor(red: 1.0, green: 1, blue: 1, alpha: 0.70)
            colorForStyle = colorForStyle.usingColorSpace(NSColorSpace.sRGB) ?? colorForStyle
            
            if !isEnabled {
                colorForStyle = colorForStyle.colorByDesaturating(disabledControlDimmingRatio)
            }
            
            return colorForStyle
        }
    }
    
    
    // MARK: - UI Sizing
    
    private var sliderWidth: CGFloat {
        get {
            if knobStyle == .square {
                return barWidth
            } else {
                return NSHeight(bounds) - verticalShadowPadding
            }
        }
    }
    
    private var sliderHeight: CGFloat {
        return isDragging ? NSHeight(bounds) - verticalShadowPadding : sliderWidth
    }
    
    private var minSliderX: CGFloat { return 0.0 }
    
    private var maxSliderX: CGFloat {
        return NSWidth(bounds) - sliderWidth - barTrailingMargin
    }
    
    private var frameRect: NSRect {
        return crispLineRect(NSMakeRect(0.0, 0.0, NSWidth(bounds), NSHeight(bounds)))
    }
    
    private var backgroundWidth: CGFloat {
        return (backgroundFillUp) ? NSWidth(bounds) : CGFloat(selection.start) * NSWidth(bounds)
    }
    
    private var backgroundHeight: CGFloat {
        return isDragging ? NSHeight(bounds) - verticalShadowPadding : 3.0
    }
    
    private var backgroundRect: NSRect {
        return crispLineRect(NSMakeRect(0.0, (NSHeight(bounds) - backgroundHeight) / 2.0, backgroundWidth, backgroundHeight))
    }
    
    private var barRect: NSRect {
        var x = max(CGFloat(selection.start) * NSWidth(bounds) - (sliderWidth / 2.0), minSliderX)
        x = min(x, maxSliderX)
        return crispLineRect(NSMakeRect(x, (NSHeight(bounds) - sliderHeight) / 2.0, sliderWidth, sliderHeight))
    }
    
    
    // MARK: - Drawing
    
    private func drawLayers() {
        // Draw control frame
        let framePath = NSBezierPath(roundedRect: frameRect, xRadius: frameRadius, yRadius: frameRadius)
        frameLayer.frame = bounds
        frameLayer.path = framePath.cgPath
        frameLayer.fillColor = NSColor.black.cgColor
        frameLayer.strokeColor = NSColor.black.cgColor
        frameGradientLayer.frame = bounds
        frameGradientLayer.colors = getFrameColors().map({ $0.cgColor })
        frameGradientLayer.startPoint = CGPoint(x: 0, y: 0)
        frameGradientLayer.endPoint = CGPoint(x: 1, y: 0)
        frameGradientLayer.mask = frameLayer
        
        // Draw bar
        let barPath = (knobStyle == .square) ? NSBezierPath(roundedRect: barRect, xRadius: barRadius, yRadius: barRadius) : NSBezierPath(ovalIn: barRect)
        barLayer.frame = bounds
        barLayer.path = barPath.cgPath
        barLayer.fillColor = getBarColor()?.cgColor
        barLayer.strokeColor = barStrokeColor.cgColor
        barLayer.lineWidth = 0.25
        barLayer.shadowColor = NSColor.shadowColor.cgColor
        barLayer.shadowOpacity = 0.35
        barLayer.shadowOffset = CGSize(width: 0, height: -0.5)
        barLayer.shadowRadius = 1
        
        // Draw background
        let backgroundPath = NSBezierPath(roundedRect: backgroundRect, xRadius: backgroundRadius, yRadius: backgroundRadius)
        backgroundLayer.frame = bounds
        backgroundLayer.path = backgroundPath.cgPath
        backgroundLayer.fillColor = NSColor.black.cgColor
        backgroundLayer.strokeColor = NSColor.black.cgColor
        backgroundGradientLayer.frame = bounds
        backgroundGradientLayer.colors = getBackgroundColors().map({ $0.cgColor })
        backgroundGradientLayer.startPoint = CGPoint(x: 0, y: 0)
        backgroundGradientLayer.endPoint = CGPoint(x: 1, y: 0)
        backgroundGradientLayer.mask = backgroundLayer
    }
    
    
    private func updateLayersOnDrag() {
        noteFocusRingMaskChanged()
        
        // Draw bar
        barLayer.fillColor = getBarColor()?.cgColor
        let barPathAnim = CABasicAnimation(keyPath: "path")
        barPathAnim.fromValue = barLayer.path
        let barPath = (knobStyle == .square) ? NSBezierPath(roundedRect: barRect, xRadius: barRadius, yRadius: barRadius) : NSBezierPath(ovalIn: barRect)
        barPathAnim.toValue = barPath
        barPathAnim.duration = 1.0
        barLayer.add(barPathAnim, forKey: "animateBarHeight")
        barLayer.path = barPath.cgPath
        
        // Draw background
        let backgroundPathAnim = CABasicAnimation(keyPath: "path")
        backgroundPathAnim.fromValue = backgroundLayer.path
        backgroundPathAnim.toValue = NSBezierPath(roundedRect: backgroundRect, xRadius: backgroundRadius, yRadius: backgroundRadius).cgPath
        backgroundPathAnim.duration = 1.0
        backgroundLayer.add(backgroundPathAnim, forKey: "animateBackgroundHeight")
        backgroundLayer.path = NSBezierPath(roundedRect: backgroundRect, xRadius: backgroundRadius, yRadius: backgroundRadius).cgPath
    }
    
    
    private func updateLayerOnDisable() {
        backgroundLayer.removeAllAnimations()
        
        barLayer.fillColor = getBarColor()?.cgColor
        barLayer.strokeColor = getBarStrokeColor().cgColor
        
        backgroundGradientLayer.colors = getBackgroundColors().map({ $0.cgColor })
    }
    
    
    override func drawFocusRingMask() {
        let barPath = (knobStyle == .square) ? NSBezierPath(roundedRect: barRect, xRadius: barRadius, yRadius: barRadius) : NSBezierPath(ovalIn: barRect)
        barPath.fill()
    }
    
    
    override var focusRingMaskBounds: NSRect {
        return bounds.insetBy(dx: 1, dy: 1)
    }
}


extension NSColor {
    func colorByDesaturating(_ desaturationRatio: CGFloat) -> NSColor {
//        let color = NSColor(hue: self.hueComponent, saturation: self.saturationComponent * desaturationRatio, brightness: self.brightnessComponent, alpha: self.alphaComponent)
        return self
    }
    
    static var transparent: NSColor {
        get {
            return NSColor(white: 1.0, alpha: 0.0)
        }
    }
}


extension NSBezierPath {
    
    var cgPath: CGPath {
        get {
            return self.transformToCGPath()
        }
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


extension CAGradientLayer {
    func animateChanges(to colors: [NSColor], duration: TimeInterval) {
        CATransaction.begin()
        CATransaction.setCompletionBlock {
            self.colors = colors.map { $0.cgColor }
        }
        let animation = CABasicAnimation(keyPath: "colors")
        animation.duration = duration
        animation.toValue = colors.map { $0.cgColor }
        animation.fillMode = CAMediaTimingFillMode.forwards
        animation.isRemovedOnCompletion = false
        add(animation, forKey: "changeColors")
        CATransaction.commit()
    }
}
