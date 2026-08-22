@_exported import AppDimens
import Foundation

/// Physical measurement unit — port of Android `UnitType`.
public enum UnitType: String, Sendable, CaseIterable { case inch, cm, mm, sp, dp, px }

/// Physical unit conversions (MM, CM, Inch) — port of Android
/// `DimenPhysicalUnits`. Metric → dp conversions use the design reference
/// 160 dpi (Android's base density) unless `pixelsPerInch` is provided.
public enum DimenPhysicalUnits {
    public static let mmToCmFactor = 10.0
    public static let mmToInchFactor = 25.4
    public static let cmToInchFactor = 2.54
    public static let circumferenceFactor = 2 * Double.pi
    /// Android base density — 160 physical px per inch (1 dp ≈ physical inch/160).
    public static let designPixelsPerInch = 160.0

    // ── MM ──────────────────────────────────────────────────────────────────

    /// mm → dp points (`mm × ppi/25.4`).
    @inlinable public static func toMm(_ mm: Double, pixelsPerInch: Double = designPixelsPerInch) -> Double {
        mm * pixelsPerInch / mmToInchFactor
    }
    @inlinable public static func convertMmToCm(_ mm: Double) -> Double { mm / mmToCmFactor }
    @inlinable public static func convertMmToInch(_ mm: Double) -> Double { mm / mmToInchFactor }
    @inlinable public static func mmToCm(_ value: Double) -> Double { convertMmToCm(value) }
    @inlinable public static func mmToInch(_ value: Double) -> Double { convertMmToInch(value) }

    // ── CM ──────────────────────────────────────────────────────────────────

    /// cm → dp points (`cm × ppi/2.54`).
    @inlinable public static func toCm(_ cm: Double, pixelsPerInch: Double = designPixelsPerInch) -> Double {
        cm * pixelsPerInch / cmToInchFactor
    }
    @inlinable public static func convertCmToMm(_ cm: Double) -> Double { cm * mmToCmFactor }
    @inlinable public static func convertCmToInch(_ cm: Double) -> Double { cm / cmToInchFactor }
    @inlinable public static func cmToMm(_ value: Double) -> Double { convertCmToMm(value) }
    @inlinable public static func cmToInch(_ value: Double) -> Double { convertCmToInch(value) }

    // ── INCH ────────────────────────────────────────────────────────────────

    /// inch → dp points (`in × ppi`).
    @inlinable public static func toInch(_ inches: Double, pixelsPerInch: Double = designPixelsPerInch) -> Double {
        inches * pixelsPerInch
    }
    @inlinable public static func convertInchToCm(_ inch: Double) -> Double { inch * cmToInchFactor }
    @inlinable public static func convertInchToMm(_ inch: Double) -> Double { inch * mmToInchFactor }
    @inlinable public static func inchToCm(_ value: Double) -> Double { convertInchToCm(value) }
    @inlinable public static func inchToMm(_ value: Double) -> Double { convertInchToMm(value) }

    // ── Diameter / radius ───────────────────────────────────────────────────

    /// Converts a diameter (in [type]) to a radius in dp points.
    @inlinable public static func radius(diameter: Double, type: UnitType,
        configuration: DimensConfiguration, pixelsPerInch: Double = designPixelsPerInch) -> Double {
        let inDp: Double
        switch type {
        case .inch: inDp = toInch(diameter, pixelsPerInch: pixelsPerInch)
        case .cm: inDp = toCm(diameter, pixelsPerInch: pixelsPerInch)
        case .mm: inDp = toMm(diameter, pixelsPerInch: pixelsPerInch)
        case .sp: inDp = diameter * configuration.fontScale
        case .dp: inDp = diameter
        case .px: inDp = diameter / configuration.displayScale
        }
        return inDp / 2
    }

    /// Diameter of a circle from circumference (or pass-through).
    @inlinable public static func displayMeasureDiameter(diameter: Double, isCircumference: Bool) -> Double {
        isCircumference ? diameter * circumferenceFactor : diameter
    }
    @inlinable public static func measureDiameter(_ diameter: Double, isCircumference: Bool) -> Double {
        displayMeasureDiameter(diameter: diameter, isCircumference: isCircumference)
    }

    /// dp-point size of one unit — Android `unitSizeInDp`.
    @inlinable public static func unitSizeInDp(type: UnitType,
        configuration: DimensConfiguration, pixelsPerInch: Double = designPixelsPerInch) -> Double {
        switch type {
        case .inch: return toInch(1, pixelsPerInch: pixelsPerInch)
        case .cm: return toCm(1, pixelsPerInch: pixelsPerInch)
        case .mm: return toMm(1, pixelsPerInch: pixelsPerInch)
        case .sp: return configuration.fontScale
        case .dp: return 1
        case .px: return 1 / configuration.displayScale
        }
    }
}

public extension BinaryInteger {
    @inlinable func mmToCm() -> Double { DimenPhysicalUnits.mmToCm(Double(self)) }
    @inlinable func mmToInch() -> Double { DimenPhysicalUnits.mmToInch(Double(self)) }
    @inlinable func cmToMm() -> Double { DimenPhysicalUnits.cmToMm(Double(self)) }
    @inlinable func cmToInch() -> Double { DimenPhysicalUnits.cmToInch(Double(self)) }
    @inlinable func inchToCm() -> Double { DimenPhysicalUnits.inchToCm(Double(self)) }
    @inlinable func inchToMm() -> Double { DimenPhysicalUnits.inchToMm(Double(self)) }
    @inlinable func radius(_ type: UnitType, _ c: DimensConfiguration) -> Double { DimenPhysicalUnits.radius(diameter: Double(self), type: type, configuration: c) }
    @inlinable func measureDiameter(isCircumference: Bool) -> Double { DimenPhysicalUnits.measureDiameter(Double(self), isCircumference: isCircumference) }
}
public extension BinaryFloatingPoint {
    @inlinable func mmToCm() -> Double { DimenPhysicalUnits.mmToCm(Double(self)) }
    @inlinable func mmToInch() -> Double { DimenPhysicalUnits.mmToInch(Double(self)) }
    @inlinable func cmToMm() -> Double { DimenPhysicalUnits.cmToMm(Double(self)) }
    @inlinable func cmToInch() -> Double { DimenPhysicalUnits.cmToInch(Double(self)) }
    @inlinable func inchToCm() -> Double { DimenPhysicalUnits.inchToCm(Double(self)) }
    @inlinable func inchToMm() -> Double { DimenPhysicalUnits.inchToMm(Double(self)) }
    @inlinable func radius(_ type: UnitType, _ c: DimensConfiguration) -> Double { DimenPhysicalUnits.radius(diameter: Double(self), type: type, configuration: c) }
    @inlinable func measureDiameter(isCircumference: Bool) -> Double { DimenPhysicalUnits.measureDiameter(Double(self), isCircumference: isCircumference) }
}