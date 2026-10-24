import Foundation

// Custom scaling strategies — platform-free engine (port of Android
// `appdimens-dynamic-custom`). A strategy is an immutable configuration that turns a
// window into one factor:
//
//   ratio  = axis(window) / axis(reference)
//   factor = clamp(curve(ratio) × multiplier × AR, minFactor, maxFactor)
//   value  = formula(clampValue(base × factor, minValue, maxValue))
//
// The JSON format is shared with every AppDimens platform (`custom-strategy.schema.json`).

/// Screen measure a strategy scales against.
public enum ScalingAxis: String, Sendable, CaseIterable, Codable {
    case smallestWidth, width, height, min, max, diagonal, perimeter
}

/// Device family matched by rules.
public enum DeviceClass: String, Sendable, CaseIterable, Codable {
    case phone, tablet, desktop, tv, watch, car, vr

    /// Smallest width (pt) from which a normal window counts as a tablet.
    public static let tabletMinSmallestWidth: Double = 600
}

/// Errors thrown while building or decoding a strategy.
public struct ScalingStrategyError: Error, CustomStringConvertible, Equatable {
    public let description: String
    public init(_ description: String) { self.description = description }
}

/// Immutable, platform-free description of the window a value is resolved for.
public struct ScreenSnapshot: Hashable, Sendable {
    public var widthDp: Double
    public var heightDp: Double
    public var smallestWidthDp: Double
    public var density: Double
    public var fontScale: Double
    public var isLandscape: Bool
    public var isMultiWindow: Bool
    public var device: DeviceClass

    public init(widthDp: Double, heightDp: Double, smallestWidthDp: Double? = nil, density: Double = 1,
                fontScale: Double = 1, isLandscape: Bool? = nil, isMultiWindow: Bool = false,
                device: DeviceClass? = nil) {
        let sw = smallestWidthDp ?? Swift.min(widthDp, heightDp)
        self.widthDp = widthDp
        self.heightDp = heightDp
        self.smallestWidthDp = sw
        self.density = density
        self.fontScale = fontScale
        self.isLandscape = isLandscape ?? (widthDp > heightDp)
        self.isMultiWindow = isMultiWindow
        self.device = device ?? (sw >= DeviceClass.tabletMinSmallestWidth ? .tablet : .phone)
    }

    public var minDp: Double { Swift.min(widthDp, heightDp) }
    public var maxDp: Double { Swift.max(widthDp, heightDp) }
    /// `max / min` (≥ 1).
    public var aspectRatio: Double { minDp > 0 ? maxDp / minDp : 1 }

    public func read(_ axis: ScalingAxis) -> Double {
        switch axis {
        case .smallestWidth: return smallestWidthDp
        case .width: return widthDp
        case .height: return heightDp
        case .min: return minDp
        case .max: return maxDp
        case .diagonal: return (minDp * minDp + maxDp * maxDp).squareRoot()
        case .perimeter: return minDp + maxDp
        }
    }
}

/// Design frame (pt). Default: the AppDimens base 300×533.
public struct ReferenceScreen: Hashable, Sendable {
    public var width: Double
    public var height: Double

    public init(width: Double = 300, height: Double = 533) {
        self.width = width
        self.height = height
    }

    public static let standard = ReferenceScreen()

    var isValid: Bool { width.isFinite && width > 0 && height.isFinite && height > 0 }

    public func read(_ axis: ScalingAxis) -> Double {
        switch axis {
        case .smallestWidth, .min: return Swift.min(width, height)
        case .width: return width
        case .height: return height
        case .max: return Swift.max(width, height)
        case .diagonal: return (width * width + height * height).squareRoot()
        case .perimeter: return width + height
        }
    }
}

/// One point of a breakpoints table: at `at` pt on the axis, the factor is `factor`.
public struct Breakpoint: Hashable, Sendable {
    public var at: Double
    public var factor: Double
    public init(_ at: Double, _ factor: Double) {
        self.at = at
        self.factor = factor
    }
}

/// How the axis ratio `r = screen / reference` becomes a factor.
public enum ScalingCurve: Sendable, Equatable, CustomStringConvertible {
    /// `r` — proportional (built-in `sdp`).
    case linear
    /// `r^exponent` (built-in power uses 0.75).
    case power(Double)
    /// `1 + k·ln(r)` (built-in logarithmic uses 0.4).
    case logarithmic(Double)
    /// `1 + (r − 1)·t` (built-in interpolated uses 0.5).
    case interpolated(Double)
    /// Fixed factor.
    case constant(Double)
    /// Piecewise linear over the **absolute** axis value (pt).
    case breakpoints([Breakpoint])
    /// Free formula written as text (JSON-serializable, same result on every platform).
    /// Build it with `try .expression("pow(ratio, 0.8)")`.
    case expressionCurve(ScalingExpression)
    /// Pure user formula `(ratio, screen) -> factor` (not JSON-serializable).
    case custom(@Sendable (Double, ScreenSnapshot) -> Double)

