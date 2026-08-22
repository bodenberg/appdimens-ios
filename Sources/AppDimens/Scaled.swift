import Foundation

/// Core scaling kernel — exact port of the 3.1.7 formulas
/// (`DimenScaled` / `DimenSdp`, `DimenSsp`, `DimenMetrics` and the 3.1.7
/// satellite math from `DimenCalculationPlumbing`).
public enum AppDimens {
    // ─────────────────────────────────────────────────────────────────────────
    // SCALED (SDP / SSP) — qualifier-driven scaled dimensions
    // ─────────────────────────────────────────────────────────────────────────

    /// Port of `calculateScaledDpCompose` + `DimenCache.calculateRawScaling`.
    @inlinable public static func scaledDp(_ baseValue: Double, configuration c: DimensConfiguration,
        qualifier: DpQualifier = .smallWidth, inverter: Inverter = .default,
        ignoreMultiWindows: Bool = false, applyAspectRatio: Bool = false,
        sensitivityK: Double? = nil) -> Double {
        if ignoreMultiWindows && c.isMultiWindow { return baseValue }
        let metrics = c.metrics
        let isDefaultSw = qualifier == .smallWidth && inverter == .default
        if isDefaultSw && sensitivityK == nil {
            return baseValue * metrics.scaledMultiplier(applyAspectRatio: applyAspectRatio, customSensitivityK: nil)
        }
        let dim = c.dimension(qualifier, inverter: inverter)
        let scale = dim * DimensConstants.invBaseRatio
        if !applyAspectRatio { return baseValue * scale }
        let diff = dim - DimensConstants.baseWidthDp
        let adj = (sensitivityK ?? DimensConstants.sensitivityDefault) * metrics.logNormalizedAspectRatio
        return baseValue * (1 + diff * (DimensConstants.adjustmentScale + adj))
    }

    /// Port of the SSP path: scaled dp times the font scale when `fontScale` is
    /// true (`ssp`/`hsp`/`wsp`); raw geometry otherwise (`sem`/`hem`/`wem`).
    @inlinable public static func scaledSp(_ baseValue: Double, configuration c: DimensConfiguration,
        qualifier: DpQualifier = .smallWidth, fontScale: Bool = true,
        inverter: Inverter = .default, ignoreMultiWindows: Bool = false,
        applyAspectRatio: Bool = false, sensitivityK: Double? = nil) -> Double {
        let geometry = scaledDp(baseValue, configuration: c, qualifier: qualifier, inverter: inverter,
            ignoreMultiWindows: ignoreMultiWindows, applyAspectRatio: applyAspectRatio, sensitivityK: sensitivityK)
        return fontScale ? geometry * c.fontScale : geometry
    }

    // ─────────────────────────────────────────────────────────────────────────
    // SATELLITES — 3.1.7 formulas
    // ─────────────────────────────────────────────────────────────────────────

    /// Percent satellite: sdp-like dimension scaling (`p*` catalog).
    @inlinable public static func percentDp(_ baseValue: Double, configuration c: DimensConfiguration,
        qualifier: DpQualifier = .smallWidth, inverter: Inverter = .default,
        ignoreMultiWindows: Bool = false, applyAspectRatio: Bool = false,
        sensitivityK: Double? = nil) -> Double {
        if ignoreMultiWindows && c.isMultiWindow { return baseValue }
        let metrics = c.metrics
        let dim = c.dimension(qualifier, inverter: inverter)
        if !applyAspectRatio { return baseValue * dim * DimensConstants.invBaseRatio }
        let diff = dim - DimensConstants.baseWidthDp
        let adj = (sensitivityK ?? DimensConstants.sensitivityDefault) * metrics.logNormalizedAspectRatio
        return baseValue * (1 + diff * (DimensConstants.adjustmentScale + adj))
    }

    /// Power satellite: `(dim/300)^0.75` (memoized `sw` scale on the default path).
    @inlinable public static func powerDp(_ baseValue: Double, configuration c: DimensConfiguration,
        qualifier: DpQualifier = .smallWidth, inverter: Inverter = .default,
        ignoreMultiWindows: Bool = false, applyAspectRatio: Bool = false,
        sensitivityK: Double? = nil) -> Double {
        if ignoreMultiWindows && c.isMultiWindow { return baseValue }
        let metrics = c.metrics
        let isDefaultSw = qualifier == .smallWidth && inverter == .default
        let scale: Double = isDefaultSw
            ? metrics.powerScale
            : pow(c.dimension(qualifier, inverter: inverter) / DimensConstants.baseWidthDp, 0.75)
        var out = baseValue * scale
        if applyAspectRatio { out *= metrics.aspectRatioMultiplier(customSensitivityK: sensitivityK) }
        return out
    }

