@_exported import AppDimens
import Foundation

/// Resize options for ``DynamicDimens/resolve(_:strategy:configuration:options:)``.
/// Mirrors the dynamic-android kernel parameters.
public struct StrategyOptions: Hashable, Sendable {
    public var qualifier: DpQualifier
    public var inverter: Inverter
    public var applyAspectRatio, ignoreMultiWindows: Bool
    /// Custom sensitivity `k` (Android `customSensitivityK`); `nil` = default.
    public var sensitivityK: Double?
    public init(qualifier: DpQualifier = .smallWidth, inverter: Inverter = .default,
        applyAspectRatio: Bool = false, ignoreMultiWindows: Bool = false,
        sensitivityK: Double? = nil) {
        self.qualifier = qualifier; self.inverter = inverter
        self.applyAspectRatio = applyAspectRatio; self.ignoreMultiWindows = ignoreMultiWindows
        self.sensitivityK = sensitivityK
    }
}

/// Runtime strategy selection (e.g. A/B tests, remote config, design tokens).
public enum DynamicDimens {
    @inlinable public static func resolve(_ value: Double, strategy: DimensStrategy,
        configuration c: DimensConfiguration, options o: StrategyOptions = .init()) -> Double {
        AppDimens.resolve(value, strategy: strategy, configuration: c, qualifier: o.qualifier,
            inverter: o.inverter, ignoreMultiWindows: o.ignoreMultiWindows,
            applyAspectRatio: o.applyAspectRatio, sensitivityK: o.sensitivityK)
    }

    /// Ambient-window variant.
    @inlinable public static func resolve(_ value: Double, strategy: DimensStrategy,
        options o: StrategyOptions = .init()) -> Double {
        AppDimens._withAmbient { resolve(value, strategy: strategy, configuration: $0, options: o) }
    }
}

public extension DimensNumber {
    /// `16.dynamic(.power, configuration)` — strategy chosen at runtime, explicit window (points).
    @inlinable func dynamic(_ strategy: DimensStrategy, _ c: DimensConfiguration, options: StrategyOptions = .init()) -> Double {
        DynamicDimens.resolve(dimensValue, strategy: strategy, configuration: c, options: options)
    }
    /// `16.dynamic(.power)` — strategy chosen at runtime, ambient window.
    @inlinable func dynamic(_ strategy: DimensStrategy, options: StrategyOptions = .init()) -> CGFloat {
        CGFloat(DynamicDimens.resolve(dimensValue, strategy: strategy, options: options))
    }

    // Named conveniences — explicit window with full options.
    @inlinable func scaledDp(_ c: DimensConfiguration, options: StrategyOptions = .init()) -> Double { dynamic(.scaled, c, options: options) }
    @inlinable func densityDp(_ c: DimensConfiguration, options: StrategyOptions = .init()) -> Double { dynamic(.density, c, options: options) }
    @inlinable func diagonalDp(_ c: DimensConfiguration, options: StrategyOptions = .init()) -> Double { dynamic(.diagonal, c, options: options) }
    @inlinable func fillDp(_ c: DimensConfiguration, options: StrategyOptions = .init()) -> Double { dynamic(.fill, c, options: options) }
    @inlinable func fitDp(_ c: DimensConfiguration, options: StrategyOptions = .init()) -> Double { dynamic(.fit, c, options: options) }
    @inlinable func fluidDp(_ c: DimensConfiguration, options: StrategyOptions = .init()) -> Double { dynamic(.fluid, c, options: options) }
    @inlinable func interpolatedDp(_ c: DimensConfiguration, options: StrategyOptions = .init()) -> Double { dynamic(.interpolated, c, options: options) }
    @inlinable func logarithmicDp(_ c: DimensConfiguration, options: StrategyOptions = .init()) -> Double { dynamic(.logarithmic, c, options: options) }
    @inlinable func percentDp(_ c: DimensConfiguration, options: StrategyOptions = .init()) -> Double { dynamic(.percent, c, options: options) }
    @inlinable func perimeterDp(_ c: DimensConfiguration, options: StrategyOptions = .init()) -> Double { dynamic(.perimeter, c, options: options) }
    @inlinable func powerDp(_ c: DimensConfiguration, options: StrategyOptions = .init()) -> Double { dynamic(.power, c, options: options) }
    @inlinable func autoDp(_ c: DimensConfiguration, options: StrategyOptions = .init()) -> Double { dynamic(.auto, c, options: options) }
}

/// Precomputed window factors for hot loops (particles, charts, per-vertex work):
/// a single switch and multiply per value, no lock, no transcendental math.
@frozen public struct DimensFactors: Hashable, Sendable {
    public let configuration: DimensConfiguration
    public let smallest, width, height, diagonal, perimeter, fit, fill: Double
    public let power, fluid, auto, interpolated, logarithmic, density: Double

    @inlinable public init(_ c: DimensConfiguration) {
        configuration = c
        let m = c.metrics
        smallest = m.scale; width = m.screenWidthFactor; height = m.screenHeightFactor
        diagonal = m.diagonalScale; perimeter = m.perimeterScale; fit = m.fitScale; fill = m.fillScale
        power = m.powerScale; fluid = m.fluidScale; auto = m.autoScale
        interpolated = m.interpolatedScale; logarithmic = m.logarithmicScale; density = m.density
    }

    /// Ambient-window snapshot.
    public static var current: DimensFactors { DimensFactors(AppDimens.configuration) }

    /// Default-path (smallest width, no aspect ratio) factor of `strategy`.
    @inlinable public func factor(_ strategy: DimensStrategy) -> Double {
        switch strategy {
        case .scaled, .percent: return smallest
        case .density: return density
        case .diagonal: return diagonal
        case .perimeter: return perimeter
        case .fill: return fill
        case .fit: return fit
        case .power: return power
        case .fluid: return fluid
        case .auto: return auto
        case .interpolated: return interpolated
        case .logarithmic: return logarithmic
        case .plain, .physical: return 1
        }
    }

    /// Allocation-free resolution on the default path (identical to the kernels).
    @inlinable public func resolve(_ value: Double, strategy: DimensStrategy) -> Double { value * factor(strategy) }

    /// Resolves a whole buffer in place (vectorizes well).
    @inlinable public func resolve(_ values: inout [Double], strategy: DimensStrategy) {
        let f = factor(strategy)
        for i in values.indices { values[i] *= f }
    }
}