    /// Free-form curve from text; see `ScalingExpression` for variables and functions.
    public static func expression(_ source: String) throws -> ScalingCurve {
        .expressionCurve(try ScalingExpression.parse(source, allowed: ScalingExpression.curveVariables))
    }

    public static func == (lhs: ScalingCurve, rhs: ScalingCurve) -> Bool {
        switch (lhs, rhs) {
        case (.linear, .linear): return true
        case let (.power(a), .power(b)), let (.logarithmic(a), .logarithmic(b)),
             let (.interpolated(a), .interpolated(b)), let (.constant(a), .constant(b)):
            return a == b
        case let (.breakpoints(a), .breakpoints(b)): return a == b
        case let (.expressionCurve(a), .expressionCurve(b)): return a == b
        default: return false
        }
    }

    public var description: String {
        switch self {
        case .linear: return "linear"
        case let .power(e): return "power(\(e))"
        case let .logarithmic(k): return "logarithmic(\(k))"
        case let .interpolated(t): return "interpolated(\(t))"
        case let .constant(f): return "constant(\(f))"
        case let .breakpoints(p): return "breakpoints(\(p.count))"
        case let .expressionCurve(e): return "expression(\(e.source))"
        case .custom: return "custom"
        }
    }

    var isValid: Bool {
        switch self {
        case .linear, .custom, .expressionCurve: return true
        case let .power(v), let .logarithmic(v), let .interpolated(v), let .constant(v): return v.isFinite
        case let .breakpoints(p):
            return !p.isEmpty && p.allSatisfy { $0.at.isFinite && $0.at >= 0 && $0.factor.isFinite }
        }
    }

    func evaluate(ratio: Double, axisDp: Double, screen: ScreenSnapshot,
                  refDp: Double = .nan, reference: ReferenceScreen = .standard) -> Double {
        switch self {
        case let .expressionCurve(e):
            return e.evaluate(ScalingExpression.variables(screen: screen, ratio: ratio, axisDp: axisDp,
                                                          refDp: refDp, reference: reference))
        case .linear: return ratio
        case let .power(e): return ratio > 0 ? pow(ratio, e) : 0
        case let .logarithmic(k): return ratio > 0 ? 1 + k * log(ratio) : 1
        case let .interpolated(t): return 1 + (ratio - 1) * t
        case let .constant(f): return f
        case let .custom(fn): return fn(ratio, screen)
        case let .breakpoints(unsorted):
            let p = unsorted.sorted { $0.at < $1.at }
            if axisDp <= p[0].at { return p[0].factor }
            for i in 1..<p.count where axisDp <= p[i].at {
                let a = p[i - 1], b = p[i]
                let span = b.at - a.at
                return span <= 0 ? b.factor : a.factor + (b.factor - a.factor) * ((axisDp - a.at) / span)
            }
            return p[p.count - 1].factor
        }
    }
}

/// Font-scale handling for text.
public enum FontScalePolicy: Hashable, Sendable {
    /// Respect the user font scale (default, accessible).
    case follow
    /// Ignore the user font scale (fixed-size labels, game HUD).
    case ignore
    /// Follow up to `max` (e.g. 1.3).
    case clamp(Double)

    public func effective(_ system: Double) -> Double {
        switch self {
        case .follow: return system
        case .ignore: return 1
        case let .clamp(max): return Swift.min(system, max)
        }
    }
}

/// When a rule applies: every non-nil field must match; ranges are `min <= v < max`.
public struct ScreenCondition: Hashable, Sendable {
    public var devices: Set<DeviceClass>?
    public var landscape: Bool?
    public var minSmallestWidth: Double?, maxSmallestWidth: Double?
    public var minWidth: Double?, maxWidth: Double?
    public var minHeight: Double?, maxHeight: Double?
    public var minAspectRatio: Double?, maxAspectRatio: Double?
    public var multiWindow: Bool?

