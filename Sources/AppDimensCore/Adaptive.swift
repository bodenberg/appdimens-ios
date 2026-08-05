import Foundation

public struct DimensCondition: Hashable, Sendable {
    public var mode: DimensInterfaceMode?
    public var qualifier: DimensQualifier?
    public var minimum: Double?
    public var orientation: DimensOrientation
    public init(mode: DimensInterfaceMode? = nil, qualifier: DimensQualifier? = nil,
                minimum: Double? = nil, orientation: DimensOrientation = .automatic) {
        self.mode = mode; self.qualifier = qualifier; self.minimum = minimum; self.orientation = orientation
    }
    func matches(_ context: DimensContext) -> Bool {
        (mode == nil || mode == context.interfaceMode) &&
        (orientation == .automatic || orientation == context.orientation) &&
        (qualifier == nil || context.measure(qualifier!) >= (minimum ?? 0))
    }
    var priority: Int { (mode == nil ? 0 : 4) + (qualifier == nil ? 0 : 2) + (orientation == .automatic ? 0 : 1) }
}

/// Immutable fluent equivalent of Android's `DimenAuto` chain.
public struct AdaptiveDimension: Sendable {
    struct Entry: Sendable { let condition: DimensCondition; let value: Double; let order: Int }
    public let baseValue: Double
    private var entries: [Entry] = []
    private var options = DimensOptions()
    public init(_ baseValue: Double) { self.baseValue = baseValue }
    public func screen(_ condition: DimensCondition, value: Double) -> Self {
        var copy = self; copy.entries.append(Entry(condition: condition, value: value, order: entries.count)); return copy
    }
    public func aspectRatio(_ enabled: Bool = true, sensitivity: Double? = nil) -> Self {
        var copy = self; copy.options.aspectRatioAware = enabled; copy.options.aspectSensitivity = sensitivity; return copy
    }
    public func ignoreMultiWindow(_ enabled: Bool = true) -> Self {
        var copy = self; copy.options.ignoreMultiWindow = enabled; return copy
    }
    public func resolve(in context: DimensContext, finalQualifier: DimensQualifier = .smallestWidth) -> Double {
        let chosen = entries.filter { $0.condition.matches(context) }.sorted {
            $0.condition.priority == $1.condition.priority ?
                (($0.condition.minimum ?? 0) == ($1.condition.minimum ?? 0) ? $0.order < $1.order : ($0.condition.minimum ?? 0) > ($1.condition.minimum ?? 0)) :
                $0.condition.priority > $1.condition.priority
        }.first?.value ?? baseValue
        var resolved = options; resolved.qualifier = finalQualifier
        return Dimens.scale(chosen, in: context, options: resolved)
    }
}

public extension BinaryInteger { var autoScaled: AdaptiveDimension { AdaptiveDimension(Double(self)) } }
public extension BinaryFloatingPoint { var autoScaled: AdaptiveDimension { AdaptiveDimension(Double(self)) } }
