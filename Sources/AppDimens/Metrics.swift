import Foundation

/// Design-scale constants — exact port of `DesignScaleConstants` and the
/// `DimenCache` scaling constants from dynamic-android.
public enum DimensConstants {
    public static let baseWidthDp = 300.0
    public static let baseHeightDp = 533.0
    /// `√(300² + 533²)`.
    public static let baseDiagonalDp = 611.6305
    public static let basePerimeterDp = 833.0
    public static let referenceAspectRatio = 1.78
    public static let invReferenceAspectRatio = 0.5617978
    /// `0.08 / 30` ≈ 0.0026666667 — k used by the default aspect-ratio multiplier.
    public static let sensitivityDefault = 0.08 / 30.0
    /// `0.10 / 30` ≈ 0.0033333334 — slope of the linear scaling term.
    public static let adjustmentScale = 0.10 / 30.0
    /// `1 / 300` ≈ 0.0033333334 — inverse of the design width.
    public static let invBaseRatio = 1.0 / 300.0
    /// AUTO satellite: linear up to this smallest-width, logarithmic beyond.
    public static let autoTransitionDp = 480.0
    /// AUTO satellite: logarithmic sensitivity beyond the transition.
    public static let autoSensitivity = 0.4
    /// LOGARITHMIC satellite sensitivity.
    public static let logarithmicSensitivity = 0.4
    /// POWER satellite exponent.
    public static let powerExponent = 0.75
    /// FLUID satellite viewport and multiplier range.
    public static let fluidMinWidthDp = 320.0, fluidMaxWidthDp = 768.0
    public static let fluidMinScale = 0.8, fluidMaxScale = 1.2
    /// INTERPOLATED satellite blend between base and linear scaling.
    public static let interpolationFactor = 0.5
}

/// Derived window snapshot — port of Android `DimenMetrics` (3.2.x).
///
/// Every factor is computed eagerly once per window snapshot (the Android
/// version also moved to eager `val`s for the hot lanes), so the scaling
/// kernels never evaluate `log`, `pow` or `sqrt` on the hot path.
@frozen public struct DimenMetrics: Hashable, Sendable {
    public let screenWidthDp: Double
    public let screenHeightDp: Double
    public let smallestScreenWidthDp: Double
    public let densityDpi: Double
    /// `densityDpi / 160` — the window's display scale (pixels per point).
    public let density: Double
    public let fontScale: Double
    public let orientation: DimensOrientation
    public let uiMode: UiModeType

    public let minDimensionDp: Double
    public let maxDimensionDp: Double
    /// `sw / 300` — the plain scaled (SDP) factor.
    public let scale: Double
    /// `width / 300` — WDP factor.
    public let screenWidthFactor: Double
    /// `height / 300` — HDP factor.
    public let screenHeightFactor: Double
    /// `(max / min) / 1.78`.
    public let normalizedAspectRatio: Double
    public let logNormalizedAspectRatio: Double
    /// `1 + k·ln(normalizedAR)` — satellite AR multiplier (default k).
    public let defaultAspectRatioMultiplier: Double
    /// `1 + (sw − 300)·(0.10/30 + k·ln(normalizedAR))` — SDPA multiplier.
    public let defaultScaledAspectRatioMultiplier: Double
    /// `(sw / 300)^0.75`.
    public let powerScale: Double
    /// `1 + (sw/300 − 1)·0.5`.
    public let interpolatedScale: Double
    /// `√(min² + max²) / 611.6305`.
    public let diagonalScale: Double
    /// `(min + max) / 833`.
    public let perimeterScale: Double
    /// `1 ± 0.4·ln(sw/300)`.
    public let logarithmicScale: Double
    /// `min(min/300, max/533)`.
    public let fitScale: Double
    /// `max(min/300, max/533)`.
    public let fillScale: Double
    /// AUTO factor on the smallest width (linear ≤ 480, logarithmic beyond).
    public let autoScale: Double
    /// FLUID factor on the smallest width (×0.8 … ×1.2 over 320 … 768).
    public let fluidScale: Double

    public init(_ configuration: DimensConfiguration) { self = configuration.metrics }