    public init(devices: Set<DeviceClass>? = nil, landscape: Bool? = nil,
                minSmallestWidth: Double? = nil, maxSmallestWidth: Double? = nil,
                minWidth: Double? = nil, maxWidth: Double? = nil,
                minHeight: Double? = nil, maxHeight: Double? = nil,
                minAspectRatio: Double? = nil, maxAspectRatio: Double? = nil,
                multiWindow: Bool? = nil) {
        self.devices = devices
        self.landscape = landscape
        self.minSmallestWidth = minSmallestWidth
        self.maxSmallestWidth = maxSmallestWidth
        self.minWidth = minWidth
        self.maxWidth = maxWidth
        self.minHeight = minHeight
        self.maxHeight = maxHeight
        self.minAspectRatio = minAspectRatio
        self.maxAspectRatio = maxAspectRatio
        self.multiWindow = multiWindow
    }

    private static func inRange(_ v: Double, _ min: Double?, _ max: Double?) -> Bool {
        (min.map { v >= $0 } ?? true) && (max.map { v < $0 } ?? true)
    }

    public func matches(_ s: ScreenSnapshot) -> Bool {
        if let devices = devices, !devices.contains(s.device) { return false }
        if let landscape = landscape, s.isLandscape != landscape { return false }
        guard Self.inRange(s.smallestWidthDp, minSmallestWidth, maxSmallestWidth),
              Self.inRange(s.widthDp, minWidth, maxWidth),
              Self.inRange(s.heightDp, minHeight, maxHeight),
              Self.inRange(s.aspectRatio, minAspectRatio, maxAspectRatio) else { return false }
        if let mw = multiWindow, s.isMultiWindow != mw { return false }
        return true
    }
}

/// Pure per-value hook `(base, scaled, screen) -> value`, applied after the value bounds.
public typealias ValueTransform = @Sendable (Double, Double, ScreenSnapshot) -> Double

/// Partial override applied by a rule (`nil` keeps the current value).
public struct ScalingPatch: Sendable {
    public var reference: ReferenceScreen?
    public var axis: ScalingAxis?
    public var curve: ScalingCurve?
    public var multiplier: Double?
    public var minFactor: Double?, maxFactor: Double?
    public var minValue: Double?, maxValue: Double?
    public var aspectRatio: Bool?
    public var sensitivity: Double?
    public var fontScale: FontScalePolicy?
    public var ignoreMultiWindow: Bool?
    public var transform: ValueTransform?
    /// Per-value text formula (JSON-serializable); replaces `transform`.
    public var formula: ScalingExpression?

    public init(reference: ReferenceScreen? = nil, axis: ScalingAxis? = nil, curve: ScalingCurve? = nil,
                multiplier: Double? = nil, minFactor: Double? = nil, maxFactor: Double? = nil,
                minValue: Double? = nil, maxValue: Double? = nil, aspectRatio: Bool? = nil,
                sensitivity: Double? = nil, fontScale: FontScalePolicy? = nil,
                ignoreMultiWindow: Bool? = nil, transform: ValueTransform? = nil,
                formula: ScalingExpression? = nil) {
        self.reference = reference
        self.axis = axis
        self.curve = curve
        self.multiplier = multiplier
        self.minFactor = minFactor
        self.maxFactor = maxFactor
        self.minValue = minValue
        self.maxValue = maxValue
        self.aspectRatio = aspectRatio
        self.sensitivity = sensitivity
        self.fontScale = fontScale
        self.ignoreMultiWindow = ignoreMultiWindow
        self.transform = transform
        self.formula = formula
    }

    /// A proportional text formula (`base * E`) is screen-only.
    var isValueDependent: Bool {
        minValue != nil || maxValue != nil || transform != nil || formula?.isProportional == false
    }
}

/// When `condition` matches, apply `patch`. Matching rules apply in declaration order.
public struct ScalingRule: Sendable {
    public var condition: ScreenCondition
    public var patch: ScalingPatch
    public var name: String?

    public init(_ condition: ScreenCondition, _ patch: ScalingPatch, name: String? = nil) {
        self.condition = condition
        self.patch = patch
        self.name = name
    }

    /// Rule for one or more device classes.
    public static func on(_ devices: Set<DeviceClass>, _ patch: ScalingPatch, name: String? = nil) -> ScalingRule {
        ScalingRule(ScreenCondition(devices: devices), patch, name: name)
    }
}

