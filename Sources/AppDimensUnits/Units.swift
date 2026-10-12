@_exported import AppDimens
import Foundation

/// Physical measurement unit — port of Android `UnitType`.
public enum UnitType: String, Sendable, CaseIterable { case inch, cm, mm, sp, dp, px }

/// Physical unit conversions (mm, cm, inch) — port of Android `DimenPhysicalUnits`.
///
/// Apple platforms do not expose the panel's physical density, so conversions take a
/// `pointsPerInch` value. ``devicePointsPerInch`` is a per-idiom estimate (iPhone ≈ 163,
/// iPad ≈ 132, Mac ≈ 110, others 160 — Android's base density); pass an exact
/// value when you know the hardware.
public enum DimenPhysicalUnits {
    public static let mmToCmFactor = 10.0
    public static let mmToInchFactor = 25.4
    public static let cmToInchFactor = 2.54
    public static let circumferenceFactor = 2 * Double.pi
    /// Android base density — 160 px per inch at 1 dp = 1 px.
    public static let designPixelsPerInch = 160.0

    /// Best-effort points-per-inch for the current device idiom.
    public static let devicePointsPerInch: Double = {
        #if os(iOS)
        return _AppDimensDeviceIdiom.isPad ? 132 : 163
        #elseif os(macOS)
        return 110
        #else
        return designPixelsPerInch
        #endif
    }()

    // ── Android `toDpFrom*` / `toPxFrom*` / `toSpFrom*` ─────────────────────

    @inlinable public static func toDpFromMm(_ mm: Double, pointsPerInch: Double = devicePointsPerInch) -> Double { mm / mmToInchFactor * pointsPerInch }
    @inlinable public static func toDpFromCm(_ cm: Double, pointsPerInch: Double = devicePointsPerInch) -> Double { cm / cmToInchFactor * pointsPerInch }
    @inlinable public static func toDpFromInch(_ inch: Double, pointsPerInch: Double = devicePointsPerInch) -> Double { inch * pointsPerInch }
    @inlinable public static func toPxFromMm(_ mm: Double, _ c: DimensConfiguration, pointsPerInch: Double = devicePointsPerInch) -> Double { toDpFromMm(mm, pointsPerInch: pointsPerInch) * c.displayScale }
    @inlinable public static func toPxFromCm(_ cm: Double, _ c: DimensConfiguration, pointsPerInch: Double = devicePointsPerInch) -> Double { toDpFromCm(cm, pointsPerInch: pointsPerInch) * c.displayScale }
    @inlinable public static func toPxFromInch(_ inch: Double, _ c: DimensConfiguration, pointsPerInch: Double = devicePointsPerInch) -> Double { toDpFromInch(inch, pointsPerInch: pointsPerInch) * c.displayScale }
    /// Text size (pre font-scale) whose rendered size equals the physical length.
    @inlinable public static func toSpFromMm(_ mm: Double, _ c: DimensConfiguration, pointsPerInch: Double = devicePointsPerInch) -> Double { toDpFromMm(mm, pointsPerInch: pointsPerInch) / c.fontScale }
    @inlinable public static func toSpFromCm(_ cm: Double, _ c: DimensConfiguration, pointsPerInch: Double = devicePointsPerInch) -> Double { toDpFromCm(cm, pointsPerInch: pointsPerInch) / c.fontScale }
    @inlinable public static func toSpFromInch(_ inch: Double, _ c: DimensConfiguration, pointsPerInch: Double = devicePointsPerInch) -> Double { toDpFromInch(inch, pointsPerInch: pointsPerInch) / c.fontScale }

    // ── Legacy iOS spellings (design 160 ppi by default) ─────────────────────

    @inlinable public static func toMm(_ mm: Double, pixelsPerInch: Double = designPixelsPerInch) -> Double { mm * pixelsPerInch / mmToInchFactor }
    @inlinable public static func toCm(_ cm: Double, pixelsPerInch: Double = designPixelsPerInch) -> Double { cm * pixelsPerInch / cmToInchFactor }
    @inlinable public static func toInch(_ inches: Double, pixelsPerInch: Double = designPixelsPerInch) -> Double { inches * pixelsPerInch }

    // ── Unit-to-unit ──────────────────────────────────────────────────────────

    @inlinable public static func convertMmToCm(_ mm: Double) -> Double { mm / mmToCmFactor }
    @inlinable public static func convertMmToInch(_ mm: Double) -> Double { mm / mmToInchFactor }
    @inlinable public static func convertCmToMm(_ cm: Double) -> Double { cm * mmToCmFactor }
    @inlinable public static func convertCmToInch(_ cm: Double) -> Double { cm / cmToInchFactor }
    @inlinable public static func convertInchToCm(_ inch: Double) -> Double { inch * cmToInchFactor }
    @inlinable public static func convertInchToMm(_ inch: Double) -> Double { inch * mmToInchFactor }
    @inlinable public static func mmToCm(_ v: Double) -> Double { convertMmToCm(v) }
    @inlinable public static func mmToInch(_ v: Double) -> Double { convertMmToInch(v) }
    @inlinable public static func cmToMm(_ v: Double) -> Double { convertCmToMm(v) }
    @inlinable public static func cmToInch(_ v: Double) -> Double { convertCmToInch(v) }
    @inlinable public static func inchToCm(_ v: Double) -> Double { convertInchToCm(v) }
    @inlinable public static func inchToMm(_ v: Double) -> Double { convertInchToMm(v) }

