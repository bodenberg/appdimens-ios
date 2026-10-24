import Foundation

// "Just write the formula" — the simplest custom strategies (reference: Android `ScalingFormula.kt`).
// Primary form: one line of typed Swift whose closure parameter is a scope with the same names as
// the text language (`base`, `sw`, `tablet`, `pow`, …). Text formulas stay for JSON / remote config.

/// What a code formula can read, with the **same names as the text formulas**, so Xcode
/// autocompletes them and typos fail at compile time. Values are in points; flags are `Bool`.
/// Adopted by ``ScreenScope`` (factor closures) and ``FormulaScope`` (value closures).
public protocol ScalingScope: Sendable {
    /// The full window snapshot.
    var screen: ScreenSnapshot { get }
}

public extension ScalingScope {
    /// Smallest width (pt).
    var sw: Double { screen.smallestWidthDp }
    var width: Double { screen.widthDp }
    var height: Double { screen.heightDp }
    var shortSide: Double { screen.minDp }
    var longSide: Double { screen.maxDp }
    var diagonal: Double { screen.read(.diagonal) }
    var perimeter: Double { screen.read(.perimeter) }
    var aspectRatio: Double { screen.aspectRatio }
    var density: Double { screen.density }
    var fontScale: Double { screen.fontScale }
    /// `sw / 300` — the ratio `sdp` uses (`base * ratio` = `sdp`).
    var ratio: Double { sw / ReferenceScreen.standard.read(.smallestWidth) }

    var landscape: Bool { screen.isLandscape }
    var portrait: Bool { !screen.isLandscape }
    var multiWindow: Bool { screen.isMultiWindow }
    var device: DeviceClass { screen.device }
    var phone: Bool { screen.device == .phone }
    var tablet: Bool { screen.device == .tablet }
    var desktop: Bool { screen.device == .desktop }
    var tv: Bool { screen.device == .tv }
    var watch: Bool { screen.device == .watch }
    var car: Bool { screen.device == .car }
    var vr: Bool { screen.device == .vr }

    // Math helpers with the text-language names, so no import is needed.
    func pow(_ x: Double, _ exponent: Double) -> Double { scopePow(x, exponent) }
    func sqrt(_ x: Double) -> Double { x.squareRoot() }
    func ln(_ x: Double) -> Double { scopeLn(x) }
    func log10(_ x: Double) -> Double { scopeLog10(x) }
    func exp(_ x: Double) -> Double { scopeExp(x) }
    func abs(_ x: Double) -> Double { Swift.abs(x) }
    /// Half up, like the text `round`: `floor(x + 0.5)`.
    func round(_ x: Double) -> Double { (x + 0.5).rounded(.down) }
    func min(_ a: Double, _ b: Double) -> Double { Swift.min(a, b) }
    func max(_ a: Double, _ b: Double) -> Double { Swift.max(a, b) }
    func clamp(_ x: Double, _ lower: Double, _ upper: Double) -> Double { Swift.max(lower, Swift.min(upper, x)) }
    func lerp(_ a: Double, _ b: Double, _ t: Double) -> Double { a + (b - a) * t }
    func smoothstep(_ edge0: Double, _ edge1: Double, _ x: Double) -> Double {
        let t = Swift.max(0, Swift.min(1, (x - edge0) / (edge1 - edge0)))
        return t * t * (3 - 2 * t)
    }
}

// File-level forwarders: inside the scope, `pow` / `exp` / … name the scope's own methods.
private func scopePow(_ x: Double, _ y: Double) -> Double { pow(x, y) }
private func scopeLn(_ x: Double) -> Double { log(x) }
private func scopeLog10(_ x: Double) -> Double { log10(x) }
private func scopeExp(_ x: Double) -> Double { exp(x) }

/// The window, for a factor closure: `CustomScaleStrategy { s in s.clamp(s.width / 360, 0.85, 1.8) }`.
public struct ScreenScope: ScalingScope {
    public let screen: ScreenSnapshot
    public init(_ screen: ScreenSnapshot) { self.screen = screen }
}

/// ``ScreenScope`` plus `base`, the value being scaled (the `16` in `16.cdp(hud)`):
/// `scalingFormula { $0.base * $0.pow($0.sw / 360, 0.8) }`.
public struct FormulaScope: ScalingScope {
    public let screen: ScreenSnapshot
    /// The value you pass (`16` in `16.cdp(hud)`).
    public let base: Double
    public init(_ screen: ScreenSnapshot, base: Double) {
        self.screen = screen
        self.base = base
    }
}