/// Full immutable definition of a strategy.
public struct ScalingConfig: Sendable {
    public var reference: ReferenceScreen = .standard
    public var axis: ScalingAxis = .smallestWidth
    public var curve: ScalingCurve = .linear
    public var multiplier: Double = 1
    public var minFactor: Double?
    public var maxFactor: Double?
    public var minValue: Double?
    public var maxValue: Double?
    public var aspectRatio: Bool = false
    public var sensitivity: Double?
    public var fontScale: FontScalePolicy = .follow
    public var ignoreMultiWindow: Bool = false
    public var transform: ValueTransform?
    /// Per-value text formula; takes the place of `transform`.
    public var formula: ScalingExpression?
    public var rules: [ScalingRule] = []

    public init() {}

    /// True when some path depends on the value itself (not only on the screen). A proportional
    /// text formula (`base * E`) is screen-only.
    public var isValueDependent: Bool {
        minValue != nil || maxValue != nil || transform != nil || formula?.isProportional == false ||
            rules.contains { $0.patch.isValueDependent }
    }

    /// Returns this config with `patch` applied (nil fields keep their value).
    public func applying(_ p: ScalingPatch) -> ScalingConfig {
        var c = self
        if let v = p.reference { c.reference = v }
        if let v = p.axis { c.axis = v }
        if let v = p.curve { c.curve = v }
        if let v = p.multiplier { c.multiplier = v }
        if let v = p.minFactor { c.minFactor = v }
        if let v = p.maxFactor { c.maxFactor = v }
        if let v = p.minValue { c.minValue = v }
        if let v = p.maxValue { c.maxValue = v }
        if let v = p.aspectRatio { c.aspectRatio = v }
        if let v = p.sensitivity { c.sensitivity = v }
        if let v = p.fontScale { c.fontScale = v }
        if let v = p.ignoreMultiWindow { c.ignoreMultiWindow = v }
        if let v = p.formula {
            c.formula = v
            c.transform = nil
        } else if let v = p.transform {
            c.transform = v
            c.formula = nil
        }
        return c
    }

    /// Validates the declared config (the base and each rule on top of it).
    public func validate() throws {
        func check(_ c: ScalingConfig, _ where_: String) throws {
            guard c.reference.isValid else { throw ScalingStrategyError("\(where_): reference must be > 0") }
            guard c.curve.isValid else { throw ScalingStrategyError("\(where_): invalid curve \(c.curve)") }
            for (name, v) in [("multiplier", Optional(c.multiplier)), ("minFactor", c.minFactor),
                              ("maxFactor", c.maxFactor), ("minValue", c.minValue), ("maxValue", c.maxValue),
                              ("sensitivity", c.sensitivity)] {
                if let v = v, !v.isFinite { throw ScalingStrategyError("\(where_): \(name) must be finite") }
            }
            if let a = c.minFactor, let b = c.maxFactor, a > b {
                throw ScalingStrategyError("\(where_): minFactor must be <= maxFactor")
            }
            if let a = c.minValue, let b = c.maxValue, a > b {
                throw ScalingStrategyError("\(where_): minValue must be <= maxValue")
            }
            if case let .clamp(max) = c.fontScale, !(max.isFinite && max > 0) {
                throw ScalingStrategyError("\(where_): fontScale max must be > 0")
            }
        }
        try check(self, "strategy")
        for (i, rule) in rules.enumerated() { try check(applying(rule.patch), "rules[\(i)]") }
    }
}

/// Default aspect-ratio sensitivity — same constant as the built-in strategies (0.08 / 30).
public let customSensitivityDefault: Double = 0.08 / 30

/// Everything a strategy needs for one window: the screen-only factor plus value parts.
public struct ResolvedScaling: Sendable {
    public let screen: ScreenSnapshot
    public let config: ScalingConfig
    public let factor: Double
    public let appliedRules: [String]
    public let axisDp: Double
    public let referenceDp: Double
    public let curveFactor: Double
    public let aspectRatioMultiplier: Double
    /// `E` of a proportional formula (`base * E`), evaluated once for this window; NaN when the
    /// formula (if any) needs the value. `base * E` then costs one multiply, like a curve.
    let formulaCoefficient: Double

