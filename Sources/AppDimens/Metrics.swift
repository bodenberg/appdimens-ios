import Foundation

/// Design-scale constants — exact port of `DesignScaleConstants` and the
/// `DimenCache` scaling constants from dynamic-android 3.1.7.
public enum DimensConstants {
    public static let baseWidthDp = 300.0
    public static let baseHeightDp = 533.0
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
}

/// Derived window snapshot — port of `DimenMetrics` from dynamic-android 3.1.7.
/// All satellite factors are pure functions of the raw window inputs and are
/// computed on demand (never persisted), mirroring the lazy memoizer semantics
/// while keeping the value type cheap to copy.
@frozen public struct DimenMetrics: Hashable, Sendable {
    public let screenWidthDp: Double
    public let screenHeightDp: Double
    public let smallestScreenWidthDp: Double
    public let densityDpi: Double
    public let fontScale: Double
    public let orientation: DimensOrientation
    public let uiMode: UiModeType

    @inlinable public init(_ configuration: DimensConfiguration) {
        screenWidthDp = configuration.screenWidth
        screenHeightDp = configuration.screenHeight
        smallestScreenWidthDp = configuration.smallestScreenWidth
        densityDpi = configuration.displayScale * 160
        fontScale = configuration.fontScale
        orientation = configuration.orientation
        uiMode = configuration.uiMode
    }

    @inlinable public var minDimensionDp: Double { min(screenWidthDp, screenHeightDp) }
    @inlinable public var maxDimensionDp: Double { max(screenWidthDp, screenHeightDp) }

    /// `scale = smallestScreenWidthDp * INV_BASE_RATIO` — the plain scaled path.
    @inlinable public var scale: Double { smallestScreenWidthDp * DimensConstants.invBaseRatio }

    /// `rawAR / REFERENCE_ASPECT_RATIO` where `rawAR = max/min` (1 when min ≤ 0).
    @inlinable public var normalizedAspectRatio: Double {
        let raw = minDimensionDp > 0 ? maxDimensionDp / minDimensionDp : 1
        let normalized = raw / DimensConstants.referenceAspectRatio
        return (normalized.isFinite && normalized > 0) ? normalized : 1
    }

    /// Exact natural logarithm of the normalized aspect ratio.
    @inlinable public var logNormalizedAspectRatio: Double {
        Foundation.log(normalizedAspectRatio)
    }

    /// `1 + SENSITIVITY_DEFAULT * ln(normalizedAR)` — satellite AR multiplier (default k).
    @inlinable public var defaultAspectRatioMultiplier: Double {
        1 + DimensConstants.sensitivityDefault * logNormalizedAspectRatio
    }

    /// `1 + (sw − 300) * (ADJUSTMENT_SCALE + SENSITIVITY_DEFAULT * ln(normalizedAR))`.
    @inlinable public var defaultScaledAspectRatioMultiplier: Double {
        1 + (smallestScreenWidthDp - DimensConstants.baseWidthDp) *
            (DimensConstants.adjustmentScale + DimensConstants.sensitivityDefault * logNormalizedAspectRatio)
    }

    /// `(sw / 300)^0.75` — power satellite default-path scale.
    @inlinable public var powerScale: Double {
        pow(smallestScreenWidthDp / DimensConstants.baseWidthDp, 0.75)
    }

    /// `1 + (sw/300 − 1) * 0.5` — interpolated satellite default-path scale.
    @inlinable public var interpolatedScale: Double {
        1 + (smallestScreenWidthDp * DimensConstants.invBaseRatio - 1) * 0.5
    }

    /// `√(min² + max²) / BASE_DIAGONAL_DP` — diagonal satellite default-path scale.
    @inlinable public var diagonalScale: Double {
        sqrt(minDimensionDp * minDimensionDp + maxDimensionDp * maxDimensionDp) /
            DimensConstants.baseDiagonalDp
    }

    /// `(min + max) / BASE_PERIMETER_DP` — perimeter satellite default-path scale.
    @inlinable public var perimeterScale: Double {
        (minDimensionDp + maxDimensionDp) / DimensConstants.basePerimeterDp
    }

    /// Logarithmic satellite default-path scale (3.1.7 when-chain on `sw`).
    @inlinable public var logarithmicScale: Double {
        if smallestScreenWidthDp > DimensConstants.baseWidthDp {
            return 1 + 0.4 * Foundation.log(smallestScreenWidthDp * DimensConstants.invBaseRatio)
        }
        if smallestScreenWidthDp > 0 {
            return 1 - 0.4 * Foundation.log(DimensConstants.baseWidthDp / smallestScreenWidthDp)
        }
        return 1
    }

    /// SDP/SSP scaled multiplier. `applyAspectRatio = false` → `scale` (sw/300).
    /// Custom sensitivities are validated instead of leaking NaN into layout.
    @inlinable public func scaledMultiplier(applyAspectRatio: Bool, customSensitivityK: Double?) -> Double {
        if !applyAspectRatio { return scale }
        if let k = customSensitivityK {
            precondition(k.isFinite, "customSensitivityK must be finite")
            let result = 1 + (smallestScreenWidthDp - DimensConstants.baseWidthDp) *
                (DimensConstants.adjustmentScale + k * logNormalizedAspectRatio)
            precondition(result.isFinite, "customSensitivityK produces a non-finite dimension multiplier")
            return result
        }
        return defaultScaledAspectRatioMultiplier
    }

    /// Satellite aspect-ratio multiplier applied after the base formula.
    @inlinable public func aspectRatioMultiplier(customSensitivityK: Double?) -> Double {
        if let k = customSensitivityK {
            precondition(k.isFinite, "customSensitivityK must be finite")
            let result = 1 + k * logNormalizedAspectRatio
            precondition(result.isFinite, "customSensitivityK produces a non-finite aspect-ratio multiplier")
            return result
        }
        return defaultAspectRatioMultiplier
    }

    public static let defaultValue = 300.0
}