import Foundation

/// Screen axis used to resolve a dimension — port of Android `DpQualifier`.
public enum DpQualifier: String, Sendable, CaseIterable { case smallWidth, height, width }

/// Android `Orientation` port — `default` never matches a specific orientation.
public enum DimensOrientation: String, Sendable, CaseIterable { case portrait, landscape, `default` }
/// Android-facing name for [DimensOrientation] (`Configuration.Orientation`).
public typealias Orientation = DimensOrientation

/// Android `UiModeType` port — full case set, including foldable states.
public enum UiModeType: String, Sendable, CaseIterable {
    case normal, television, car, watch, desk, appliance, vrHeadset, undefined
    case foldOpen, foldClosed, flipOpen, flipClosed, foldHalfOpened, flipHalfOpened
}

/// Orientation-dependent axis swap — port of Android `Inverter`.
/// `default` never swaps (identical to `Inverter.DEFAULT -> Unit` on Android).
public enum Inverter: String, Sendable, CaseIterable {
    case phToLw, pwToLh, lhToPw, lwToPh, swToLh, swToLw, swToPh, swToPw, `default`
}

/// Apple equivalent of Android `Configuration` for one window.
///
/// Width and height always describe the current window/scene in points (the
/// Apple equivalent of `dp`), never an arbitrary child view. Every factor used
/// by the scaling kernels is precomputed once in ``metrics`` when the value is
/// created, so resolving a dimension is a branch and a multiply.
///
/// Invalid inputs (zero, negative, NaN or infinite) are normalized to the
/// 300×533 design reference instead of trapping, which keeps transient layout
/// passes (e.g. a zero-sized window during a scene transition) crash-free.
public struct DimensConfiguration: Hashable, Sendable {
    public let screenWidth: Double
    public let screenHeight: Double
    public let displayScale: Double
    public let fontScale: Double
    public let uiMode: UiModeType
    public let maximumWindowWidth: Double
    public let maximumWindowHeight: Double
    /// Explicit multi-window flag (iPad Split View / Slide Over / Stage Manager,
    /// macOS resizable window). `nil` falls back to the window-vs-screen heuristic.
    public let multiWindowOverride: Bool?
    /// Every derived factor, computed once at construction.
    public let metrics: DimenMetrics

    public init(screenWidth: Double, screenHeight: Double, displayScale: Double = 1,
                fontScale: Double = 1, uiMode: UiModeType = .undefined,
                maximumWindowWidth: Double? = nil, maximumWindowHeight: Double? = nil,
                isInMultiWindowMode: Bool? = nil) {
        let w = Self.sanitize(screenWidth, DimensConstants.baseWidthDp)
        let h = Self.sanitize(screenHeight, DimensConstants.baseHeightDp)
        self.screenWidth = w
        self.screenHeight = h
        self.displayScale = Self.sanitize(displayScale, 1)
        self.fontScale = Self.sanitize(fontScale, 1)
        self.uiMode = uiMode
        self.maximumWindowWidth = max(w, Self.sanitize(maximumWindowWidth ?? w, w))
        self.maximumWindowHeight = max(h, Self.sanitize(maximumWindowHeight ?? h, h))
        self.multiWindowOverride = isInMultiWindowMode
        self.metrics = DimenMetrics(width: w, height: h, displayScale: self.displayScale,
                                    fontScale: self.fontScale, uiMode: uiMode)
    }

    @inline(__always) @usableFromInline
    static func sanitize(_ value: Double, _ fallback: Double) -> Double {
        value.isFinite && value > 0 ? value : fallback
    }

    /// The design reference window (300×533 pt, @1x, font scale 1) — Android `DimenMetrics.DEFAULT`.
    public static let reference = DimensConfiguration(screenWidth: DimensConstants.baseWidthDp,
                                                      screenHeight: DimensConstants.baseHeightDp)

    /// Ambient configuration used by the Android-style zero-argument accessors
    /// (`16.sdp`). Kept for source compatibility; forwards to ``AppDimens/configuration``.
    public static var current: DimensConfiguration {
        get { AppDimens.configuration }
        set { AppDimens.update(newValue) }
    }

    @inlinable public var smallestScreenWidth: Double { metrics.smallestScreenWidthDp }
    @inlinable public var orientation: DimensOrientation { metrics.orientation }
    /// `max / min` side ratio of the window.
    @inlinable public var aspectRatio: Double { metrics.maxDimensionDp / metrics.minDimensionDp }
    /// Android `densityDpi` equivalent: `displayScale * 160`.
    @inlinable public var densityDpi: Double { metrics.densityDpi }

    /// `true` when the window is narrower/shorter than its container (split view,
    /// slide over, Stage Manager, a resized macOS window) or when explicitly set.
    @inlinable public var isMultiWindow: Bool {
        if let explicit = multiWindowOverride { return explicit }
        return screenWidth < maximumWindowWidth * 0.95 || screenHeight < maximumWindowHeight * 0.95
    }

    /// Resolves the screen axis for `qualifier` after applying `inverter`
    /// (exact port of `DimenCalculationPlumbing.effectiveQualifier` + `readScreenDp`).
    @inlinable public func dimension(_ qualifier: DpQualifier, inverter: Inverter = .default) -> Double {
        switch DimensConfiguration.effectiveQualifier(qualifier, inverter: inverter, orientation: orientation) {
        case .smallWidth: return metrics.smallestScreenWidthDp
        case .height: return screenHeight
        case .width: return screenWidth
        }
    }

    /// Android `DimenCalculationPlumbing.effectiveQualifier`.
    @inlinable public static func effectiveQualifier(_ qualifier: DpQualifier, inverter: Inverter,
                                                     orientation: DimensOrientation) -> DpQualifier {
        let landscape = orientation == .landscape, portrait = orientation == .portrait
        switch inverter {
        case .phToLw where landscape && qualifier == .height: return .width
        case .pwToLh where landscape && qualifier == .width: return .height
        case .lhToPw where portrait && qualifier == .height: return .width
        case .lwToPh where portrait && qualifier == .width: return .height
        case .swToLh where landscape && qualifier == .smallWidth: return .height
        case .swToLw where landscape && qualifier == .smallWidth: return .width
        case .swToPh where portrait && qualifier == .smallWidth: return .height
        case .swToPw where portrait && qualifier == .smallWidth: return .width
        default: return qualifier
        }
    }

    // Equality/hash cover the raw inputs only; `metrics` is a pure function of them.
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.screenWidth == rhs.screenWidth && lhs.screenHeight == rhs.screenHeight &&
            lhs.displayScale == rhs.displayScale && lhs.fontScale == rhs.fontScale &&
            lhs.uiMode == rhs.uiMode && lhs.maximumWindowWidth == rhs.maximumWindowWidth &&
            lhs.maximumWindowHeight == rhs.maximumWindowHeight &&
            lhs.multiWindowOverride == rhs.multiWindowOverride
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(screenWidth); hasher.combine(screenHeight)
        hasher.combine(displayScale); hasher.combine(fontScale); hasher.combine(uiMode)
        hasher.combine(maximumWindowWidth); hasher.combine(maximumWindowHeight)
        hasher.combine(multiWindowOverride)
    }
}

extension DimensConfiguration: CustomStringConvertible {
    public var description: String {
        "DimensConfiguration(\(screenWidth)×\(screenHeight)pt @\(displayScale)x, font \(fontScale), \(uiMode), \(orientation)\(isMultiWindow ? ", multi-window" : ""))"
    }
}