    /// Fluid satellite: fixed 320…768 viewport mapped to a fixed ×0.8…×1.2 range.
    @inlinable public static func fluidDp(_ baseValue: Double, configuration c: DimensConfiguration,
        qualifier: DpQualifier = .smallWidth, inverter: Inverter = .default,
        ignoreMultiWindows: Bool = false, applyAspectRatio: Bool = false,
        sensitivityK: Double? = nil) -> Double {
        if ignoreMultiWindows && c.isMultiWindow { return baseValue }
        let metrics = c.metrics
        let dim = c.dimension(qualifier, inverter: inverter)
        let minV = baseValue * 0.8
        let maxV = baseValue * 1.2
        let minW = 320.0
        let maxW = 768.0
        let v: Double = dim <= minW ? minV : dim >= maxW ? maxV : minV + (maxV - minV) * (dim - minW) / (maxW - minW)
        var out = v
        if applyAspectRatio { out *= metrics.aspectRatioMultiplier(customSensitivityK: sensitivityK) }
        return out
    }

    /// Auto satellite: linear up to 480 dp, logarithmic beyond (transient 480/0.4).
    @inlinable public static func autoDp(_ baseValue: Double, configuration c: DimensConfiguration,
        qualifier: DpQualifier = .smallWidth, inverter: Inverter = .default,
        ignoreMultiWindows: Bool = false, applyAspectRatio: Bool = false,
        sensitivityK: Double? = nil) -> Double {
        if ignoreMultiWindows && c.isMultiWindow { return baseValue }
        let metrics = c.metrics
        let dim = c.dimension(qualifier, inverter: inverter)
        let inv = DimensConstants.invBaseRatio
        let transition = 480.0
        let sensitivity = 0.4
        let scale: Double = dim <= transition
            ? dim * inv
            : transition * inv + sensitivity * Foundation.log(1 + (dim - transition) * inv)
        var out = baseValue * scale
        if applyAspectRatio { out *= metrics.aspectRatioMultiplier(customSensitivityK: sensitivityK) }
        return out
    }

    /// Density satellite: `base × densityDpi/160` (`displayScale`) — density ONLY.
    @inlinable public static func densityDp(_ baseValue: Double, configuration c: DimensConfiguration,
        qualifier: DpQualifier = .smallWidth, inverter: Inverter = .default,
        ignoreMultiWindows: Bool = false, applyAspectRatio: Bool = false,
        sensitivityK: Double? = nil) -> Double {
        if ignoreMultiWindows && c.isMultiWindow { return baseValue }
        var out = baseValue * c.displayScale
        if applyAspectRatio { out *= c.metrics.aspectRatioMultiplier(customSensitivityK: sensitivityK) }
        return out
    }

    /// Diagonal satellite: `√(min²+max²) / 611.6305` — window-based, no qualifier.
    @inlinable public static func diagonalDp(_ baseValue: Double, configuration c: DimensConfiguration,
        qualifier: DpQualifier = .smallWidth, inverter: Inverter = .default,
        ignoreMultiWindows: Bool = false, applyAspectRatio: Bool = false,
        sensitivityK: Double? = nil) -> Double {
        if ignoreMultiWindows && c.isMultiWindow { return baseValue }
        var out = baseValue * c.metrics.diagonalScale
        if applyAspectRatio { out *= c.metrics.aspectRatioMultiplier(customSensitivityK: sensitivityK) }
        return out
    }

    /// Perimeter satellite: `(min+max) / 833`.
    @inlinable public static func perimeterDp(_ baseValue: Double, configuration c: DimensConfiguration,
        qualifier: DpQualifier = .smallWidth, inverter: Inverter = .default,
        ignoreMultiWindows: Bool = false, applyAspectRatio: Bool = false,
        sensitivityK: Double? = nil) -> Double {
        if ignoreMultiWindows && c.isMultiWindow { return baseValue }
        var out = baseValue * c.metrics.perimeterScale
        if applyAspectRatio { out *= c.metrics.aspectRatioMultiplier(customSensitivityK: sensitivityK) }
        return out
    }

