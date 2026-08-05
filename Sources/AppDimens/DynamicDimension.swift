import Foundation
#if canImport(CoreGraphics)
import CoreGraphics
#endif

/// Immutable, reusable dynamic dimension declaration.
public struct DynamicDimension: Sendable, Hashable {
    public let baseValue: CGFloat
    public private(set) var configuration: DimensionConfiguration
    public private(set) var overrides: [DimensionOverride]
    public private(set) var lowerBound: CGFloat?
    public private(set) var upperBound: CGFloat?

    public init(_ value: CGFloat, configuration: DimensionConfiguration = .default) {
        baseValue = value; self.configuration = configuration; overrides = []; lowerBound = nil; upperBound = nil
    }

    public func configured(_ configuration: DimensionConfiguration) -> Self { changing { $0.configuration = configuration } }
    public func reference(width: CGFloat, height: CGFloat) -> Self { changing { $0.configuration.referenceWidth = max(width, 1); $0.configuration.referenceHeight = max(height, 1) } }
    public func screen(_ axis: DimensionAxis) -> Self { changing { $0.configuration.axis = axis } }
    public func strategy(_ strategy: ScalingStrategy) -> Self { changing { $0.configuration.strategy = strategy } }
    public func limits(min: CGFloat? = nil, max: CGFloat? = nil) -> Self { changing { $0.lowerBound = min; $0.upperBound = max } }
    public func when(_ qualifier: DimensionQualifier, _ value: CGFloat) -> Self { when([qualifier], value) }
    public func when(_ qualifiers: [DimensionQualifier], _ value: CGFloat) -> Self { changing { $0.overrides.append(.init(qualifiers, value: value)) } }

    /// Resolves to logical points. Last matching override wins, like the most recently declared Android qualifier.
    public func points(in context: DimensionContext, text: Bool = false) -> CGFloat {
        let source = overrides.last(where: { $0.matches(context) })?.value ?? baseValue
        let c = configuration
        let reference: CGFloat
        switch c.axis { case .width: reference = c.referenceWidth; case .height: reference = c.referenceHeight
        case .lowest: reference = min(c.referenceWidth, c.referenceHeight); case .highest: reference = max(c.referenceWidth, c.referenceHeight) }
        let linear = context.length(for: c.axis) / max(reference, 1)
        let rawScale: CGFloat
        switch c.strategy { case .none: rawScale = 1; case .linear: rawScale = linear
        case .balanced: rawScale = sqrt(max(linear, 0)); case .clamped: rawScale = linear }
        let scale = min(max(rawScale, c.minimumScale), c.maximumScale)
        var result = source * scale
        if text, c.fontScaling == .system { result *= context.dynamicTypeScale }
        if let lowerBound { result = max(result, lowerBound) }
        if let upperBound { result = min(result, upperBound) }
        return round(result, scale: context.displayScale, mode: c.pixelRounding)
    }

    public func pixels(in context: DimensionContext, text: Bool = false) -> CGFloat { points(in: context, text: text) * context.displayScale }
    private func changing(_ body: (inout Self) -> Void) -> Self { var copy = self; body(&copy); return copy }
}

public struct FixedDimension: Sendable, Hashable {
    public let value: CGFloat
    public init(_ value: CGFloat) { self.value = value }
    public func points(in context: DimensionContext) -> CGFloat { round(value, scale: context.displayScale, mode: .nearestPixel) }
    public func pixels(in context: DimensionContext) -> CGFloat { points(in: context) * context.displayScale }
}

private func round(_ value: CGFloat, scale: CGFloat, mode: PixelRounding) -> CGFloat {
    guard mode != .none else { return value }
    let pixels = value * max(scale, 1)
    let rounded: CGFloat
    switch mode { case .nearestPixel: rounded = pixels.rounded(); case .up: rounded = pixels.rounded(.up); case .down: rounded = pixels.rounded(.down); case .none: rounded = pixels }
    return rounded / max(scale, 1)
}
