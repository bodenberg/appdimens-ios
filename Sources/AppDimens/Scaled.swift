import Foundation

public enum AppDimens {
    public static let baseRatio = 300.0
    public static let referenceAspectRatio = 1.78

    @inlinable public static func dp(_ value: Double, configuration: DimensConfiguration,
        qualifier: DpQualifier = .smallWidth, inverter: Inverter = .default,
        ignoreMultiWindows: Bool = false, applyAspectRatio: Bool = false,
        sensitivity: Double? = nil) -> Double {
        if ignoreMultiWindows && configuration.isMultiWindow { return value }
        let dimension = configuration.dimension(qualifier, inverter: inverter)
        if !applyAspectRatio { return value * dimension / baseRatio }
        let k = sensitivity ?? 0.10
        let normalized = max(configuration.aspectRatio / referenceAspectRatio, 0.0001)
        return value * (1 + (dimension - baseRatio) * (1 / baseRatio + k * log(normalized) / baseRatio))
    }

    @inlinable public static func sp(_ value: Double, configuration: DimensConfiguration,
        qualifier: DpQualifier = .smallWidth, fontScale: Bool = true,
        inverter: Inverter = .default, ignoreMultiWindows: Bool = false,
        applyAspectRatio: Bool = false, sensitivity: Double? = nil) -> Double {
        let scaled = dp(value, configuration: configuration, qualifier: qualifier, inverter: inverter,
            ignoreMultiWindows: ignoreMultiWindows, applyAspectRatio: applyAspectRatio, sensitivity: sensitivity)
        // Apple points already are density independent. Dynamic Type is the font-scale equivalent.
        return fontScale ? scaled * configuration.fontScale : scaled
    }
}

