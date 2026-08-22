@_exported import AppDimens
import Foundation

public enum DimensStrategy: String, Sendable, CaseIterable {
    case scaled, auto, density, diagonal, fill, fit, fluid, interpolated
    case logarithmic, percent, perimeter, power, physical, plain
}

/// Resize options for [DynamicDimens.resolve]. Mirrors the 3.1.7 kernel
/// parameters; fluid viewport/scale and interpolation are no longer
/// configurable (fixed constants, as in dynamic-android 3.1.7).
public struct StrategyOptions: Hashable, Sendable {
    public var qualifier: DpQualifier
    public var inverter: Inverter
    public var applyAspectRatio, ignoreMultiWindows: Bool
    /// Custom sensitivity `k` (3.1.7 `customSensitivityK`); `nil` = default.
    public var sensitivityK: Double?
    public init(qualifier: DpQualifier = .smallWidth, inverter: Inverter = .default,
        applyAspectRatio: Bool = false, ignoreMultiWindows: Bool = false,
        sensitivityK: Double? = nil) {
        self.qualifier = qualifier; self.inverter = inverter
        self.applyAspectRatio = applyAspectRatio; self.ignoreMultiWindows = ignoreMultiWindows
        self.sensitivityK = sensitivityK
    }
}

public enum DynamicDimens {
    @inlinable public static func resolve(_ value: Double, strategy: DimensStrategy,
        configuration c: DimensConfiguration, options o: StrategyOptions = .init()) -> Double {
        switch strategy {
        case .plain, .physical: return value
        case .scaled:
            return AppDimens.scaledDp(value, configuration: c, qualifier: o.qualifier,
                inverter: o.inverter, ignoreMultiWindows: o.ignoreMultiWindows,
                applyAspectRatio: o.applyAspectRatio, sensitivityK: o.sensitivityK)
        case .auto:
            return AppDimens.autoDp(value, configuration: c, qualifier: o.qualifier,
                inverter: o.inverter, ignoreMultiWindows: o.ignoreMultiWindows,
                applyAspectRatio: o.applyAspectRatio, sensitivityK: o.sensitivityK)
        case .density:
            return AppDimens.densityDp(value, configuration: c, qualifier: o.qualifier,
                inverter: o.inverter, ignoreMultiWindows: o.ignoreMultiWindows,
                applyAspectRatio: o.applyAspectRatio, sensitivityK: o.sensitivityK)
        case .diagonal:
            return AppDimens.diagonalDp(value, configuration: c, qualifier: o.qualifier,
                inverter: o.inverter, ignoreMultiWindows: o.ignoreMultiWindows,
                applyAspectRatio: o.applyAspectRatio, sensitivityK: o.sensitivityK)
        case .perimeter:
            return AppDimens.perimeterDp(value, configuration: c, qualifier: o.qualifier,
                inverter: o.inverter, ignoreMultiWindows: o.ignoreMultiWindows,
                applyAspectRatio: o.applyAspectRatio, sensitivityK: o.sensitivityK)
        case .fill:
            return AppDimens.fillDp(value, configuration: c, qualifier: o.qualifier,
                inverter: o.inverter, ignoreMultiWindows: o.ignoreMultiWindows,
                applyAspectRatio: o.applyAspectRatio, sensitivityK: o.sensitivityK)
        case .fit:
            return AppDimens.fitDp(value, configuration: c, qualifier: o.qualifier,
                inverter: o.inverter, ignoreMultiWindows: o.ignoreMultiWindows,
                applyAspectRatio: o.applyAspectRatio, sensitivityK: o.sensitivityK)
        case .fluid:
            return AppDimens.fluidDp(value, configuration: c, qualifier: o.qualifier,
                inverter: o.inverter, ignoreMultiWindows: o.ignoreMultiWindows,
                applyAspectRatio: o.applyAspectRatio, sensitivityK: o.sensitivityK)
        case .interpolated:
            return AppDimens.interpolatedDp(value, configuration: c, qualifier: o.qualifier,
                inverter: o.inverter, ignoreMultiWindows: o.ignoreMultiWindows,
                applyAspectRatio: o.applyAspectRatio, sensitivityK: o.sensitivityK)
        case .logarithmic:
            return AppDimens.logarithmicDp(value, configuration: c, qualifier: o.qualifier,
                inverter: o.inverter, ignoreMultiWindows: o.ignoreMultiWindows,
                applyAspectRatio: o.applyAspectRatio, sensitivityK: o.sensitivityK)
        case .percent:
            return AppDimens.percentDp(value, configuration: c, qualifier: o.qualifier,
                inverter: o.inverter, ignoreMultiWindows: o.ignoreMultiWindows,
                applyAspectRatio: o.applyAspectRatio, sensitivityK: o.sensitivityK)
        case .power:
            return AppDimens.powerDp(value, configuration: c, qualifier: o.qualifier,
                inverter: o.inverter, ignoreMultiWindows: o.ignoreMultiWindows,
                applyAspectRatio: o.applyAspectRatio, sensitivityK: o.sensitivityK)
        }
    }
}