    /// Fill satellite: `max(sm/300, lg/533)` — smallest/largest side, not w/h.
    @inlinable public static func fillDp(_ baseValue: Double, configuration c: DimensConfiguration,
        qualifier: DpQualifier = .smallWidth, inverter: Inverter = .default,
        ignoreMultiWindows: Bool = false, applyAspectRatio: Bool = false,
        sensitivityK: Double? = nil) -> Double {
        if ignoreMultiWindows && c.isMultiWindow { return baseValue }
        let metrics = c.metrics
        let sm = metrics.minDimensionDp
        let lg = metrics.maxDimensionDp
        var out = baseValue * max(sm / DimensConstants.baseWidthDp, lg / DimensConstants.baseHeightDp)
        if applyAspectRatio { out *= metrics.aspectRatioMultiplier(customSensitivityK: sensitivityK) }
        return out
    }

    /// Fit satellite: `min(sm/300, lg/533)` — smallest/largest side, not w/h.
    @inlinable public static func fitDp(_ baseValue: Double, configuration c: DimensConfiguration,
        qualifier: DpQualifier = .smallWidth, inverter: Inverter = .default,
        ignoreMultiWindows: Bool = false, applyAspectRatio: Bool = false,
        sensitivityK: Double? = nil) -> Double {
        if ignoreMultiWindows && c.isMultiWindow { return baseValue }
        let metrics = c.metrics
        let sm = metrics.minDimensionDp
        let lg = metrics.maxDimensionDp
        var out = baseValue * min(sm / DimensConstants.baseWidthDp, lg / DimensConstants.baseHeightDp)
        if applyAspectRatio { out *= metrics.aspectRatioMultiplier(customSensitivityK: sensitivityK) }
        return out
    }

    /// Interpolated satellite: fixed 0.5 blend of linear vs. base.
    @inlinable public static func interpolatedDp(_ baseValue: Double, configuration c: DimensConfiguration,
        qualifier: DpQualifier = .smallWidth, inverter: Inverter = .default,
        ignoreMultiWindows: Bool = false, applyAspectRatio: Bool = false,
        sensitivityK: Double? = nil) -> Double {
        if ignoreMultiWindows && c.isMultiWindow { return baseValue }
        let metrics = c.metrics
        let isDefaultSw = qualifier == .smallWidth && inverter == .default
        var out: Double
        if isDefaultSw {
            out = baseValue * metrics.interpolatedScale
        } else {
            let dim = c.dimension(qualifier, inverter: inverter)
            let linear = baseValue * dim * DimensConstants.invBaseRatio
            out = baseValue + (linear - baseValue) * 0.5
        }
        if applyAspectRatio { out *= metrics.aspectRatioMultiplier(customSensitivityK: sensitivityK) }
        return out
    }

    /// Logarithmic satellite: `1 + 0.4·ln(dim/300)` / `1 − 0.4·ln(300/dim)`.
    @inlinable public static func logarithmicDp(_ baseValue: Double, configuration c: DimensConfiguration,
        qualifier: DpQualifier = .smallWidth, inverter: Inverter = .default,
        ignoreMultiWindows: Bool = false, applyAspectRatio: Bool = false,
        sensitivityK: Double? = nil) -> Double {
        if ignoreMultiWindows && c.isMultiWindow { return baseValue }
        let metrics = c.metrics
        let isDefaultSw = qualifier == .smallWidth && inverter == .default
        let sens = 0.4
        let inv = DimensConstants.invBaseRatio
        let scale: Double
        if isDefaultSw {
            scale = metrics.logarithmicScale
        } else {
            let dim = c.dimension(qualifier, inverter: inverter)
            scale = dim > DimensConstants.baseWidthDp
                ? 1 + sens * Foundation.log(dim * inv)
                : 1 - sens * Foundation.log(DimensConstants.baseWidthDp / dim)
        }
        var out = baseValue * scale
        if applyAspectRatio { out *= metrics.aspectRatioMultiplier(customSensitivityK: sensitivityK) }
        return out
    }

    /// Literal % of a screen axis (`spaceW` / `spaceH` / `spaceSw`).
    @inlinable public static func literalPercentOfScreenDp(_ percent: Double,
        qualifier: DpQualifier, configuration c: DimensConfiguration,
        ignoreMultiWindows: Bool = false) -> Double {
        guard percent.isFinite else { return 0 }
        if ignoreMultiWindows && c.isMultiWindow { return percent }
        return (percent / 100) * c.dimension(qualifier)
    }

    /// Literal % of an arbitrary reference dp (`space(reference:)`).
    @inlinable public static func literalPercentOfReferenceDp(_ percent: Double, referenceDp: Double) -> Double {
        guard percent.isFinite else { return 0 }
        return (percent / 100) * referenceDp
    }
}

