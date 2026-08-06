import Foundation
import AppDimensCore

/// Precomputed viewport factors for hot render/layout loops. Build once when the
/// viewport changes and resolve any number of values without repeating geometry math.
@frozen public struct DimensSnapshot: Hashable, Sendable {
    public let context: DimensContext
    public let widthRatio, heightRatio, diagonalRatio, perimeterRatio: Double
    public let smallestRatio, widthAxisRatio, heightAxisRatio: Double

    @inlinable public init(_ context: DimensContext) {
        self.context = context
        widthRatio = context.width / DimensDesign.baseWidth
        heightRatio = context.height / DimensDesign.baseHeight
        diagonalRatio = (context.width * context.width + context.height * context.height).squareRoot() / DimensDesign.baseDiagonal
        perimeterRatio = (context.width + context.height) / DimensDesign.basePerimeter
        smallestRatio = context.smallestWidth / DimensDesign.baseWidth
        widthAxisRatio = context.width / DimensDesign.baseWidth
        heightAxisRatio = context.height / DimensDesign.baseWidth
    }

    /// Fast path for the common non-inverted strategy set.
    @inlinable public func resolve(_ value: Double, strategy: DimensStrategy,
                                   options: StrategyOptions = .init()) -> Double {
        if options.inverter != .none || options.aspectRatioAware || options.ignoreMultiWindow {
            return DimensStrategies.resolve(value, strategy: strategy, in: context, options: options)
        }
        let ratio: Double
        switch options.qualifier { case .smallestWidth: ratio = smallestRatio; case .width: ratio = widthAxisRatio; case .height: ratio = heightAxisRatio }
        switch strategy {
        case .plain, .physical: return value
        case .scaled, .auto, .density: return value * ratio
        case .diagonal: return value * diagonalRatio
        case .perimeter: return value * perimeterRatio
        case .fill: return value * Swift.max(widthRatio, heightRatio)
        case .fit: return value * Swift.min(widthRatio, heightRatio)
        case .interpolated: return value * (1 + (ratio - 1) * Swift.min(Swift.max(options.interpolation, 0), 1))
        case .power: return value * Foundation.pow(ratio, options.power)
        case .logarithmic:
            return value * (ratio >= 1 ? 1 + 0.4 * Foundation.log(ratio) : 1 - 0.4 * Foundation.log(1 / ratio))
        case .percent: return context.measure(options.qualifier) * options.percent * value / 10_000
        case .fluid:
            let span = options.fluidRange.upperBound - options.fluidRange.lowerBound
            let dimension = context.measure(options.qualifier)
            let t = Swift.min(Swift.max((dimension - options.fluidRange.lowerBound) / span, 0), 1)
            return value * (options.fluidScale.lowerBound + t * (options.fluidScale.upperBound - options.fluidScale.lowerBound))
        }
    }

    /// Allocation-free in-place batch resolution.
    @inlinable public func resolve(_ values: UnsafeBufferPointer<Double>,
                                   into output: UnsafeMutableBufferPointer<Double>,
                                   strategy: DimensStrategy, options: StrategyOptions = .init()) {
        precondition(output.count >= values.count)
        for index in values.indices { output[index] = resolve(values[index], strategy: strategy, options: options) }
    }
}
