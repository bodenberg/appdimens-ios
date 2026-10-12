import Foundation

/// Every scaling strategy shipped by AppDimens (Android module names).
public enum DimensStrategy: String, Sendable, CaseIterable {
    case scaled, auto, density, diagonal, fill, fit, fluid, interpolated
    case logarithmic, percent, perimeter, power, physical, plain
}

/// Core scaling kernels — exact ports of the dynamic-android formulas
/// (`calculateScaledDpCompose` / `DimenCache.calculateRawScaling` and every
/// `calculate<Strategy>DpCompose`). All results are in points (Apple `dp`).
///
/// Hot paths read the factors precomputed in ``DimenMetrics`` — a branch and
/// one multiply, no transcendental math, no allocation.
public enum AppDimens {
    /// Library version (matches the Android release it is at parity with).
    public static let version = "3.2.0"

    // ─────────────────────────────────────────────────────────────────────────
    // SCALED (SDP / SSP)
    // ─────────────────────────────────────────────────────────────────────────

    /// Port of `calculateScaledDpCompose` + `DimenCache.calculateRawScaling`.
    @inlinable public static func scaledDp(_ baseValue: Double, configuration c: DimensConfiguration,
        qualifier: DpQualifier = .smallWidth, inverter: Inverter = .default,
        ignoreMultiWindows: Bool = false, applyAspectRatio: Bool = false,
        sensitivityK: Double? = nil) -> Double {
        if ignoreMultiWindows && c.isMultiWindow { return baseValue }
        let m = c.metrics
        if inverter == .default && sensitivityK == nil {
            switch qualifier {
            case .smallWidth:
                return baseValue * (applyAspectRatio ? m.defaultScaledAspectRatioMultiplier : m.scale)
            case .width where !applyAspectRatio: return baseValue * m.screenWidthFactor
            case .height where !applyAspectRatio: return baseValue * m.screenHeightFactor
            default: break
            }
        }
        return linearScaled(baseValue, dimension: c.dimension(qualifier, inverter: inverter),
                            metrics: m, applyAspectRatio: applyAspectRatio, sensitivityK: sensitivityK)
    }

    /// Shared linear kernel (`base·dim/300`, or the aspect-ratio-aware curve).
    @inlinable @inline(__always) static func linearScaled(_ baseValue: Double, dimension dim: Double,
        metrics m: DimenMetrics, applyAspectRatio: Bool, sensitivityK: Double?) -> Double {
        if !applyAspectRatio { return baseValue * dim * DimensConstants.invBaseRatio }
        let adj = (sensitivityK ?? DimensConstants.sensitivityDefault) * m.logNormalizedAspectRatio
        let out = baseValue * (1 + (dim - DimensConstants.baseWidthDp) * (DimensConstants.adjustmentScale + adj))
        assert(out.isFinite, "sensitivityK produces a non-finite dimension")
        return out
    }

    /// SSP path: scaled geometry times the font scale when `fontScale` is true
    /// (`ssp`/`hsp`/`wsp`), raw geometry otherwise (`sem`/`hem`/`wem`).
    @inlinable public static func scaledSp(_ baseValue: Double, configuration c: DimensConfiguration,
        qualifier: DpQualifier = .smallWidth, fontScale: Bool = true,
        inverter: Inverter = .default, ignoreMultiWindows: Bool = false,
        applyAspectRatio: Bool = false, sensitivityK: Double? = nil) -> Double {
        let geometry = scaledDp(baseValue, configuration: c, qualifier: qualifier, inverter: inverter,
            ignoreMultiWindows: ignoreMultiWindows, applyAspectRatio: applyAspectRatio, sensitivityK: sensitivityK)
        return fontScale ? geometry * c.fontScale : geometry
    }

