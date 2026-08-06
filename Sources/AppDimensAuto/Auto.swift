@_exported import AppDimens

public struct AutoCondition: Hashable, Sendable {
    public var mode: UiModeType?; public var orientation: DimensOrientation?
    public var qualifier: DpQualifier?; public var minimum: Double
    public init(mode: UiModeType? = nil, orientation: DimensOrientation? = nil,
        qualifier: DpQualifier? = nil, minimum: Double = 0) {
        self.mode = mode; self.orientation = orientation; self.qualifier = qualifier; self.minimum = minimum
    }
    @inlinable public func matches(_ c: DimensConfiguration) -> Bool {
        (mode == nil || mode == c.uiMode) && (orientation == nil || orientation == c.orientation) &&
        (qualifier == nil || c.dimension(qualifier!) >= minimum)
    }
    @inlinable var priority: Int { (mode == nil ? 0 : 4) + (qualifier == nil ? 0 : 2) + (orientation == nil ? 0 : 1) }
}

public struct AutoDp: Sendable {
    private struct Entry: Sendable { let condition: AutoCondition; let value: Double; let order: Int }
    public let value: Double; private var entries: [Entry] = []
    private var aspect = false, ignoreMulti = false; private var sensitivity: Double?
    public init(_ value: Double) { self.value = value }
    public func screen(_ value: Double, condition: AutoCondition) -> Self {
        var x = self; x.entries.append(.init(condition: condition, value: value, order: entries.count)); return x
    }
    public func qualifier(_ value: Double, _ q: DpQualifier, minimum: Double) -> Self { screen(value, condition: .init(qualifier: q, minimum: minimum)) }
    public func mode(_ value: Double, _ mode: UiModeType) -> Self { screen(value, condition: .init(mode: mode)) }
    public func rotate(_ value: Double, _ orientation: DimensOrientation = .landscape) -> Self { screen(value, condition: .init(orientation: orientation)) }
    public func aspectRatio(_ enabled: Bool = true, sensitivity: Double? = nil) -> Self { var x = self; x.aspect = enabled; x.sensitivity = sensitivity; return x }
    public func ignoreMultiWindows(_ enabled: Bool = true) -> Self { var x = self; x.ignoreMulti = enabled; return x }
    public func resolve(_ c: DimensConfiguration, qualifier: DpQualifier = .smallWidth) -> Double {
        let selected = entries.filter { $0.condition.matches(c) }.sorted {
            if $0.condition.priority != $1.condition.priority { return $0.condition.priority > $1.condition.priority }
            if $0.condition.minimum != $1.condition.minimum { return $0.condition.minimum > $1.condition.minimum }
            return $0.order < $1.order
        }.first?.value ?? value
        return AppDimens.dp(selected, configuration: c, qualifier: qualifier,
            ignoreMultiWindows: ignoreMulti, applyAspectRatio: aspect, sensitivity: sensitivity)
    }
}
public struct AutoSp: Sendable {
    private let dp: AutoDp; private let fontScale: Bool
    public init(_ value: Double, fontScale: Bool = true) { dp = AutoDp(value); self.fontScale = fontScale }
    private init(dp: AutoDp, fontScale: Bool) { self.dp = dp; self.fontScale = fontScale }
    public func screen(_ value: Double, condition: AutoCondition) -> Self { .init(dp: dp.screen(value, condition: condition), fontScale: fontScale) }
    public func resolve(_ c: DimensConfiguration, qualifier: DpQualifier = .smallWidth) -> Double {
        let geometry = dp.resolve(c, qualifier: qualifier)
        return fontScale ? geometry * c.fontScale : geometry
    }
}
public extension BinaryInteger { var autoScaledDp: AutoDp { AutoDp(Double(self)) }; var autoSp: AutoSp { AutoSp(Double(self)) } }
public extension BinaryFloatingPoint { var autoScaledDp: AutoDp { AutoDp(Double(self)) }; var autoSp: AutoSp { AutoSp(Double(self)) } }
