import Foundation

/// Literal-percent “space” family — port of Android `DimenPercentSpace`.
///
/// `25.spaceW` is 25 % of the current window width; `10.space(200)` is 10 % of
/// 200 pt. `i` = ignore multi-window (returns the raw percent when the window is
/// constrained), `Px` = pixels, `Sp` = text size with the same physical size.
/// Ambient properties return `CGFloat`; `(_ configuration)` overloads return points.
public extension DimensNumber {
    @inlinable internal func _space(_ q: DpQualifier, _ c: DimensConfiguration, _ ignore: Bool) -> Double {
        AppDimens.literalPercentOfScreenDp(dimensValue, qualifier: q, configuration: c, ignoreMultiWindows: ignore)
    }
    @inlinable internal func _spaceAmbient(_ q: DpQualifier, _ ignore: Bool, px: Bool) -> CGFloat {
        CGFloat(AppDimens._withAmbient { c in
            AppDimens.literalPercentOfScreenDp(dimensValue, qualifier: q, configuration: c, ignoreMultiWindows: ignore) *
                (px ? c.displayScale : 1)
        })
    }

    // ── Width ──────────────────────────────────────────────────────────────
    @inlinable var spaceW: CGFloat { _spaceAmbient(.width, false, px: false) }
    @inlinable var spaceWi: CGFloat { _spaceAmbient(.width, true, px: false) }
    @inlinable var spaceWPx: CGFloat { _spaceAmbient(.width, false, px: true) }
    @inlinable var spaceWPxi: CGFloat { _spaceAmbient(.width, true, px: true) }
    @inlinable func spaceW(_ c: DimensConfiguration, ignoreMultiWindows: Bool = false) -> Double { _space(.width, c, ignoreMultiWindows) }
    @inlinable func spaceWi(_ c: DimensConfiguration) -> Double { _space(.width, c, true) }
    @inlinable func spaceWPx(_ c: DimensConfiguration, ignoreMultiWindows: Bool = false) -> Double { _space(.width, c, ignoreMultiWindows) * c.displayScale }
    @inlinable func spaceWPxi(_ c: DimensConfiguration) -> Double { _space(.width, c, true) * c.displayScale }
    @inlinable func spaceWSp(fontScale: Bool = true, ignoreMultiWindows: Bool = false) -> CGFloat { _spaceAmbient(.width, ignoreMultiWindows, px: false) }
    @inlinable func spaceWSpi(fontScale: Bool = true) -> CGFloat { _spaceAmbient(.width, true, px: false) }
    @inlinable func spaceWSpPx(ignoreMultiWindows: Bool = false) -> CGFloat { _spaceAmbient(.width, ignoreMultiWindows, px: true) }
    @inlinable func spaceWSpiPx() -> CGFloat { _spaceAmbient(.width, true, px: true) }

    // ── Smallest width ─────────────────────────────────────────────────────
    @inlinable var spaceSw: CGFloat { _spaceAmbient(.smallWidth, false, px: false) }
    @inlinable var spaceSwi: CGFloat { _spaceAmbient(.smallWidth, true, px: false) }
    @inlinable var spaceSwPx: CGFloat { _spaceAmbient(.smallWidth, false, px: true) }
    @inlinable var spaceSwPxi: CGFloat { _spaceAmbient(.smallWidth, true, px: true) }
    @inlinable func spaceSw(_ c: DimensConfiguration, ignoreMultiWindows: Bool = false) -> Double { _space(.smallWidth, c, ignoreMultiWindows) }
    @inlinable func spaceSwi(_ c: DimensConfiguration) -> Double { _space(.smallWidth, c, true) }
    @inlinable func spaceSwPx(_ c: DimensConfiguration, ignoreMultiWindows: Bool = false) -> Double { _space(.smallWidth, c, ignoreMultiWindows) * c.displayScale }
    @inlinable func spaceSwPxi(_ c: DimensConfiguration) -> Double { _space(.smallWidth, c, true) * c.displayScale }
    @inlinable func spaceSwSp(fontScale: Bool = true, ignoreMultiWindows: Bool = false) -> CGFloat { _spaceAmbient(.smallWidth, ignoreMultiWindows, px: false) }
    @inlinable func spaceSwSpi(fontScale: Bool = true) -> CGFloat { _spaceAmbient(.smallWidth, true, px: false) }
    @inlinable func spaceSwSpPx(ignoreMultiWindows: Bool = false) -> CGFloat { _spaceAmbient(.smallWidth, ignoreMultiWindows, px: true) }
    @inlinable func spaceSwSpiPx() -> CGFloat { _spaceAmbient(.smallWidth, true, px: true) }

