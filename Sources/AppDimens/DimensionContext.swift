import Foundation
#if canImport(CoreGraphics)
import CoreGraphics
#endif

/// All mutable platform information needed by the calculator, supplied explicitly for testability.
public struct DimensionContext: Sendable, Hashable {
    public var width: CGFloat
    public var height: CGFloat
    public var displayScale: CGFloat
    public var dynamicTypeScale: CGFloat
    public var idiom: DeviceIdiom
    public var horizontalSizeClass: AdaptiveSizeClass?
    public var verticalSizeClass: AdaptiveSizeClass?

    public init(width: CGFloat, height: CGFloat, displayScale: CGFloat = 1, dynamicTypeScale: CGFloat = 1,
                idiom: DeviceIdiom = .unspecified, horizontalSizeClass: AdaptiveSizeClass? = nil,
                verticalSizeClass: AdaptiveSizeClass? = nil) {
        self.width = max(0, width); self.height = max(0, height)
        self.displayScale = max(displayScale, 1); self.dynamicTypeScale = max(dynamicTypeScale, 0.5)
        self.idiom = idiom; self.horizontalSizeClass = horizontalSizeClass; self.verticalSizeClass = verticalSizeClass
    }

    public var shortestSide: CGFloat { min(width, height) }
    public var longestSide: CGFloat { max(width, height) }
    public var orientation: BaseOrientation { width > height ? .landscape : .portrait }
    public func length(for axis: DimensionAxis) -> CGFloat {
        switch axis { case .width: width; case .height: height; case .lowest: shortestSide; case .highest: longestSide }
    }
}

public enum DimensionAxis: String, Sendable, Hashable { case lowest, highest, width, height }
public enum BaseOrientation: String, Sendable, Hashable { case auto, portrait, landscape }
public enum DeviceIdiom: String, Sendable, Hashable { case phone, pad, mac, tv, watch, vision, carPlay, unspecified }
public enum AdaptiveSizeClass: String, Sendable, Hashable { case compact, regular }
