import Foundation
#if canImport(CoreGraphics)
import CoreGraphics
#endif

/// Scaling policy. Defaults model a 360 pt-wide phone design without Android density assumptions.
public struct DimensionConfiguration: Sendable, Hashable {
    public var referenceWidth: CGFloat
    public var referenceHeight: CGFloat
    public var axis: DimensionAxis
    public var strategy: ScalingStrategy
    public var minimumScale: CGFloat
    public var maximumScale: CGFloat
    public var fontScaling: FontScaling
    public var pixelRounding: PixelRounding

    public init(referenceWidth: CGFloat = 360, referenceHeight: CGFloat = 800, axis: DimensionAxis = .lowest,
                strategy: ScalingStrategy = .balanced, minimumScale: CGFloat = 0.75, maximumScale: CGFloat = 1.5,
                fontScaling: FontScaling = .system, pixelRounding: PixelRounding = .nearestPixel) {
        self.referenceWidth = max(referenceWidth, 1); self.referenceHeight = max(referenceHeight, 1)
        self.axis = axis; self.strategy = strategy
        self.minimumScale = min(minimumScale, maximumScale); self.maximumScale = max(minimumScale, maximumScale)
        self.fontScaling = fontScaling; self.pixelRounding = pixelRounding
    }

    public static let `default` = DimensionConfiguration()
}

public enum ScalingStrategy: Sendable, Hashable {
    case linear
    /// Dampens extremes using the geometric mean of linear scaling and 1.
    case balanced
    /// Responsive until the configured limits, useful for readable controls.
    case clamped
    case none
}
public enum FontScaling: Sendable, Hashable { case system, layoutOnly, none }
public enum PixelRounding: Sendable, Hashable { case none, nearestPixel, up, down }