/// Direct port of the principal artifact's plain branch helpers. Values are
/// selected without scaling.
public enum AppDimensPlain {
    @inlinable public static func rotate(_ value: Double, branch: Double,
        orientation: DimensOrientation, configuration: DimensConfiguration) -> Double {
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

public extension BinaryInteger {
    @inlinable func sdp(_ c: DimensConfiguration) -> Double { AppDimens.dp(Double(self), configuration: c) }
    @inlinable func sdpa(_ c: DimensConfiguration) -> Double { AppDimens.dp(Double(self), configuration: c, applyAspectRatio: true) }
    @inlinable func sdpi(_ c: DimensConfiguration) -> Double { AppDimens.dp(Double(self), configuration: c, ignoreMultiWindows: true) }
    @inlinable func sdpia(_ c: DimensConfiguration) -> Double { AppDimens.dp(Double(self), configuration: c, ignoreMultiWindows: true, applyAspectRatio: true) }
    @inlinable func hdp(_ c: DimensConfiguration) -> Double { AppDimens.dp(Double(self), configuration: c, qualifier: .height) }
    @inlinable func wdp(_ c: DimensConfiguration) -> Double { AppDimens.dp(Double(self), configuration: c, qualifier: .width) }
    @inlinable func ssp(_ c: DimensConfiguration) -> Double { AppDimens.sp(Double(self), configuration: c) }
    @inlinable func hsp(_ c: DimensConfiguration) -> Double { AppDimens.sp(Double(self), configuration: c, qualifier: .height) }
    @inlinable func wsp(_ c: DimensConfiguration) -> Double { AppDimens.sp(Double(self), configuration: c, qualifier: .width) }
    @inlinable func sem(_ c: DimensConfiguration) -> Double { AppDimens.sp(Double(self), configuration: c, fontScale: false) }
    @inlinable func hem(_ c: DimensConfiguration) -> Double { AppDimens.sp(Double(self), configuration: c, qualifier: .height, fontScale: false) }
    @inlinable func wem(_ c: DimensConfiguration) -> Double { AppDimens.sp(Double(self), configuration: c, qualifier: .width, fontScale: false) }
    @inlinable func hdpa(_ c: DimensConfiguration) -> Double { AppDimens.dp(Double(self), configuration: c, qualifier: .height, applyAspectRatio: true) }
    @inlinable func hdpi(_ c: DimensConfiguration) -> Double { AppDimens.dp(Double(self), configuration: c, qualifier: .height, ignoreMultiWindows: true) }
    @inlinable func hdpia(_ c: DimensConfiguration) -> Double { AppDimens.dp(Double(self), configuration: c, qualifier: .height, ignoreMultiWindows: true, applyAspectRatio: true) }
    @inlinable func wdpa(_ c: DimensConfiguration) -> Double { AppDimens.dp(Double(self), configuration: c, qualifier: .width, applyAspectRatio: true) }
    @inlinable func wdpi(_ c: DimensConfiguration) -> Double { AppDimens.dp(Double(self), configuration: c, qualifier: .width, ignoreMultiWindows: true) }
    @inlinable func wdpia(_ c: DimensConfiguration) -> Double { AppDimens.dp(Double(self), configuration: c, qualifier: .width, ignoreMultiWindows: true, applyAspectRatio: true) }
}
public extension BinaryFloatingPoint {
    @inlinable func sdp(_ c: DimensConfiguration) -> Double { AppDimens.dp(Double(self), configuration: c) }
    @inlinable func sdpa(_ c: DimensConfiguration) -> Double { AppDimens.dp(Double(self), configuration: c, applyAspectRatio: true) }
    @inlinable func sdpi(_ c: DimensConfiguration) -> Double { AppDimens.dp(Double(self), configuration: c, ignoreMultiWindows: true) }
    @inlinable func sdpia(_ c: DimensConfiguration) -> Double { AppDimens.dp(Double(self), configuration: c, ignoreMultiWindows: true, applyAspectRatio: true) }
    @inlinable func hdp(_ c: DimensConfiguration) -> Double { AppDimens.dp(Double(self), configuration: c, qualifier: .height) }
    @inlinable func wdp(_ c: DimensConfiguration) -> Double { AppDimens.dp(Double(self), configuration: c, qualifier: .width) }
    @inlinable func ssp(_ c: DimensConfiguration) -> Double { AppDimens.sp(Double(self), configuration: c) }
    @inlinable func hsp(_ c: DimensConfiguration) -> Double { AppDimens.sp(Double(self), configuration: c, qualifier: .height) }
    @inlinable func wsp(_ c: DimensConfiguration) -> Double { AppDimens.sp(Double(self), configuration: c, qualifier: .width) }
    @inlinable func sem(_ c: DimensConfiguration) -> Double { AppDimens.sp(Double(self), configuration: c, fontScale: false) }
    @inlinable func hem(_ c: DimensConfiguration) -> Double { AppDimens.sp(Double(self), configuration: c, qualifier: .height, fontScale: false) }
    @inlinable func wem(_ c: DimensConfiguration) -> Double { AppDimens.sp(Double(self), configuration: c, qualifier: .width, fontScale: false) }
    @inlinable func hdpa(_ c: DimensConfiguration) -> Double { AppDimens.dp(Double(self), configuration: c, qualifier: .height, applyAspectRatio: true) }
    @inlinable func hdpi(_ c: DimensConfiguration) -> Double { AppDimens.dp(Double(self), configuration: c, qualifier: .height, ignoreMultiWindows: true) }
    @inlinable func hdpia(_ c: DimensConfiguration) -> Double { AppDimens.dp(Double(self), configuration: c, qualifier: .height, ignoreMultiWindows: true, applyAspectRatio: true) }
    @inlinable func wdpa(_ c: DimensConfiguration) -> Double { AppDimens.dp(Double(self), configuration: c, qualifier: .width, applyAspectRatio: true) }
    @inlinable func wdpi(_ c: DimensConfiguration) -> Double { AppDimens.dp(Double(self), configuration: c, qualifier: .width, ignoreMultiWindows: true) }
    @inlinable func wdpia(_ c: DimensConfiguration) -> Double { AppDimens.dp(Double(self), configuration: c, qualifier: .width, ignoreMultiWindows: true, applyAspectRatio: true) }
}

public extension AppDimens {
    @inlinable static func rotate(_ value: Double, rotationValue: Double,
        configuration: DimensConfiguration, qualifier: DpQualifier = .smallWidth,
        orientation: DimensOrientation = .landscape, ignoreMultiWindows: Bool = false,
        applyAspectRatio: Bool = false) -> Double {
        dp(configuration.orientation == orientation ? rotationValue : value,
           configuration: configuration, qualifier: qualifier,
           ignoreMultiWindows: ignoreMultiWindows, applyAspectRatio: applyAspectRatio)
    }

    @inlinable static func qualified(_ value: Double, qualifiedValue: Double,
        configuration: DimensConfiguration, qualifier: DpQualifier, minimum: Double,
        finalQualifier: DpQualifier = .smallWidth, ignoreMultiWindows: Bool = false,
        applyAspectRatio: Bool = false) -> Double {
        let selected = configuration.dimension(qualifier) >= minimum ? qualifiedValue : value
        return dp(selected, configuration: configuration, qualifier: finalQualifier,
                  ignoreMultiWindows: ignoreMultiWindows, applyAspectRatio: applyAspectRatio)
    }

    @inlinable static func mode(_ value: Double, modeValue: Double, mode: UiModeType,
        configuration: DimensConfiguration, qualifier: DpQualifier = .smallWidth,
        ignoreMultiWindows: Bool = false, applyAspectRatio: Bool = false) -> Double {
        dp(configuration.uiMode == mode ? modeValue : value, configuration: configuration,
           qualifier: qualifier, ignoreMultiWindows: ignoreMultiWindows, applyAspectRatio: applyAspectRatio)
    }
}

/// Direct Swift value-semantic port of the principal artifact's `scaledDp()` builder.
public struct ScaledDp: Sendable {
    private struct Entry: Sendable { let value: Double; let mode: UiModeType?; let orientation: DimensOrientation?; let qualifier: DpQualifier?; let minimum: Double }
    public let value: Double
    private var entries: [Entry] = []
    private var aspect = false, ignoreMulti = false
    public init(_ value: Double) { self.value = value }
    public func screen(_ value: Double, qualifier: DpQualifier, minimum: Double) -> Self {
        var copy = self; copy.entries.append(.init(value: value, mode: nil, orientation: nil, qualifier: qualifier, minimum: minimum)); return copy
    }
    public func mode(_ value: Double, _ mode: UiModeType) -> Self {
        var copy = self; copy.entries.append(.init(value: value, mode: mode, orientation: nil, qualifier: nil, minimum: 0)); return copy
    }
    public func rotate(_ value: Double, _ orientation: DimensOrientation = .landscape) -> Self {
        var copy = self; copy.entries.append(.init(value: value, mode: nil, orientation: orientation, qualifier: nil, minimum: 0)); return copy
    }
    public func aspectRatio(_ enabled: Bool = true) -> Self { var copy = self; copy.aspect = enabled; return copy }
    public func ignoreMultiWindows(_ enabled: Bool = true) -> Self { var copy = self; copy.ignoreMulti = enabled; return copy }
    public func resolve(_ configuration: DimensConfiguration, qualifier: DpQualifier = .smallWidth) -> Double {
        var selected = value
        for entry in entries {
            if let mode = entry.mode, mode == configuration.uiMode { selected = entry.value }
            else if let orientation = entry.orientation, orientation == configuration.orientation { selected = entry.value }
            else if let q = entry.qualifier, configuration.dimension(q) >= entry.minimum { selected = entry.value }
        }
        return AppDimens.dp(selected, configuration: configuration, qualifier: qualifier,
                           ignoreMultiWindows: ignoreMulti, applyAspectRatio: aspect)
    }
}

public extension BinaryInteger { var scaledDp: ScaledDp { ScaledDp(Double(self)) } }
public extension BinaryFloatingPoint { var scaledDp: ScaledDp { ScaledDp(Double(self)) } }
