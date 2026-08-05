import Foundation

public struct DimensOptions: Hashable, Sendable {
    public var qualifier: DimensQualifier
    public var inverter: DimensInverter
    public var aspectRatioAware: Bool
    public var aspectSensitivity: Double?
    public var ignoreMultiWindow: Bool

    public init(qualifier: DimensQualifier = .smallestWidth, inverter: DimensInverter = .none,
                aspectRatioAware: Bool = false, aspectSensitivity: Double? = nil,
                ignoreMultiWindow: Bool = false) {
        self.qualifier = qualifier; self.inverter = inverter
        self.aspectRatioAware = aspectRatioAware; self.aspectSensitivity = aspectSensitivity
        self.ignoreMultiWindow = ignoreMultiWindow
    }
}

/// Stateless linear engine behind `sdp`, `wdp`, `hdp`, and their text variants.
public enum Dimens {
    public static func scale(_ value: Double, in context: DimensContext,
                             options: DimensOptions = .init()) -> Double {
        guard value.isFinite else { return value }
        if options.ignoreMultiWindow && context.isMultiWindow { return value }
        let dimension = context.measure(options.qualifier, inverter: options.inverter)
        guard options.aspectRatioAware else { return value * dimension / DimensDesign.baseWidth }
        let k = options.aspectSensitivity ?? 0.10
        let logAspect = log((context.aspectRatio / DimensDesign.referenceAspectRatio).clamped(min: 0.01, max: 100))
        return value * (1 + (dimension - DimensDesign.baseWidth) * ((1 / DimensDesign.baseWidth) + k * logAspect / DimensDesign.baseWidth))
    }

    public static func text(_ value: Double, in context: DimensContext,
                            policy: DimensTextScale = .scaled,
                            options: DimensOptions = .init()) -> Double {
        let points = scale(value, in: context, options: options)
        return policy == .scaled ? points * context.dynamicTypeScale : points
    }

    public static func pixels(_ points: Double, in context: DimensContext) -> Double { points * context.displayScale }
    public static func points(_ pixels: Double, in context: DimensContext) -> Double { pixels / context.displayScale }
}

extension Comparable {
    fileprivate func clamped(min lower: Self, max upper: Self) -> Self { Swift.min(Swift.max(self, lower), upper) }
}

/// Familiar Android-like names without hidden global screen state.
public extension BinaryInteger {
    func sdp(in context: DimensContext) -> Double { Dimens.scale(Double(self), in: context) }
    func wdp(in context: DimensContext) -> Double { Dimens.scale(Double(self), in: context, options: .init(qualifier: .width)) }
    func hdp(in context: DimensContext) -> Double { Dimens.scale(Double(self), in: context, options: .init(qualifier: .height)) }
    func ssp(in context: DimensContext) -> Double { Dimens.text(Double(self), in: context) }
    func sem(in context: DimensContext) -> Double { Dimens.text(Double(self), in: context, policy: .fixed) }
}

public extension BinaryFloatingPoint {
    func sdp(in context: DimensContext) -> Double { Dimens.scale(Double(self), in: context) }
    func wdp(in context: DimensContext) -> Double { Dimens.scale(Double(self), in: context, options: .init(qualifier: .width)) }
    func hdp(in context: DimensContext) -> Double { Dimens.scale(Double(self), in: context, options: .init(qualifier: .height)) }
    func ssp(in context: DimensContext) -> Double { Dimens.text(Double(self), in: context) }
    func sem(in context: DimensContext) -> Double { Dimens.text(Double(self), in: context, policy: .fixed) }
}
