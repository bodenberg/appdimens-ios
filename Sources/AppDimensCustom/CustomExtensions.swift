import Foundation
#if canImport(SwiftUI)
import SwiftUI
#endif

// Android-style accessors — `16.cdp(brand)` mirrors Kotlin `16.cdp(Brand)`, `16.cdp` uses
// ``ScalingStrategies/defaultStrategy``. Zero-argument forms read the ambient window
// (`AppDimens.configuration`); the `(_ configuration:)` forms are explicit (multi-window).

public extension DimensNumber {
    // ── default strategy ────────────────────────────────────────────────────
    /// Default strategy · ambient window · points.
    var cdp: CGFloat { CGFloat(ScalingStrategies.defaultStrategy.dp(dimensValue)) }
    /// Default strategy · ambient window · physical pixels.
    var cdpPx: CGFloat { CGFloat(ScalingStrategies.defaultStrategy.px(dimensValue)) }
    /// Default strategy · ambient window · final text point size.
    var csp: CGFloat { CGFloat(ScalingStrategies.defaultStrategy.sp(dimensValue)) }
    /// Default strategy · ambient window · text physical pixels.
    var cspPx: CGFloat { CGFloat(ScalingStrategies.defaultStrategy.spPx(dimensValue)) }

    /// Default strategy · explicit window · points.
    func cdp(_ configuration: DimensConfiguration) -> Double {
        ScalingStrategies.defaultStrategy.dp(dimensValue, configuration)
    }
    /// Default strategy · explicit window · final text point size.
    func csp(_ configuration: DimensConfiguration) -> Double {
        ScalingStrategies.defaultStrategy.sp(dimensValue, configuration)
    }

    // ── explicit strategy ───────────────────────────────────────────────────
    /// `16.cdp(brand)` · ambient window · points.
    func cdp(_ strategy: ScalingStrategy) -> CGFloat { CGFloat(strategy.dp(dimensValue)) }
    /// `16.cdp(brand, configuration)` · explicit window · points.
    func cdp(_ strategy: ScalingStrategy, _ configuration: DimensConfiguration) -> Double {
        strategy.dp(dimensValue, configuration)
    }
    /// `16.cdpPx(brand)` · ambient window · physical pixels.
    func cdpPx(_ strategy: ScalingStrategy) -> CGFloat { CGFloat(strategy.px(dimensValue)) }
    /// `14.csp(brand)` · ambient window · final text point size.
    func csp(_ strategy: ScalingStrategy) -> CGFloat { CGFloat(strategy.sp(dimensValue)) }
    /// `14.csp(brand, configuration)` · explicit window · final text point size.
    func csp(_ strategy: ScalingStrategy, _ configuration: DimensConfiguration) -> Double {
        strategy.sp(dimensValue, configuration)
    }
    /// `14.cspPx(brand)` · ambient window · text physical pixels.
    func cspPx(_ strategy: ScalingStrategy) -> CGFloat { CGFloat(strategy.spPx(dimensValue)) }

    // ── inline formula ──────────────────────────────────────────────────────
    // The formula **is** the value, shared per text (``ScalingStrategies/formula(_:)``); write
    // `base * (…)` for the one-multiply fast path. Invalid formulas throw the parse error.

    /// `try 16.cdp("base * pow(sw / 360, 0.8)")` · ambient window · points.
    func cdp(_ formula: String) throws -> CGFloat { try cdp(ScalingStrategies.formula(formula)) }
    /// `try 16.cdp("…", configuration)` · explicit window · points.
    func cdp(_ formula: String, _ configuration: DimensConfiguration) throws -> Double {
        try cdp(ScalingStrategies.formula(formula), configuration)
    }
    /// `try 16.cdpPx("…")` · ambient window · physical pixels.
    func cdpPx(_ formula: String) throws -> CGFloat { try cdpPx(ScalingStrategies.formula(formula)) }
    /// `try 14.csp("base * min(sw / 360, 1.3)")` · ambient window · final text point size.
    func csp(_ formula: String) throws -> CGFloat { try csp(ScalingStrategies.formula(formula)) }
    /// `try 14.csp("…", configuration)` · explicit window · final text point size.
    func csp(_ formula: String, _ configuration: DimensConfiguration) throws -> Double {
        try csp(ScalingStrategies.formula(formula), configuration)
    }
    /// `try 14.cspPx("…")` · ambient window · text physical pixels.
    func cspPx(_ formula: String) throws -> CGFloat { try cspPx(ScalingStrategies.formula(formula)) }
}

#if canImport(SwiftUI)
private struct ScalingStrategyKey: EnvironmentKey {
    static let defaultValue: ScalingStrategy? = nil
}

public extension EnvironmentValues {
    /// Strategy provided by ``SwiftUI/View/scalingStrategy(_:)`` (`nil` = the global default).
    var scalingStrategy: ScalingStrategy? {
        get { self[ScalingStrategyKey.self] }
        set { self[ScalingStrategyKey.self] = newValue }
    }
}

public extension View {
    /// Every ``CustomDimension`` without an explicit strategy below this view uses `strategy`.
    func scalingStrategy(_ strategy: ScalingStrategy) -> some View {
        environment(\.scalingStrategy, strategy)
    }
}

/// Resolves a value with a custom strategy against the window of the view that owns it
/// (correct in multi-window apps on every OS version).
///
/// ```swift
/// @CustomDimension(16) var padding                  // environment strategy (or default)
/// @CustomDimension(16, strategy: brand) var gap      // explicit strategy
/// @CustomDimension(text: 14) var bodySize            // final text point size
/// ```
@propertyWrapper public struct CustomDimension: DynamicProperty {
    @Environment(\.appDimensConfiguration) private var configuration
    @Environment(\.scalingStrategy) private var scoped
    private let value: Double
    private let strategy: ScalingStrategy?
    private let text: Bool

    public init(_ value: Double, strategy: ScalingStrategy? = nil) {
        self.value = value
        self.strategy = strategy
        self.text = false
    }

    public init(text value: Double, strategy: ScalingStrategy? = nil) {
        self.value = value
        self.strategy = strategy
        self.text = true
    }

    /// `@CustomDimension(16, formula: "base * pow(sw / 360, 0.8)") var padding` — the formula
    /// **is** the value (shared per text). Write `base * (…)` for the one-multiply fast path.
    /// Prefer a strategy built with `try scalingFormula(_:)` to handle parse errors; here an
    /// invalid formula stops in debug builds and returns the value unscaled in release builds.
    public init(_ value: Double, formula: String) {
        self.init(value, strategy: Self.formulaStrategy(formula))
    }

    /// `@CustomDimension(text: 14, formula: "base * min(sw / 360, 1.3)") var bodySize`.
    public init(text value: Double, formula: String) {
        self.init(text: value, strategy: Self.formulaStrategy(formula))
    }

    private static func formulaStrategy(_ formula: String) -> ScalingStrategy {
        do {
            return try ScalingStrategies.formula(formula)
        } catch {
            assertionFailure("\(error)")
            return BuiltInStrategies.fixed
        }
    }

    public var wrappedValue: CGFloat {
        let s = strategy ?? scoped ?? ScalingStrategies.defaultStrategy
        return CGFloat(text ? s.sp(value, configuration) : s.dp(value, configuration))
    }
}
#endif