    /// Generic SP wrapper for any strategy (`fontScale` multiplies by the window font scale).
    @inlinable public static func sp(_ baseValue: Double, strategy: DimensStrategy, configuration c: DimensConfiguration,
        qualifier: DpQualifier = .smallWidth, fontScale: Bool = true, inverter: Inverter = .default,
        ignoreMultiWindows: Bool = false, applyAspectRatio: Bool = false, sensitivityK: Double? = nil) -> Double {
        let geometry = resolve(baseValue, strategy: strategy, configuration: c, qualifier: qualifier, inverter: inverter,
            ignoreMultiWindows: ignoreMultiWindows, applyAspectRatio: applyAspectRatio, sensitivityK: sensitivityK)
        return fontScale ? geometry * c.fontScale : geometry
    }

    // ─────────────────────────────────────────────────────────────────────────
    // SATELLITES
    // ─────────────────────────────────────────────────────────────────────────

    @inlinable @inline(__always) static func withAspect(_ value: Double, _ m: DimenMetrics,
                                                         _ apply: Bool, _ k: Double?) -> Double {
        apply ? value * m.aspectRatioMultiplier(customSensitivityK: k) : value
    }

    /// Percent satellite (`p*` catalog) — linear on the resolved axis.
    @inlinable public static func percentDp(_ baseValue: Double, configuration c: DimensConfiguration,
        qualifier: DpQualifier = .smallWidth, inverter: Inverter = .default,
        ignoreMultiWindows: Bool = false, applyAspectRatio: Bool = false,
        sensitivityK: Double? = nil) -> Double {
        if ignoreMultiWindows && c.isMultiWindow { return baseValue }
        return linearScaled(baseValue, dimension: c.dimension(qualifier, inverter: inverter),
                            metrics: c.metrics, applyAspectRatio: applyAspectRatio, sensitivityK: sensitivityK)
    }

    /// Power satellite: `(dim/300)^0.75`.
    @inlinable public static func powerDp(_ baseValue: Double, configuration c: DimensConfiguration,
        qualifier: DpQualifier = .smallWidth, inverter: Inverter = .default,
        ignoreMultiWindows: Bool = false, applyAspectRatio: Bool = false,
        sensitivityK: Double? = nil) -> Double {
        if ignoreMultiWindows && c.isMultiWindow { return baseValue }
        let m = c.metrics
        let scale = qualifier == .smallWidth && inverter == .default
            ? m.powerScale : DimenMetrics.power(c.dimension(qualifier, inverter: inverter))
        return withAspect(baseValue * scale, m, applyAspectRatio, sensitivityK)
    }

    /// Fluid satellite: fixed 320…768 viewport mapped to ×0.8…×1.2.
    @inlinable public static func fluidDp(_ baseValue: Double, configuration c: DimensConfiguration,
        qualifier: DpQualifier = .smallWidth, inverter: Inverter = .default,
        ignoreMultiWindows: Bool = false, applyAspectRatio: Bool = false,
        sensitivityK: Double? = nil) -> Double {
        if ignoreMultiWindows && c.isMultiWindow { return baseValue }
        let m = c.metrics
        let scale = qualifier == .smallWidth && inverter == .default
            ? m.fluidScale : DimenMetrics.fluid(c.dimension(qualifier, inverter: inverter))
        return withAspect(baseValue * scale, m, applyAspectRatio, sensitivityK)
    }

    /// Auto satellite: linear up to 480 pt, logarithmic beyond.
    @inlinable public static func autoDp(_ baseValue: Double, configuration c: DimensConfiguration,
        qualifier: DpQualifier = .smallWidth, inverter: Inverter = .default,
        ignoreMultiWindows: Bool = false, applyAspectRatio: Bool = false,
        sensitivityK: Double? = nil) -> Double {
        if ignoreMultiWindows && c.isMultiWindow { return baseValue }
        let m = c.metrics
        let scale = qualifier == .smallWidth && inverter == .default
            ? m.autoScale : DimenMetrics.auto(c.dimension(qualifier, inverter: inverter))
        return withAspect(baseValue * scale, m, applyAspectRatio, sensitivityK)
    }