    // ── Height ─────────────────────────────────────────────────────────────
    @inlinable var spaceH: CGFloat { _spaceAmbient(.height, false, px: false) }
    @inlinable var spaceHi: CGFloat { _spaceAmbient(.height, true, px: false) }
    @inlinable var spaceHPx: CGFloat { _spaceAmbient(.height, false, px: true) }
    @inlinable var spaceHPxi: CGFloat { _spaceAmbient(.height, true, px: true) }
    @inlinable func spaceH(_ c: DimensConfiguration, ignoreMultiWindows: Bool = false) -> Double { _space(.height, c, ignoreMultiWindows) }
    @inlinable func spaceHi(_ c: DimensConfiguration) -> Double { _space(.height, c, true) }
    @inlinable func spaceHPx(_ c: DimensConfiguration, ignoreMultiWindows: Bool = false) -> Double { _space(.height, c, ignoreMultiWindows) * c.displayScale }
    @inlinable func spaceHPxi(_ c: DimensConfiguration) -> Double { _space(.height, c, true) * c.displayScale }
    @inlinable func spaceHSp(fontScale: Bool = true, ignoreMultiWindows: Bool = false) -> CGFloat { _spaceAmbient(.height, ignoreMultiWindows, px: false) }
    @inlinable func spaceHSpi(fontScale: Bool = true) -> CGFloat { _spaceAmbient(.height, true, px: false) }
    @inlinable func spaceHSpPx(ignoreMultiWindows: Bool = false) -> CGFloat { _spaceAmbient(.height, ignoreMultiWindows, px: true) }
    @inlinable func spaceHSpiPx() -> CGFloat { _spaceAmbient(.height, true, px: true) }

    // ── Reference length ───────────────────────────────────────────────────
    /// `10.space(200)` → 20 pt (10 % of 200 pt).
    @inlinable func space(_ reference: Double, ignoreMultiWindows: Bool = false) -> CGFloat {
        CGFloat(AppDimens.literalPercentOfReferenceDp(dimensValue, referenceDp: reference))
    }
    @inlinable func spaceI(_ reference: Double) -> CGFloat { space(reference, ignoreMultiWindows: true) }
    @inlinable func spacePx(_ reference: Double, ignoreMultiWindows: Bool = false) -> CGFloat {
        CGFloat(AppDimens._withAmbient { AppDimens.literalPercentOfReferenceDp(dimensValue, referenceDp: reference) * $0.displayScale })
    }
    @inlinable func spacePxi(_ reference: Double) -> CGFloat { spacePx(reference, ignoreMultiWindows: true) }
    @inlinable func spaceSp(_ reference: Double, fontScale: Bool = true, ignoreMultiWindows: Bool = false) -> CGFloat { space(reference) }
    @inlinable func spaceSpi(_ reference: Double, fontScale: Bool = true) -> CGFloat { space(reference) }
    @inlinable func spaceSpPx(_ reference: Double, ignoreMultiWindows: Bool = false) -> CGFloat { spacePx(reference) }
    @inlinable func spaceSpiPx(_ reference: Double) -> CGFloat { spacePx(reference) }
    @inlinable func space(_ reference: Double, _ c: DimensConfiguration, ignoreMultiWindows: Bool = false) -> Double {
        AppDimens.literalPercentOfReferenceDp(dimensValue, referenceDp: reference)
    }
    @inlinable func spaceDp(_ reference: Double, _ c: DimensConfiguration, ignoreMultiWindows: Bool = false) -> Double {
        AppDimens.literalPercentOfReferenceDp(dimensValue, referenceDp: reference)
    }
    @inlinable func spacePx(_ reference: Double, _ c: DimensConfiguration, ignoreMultiWindows: Bool = false) -> Double {
        AppDimens.literalPercentOfReferenceDp(dimensValue, referenceDp: reference) * c.displayScale
    }
}
