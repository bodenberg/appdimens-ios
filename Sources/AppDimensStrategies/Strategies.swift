import Foundation
import AppDimensCore

/// The fourteen scaling families exposed by AppDimens Dynamic 3.1.6.
public enum DimensStrategy: String, Sendable, CaseIterable {
    case plain, scaled, auto, density, diagonal, fill, fit, fluid
    case interpolated, logarithmic, percent, perimeter, power, physical
}

public struct StrategyOptions: Hashable, Sendable {
    public var qualifier: DimensQualifier
    public var inverter: DimensInverter
    public var aspectRatioAware: Bool
    public var ignoreMultiWindow: Bool
    public var percent: Double
    public var fluidRange: ClosedRange<Double>
    public var fluidScale: ClosedRange<Double>
    public var power: Double
    public var interpolation: Double

    public init(qualifier: DimensQualifier = .smallestWidth, inverter: DimensInverter = .none,
                aspectRatioAware: Bool = false, ignoreMultiWindow: Bool = false,
                percent: Double = 100, fluidRange: ClosedRange<Double> = 320...768,
                fluidScale: ClosedRange<Double> = 0.8...1.2, power: Double = 0.75,
                interpolation: Double = 0.5) {
        self.qualifier = qualifier; self.inverter = inverter; self.aspectRatioAware = aspectRatioAware
        self.ignoreMultiWindow = ignoreMultiWindow; self.percent = percent
        self.fluidRange = fluidRange; self.fluidScale = fluidScale; self.power = power
        self.interpolation = interpolation
    }
}

public enum DimensStrategies {
    public static func resolve(_ value: Double, strategy: DimensStrategy, in context: DimensContext,
                               options: StrategyOptions = .init()) -> Double {
        guard value.isFinite else { return value }
        if options.ignoreMultiWindow && context.isMultiWindow { return value }
        let d = context.measure(options.qualifier, inverter: options.inverter)
        let widthRatio = context.width / DimensDesign.baseWidth
        let heightRatio = context.height / DimensDesign.baseHeight
        let linear = d / DimensDesign.baseWidth
        let factor: Double
        switch strategy {
        case .plain: factor = 1
        case .scaled, .auto, .density:
            return Dimens.scale(value, in: context, options: .init(qualifier: options.qualifier,
                inverter: options.inverter, aspectRatioAware: options.aspectRatioAware,
                ignoreMultiWindow: options.ignoreMultiWindow))
        case .diagonal: factor = hypot(context.width, context.height) / DimensDesign.baseDiagonal
        case .perimeter: factor = (context.width + context.height) / DimensDesign.basePerimeter
        case .fill: factor = max(widthRatio, heightRatio)
        case .fit: factor = min(widthRatio, heightRatio)
        case .fluid:
            let range = options.fluidRange
            let t = ((d - range.lowerBound) / (range.upperBound - range.lowerBound)).clamped(to: 0...1)
            factor = options.fluidScale.lowerBound + t * (options.fluidScale.upperBound - options.fluidScale.lowerBound)
        case .interpolated: factor = 1 + (linear - 1) * options.interpolation.clamped(to: 0...1)
        case .logarithmic:
            factor = d >= DimensDesign.baseWidth ? 1 + 0.4 * log(d / DimensDesign.baseWidth) : 1 - 0.4 * log(DimensDesign.baseWidth / d)
        case .percent: return d * (options.percent / 100) * (value / 100)
        case .power: factor = pow(d / DimensDesign.baseWidth, options.power)
        case .physical: factor = 1
        }
        return value * factor
    }
}

private extension Comparable { func clamped(to range: ClosedRange<Self>) -> Self { min(max(self, range.lowerBound), range.upperBound) } }

public extension BinaryInteger {
    func dynamic(_ strategy: DimensStrategy, in context: DimensContext, options: StrategyOptions = .init()) -> Double {
        DimensStrategies.resolve(Double(self), strategy: strategy, in: context, options: options)
    }
}
public extension BinaryFloatingPoint {
    func dynamic(_ strategy: DimensStrategy, in context: DimensContext, options: StrategyOptions = .init()) -> Double {
        DimensStrategies.resolve(Double(self), strategy: strategy, in: context, options: options)
    }
}
