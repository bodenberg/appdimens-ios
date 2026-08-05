import Foundation
import AppDimensCore

/// Physical conversion utilities. Apple screen PPI is not a public API, so callers inject measured PPI.
public enum PhysicalUnit: String, Sendable { case millimeters, centimeters, inches }

public enum DimensPhysical {
    public static func points(_ value: Double, unit: PhysicalUnit) -> Double {
        switch unit { case .inches: return value * 72; case .centimeters: return value * 72 / 2.54; case .millimeters: return value * 72 / 25.4 }
    }
    public static func pixels(_ value: Double, unit: PhysicalUnit, pixelsPerInch: Double) -> Double {
        precondition(pixelsPerInch > 0 && pixelsPerInch.isFinite)
        let inches: Double
        switch unit { case .inches: inches = value; case .centimeters: inches = value / 2.54; case .millimeters: inches = value / 25.4 }
        return inches * pixelsPerInch
    }
}