// ───────────────────────────────────────────────────────────────────────────
// Literal percent APIs — “space” family (Android-familiar naming)
// ───────────────────────────────────────────────────────────────────────────

public extension BinaryInteger {
    @inlinable func spaceW(_ c: DimensConfiguration) -> Double { AppDimens.literalPercentOfScreenDp(Double(self), qualifier: .width, configuration: c) }
    @inlinable func spaceH(_ c: DimensConfiguration) -> Double { AppDimens.literalPercentOfScreenDp(Double(self), qualifier: .height, configuration: c) }
    @inlinable func spaceSw(_ c: DimensConfiguration) -> Double { AppDimens.literalPercentOfScreenDp(Double(self), qualifier: .smallWidth, configuration: c) }
    @inlinable func space(_ referenceDp: Double) -> Double { AppDimens.literalPercentOfReferenceDp(Double(self), referenceDp: referenceDp) }
    @inlinable func space(_ referenceDp: Double, _ c: DimensConfiguration) -> Double { AppDimens.literalPercentOfReferenceDp(Double(self), referenceDp: referenceDp) }
}
public extension BinaryFloatingPoint {
    @inlinable func spaceW(_ c: DimensConfiguration) -> Double { AppDimens.literalPercentOfScreenDp(Double(self), qualifier: .width, configuration: c) }
    @inlinable func spaceH(_ c: DimensConfiguration) -> Double { AppDimens.literalPercentOfScreenDp(Double(self), qualifier: .height, configuration: c) }
    @inlinable func spaceSw(_ c: DimensConfiguration) -> Double { AppDimens.literalPercentOfScreenDp(Double(self), qualifier: .smallWidth, configuration: c) }
    @inlinable func space(_ referenceDp: Double) -> Double { AppDimens.literalPercentOfReferenceDp(Double(self), referenceDp: referenceDp) }
    @inlinable func space(_ referenceDp: Double, _ c: DimensConfiguration) -> Double { AppDimens.literalPercentOfReferenceDp(Double(self), referenceDp: referenceDp) }
}

// ───────────────────────────────────────────────────────────────────────────
// Deprecated 3.1.6 convenience aliases — formulas now match 3.1.7
// ───────────────────────────────────────────────────────────────────────────

public extension AppDimens {
    @available(*, deprecated, renamed: "scaledDp(_:configuration:qualifier:inverter:ignoreMultiWindows:applyAspectRatio:sensitivityK:)",
        message: "Use scaledDp(_:configuration:); formulas updated to 3.1.7")
    @inlinable static func dp(_ value: Double, configuration: DimensConfiguration,
        qualifier: DpQualifier = .smallWidth, inverter: Inverter = .default,
        ignoreMultiWindows: Bool = false, applyAspectRatio: Bool = false,
        sensitivity: Double? = nil) -> Double {
        scaledDp(value, configuration: configuration, qualifier: qualifier, inverter: inverter,
            ignoreMultiWindows: ignoreMultiWindows, applyAspectRatio: applyAspectRatio, sensitivityK: sensitivity)
    }

    @available(*, deprecated, renamed: "scaledSp(_:configuration:qualifier:fontScale:inverter:ignoreMultiWindows:applyAspectRatio:sensitivityK:)",
        message: "Use scaledSp(_:configuration:); formulas updated to 3.1.7")
    @inlinable static func sp(_ value: Double, configuration: DimensConfiguration,
        qualifier: DpQualifier = .smallWidth, fontScale: Bool = true,
        inverter: Inverter = .default, ignoreMultiWindows: Bool = false,
        applyAspectRatio: Bool = false, sensitivity: Double? = nil) -> Double {
        scaledSp(value, configuration: configuration, qualifier: qualifier, fontScale: fontScale,
            inverter: inverter, ignoreMultiWindows: ignoreMultiWindows,
            applyAspectRatio: applyAspectRatio, sensitivityK: sensitivity)
    }
}

/// Plain (unscaled) branch helpers — port of `DimenPlainBranch` (3.1.7).
public enum AppDimensPlain {
    @inlinable public static func rotate(_ value: Double, branch: Double,
        orientation: Orientation, configuration: DimensConfiguration) -> Double {
        configuration.orientation == orientation ? branch : value
    }
    @inlinable public static func mode(_ value: Double, branch: Double,
        mode: UiModeType, configuration: DimensConfiguration) -> Double {
        configuration.uiMode == mode ? branch : value
    }
    @inlinable public static func qualifier(_ value: Double, branch: Double,
        qualifier: DpQualifier, minimum: Double, configuration: DimensConfiguration) -> Double {
        configuration.dimension(qualifier) >= minimum ? branch : value
    }
    @inlinable public static func screen(_ value: Double, branch: Double, mode: UiModeType,
        qualifier: DpQualifier, minimum: Double, configuration: DimensConfiguration) -> Double {
        configuration.uiMode == mode && configuration.dimension(qualifier) >= minimum ? branch : value
    }
}

