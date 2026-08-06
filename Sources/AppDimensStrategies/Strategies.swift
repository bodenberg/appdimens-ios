@_exported import AppDimens
import Foundation

public enum DimensStrategy: String, Sendable, CaseIterable {
    case scaled, auto, density, diagonal, fill, fit, fluid, interpolated
    case logarithmic, percent, perimeter, power, physical, plain
}

public struct StrategyOptions: Hashable, Sendable {
    public var qualifier: DpQualifier; public var inverter: Inverter
    public var applyAspectRatio, ignoreMultiWindows: Bool
    public var sensitivity, percent, power, interpolation: Double
    public var fluidViewport, fluidScale: ClosedRange<Double>
    public init(qualifier: DpQualifier = .smallWidth, inverter: Inverter = .default,
        applyAspectRatio: Bool = false, ignoreMultiWindows: Bool = false,
        sensitivity: Double = 0.10, percent: Double = 100, power: Double = 0.75,
        interpolation: Double = 0.5, fluidViewport: ClosedRange<Double> = 320...768,
        fluidScale: ClosedRange<Double> = 0.8...1.2) {
        self.qualifier = qualifier; self.inverter = inverter; self.applyAspectRatio = applyAspectRatio
        self.ignoreMultiWindows = ignoreMultiWindows; self.sensitivity = sensitivity
        self.percent = percent; self.power = power; self.interpolation = interpolation
        self.fluidViewport = fluidViewport; self.fluidScale = fluidScale
    }
}

public enum DynamicDimens {
    @inlinable public static func resolve(_ value: Double, strategy: DimensStrategy,
        configuration c: DimensConfiguration, options o: StrategyOptions = .init()) -> Double {
        if o.ignoreMultiWindows && c.isMultiWindow { return value }
        let d = c.dimension(o.qualifier, inverter: o.inverter)
        let linear = d / AppDimens.baseRatio
        let wr = c.screenWidth / 300, hr = c.screenHeight / 533
        switch strategy {
        case .plain, .physical: return value
        case .scaled, .auto: return AppDimens.dp(value, configuration: c, qualifier: o.qualifier,
            inverter: o.inverter, ignoreMultiWindows: o.ignoreMultiWindows,
            applyAspectRatio: o.applyAspectRatio, sensitivity: o.sensitivity)
        case .density: return value * linear * c.displayScale
        case .diagonal: return value * hypot(c.screenWidth, c.screenHeight) / hypot(300, 533)
        case .perimeter: return value * (c.screenWidth + c.screenHeight) / 833
        case .fill: return value * max(wr, hr)
        case .fit: return value * min(wr, hr)
        case .fluid:
            let span = o.fluidViewport.upperBound - o.fluidViewport.lowerBound
            let t = min(max((d - o.fluidViewport.lowerBound) / span, 0), 1)
            return value * (o.fluidScale.lowerBound + t * (o.fluidScale.upperBound - o.fluidScale.lowerBound))
        case .interpolated: return value * (1 + (linear - 1) * min(max(o.interpolation, 0), 1))
        case .logarithmic: return value * (linear >= 1 ? 1 + 0.4 * log(linear) : 1 - 0.4 * log(1 / linear))
        case .percent: return d * o.percent * value / 10_000
        case .power: return value * pow(linear, o.power)
        }
    }
}

public extension BinaryInteger {
    @inlinable func dynamic(_ strategy: DimensStrategy, _ c: DimensConfiguration, options: StrategyOptions = .init()) -> Double { DynamicDimens.resolve(Double(self), strategy: strategy, configuration: c, options: options) }
}
public extension BinaryFloatingPoint {
    @inlinable func dynamic(_ strategy: DimensStrategy, _ c: DimensConfiguration, options: StrategyOptions = .init()) -> Double { DynamicDimens.resolve(Double(self), strategy: strategy, configuration: c, options: options) }
}