    /// Density satellite: `base × densityDpi/160` (`displayScale`) — density only.
    @inlinable public static func densityDp(_ baseValue: Double, configuration c: DimensConfiguration,
        qualifier: DpQualifier = .smallWidth, inverter: Inverter = .default,
        ignoreMultiWindows: Bool = false, applyAspectRatio: Bool = false,
        sensitivityK: Double? = nil) -> Double {
        if ignoreMultiWindows && c.isMultiWindow { return baseValue }
        return withAspect(baseValue * c.metrics.density, c.metrics, applyAspectRatio, sensitivityK)
    }

    /// Diagonal satellite: `√(min²+max²) / 611.6305` — window-based, no qualifier.
    @inlinable public static func diagonalDp(_ baseValue: Double, configuration c: DimensConfiguration,
        qualifier: DpQualifier = .smallWidth, inverter: Inverter = .default,
        ignoreMultiWindows: Bool = false, applyAspectRatio: Bool = false,
        sensitivityK: Double? = nil) -> Double {
        if ignoreMultiWindows && c.isMultiWindow { return baseValue }
        return withAspect(baseValue * c.metrics.diagonalScale, c.metrics, applyAspectRatio, sensitivityK)
    }

    /// Perimeter satellite: `(min+max) / 833`.
    @inlinable public static func perimeterDp(_ baseValue: Double, configuration c: DimensConfiguration,
        qualifier: DpQualifier = .smallWidth, inverter: Inverter = .default,
        ignoreMultiWindows: Bool = false, applyAspectRatio: Bool = false,
        sensitivityK: Double? = nil) -> Double {
        if ignoreMultiWindows && c.isMultiWindow { return baseValue }
        return withAspect(baseValue * c.metrics.perimeterScale, c.metrics, applyAspectRatio, sensitivityK)
    }

    /// Fill satellite: `max(min/300, max/533)` — cover.
    @inlinable public static func fillDp(_ baseValue: Double, configuration c: DimensConfiguration,
        qualifier: DpQualifier = .smallWidth, inverter: Inverter = .default,
        ignoreMultiWindows: Bool = false, applyAspectRatio: Bool = false,
        sensitivityK: Double? = nil) -> Double {
        if ignoreMultiWindows && c.isMultiWindow { return baseValue }
        return withAspect(baseValue * c.metrics.fillScale, c.metrics, applyAspectRatio, sensitivityK)
    }

    /// Fit satellite: `min(min/300, max/533)` — contain.
    @inlinable public static func fitDp(_ baseValue: Double, configuration c: DimensConfiguration,
        qualifier: DpQualifier = .smallWidth, inverter: Inverter = .default,
        ignoreMultiWindows: Bool = false, applyAspectRatio: Bool = false,
        sensitivityK: Double? = nil) -> Double {
        if ignoreMultiWindows && c.isMultiWindow { return baseValue }
        return withAspect(baseValue * c.metrics.fitScale, c.metrics, applyAspectRatio, sensitivityK)
    }

    /// Interpolated satellite: 50 % blend of base and linear scaling.
    @inlinable public static func interpolatedDp(_ baseValue: Double, configuration c: DimensConfiguration,
        qualifier: DpQualifier = .smallWidth, inverter: Inverter = .default,
        ignoreMultiWindows: Bool = false, applyAspectRatio: Bool = false,
        sensitivityK: Double? = nil) -> Double {
        if ignoreMultiWindows && c.isMultiWindow { return baseValue }
        let m = c.metrics
        let out: Double
        if qualifier == .smallWidth && inverter == .default {
            out = baseValue * m.interpolatedScale
        } else {
            let linear = baseValue * c.dimension(qualifier, inverter: inverter) * DimensConstants.invBaseRatio
            out = baseValue + (linear - baseValue) * DimensConstants.interpolationFactor
        }
        return withAspect(out, m, applyAspectRatio, sensitivityK)
    }