/// One-liner strategy from a **text** formula, for JSON, remote config or a formula that comes from
/// outside the code. Same names as the code form (`base`, `sw`, `tablet`, `pow`, …); the formula
/// **is** the final value:
///
/// ```swift
/// let hud = try scalingFormula("base * pow(sw / 360, 0.8)")
/// view.layoutMargins.left = 16.cdp(hud)        // or straight: try 16.cdp("base * pow(sw / 360, 0.8)")
/// ```
///
/// Variables: `base` (the value you pass, e.g. 16), `sw`, `width`, `height`, `shortSide`, `longSide`,
/// `diagonal`, `aspectRatio`, `density`, `fontScale`, the device flags (`tablet`, `tv`, `landscape`, …)
/// and `ratio` (`sw / 300`, the same ratio `sdp` uses). Writing it as `base * (…)` keeps it on the
/// one-multiply fast path (the `(…)` part is computed once per window); any other shape still works.
///
/// Without an `id` the strategy is shared per formula text (calling this again with the same text
/// returns the same instance) and not registered. With an `id` it is a new strategy, registered
/// unless `register: false`. Parse errors throw right away, with the position.
public func scalingFormula(_ formula: String, id: String? = nil, register: Bool? = nil) throws -> ScalingStrategy {
    let shouldRegister = register ?? (id != nil)
    if id == nil && !shouldRegister { return try ScalingStrategies.formula(formula) }
    let strategy = try ScalingStrategy.textFormula(id: id ?? "formula:\(formula)", formula)
    if shouldRegister { ScalingStrategies.register(strategy) }
    return strategy
}

/// One-liner strategy from a **code** formula — the result **is** the final value. Typed Swift with
/// autocomplete, no strings, no limits:
///
/// ```swift
/// let hud = scalingFormula { $0.base * $0.pow($0.sw / 360, 0.8) }
/// let card = scalingFormula { s in s.tablet ? s.base * 1.2 : s.base * s.ratio }
/// ```
///
/// The closure gets a ``FormulaScope``: `base`, the window (`sw`, `width`, `height`, `ratio`,
/// `tablet`, `landscape`, …) and `pow`, `clamp`, `min`, `max`, `lerp`… Must be pure. Declare it once
/// (e.g. a `static let`). Not JSON-serializable: the text form `try scalingFormula("…")` is.
/// Without an `id` a unique `formula#N` id is generated; with an `id` it is registered unless
/// `register: false`.
public func scalingFormula(id: String? = nil, register: Bool? = nil,
                           _ formula: @escaping @Sendable (FormulaScope) -> Double) -> ScalingStrategy {
    var config = ScalingConfig()
    config.transform = { base, _, screen in formula(FormulaScope(screen, base: base)) }
    return codeStrategy(id: id ?? ScalingStrategies.nextCodeId("formula"), config,
                        register: register ?? (id != nil))
}

/// Strategy from a programmable **factor** — you return the number that multiplies every value:
///
/// ```swift
/// let product = CustomScaleStrategy { s in s.clamp(s.width / 360, 0.85, 1.80) }
/// let living = CustomScaleStrategy { s in s.tv ? s.height / 540 : s.ratio }
/// view.layoutMargins.left = 16.cdp(product)   // 16 × factor
/// ```
///
/// The closure gets a ``ScreenScope`` (the window, with autocomplete) and can use any Swift code of
/// yours. The factor depends only on the window, so it runs once per window and every value then
/// costs one multiply. A non-finite factor falls back to 1 when the window resolves (a broken curve
/// never poisons a layout pass). Without an `id` a unique `scale#N` id is generated; with an `id` it
/// is registered unless `register: false`. Not JSON-serializable: for JSON, use a text curve
/// (`try .expression("clamp(width / 360, 0.85, 1.8)")`).
public func CustomScaleStrategy(id: String? = nil, register: Bool? = nil,
                                _ factor: @escaping @Sendable (ScreenScope) -> Double) -> ScalingStrategy {
    var config = ScalingConfig()
    config.curve = .custom({ _, screen in factor(ScreenScope(screen)) })
    return codeStrategy(id: id ?? ScalingStrategies.nextCodeId("scale"), config,
                        register: register ?? (id != nil))
}

public extension ScalingStrategy {
    /// `ScalingStrategy.formula("base * pow(sw / 360, 0.8)")` — shared per text, same as
    /// ``scalingFormula(_:id:register:)`` without an id.
    static func formula(_ formula: String) throws -> ScalingStrategy {
        try ScalingStrategies.formula(formula)
    }

    /// `ScalingStrategy.formula { $0.base * $0.pow($0.sw / 360, 0.8) }` — same as
    /// ``scalingFormula(id:register:_:)``.
    static func formula(id: String? = nil, register: Bool? = nil,
                        _ formula: @escaping @Sendable (FormulaScope) -> Double) -> ScalingStrategy {
        scalingFormula(id: id, register: register, formula)
    }

    /// Strategy whose config is the default one plus the text `formula` (per-value).
    internal static func textFormula(id: String, _ formula: String) throws -> ScalingStrategy {
        var config = ScalingConfig()
        config.formula = try ScalingExpression.parse(formula, allowed: ScalingExpression.formulaVariables)
        return try ScalingStrategy(id, config: config)
    }
}

/// Builds a code strategy. Its config is the default one plus a function, so it is always valid;
/// only a blank `id` can fail, which is a programming error.
private func codeStrategy(id: String, _ config: ScalingConfig, register: Bool) -> ScalingStrategy {
    let strategy: ScalingStrategy
    do {
        strategy = try ScalingStrategy(id, config: config)
    } catch {
        preconditionFailure("\(error)")
    }
    if register { ScalingStrategies.register(strategy) }
    return strategy
}
