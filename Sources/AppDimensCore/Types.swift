import Foundation

/// Logical screen orientation. `automatic` derives it from the viewport.
public enum DimensOrientation: String, Sendable, CaseIterable { case automatic, portrait, landscape }

/// iOS equivalents for Android's `UiModeType` qualifiers.
public enum DimensInterfaceMode: String, Sendable, CaseIterable {
    case normal, phone, pad, television, watch, carPlay, vision, mac, unspecified
}

/// Axis used by Android-compatible `sdp`, `wdp`, and `hdp` calculations.
public enum DimensQualifier: String, Sendable, CaseIterable { case smallestWidth, width, height }

/// Controls which physical axis is used after an orientation change.
public enum DimensInverter: String, Sendable, CaseIterable {
    case none, portraitWidth, portraitHeight, landscapeWidth, landscapeHeight
}

/// Font scaling policy. Use `scaled` for Android `sp`, and `fixed` for `em`-style values.
public enum DimensTextScale: Sendable { case scaled, fixed }

/// Immutable, testable description of the current Apple viewport in points.
public struct DimensContext: Hashable, Sendable {
    public var width: Double
    public var height: Double
    public var displayScale: Double
    public var dynamicTypeScale: Double
    public var interfaceMode: DimensInterfaceMode
    public var fullScreenWidth: Double?
    public var fullScreenHeight: Double?

    public init(width: Double, height: Double, displayScale: Double = 1,
                dynamicTypeScale: Double = 1, interfaceMode: DimensInterfaceMode = .unspecified,
                fullScreenWidth: Double? = nil, fullScreenHeight: Double? = nil) {
        precondition(width.isFinite && height.isFinite && width > 0 && height > 0)
        precondition(displayScale.isFinite && displayScale > 0)
        precondition(dynamicTypeScale.isFinite && dynamicTypeScale > 0)
        self.width = width; self.height = height; self.displayScale = displayScale
        self.dynamicTypeScale = dynamicTypeScale; self.interfaceMode = interfaceMode
        self.fullScreenWidth = fullScreenWidth; self.fullScreenHeight = fullScreenHeight
    }

    public var smallestWidth: Double { min(width, height) }
    public var longestWidth: Double { max(width, height) }
    public var orientation: DimensOrientation { width > height ? .landscape : .portrait }
    public var aspectRatio: Double { longestWidth / smallestWidth }
    public var isMultiWindow: Bool {
        guard let fw = fullScreenWidth, let fh = fullScreenHeight else { return false }
        return width < fw * 0.95 || height < fh * 0.95
    }

    public func measure(_ qualifier: DimensQualifier, inverter: DimensInverter = .none) -> Double {
        switch inverter {
        case .portraitWidth where orientation == .portrait, .landscapeWidth where orientation == .landscape: return width
        case .portraitHeight where orientation == .portrait, .landscapeHeight where orientation == .landscape: return height
        default:
            switch qualifier { case .smallestWidth: return smallestWidth; case .width: return width; case .height: return height }
        }
    }
}

/// Shared constants mirror AppDimens Dynamic 3.1.6's Android design baseline.
public enum DimensDesign {
    public static let baseWidth = 300.0
    public static let baseHeight = 533.0
    public static let referenceAspectRatio = 1.78
    public static let baseDiagonal = hypot(baseWidth, baseHeight)
    public static let basePerimeter = baseWidth + baseHeight
}