public extension BinaryInteger {
    @inlinable func dynamic(_ strategy: DimensStrategy, _ c: DimensConfiguration, options: StrategyOptions = .init()) -> Double { DynamicDimens.resolve(Double(self), strategy: strategy, configuration: c, options: options) }
}
public extension BinaryFloatingPoint {
    @inlinable func dynamic(_ strategy: DimensStrategy, _ c: DimensConfiguration, options: StrategyOptions = .init()) -> Double { DynamicDimens.resolve(Double(self), strategy: strategy, configuration: c, options: options) }
}

/// Precomputes immutable window factors for hot loops (3.1.7 formulas).
@frozen public struct DimensFactors: Hashable, Sendable {
    public let configuration: DimensConfiguration
    public let smallest, width, height, diagonal, perimeter, fit, fill: Double
    @inlinable public init(_ c: DimensConfiguration) {
        configuration = c
        let m = c.metrics
        smallest = m.scale
        width = c.screenWidth * DimensConstants.invBaseRatio
        height = c.screenHeight * DimensConstants.invBaseRatio
        diagonal = m.diagonalScale
        perimeter = m.perimeterScale
        let sm = m.minDimensionDp, lg = m.maxDimensionDp
        fit = min(sm / DimensConstants.baseWidthDp, lg / DimensConstants.baseHeightDp)
        fill = max(sm / DimensConstants.baseWidthDp, lg / DimensConstants.baseHeightDp)
    }

    /// Allocation-free fast path for strategies whose factor depends only on the window.
    @inlinable public func resolve(_ value: Double, strategy: DimensStrategy) -> Double {
        switch strategy {
        case .scaled: return value * smallest
        case .density: return value * configuration.displayScale
        case .diagonal: return value * diagonal
        case .perimeter: return value * perimeter
        case .fill: return value * fill
        case .fit: return value * fit
        case .plain, .physical: return value
        default: return DynamicDimens.resolve(value, strategy: strategy, configuration: configuration)
        }
    }
}

/// Named conveniences for each satellite — Android-style strategy naming.
public extension BinaryInteger {
    func densityDp(_ c: DimensConfiguration, options: StrategyOptions = .init()) -> Double { dynamic(.density, c, options: options) }
    func diagonalDp(_ c: DimensConfiguration, options: StrategyOptions = .init()) -> Double { dynamic(.diagonal, c, options: options) }
    func fillDp(_ c: DimensConfiguration, options: StrategyOptions = .init()) -> Double { dynamic(.fill, c, options: options) }
    func fitDp(_ c: DimensConfiguration, options: StrategyOptions = .init()) -> Double { dynamic(.fit, c, options: options) }
    func fluidDp(_ c: DimensConfiguration, options: StrategyOptions = .init()) -> Double { dynamic(.fluid, c, options: options) }
    func interpolatedDp(_ c: DimensConfiguration, options: StrategyOptions = .init()) -> Double { dynamic(.interpolated, c, options: options) }
    func logarithmicDp(_ c: DimensConfiguration, options: StrategyOptions = .init()) -> Double { dynamic(.logarithmic, c, options: options) }
    func percentDp(_ c: DimensConfiguration, options: StrategyOptions = .init()) -> Double { dynamic(.percent, c, options: options) }
    func perimeterDp(_ c: DimensConfiguration, options: StrategyOptions = .init()) -> Double { dynamic(.perimeter, c, options: options) }
    func powerDp(_ c: DimensConfiguration, options: StrategyOptions = .init()) -> Double { dynamic(.power, c, options: options) }
    func autoDp(_ c: DimensConfiguration, options: StrategyOptions = .init()) -> Double { dynamic(.auto, c, options: options) }
}
public extension BinaryFloatingPoint {
    func densityDp(_ c: DimensConfiguration, options: StrategyOptions = .init()) -> Double { dynamic(.density, c, options: options) }
    func diagonalDp(_ c: DimensConfiguration, options: StrategyOptions = .init()) -> Double { dynamic(.diagonal, c, options: options) }
    func fillDp(_ c: DimensConfiguration, options: StrategyOptions = .init()) -> Double { dynamic(.fill, c, options: options) }
    func fitDp(_ c: DimensConfiguration, options: StrategyOptions = .init()) -> Double { dynamic(.fit, c, options: options) }
    func fluidDp(_ c: DimensConfiguration, options: StrategyOptions = .init()) -> Double { dynamic(.fluid, c, options: options) }
    func interpolatedDp(_ c: DimensConfiguration, options: StrategyOptions = .init()) -> Double { dynamic(.interpolated, c, options: options) }
    func logarithmicDp(_ c: DimensConfiguration, options: StrategyOptions = .init()) -> Double { dynamic(.logarithmic, c, options: options) }
    func percentDp(_ c: DimensConfiguration, options: StrategyOptions = .init()) -> Double { dynamic(.percent, c, options: options) }
    func perimeterDp(_ c: DimensConfiguration, options: StrategyOptions = .init()) -> Double { dynamic(.perimeter, c, options: options) }
    func powerDp(_ c: DimensConfiguration, options: StrategyOptions = .init()) -> Double { dynamic(.power, c, options: options) }
    func autoDp(_ c: DimensConfiguration, options: StrategyOptions = .init()) -> Double { dynamic(.auto, c, options: options) }
}