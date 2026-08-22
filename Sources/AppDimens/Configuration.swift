import Foundation

public enum DpQualifier: String, Sendable, CaseIterable { case smallWidth, height, width }
/// Android `Orientation` port — `default` never matches a specific orientation.
public enum DimensOrientation: String, Sendable, CaseIterable { case portrait, landscape, `default` }
/// Android-facing name for [DimensOrientation] (`Configuration.Orientation`).
public typealias Orientation = DimensOrientation
/// Android `UiModeType` port — full 3.1.7 case set, including foldable states.
public enum UiModeType: String, Sendable, CaseIterable {
    case normal, television, car, watch, desk, appliance, vrHeadset, undefined
    case foldOpen, foldClosed, flipOpen, flipClosed, foldHalfOpened, flipHalfOpened
}
public enum Inverter: String, Sendable, CaseIterable {
    case phToLw, pwToLh, lhToPw, lwToPh, swToLh, swToLw, swToPh, swToPw, `default`
}

/// Apple equivalent of Android `Configuration`. Width and height always describe
/// the current window/scene in points, never an arbitrary child view.
@frozen public struct DimensConfiguration: Hashable, Sendable {
    public let screenWidth: Double
    public let screenHeight: Double
    public let displayScale: Double
    public let fontScale: Double
    public let uiMode: UiModeType
    public let maximumWindowWidth: Double
    public let maximumWindowHeight: Double

    public init(screenWidth: Double, screenHeight: Double, displayScale: Double = 1,
                fontScale: Double = 1, uiMode: UiModeType = .undefined,
                maximumWindowWidth: Double? = nil, maximumWindowHeight: Double? = nil) {
        precondition(screenWidth > 0 && screenHeight > 0 && screenWidth.isFinite && screenHeight.isFinite)
        precondition(displayScale > 0 && displayScale.isFinite && fontScale > 0 && fontScale.isFinite)
        self.screenWidth = screenWidth; self.screenHeight = screenHeight
        self.displayScale = displayScale; self.fontScale = fontScale; self.uiMode = uiMode
        self.maximumWindowWidth = maximumWindowWidth ?? screenWidth
        self.maximumWindowHeight = maximumWindowHeight ?? screenHeight
    }

    /// Ambient configuration used by the Android-style property accessors
    /// (`16.fsdp`). Set it once per window (or from a SwiftUI environment
    /// observer); falls back to the 300×533 design reference.
    public static var current = DimensConfiguration(screenWidth: 300, screenHeight: 533)

    public var smallestScreenWidth: Double { min(screenWidth, screenHeight) }
    public var orientation: DimensOrientation { screenWidth > screenHeight ? .landscape : .portrait }
    public var aspectRatio: Double { max(screenWidth, screenHeight) / smallestScreenWidth }
    /// Android `densityDpi` equivalent: `displayScale * 160`.
    public var densityDpi: Double { displayScale * 160 }
    public var isMultiWindow: Bool {
        screenWidth < maximumWindowWidth * 0.95 || screenHeight < maximumWindowHeight * 0.95
    }
    /// Derived window snapshot (metrics/factors memoized per configuration value).
    public var metrics: DimenMetrics { DimenMetrics(self) }

    @inlinable public func dimension(_ qualifier: DpQualifier, inverter: Inverter = .default) -> Double {
        let effective: DpQualifier
        switch inverter {
        case .phToLw where orientation == .landscape && qualifier == .height: effective = .width
        case .pwToLh where orientation == .landscape && qualifier == .width: effective = .height
        case .lhToPw where orientation == .portrait && qualifier == .height: effective = .width
        case .lwToPh where orientation == .portrait && qualifier == .width: effective = .height
        case .swToLh where orientation == .landscape && qualifier == .smallWidth: effective = .height
        case .swToLw where orientation == .landscape && qualifier == .smallWidth: effective = .width
        case .swToPh where orientation == .portrait && qualifier == .smallWidth: effective = .height
        case .swToPw where orientation == .portrait && qualifier == .smallWidth: effective = .width
        case .default where orientation == .landscape && qualifier == .height: effective = .width
        default: effective = qualifier
        }
        switch effective { case .smallWidth: return smallestScreenWidth; case .height: return screenHeight; case .width: return screenWidth }
    }
}