/// Swift value-semantic port of the Android `ScaledDp`/`ScaledSp` builders.
public struct ScaledDp: Sendable {
    private struct Entry: Sendable { let value: Double; let mode: UiModeType?; let orientation: Orientation?; let qualifier: DpQualifier?; let minimum: Double }
    public let value: Double
    private var entries: [Entry] = []
    private var aspect = false, ignoreMulti = false
    private var sensitivityK: Double?
    public init(_ value: Double) { self.value = value }
    public func screen(_ value: Double, qualifier: DpQualifier, minimum: Double) -> Self {
        var copy = self; copy.entries.append(.init(value: value, mode: nil, orientation: nil, qualifier: qualifier, minimum: minimum)); return copy
    }
    public func mode(_ value: Double, _ mode: UiModeType) -> Self {
        var copy = self; copy.entries.append(.init(value: value, mode: mode, orientation: nil, qualifier: nil, minimum: 0)); return copy
    }
    public func rotate(_ value: Double, _ orientation: Orientation = .landscape) -> Self {
        var copy = self; copy.entries.append(.init(value: value, mode: nil, orientation: orientation, qualifier: nil, minimum: 0)); return copy
    }
    public func aspectRatio(_ enabled: Bool = true, sensitivityK: Double? = nil) -> Self { var copy = self; copy.aspect = enabled; copy.sensitivityK = sensitivityK; return copy }
    public func ignoreMultiWindows(_ enabled: Bool = true) -> Self { var copy = self; copy.ignoreMulti = enabled; return copy }
    public func resolve(_ configuration: DimensConfiguration, qualifier: DpQualifier = .smallWidth) -> Double {
        var selected = value
        for entry in entries {
            if let mode = entry.mode, mode == configuration.uiMode { selected = entry.value }
            else if let orientation = entry.orientation, orientation == configuration.orientation { selected = entry.value }
            else if let q = entry.qualifier, configuration.dimension(q) >= entry.minimum { selected = entry.value }
        }
        return AppDimens.scaledDp(selected, configuration: configuration, qualifier: qualifier,
            ignoreMultiWindows: ignoreMulti, applyAspectRatio: aspect, sensitivityK: sensitivityK)
    }
}

public struct ScaledSp: Sendable {
    private let dp: ScaledDp
    private let fontScale: Bool
    public init(_ value: Double, fontScale: Bool = true) { dp = ScaledDp(value); self.fontScale = fontScale }
    private init(dp: ScaledDp, fontScale: Bool) { self.dp = dp; self.fontScale = fontScale }
    public func screen(_ value: Double, qualifier: DpQualifier, minimum: Double) -> Self { .init(dp: dp.screen(value, qualifier: qualifier, minimum: minimum), fontScale: fontScale) }
    public func mode(_ value: Double, _ mode: UiModeType) -> Self { .init(dp: dp.mode(value, mode), fontScale: fontScale) }
    public func rotate(_ value: Double, _ orientation: Orientation = .landscape) -> Self { .init(dp: dp.rotate(value, orientation), fontScale: fontScale) }
    public func aspectRatio(_ enabled: Bool = true, sensitivityK: Double? = nil) -> Self { .init(dp: dp.aspectRatio(enabled, sensitivityK: sensitivityK), fontScale: fontScale) }
    public func ignoreMultiWindows(_ enabled: Bool = true) -> Self { .init(dp: dp.ignoreMultiWindows(enabled), fontScale: fontScale) }
    public func resolve(_ configuration: DimensConfiguration, qualifier: DpQualifier = .smallWidth) -> Double {
        let geometry = dp.resolve(configuration, qualifier: qualifier)
        return fontScale ? geometry * configuration.fontScale : geometry
    }
}

public extension BinaryInteger {
    var scaledDp: ScaledDp { ScaledDp(Double(self)) }
    var scaledSp: ScaledSp { ScaledSp(Double(self)) }
}
public extension BinaryFloatingPoint {
    var scaledDp: ScaledDp { ScaledDp(Double(self)) }
    var scaledSp: ScaledSp { ScaledSp(Double(self)) }
}