/// Precomputes immutable factors once per window configuration for hot loops.
@frozen public struct DimensFactors: Hashable, Sendable {
    public let configuration: DimensConfiguration
    public let smallest, width, height, diagonal, perimeter, fit, fill: Double
    @inlinable public init(_ c: DimensConfiguration) {
        configuration = c; smallest = c.smallestScreenWidth / 300; width = c.screenWidth / 300
        height = c.screenHeight / 300; diagonal = hypot(c.screenWidth, c.screenHeight) / hypot(300, 533)
        perimeter = (c.screenWidth + c.screenHeight) / 833
        fit = min(c.screenWidth / 300, c.screenHeight / 533); fill = max(c.screenWidth / 300, c.screenHeight / 533)
    }
}

public extension BinaryInteger {
    func densityDp(_ c: DimensConfiguration, options: StrategyOptions = .init()) -> Double { dynamic(.density, c, options: options) }
    func diagonalDp(_ c: DimensConfiguration, options: StrategyOptions = .init()) -> Double { dynamic(.diagonal, c, options: options) }
    func fillDp(_ c: DimensConfiguration, options: StrategyOptions = .init()) -> Double { dynamic(.fill, c, options: options) }
    func fitDp(_ c: DimensConfiguration, options: StrategyOptions = .init()) -> Double { dynamic(.fit, c, options: options) }
    func fluidDp(_ c: DimensConfiguration, options: StrategyOptions = .init()) -> Double { dynamic(.fluid, c, options: options) }
    func interpolatedDp(_ c: DimensConfiguration, options: StrategyOptions = .init()) -> Double { dynamic(.interpolated, c, options: options) }
    func logarithmicDp(_ c: DimensConfiguration, options: StrategyOptions = .init()) -> Double { dynamic(.logarithmic, c, options: options) }
    func percentDp(_ c: DimensConfiguration, percent: Double, qualifier: DpQualifier = .smallWidth) -> Double { dynamic(.percent, c, options: .init(qualifier: qualifier, percent: percent)) }
    func perimeterDp(_ c: DimensConfiguration, options: StrategyOptions = .init()) -> Double { dynamic(.perimeter, c, options: options) }
    func powerDp(_ c: DimensConfiguration, options: StrategyOptions = .init()) -> Double { dynamic(.power, c, options: options) }
}
public extension BinaryFloatingPoint {
    func densityDp(_ c: DimensConfiguration, options: StrategyOptions = .init()) -> Double { dynamic(.density, c, options: options) }
    func diagonalDp(_ c: DimensConfiguration, options: StrategyOptions = .init()) -> Double { dynamic(.diagonal, c, options: options) }
    func fillDp(_ c: DimensConfiguration, options: StrategyOptions = .init()) -> Double { dynamic(.fill, c, options: options) }
    func fitDp(_ c: DimensConfiguration, options: StrategyOptions = .init()) -> Double { dynamic(.fit, c, options: options) }
    func fluidDp(_ c: DimensConfiguration, options: StrategyOptions = .init()) -> Double { dynamic(.fluid, c, options: options) }
    func interpolatedDp(_ c: DimensConfiguration, options: StrategyOptions = .init()) -> Double { dynamic(.interpolated, c, options: options) }
    func logarithmicDp(_ c: DimensConfiguration, options: StrategyOptions = .init()) -> Double { dynamic(.logarithmic, c, options: options) }
    func percentDp(_ c: DimensConfiguration, percent: Double, qualifier: DpQualifier = .smallWidth) -> Double { dynamic(.percent, c, options: .init(qualifier: qualifier, percent: percent)) }
    func perimeterDp(_ c: DimensConfiguration, options: StrategyOptions = .init()) -> Double { dynamic(.perimeter, c, options: options) }
    func powerDp(_ c: DimensConfiguration, options: StrategyOptions = .init()) -> Double { dynamic(.power, c, options: options) }
}