    /// `base` → scaled value (pt).
    public func scale(_ base: Double) -> Double {
        var out = base * factor
        if config.minValue != nil || config.maxValue != nil, out != 0 {
            // Bounds apply to the magnitude so negative offsets mirror positive ones; 0 stays 0.
            var magnitude = abs(out)
            if let min = config.minValue, magnitude < min { magnitude = min }
            if let max = config.maxValue, magnitude > max { magnitude = max }
            out = out < 0 ? -magnitude : magnitude
        }
        if let formula = config.formula, formula.isProportional {
            out = base * formulaCoefficient
        } else if let formula = config.formula {
            let ratio = referenceDp > 0 ? axisDp / referenceDp : 1
            out = formula.evaluate(ScalingExpression.variables(screen: screen, ratio: ratio, axisDp: axisDp,
                                                               refDp: referenceDp, reference: config.reference,
                                                               base: base, scaled: out, factor: factor))
        } else if let transform = config.transform {
            out = transform(base, out, screen)
        }
        return out
    }

    public var effectiveFontScale: Double { config.fontScale.effective(screen.fontScale) }

    /// Final text point size (Apple fonts take the final size).
    public func scaleSpDp(_ base: Double) -> Double { scale(base) * effectiveFontScale }

    /// Text size before a platform font scale is applied (`scaleSpDp / systemFontScale`).
    public func scaleSpUnits(_ base: Double) -> Double {
        screen.fontScale > 0 ? scale(base) * (effectiveFontScale / screen.fontScale) : scale(base)
    }

    public func explain(_ strategyId: String) -> String {
        func f(_ v: Double) -> String {
            let r = (v * 10_000).rounded() / 10_000
            return r == r.rounded() ? String(Int(r)) : String(r)
        }
        let c = config
        var out = "[\(strategyId)] \(screen.device.rawValue) \(c.axis.rawValue)=\(f(axisDp))dp / ref \(f(referenceDp)) = \(f(axisDp / referenceDp))"
        out += " -> \(c.curve) = \(f(curveFactor))"
        if c.multiplier != 1 { out += " x \(f(c.multiplier))" }
        if c.aspectRatio { out += " x AR \(f(aspectRatioMultiplier))" }
        if c.minFactor != nil || c.maxFactor != nil {
            out += " clamp[\(c.minFactor.map(f) ?? "-"), \(c.maxFactor.map(f) ?? "-")]"
        }
        out += " => factor \(f(factor))"
        if let formula = c.formula {
            out += " then formula(\(formula.source))"
        } else if c.transform != nil {
            out += " then transform"
        }
        if !appliedRules.isEmpty { out += " rules=[\(appliedRules.joined(separator: ", "))]" }
        return out
    }
}

/// Pure math shared by every binding.
public enum ScalingEngine {
    static let referenceAspectRatio: Double = 1.78

    /// Resolves `base` for `screen` (matching rules applied in declaration order).
    public static func resolve(_ base: ScalingConfig, _ screen: ScreenSnapshot) -> ResolvedScaling {
        var cfg = base
        var applied: [String] = []
        for (i, rule) in base.rules.enumerated() where rule.condition.matches(screen) {
            cfg = cfg.applying(rule.patch)
            applied.append(rule.name ?? "#\(i)")
        }
        let axisDp = screen.read(cfg.axis)
        let refDp = cfg.reference.read(cfg.axis)
        let ratio = refDp > 0 ? axisDp / refDp : 1
        let coefficient = cfg.formula?.baseCoefficient?.eval(
            ScalingExpression.variables(screen: screen, ratio: ratio, axisDp: axisDp, refDp: refDp,
                                        reference: cfg.reference)) ?? .nan
        if cfg.ignoreMultiWindow && screen.isMultiWindow {
            return ResolvedScaling(screen: screen, config: cfg, factor: 1, appliedRules: applied,
                                   axisDp: axisDp, referenceDp: refDp, curveFactor: 1, aspectRatioMultiplier: 1,
                                   formulaCoefficient: coefficient)
        }
        let curveFactor = cfg.curve.evaluate(ratio: ratio, axisDp: axisDp, screen: screen,
                                             refDp: refDp, reference: cfg.reference)
        var factor = curveFactor * cfg.multiplier
        var arMul = 1.0
        if cfg.aspectRatio {
            let k = cfg.sensitivity ?? customSensitivityDefault
            arMul = 1 + k * log(screen.aspectRatio / referenceAspectRatio)
            factor *= arMul
        }
        if let min = cfg.minFactor, factor < min { factor = min }
        if let max = cfg.maxFactor, factor > max { factor = max }
        if !factor.isFinite { factor = 1 } // a broken custom curve must never poison a layout pass
        return ResolvedScaling(screen: screen, config: cfg, factor: factor, appliedRules: applied,
                               axisDp: axisDp, referenceDp: refDp, curveFactor: curveFactor,
                               aspectRatioMultiplier: arMul, formulaCoefficient: coefficient)
    }
}