    // ── Geometry helpers ──────────────────────────────────────────────────────

    /// Length of one `type` unit in points.
    @inlinable public static func unitSizeInDp(type: UnitType, configuration: DimensConfiguration,
        pixelsPerInch: Double = designPixelsPerInch) -> Double {
        switch type {
        case .inch: return toDpFromInch(1, pointsPerInch: pixelsPerInch)
        case .cm: return toDpFromCm(1, pointsPerInch: pixelsPerInch)
        case .mm: return toDpFromMm(1, pointsPerInch: pixelsPerInch)
        case .sp: return configuration.fontScale
        case .dp: return 1
        case .px: return 1 / configuration.displayScale
        }
    }

    /// Android `radiusFromDiameter` — radius in points.
    @inlinable public static func radiusFromDiameter(_ diameter: Double, _ type: UnitType, _ c: DimensConfiguration,
        pointsPerInch: Double = devicePointsPerInch) -> Double {
        diameter * unitSizeInDp(type: type, configuration: c, pixelsPerInch: pointsPerInch) / 2
    }

    /// Android `radiusFromCircumference` — radius in points.
    @inlinable public static func radiusFromCircumference(_ circumference: Double, _ type: UnitType, _ c: DimensConfiguration,
        pointsPerInch: Double = devicePointsPerInch) -> Double {
        circumference * unitSizeInDp(type: type, configuration: c, pixelsPerInch: pointsPerInch) / circumferenceFactor
    }

    /// Converts a diameter (in `type`) to a radius in points (legacy iOS spelling).
    @inlinable public static func radius(diameter: Double, type: UnitType,
        configuration: DimensConfiguration, pixelsPerInch: Double = designPixelsPerInch) -> Double {
        radiusFromDiameter(diameter, type, configuration, pointsPerInch: pixelsPerInch)
    }

    /// Circumference of a circle with `diameter` (or pass-through).
    @inlinable public static func displayMeasureDiameter(diameter: Double, isCircumference: Bool) -> Double {
        isCircumference ? diameter * Double.pi : diameter
    }
    @inlinable public static func measureDiameter(_ diameter: Double, isCircumference: Bool) -> Double {
        displayMeasureDiameter(diameter: diameter, isCircumference: isCircumference)
    }
}

public extension DimensNumber {
    @inlinable func mmToCm() -> Double { DimenPhysicalUnits.mmToCm(dimensValue) }
    @inlinable func mmToInch() -> Double { DimenPhysicalUnits.mmToInch(dimensValue) }
    @inlinable func cmToMm() -> Double { DimenPhysicalUnits.cmToMm(dimensValue) }
    @inlinable func cmToInch() -> Double { DimenPhysicalUnits.cmToInch(dimensValue) }
    @inlinable func inchToCm() -> Double { DimenPhysicalUnits.inchToCm(dimensValue) }
    @inlinable func inchToMm() -> Double { DimenPhysicalUnits.inchToMm(dimensValue) }

    /// `5.mm` → points for 5 millimetres on the current device (estimate, see ``DimenPhysicalUnits``).
    @inlinable var mm: CGFloat { CGFloat(DimenPhysicalUnits.toDpFromMm(dimensValue)) }
    @inlinable var cm: CGFloat { CGFloat(DimenPhysicalUnits.toDpFromCm(dimensValue)) }
    @inlinable var inch: CGFloat { CGFloat(DimenPhysicalUnits.toDpFromInch(dimensValue)) }
    @inlinable var mmPx: CGFloat { CGFloat(AppDimens._withAmbient { DimenPhysicalUnits.toPxFromMm(dimensValue, $0) }) }
    @inlinable var cmPx: CGFloat { CGFloat(AppDimens._withAmbient { DimenPhysicalUnits.toPxFromCm(dimensValue, $0) }) }
    @inlinable var inchPx: CGFloat { CGFloat(AppDimens._withAmbient { DimenPhysicalUnits.toPxFromInch(dimensValue, $0) }) }

    @inlinable func radius(_ type: UnitType, _ c: DimensConfiguration) -> Double {
        DimenPhysicalUnits.radiusFromDiameter(dimensValue, type, c, pointsPerInch: DimenPhysicalUnits.designPixelsPerInch)
    }
    @inlinable func measureDiameter(isCircumference: Bool) -> Double {
        DimenPhysicalUnits.measureDiameter(dimensValue, isCircumference: isCircumference)
    }
}

#if os(iOS)
/// Device-idiom probe that does not touch main-actor UIKit state (safe from any thread).
@usableFromInline enum _AppDimensDeviceIdiom {
    static var isPad: Bool {
        if let simulated = ProcessInfo.processInfo.environment["SIMULATOR_MODEL_IDENTIFIER"] {
            return simulated.hasPrefix("iPad")
        }
        var size = 0
        guard sysctlbyname("hw.machine", nil, &size, nil, 0) == 0, size > 0 else { return false }
        var machine = [CChar](repeating: 0, count: size)
        guard sysctlbyname("hw.machine", &machine, &size, nil, 0) == 0 else { return false }
        return String(cString: machine).hasPrefix("iPad")
    }
}
#endif
