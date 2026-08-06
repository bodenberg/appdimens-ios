@_exported import AppDimens

public enum PhysicalUnit: String, Sendable, CaseIterable { case inch, centimeter, millimeter, point, pixel }
public enum DimensUnits {
    @inlinable public static func points(_ value: Double, from unit: PhysicalUnit,
        configuration: DimensConfiguration, pixelsPerInch: Double? = nil) -> Double {
        switch unit { case .point: return value; case .pixel: return value / configuration.displayScale
        case .inch: return value * 72; case .centimeter: return value * 72 / 2.54
        case .millimeter: return value * 72 / 25.4 }
    }
    @inlinable public static func pixels(_ value: Double, from unit: PhysicalUnit,
        configuration: DimensConfiguration, pixelsPerInch: Double? = nil) -> Double {
        if unit == .pixel { return value }; if let ppi = pixelsPerInch {
            switch unit { case .inch: return value * ppi; case .centimeter: return value * ppi / 2.54
            case .millimeter: return value * ppi / 25.4; default: break }
        }
        return points(value, from: unit, configuration: configuration) * configuration.displayScale
    }
}