    /// Logarithmic satellite: `1 + 0.4·ln(dim/300)` / `1 − 0.4·ln(300/dim)`.
    @inlinable public static func logarithmicDp(_ baseValue: Double, configuration c: DimensConfiguration,
        qualifier: DpQualifier = .smallWidth, inverter: Inverter = .default,
        ignoreMultiWindows: Bool = false, applyAspectRatio: Bool = false,
        sensitivityK: Double? = nil) -> Double {
        if ignoreMultiWindows && c.isMultiWindow { return baseValue }
        let m = c.metrics
        let scale = qualifier == .smallWidth && inverter == .default
            ? m.logarithmicScale : DimenMetrics.logarithmic(c.dimension(qualifier, inverter: inverter))
        return withAspect(baseValue * scale, m, applyAspectRatio, sensitivityK)
    }

    /// Single dispatcher over every strategy (used by builders, `dynamic(_:)`, Metal).
    @inlinable public static func resolve(_ value: Double, strategy: DimensStrategy, configuration c: DimensConfiguration,
        qualifier q: DpQualifier = .smallWidth, inverter i: Inverter = .default,
        ignoreMultiWindows im: Bool = false, applyAspectRatio ar: Bool = false, sensitivityK k: Double? = nil) -> Double {
        switch strategy {
        case .plain, .physical: return value
        case .scaled: return scaledDp(value, configuration: c, qualifier: q, inverter: i, ignoreMultiWindows: im, applyAspectRatio: ar, sensitivityK: k)
        case .percent: return percentDp(value, configuration: c, qualifier: q, inverter: i, ignoreMultiWindows: im, applyAspectRatio: ar, sensitivityK: k)
        case .power: return powerDp(value, configuration: c, qualifier: q, inverter: i, ignoreMultiWindows: im, applyAspectRatio: ar, sensitivityK: k)
        case .fluid: return fluidDp(value, configuration: c, qualifier: q, inverter: i, ignoreMultiWindows: im, applyAspectRatio: ar, sensitivityK: k)
        case .auto: return autoDp(value, configuration: c, qualifier: q, inverter: i, ignoreMultiWindows: im, applyAspectRatio: ar, sensitivityK: k)
        case .density: return densityDp(value, configuration: c, qualifier: q, inverter: i, ignoreMultiWindows: im, applyAspectRatio: ar, sensitivityK: k)
        case .diagonal: return diagonalDp(value, configuration: c, qualifier: q, inverter: i, ignoreMultiWindows: im, applyAspectRatio: ar, sensitivityK: k)
        case .perimeter: return perimeterDp(value, configuration: c, qualifier: q, inverter: i, ignoreMultiWindows: im, applyAspectRatio: ar, sensitivityK: k)
        case .fill: return fillDp(value, configuration: c, qualifier: q, inverter: i, ignoreMultiWindows: im, applyAspectRatio: ar, sensitivityK: k)
        case .fit: return fitDp(value, configuration: c, qualifier: q, inverter: i, ignoreMultiWindows: im, applyAspectRatio: ar, sensitivityK: k)
        case .interpolated: return interpolatedDp(value, configuration: c, qualifier: q, inverter: i, ignoreMultiWindows: im, applyAspectRatio: ar, sensitivityK: k)
        case .logarithmic: return logarithmicDp(value, configuration: c, qualifier: q, inverter: i, ignoreMultiWindows: im, applyAspectRatio: ar, sensitivityK: k)
        }
    }