    @usableFromInline
    init(width: Double, height: Double, displayScale: Double, fontScale: Double, uiMode: UiModeType) {
        screenWidthDp = width
        screenHeightDp = height
        let sm = min(width, height), lg = max(width, height)
        minDimensionDp = sm
        maxDimensionDp = lg
        smallestScreenWidthDp = sm
        density = displayScale
        densityDpi = displayScale * 160
        self.fontScale = fontScale
        orientation = width > height ? .landscape : .portrait
        self.uiMode = uiMode

        let inv = DimensConstants.invBaseRatio
        scale = sm * inv
        screenWidthFactor = width * inv
        screenHeightFactor = height * inv

        let rawAR = sm > 0 ? lg / sm : 1
        let nAR = rawAR / DimensConstants.referenceAspectRatio
        normalizedAspectRatio = (nAR.isFinite && nAR > 0) ? nAR : 1
        logNormalizedAspectRatio = Foundation.log(normalizedAspectRatio)
        defaultAspectRatioMultiplier = 1 + DimensConstants.sensitivityDefault * logNormalizedAspectRatio
        defaultScaledAspectRatioMultiplier = 1 + (sm - DimensConstants.baseWidthDp) *
            (DimensConstants.adjustmentScale + DimensConstants.sensitivityDefault * logNormalizedAspectRatio)

        powerScale = DimenMetrics.power(sm)
        interpolatedScale = 1 + (sm * inv - 1) * DimensConstants.interpolationFactor
        diagonalScale = (sm * sm + lg * lg).squareRoot() / DimensConstants.baseDiagonalDp
        perimeterScale = (sm + lg) / DimensConstants.basePerimeterDp
        logarithmicScale = DimenMetrics.logarithmic(sm)
        fitScale = min(sm / DimensConstants.baseWidthDp, lg / DimensConstants.baseHeightDp)
        fillScale = max(sm / DimensConstants.baseWidthDp, lg / DimensConstants.baseHeightDp)
        autoScale = DimenMetrics.auto(sm)
        fluidScale = DimenMetrics.fluid(sm)
    }

    // ── Per-axis factor functions (used when the axis is not the smallest width) ──

    /// `(dim / 300)^0.75`.
    @inlinable public static func power(_ dim: Double) -> Double {
        pow(dim / DimensConstants.baseWidthDp, DimensConstants.powerExponent)
    }

    /// `1 + 0.4·ln(dim/300)` above the base, `1 − 0.4·ln(300/dim)` below it.
    @inlinable public static func logarithmic(_ dim: Double) -> Double {
        if dim > DimensConstants.baseWidthDp {
            return 1 + DimensConstants.logarithmicSensitivity * Foundation.log(dim * DimensConstants.invBaseRatio)
        }
        if dim > 0 {
            return 1 - DimensConstants.logarithmicSensitivity * Foundation.log(DimensConstants.baseWidthDp / dim)
        }
        return 1
    }

    /// Linear `dim/300` up to 480, then `480/300 + 0.4·ln(1 + (dim − 480)/300)`.
    @inlinable public static func auto(_ dim: Double) -> Double {
        let inv = DimensConstants.invBaseRatio, t = DimensConstants.autoTransitionDp
        return dim <= t ? dim * inv : t * inv + DimensConstants.autoSensitivity * Foundation.log(1 + (dim - t) * inv)
    }

    /// ×0.8 at ≤ 320, ×1.2 at ≥ 768, linear in between.
    @inlinable public static func fluid(_ dim: Double) -> Double {
        let lo = DimensConstants.fluidMinScale, hi = DimensConstants.fluidMaxScale
        let minW = DimensConstants.fluidMinWidthDp, maxW = DimensConstants.fluidMaxWidthDp
        if dim <= minW { return lo }
        if dim >= maxW { return hi }
        return lo + (hi - lo) * (dim - minW) / (maxW - minW)
    }

    /// SDP/SSP multiplier. `applyAspectRatio = false` → `scale` (sw/300).
    /// Invalid custom sensitivities fall back to the default curve instead of
    /// leaking NaN into layout (debug builds assert).
    @inlinable public func scaledMultiplier(applyAspectRatio: Bool, customSensitivityK: Double?) -> Double {
        if !applyAspectRatio { return scale }
        guard let k = customSensitivityK else { return defaultScaledAspectRatioMultiplier }
        let result = 1 + (smallestScreenWidthDp - DimensConstants.baseWidthDp) *
            (DimensConstants.adjustmentScale + k * logNormalizedAspectRatio)
        assert(result.isFinite, "customSensitivityK produces a non-finite dimension multiplier")
        return result.isFinite ? result : defaultScaledAspectRatioMultiplier
    }

    /// Satellite aspect-ratio multiplier applied after the base formula.
    @inlinable public func aspectRatioMultiplier(customSensitivityK: Double?) -> Double {
        guard let k = customSensitivityK else { return defaultAspectRatioMultiplier }
        let result = 1 + k * logNormalizedAspectRatio
        assert(result.isFinite, "customSensitivityK produces a non-finite aspect-ratio multiplier")
        return result.isFinite ? result : defaultAspectRatioMultiplier
    }

    public static let defaultValue = DimensConstants.baseWidthDp
    /// Android `DimenMetrics.DEFAULT`.
    public static var `default`: DimenMetrics { DimensConfiguration.reference.metrics }
}
