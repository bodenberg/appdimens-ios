import Foundation

#if canImport(CoreGraphics)
import CoreGraphics
#else
public typealias CGFloat = Double
#endif

/// Facade whose names mirror AppDimens Dynamic on Android while using iOS points.
public enum AppDimens {
    public static func dynamic(_ value: CGFloat) -> DynamicDimension { DynamicDimension(value) }
    public static func dynamic(_ value: Int) -> DynamicDimension { dynamic(CGFloat(value)) }
    public static func fixed(_ value: CGFloat) -> FixedDimension { FixedDimension(value) }
    public static func fixed(_ value: Int) -> FixedDimension { fixed(CGFloat(value)) }
    public static func dy(_ value: CGFloat) -> DynamicDimension { dynamic(value) }
    public static func fx(_ value: CGFloat) -> FixedDimension { fixed(value) }

    public static func percentage(_ percentage: CGFloat, of axis: DimensionAxis = .lowest, in context: DimensionContext) -> CGFloat {
        context.length(for: axis) * min(max(percentage, 0), 1)
    }

    public static func availableItemCount(container: CGFloat, item: CGFloat, spacing: CGFloat = 0) -> Int {
        guard container > 0, item > 0, spacing >= 0 else { return 0 }
        return max(0, Int((container + spacing) / (item + spacing)))
    }
}