    /// Android `toDynamicScaledDp` equivalent with every option.
    @inlinable public static func toDynamicScaledDp(_ value: Double, configuration: DimensConfiguration,
        qualifier: DpQualifier, inverter: Inverter = .default, ignoreMultiWindows: Bool = false,
        applyAspectRatio: Bool = false, customSensitivityK: Double? = nil) -> Double {
        scaledDp(value, configuration: configuration, qualifier: qualifier, inverter: inverter,
                 ignoreMultiWindows: ignoreMultiWindows, applyAspectRatio: applyAspectRatio, sensitivityK: customSensitivityK)
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Literal percent (“space” family)
    // ─────────────────────────────────────────────────────────────────────────

    /// Literal % of a screen axis (`spaceW` / `spaceH` / `spaceSw`).
    @inlinable public static func literalPercentOfScreenDp(_ percent: Double,
        qualifier: DpQualifier, configuration c: DimensConfiguration,
        ignoreMultiWindows: Bool = false) -> Double {
        guard percent.isFinite else { return 0 }
        if ignoreMultiWindows && c.isMultiWindow { return percent }
        return (percent / 100) * c.dimension(qualifier)
    }

    /// Literal % of an arbitrary reference length (`space(reference:)`).
    @inlinable public static func literalPercentOfReferenceDp(_ percent: Double, referenceDp: Double) -> Double {
        guard percent.isFinite else { return 0 }
        return (percent / 100) * referenceDp
    }
}

// ───────────────────────────────────────────────────────────────────────────
// Deprecated 3.1.6 convenience aliases
// ───────────────────────────────────────────────────────────────────────────

public extension AppDimens {
    @available(*, deprecated, renamed: "scaledDp(_:configuration:qualifier:inverter:ignoreMultiWindows:applyAspectRatio:sensitivityK:)")
    @inlinable static func dp(_ value: Double, configuration: DimensConfiguration,
        qualifier: DpQualifier = .smallWidth, inverter: Inverter = .default,
        ignoreMultiWindows: Bool = false, applyAspectRatio: Bool = false,
        sensitivity: Double? = nil) -> Double {
        scaledDp(value, configuration: configuration, qualifier: qualifier, inverter: inverter,
            ignoreMultiWindows: ignoreMultiWindows, applyAspectRatio: applyAspectRatio, sensitivityK: sensitivity)
    }

    @available(*, deprecated, renamed: "scaledSp(_:configuration:qualifier:fontScale:inverter:ignoreMultiWindows:applyAspectRatio:sensitivityK:)")
    @inlinable static func sp(_ value: Double, configuration: DimensConfiguration,
        qualifier: DpQualifier = .smallWidth, fontScale: Bool = true,
        inverter: Inverter = .default, ignoreMultiWindows: Bool = false,
        applyAspectRatio: Bool = false, sensitivity: Double? = nil) -> Double {
        scaledSp(value, configuration: configuration, qualifier: qualifier, fontScale: fontScale,
            inverter: inverter, ignoreMultiWindows: ignoreMultiWindows,
            applyAspectRatio: applyAspectRatio, sensitivityK: sensitivity)
    }
}

/// Plain (unscaled) branch helpers — port of `DimenPlainBranch`.
/// The receiver is an already-resolved length that passes through unchanged
/// when the condition does not match.
public enum AppDimensPlain {
    @inlinable public static func isOrientationMatch(_ c: DimensConfiguration, _ orientation: Orientation) -> Bool {
        orientation != .default && c.orientation == orientation
    }
    @inlinable public static func qualifierMeetsThreshold(_ c: DimensConfiguration, _ qualifier: DpQualifier, _ value: Double) -> Bool {
        c.dimension(qualifier) >= value
    }
    @inlinable public static func rotate(_ value: Double, branch: Double,
        orientation: Orientation, configuration: DimensConfiguration) -> Double {
        isOrientationMatch(configuration, orientation) ? branch : value
    }
    @inlinable public static func mode(_ value: Double, branch: Double,
        mode: UiModeType, configuration: DimensConfiguration) -> Double {
        configuration.uiMode == mode ? branch : value
    }
    @inlinable public static func qualifier(_ value: Double, branch: Double,
        qualifier: DpQualifier, minimum: Double, configuration: DimensConfiguration) -> Double {
        qualifierMeetsThreshold(configuration, qualifier, minimum) ? branch : value
    }
    @inlinable public static func screen(_ value: Double, branch: Double, mode: UiModeType,
        qualifier: DpQualifier, minimum: Double, configuration: DimensConfiguration) -> Double {
        configuration.uiMode == mode && qualifierMeetsThreshold(configuration, qualifier, minimum) ? branch : value
    }
}
