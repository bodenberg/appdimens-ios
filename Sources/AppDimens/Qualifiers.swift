import Foundation
#if canImport(CoreGraphics)
import CoreGraphics
#endif

/// iOS-native equivalent of Android resource qualifiers.
public enum DimensionQualifier: Sendable, Hashable {
    case minWidth(CGFloat), maxWidth(CGFloat)
    case minHeight(CGFloat), maxHeight(CGFloat)
    case minShortestSide(CGFloat), maxShortestSide(CGFloat)
    case orientation(BaseOrientation)
    case idiom(DeviceIdiom)
    case horizontalSizeClass(AdaptiveSizeClass)
    case verticalSizeClass(AdaptiveSizeClass)

    public func matches(_ context: DimensionContext) -> Bool {
        switch self {
        case .minWidth(let v): context.width >= v
        case .maxWidth(let v): context.width <= v
        case .minHeight(let v): context.height >= v
        case .maxHeight(let v): context.height <= v
        case .minShortestSide(let v): context.shortestSide >= v
        case .maxShortestSide(let v): context.shortestSide <= v
        case .orientation(.auto): true
        case .orientation(let v): context.orientation == v
        case .idiom(let v): context.idiom == v
        case .horizontalSizeClass(let v): context.horizontalSizeClass == v
        case .verticalSizeClass(let v): context.verticalSizeClass == v
        }
    }
}

public struct DimensionOverride: Sendable, Hashable {
    public let qualifiers: [DimensionQualifier]
    public let value: CGFloat
    public init(_ qualifiers: [DimensionQualifier], value: CGFloat) { self.qualifiers = qualifiers; self.value = value }
    func matches(_ context: DimensionContext) -> Bool { qualifiers.allSatisfy { $0.matches(context) } }
}
