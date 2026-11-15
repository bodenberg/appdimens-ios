@_exported import AppDimens
import Foundation

/// Device class for an Apple window: UI mode (TV / car / watch / desk / visionOS), the
/// platform (macOS / Mac Catalyst → desktop, tvOS → TV, watchOS → watch, visionOS → VR),
/// then `smallestWidth >= 600` → tablet. Override with ``ScalingStrategies/deviceClassResolver``.
public func defaultDeviceClass(_ configuration: DimensConfiguration) -> DeviceClass {
    switch configuration.uiMode {
    case .television: return .tv
    case .car: return .car
    case .watch: return .watch
    case .desk: return .desktop
    case .vrHeadset: return .vr
    default: break
    }
    #if os(macOS) || targetEnvironment(macCatalyst)
    return .desktop
    #elseif os(tvOS)
    return .tv
    #elseif os(watchOS)
    return .watch
    #elseif os(visionOS)
    return .vr
    #else
    return configuration.smallestScreenWidth >= DeviceClass.tabletMinSmallestWidth ? .tablet : .phone
    #endif
}

/// Platform-free snapshot of a window configuration.
public func screenSnapshot(_ c: DimensConfiguration) -> ScreenSnapshot {
    ScreenSnapshot(widthDp: c.screenWidth, heightDp: c.screenHeight, smallestWidthDp: c.smallestScreenWidth,
                   density: c.displayScale, fontScale: c.fontScale,
                   isLandscape: c.orientation == .landscape || (c.orientation != .portrait && c.screenWidth > c.screenHeight),
                   isMultiWindow: c.isMultiWindow,
                   device: ScalingStrategies.deviceClassResolver?(c) ?? defaultDeviceClass(c))
}

/// A named, immutable custom scaling strategy. The factor is memoized per window
/// configuration, so `16.cdp(brand)` is one multiply (plus optional value bounds).
///
/// ```swift
/// let brand = try ScalingStrategy.define("brand",
///     reference: ReferenceScreen(width: 360, height: 640),
///     curve: .power(0.8), minFactor: 0.85, maxFactor: 1.6,
///     rules: [.on([.tablet, .desktop], ScalingPatch(curve: .logarithmic(0.4)), name: "large")])
/// ```
public final class ScalingStrategy: @unchecked Sendable, CustomStringConvertible {
    public let id: String
    public let config: ScalingConfig
    /// True when results depend on the value itself (value bounds / transform).
    public let isValueDependent: Bool

    private let lock = NSLock()
    private var memoKey: DimensConfiguration?
    private var memoDevice: DeviceClass?
    private var memo: ResolvedScaling?
    /// ``withAxis(_:)`` variants of this instance (guarded by `lock`).
    private var axisVariants: [ScalingAxis: ScalingStrategy] = [:]

    public init(_ id: String, config: ScalingConfig) throws {
        guard !id.trimmingCharacters(in: .whitespaces).isEmpty else {
            throw ScalingStrategyError("strategy id must not be blank")
        }
        try config.validate()
        self.id = id
        self.config = config
        self.isValueDependent = config.isValueDependent
    }

    /// Creates **and registers** a strategy (named parameters = the JSON fields).
    @discardableResult
    public static func define(_ id: String, extending parent: ScalingStrategy? = nil,
                              reference: ReferenceScreen? = nil, axis: ScalingAxis? = nil,
                              curve: ScalingCurve? = nil, multiplier: Double? = nil,
                              minFactor: Double? = nil, maxFactor: Double? = nil,
                              minValue: Double? = nil, maxValue: Double? = nil,
                              aspectRatio: Bool? = nil, sensitivity: Double? = nil,
                              fontScale: FontScalePolicy? = nil, ignoreMultiWindow: Bool? = nil,
                              transform: ValueTransform? = nil, formula: String? = nil,
                              rules: [ScalingRule] = [],
                              register: Bool = true) throws -> ScalingStrategy {
        let base = parent?.config ?? ScalingConfig()
        let parsedFormula = try formula.map {
            try ScalingExpression.parse($0, allowed: ScalingExpression.formulaVariables)
        }
        var cfg = base.applying(ScalingPatch(reference: reference, axis: axis, curve: curve, multiplier: multiplier,
                                             minFactor: minFactor, maxFactor: maxFactor, minValue: minValue,
                                             maxValue: maxValue, aspectRatio: aspectRatio, sensitivity: sensitivity,
                                             fontScale: fontScale, ignoreMultiWindow: ignoreMultiWindow,
                                             transform: transform, formula: parsedFormula))
        cfg.rules = base.rules + rules
        let strategy = try ScalingStrategy(id, config: cfg)
        if register { ScalingStrategies.register(strategy) }
        return strategy
    }

    /// Resolution for `configuration` (default: the ambient window) — memoized.
    public func resolve(_ configuration: DimensConfiguration = AppDimens.configuration) -> ResolvedScaling {
        let snapshot = screenSnapshot(configuration)
        lock.lock()
        if let memo = memo, memoKey == configuration, memoDevice == snapshot.device {
            lock.unlock()
            return memo
        }
        lock.unlock()
        let resolved = ScalingEngine.resolve(config, snapshot)
        lock.lock()
        memoKey = configuration
        memoDevice = snapshot.device
        memo = resolved
        lock.unlock()
        return resolved
    }

    /// Resolution for an explicit platform-free snapshot (tests, previews).
    public func resolve(screen: ScreenSnapshot) -> ResolvedScaling { ScalingEngine.resolve(config, screen) }

    public func factor(_ c: DimensConfiguration = AppDimens.configuration) -> Double { resolve(c).factor }

    /// Value (pt) → scaled pt.
    public func dp(_ value: Double, _ c: DimensConfiguration = AppDimens.configuration) -> Double {
        resolve(c).scale(value)
    }

    /// Value (pt) → physical pixels.
    public func px(_ value: Double, _ c: DimensConfiguration = AppDimens.configuration) -> Double {
        resolve(c).scale(value) * c.displayScale
    }

    /// Final text point size (Dynamic Type applied per the strategy font-scale policy).
    public func sp(_ value: Double, _ c: DimensConfiguration = AppDimens.configuration) -> Double {
        resolve(c).scaleSpDp(value)
    }

    /// Text size in physical pixels.
    public func spPx(_ value: Double, _ c: DimensConfiguration = AppDimens.configuration) -> Double {
        resolve(c).scaleSpDp(value) * c.displayScale
    }

    /// Human-readable breakdown for logs / debug overlays.
    public func explain(_ c: DimensConfiguration = AppDimens.configuration) -> String { resolve(c).explain(id) }

    /// New strategy starting from this one (parent rules first). Registered unless `register: false`.
    @discardableResult
    public func extend(_ id: String, reference: ReferenceScreen? = nil, axis: ScalingAxis? = nil,
                       curve: ScalingCurve? = nil, multiplier: Double? = nil,
                       minFactor: Double? = nil, maxFactor: Double? = nil,
                       minValue: Double? = nil, maxValue: Double? = nil,
                       aspectRatio: Bool? = nil, sensitivity: Double? = nil,
                       fontScale: FontScalePolicy? = nil, ignoreMultiWindow: Bool? = nil,
                       transform: ValueTransform? = nil, formula: String? = nil,
                       rules: [ScalingRule] = [],
                       register: Bool = true) throws -> ScalingStrategy {
        try ScalingStrategy.define(id, extending: self, reference: reference, axis: axis, curve: curve,
                                   multiplier: multiplier, minFactor: minFactor, maxFactor: maxFactor,
                                   minValue: minValue, maxValue: maxValue, aspectRatio: aspectRatio,
                                   sensitivity: sensitivity, fontScale: fontScale,
                                   ignoreMultiWindow: ignoreMultiWindow, transform: transform,
                                   formula: formula, rules: rules, register: register)
    }

    /// Same strategy on another axis. Id `"<id>@<axis>"`, cached per instance (so a re-registered
    /// id never returns another config's variant; a race only builds an equivalent variant twice).
    public func withAxis(_ axis: ScalingAxis) -> ScalingStrategy {
        if axis == config.axis { return self }
        lock.lock()
        let hit = axisVariants[axis]
        lock.unlock()
        if let hit = hit { return hit }
        var cfg = config
        cfg.axis = axis
        // The derived config differs only by axis, so it is valid whenever `config` is.
        let made = try! ScalingStrategy("\(id)@\(axis.rawValue)", config: cfg)
        lock.lock()
        defer { lock.unlock() }
        if let raced = axisVariants[axis] { return raced }
        axisVariants[axis] = made
        return made
    }

    /// JSON value (throws for function curves / transforms).
    public func toJSON() throws -> JSONValue { try ScalingStrategyJSON.encode(id: id, config) }

    public var description: String { "ScalingStrategy(\(id))" }
}

// swiftlint:disable force_try
private func builtIn(_ id: String, _ build: (inout ScalingConfig) -> Void) -> ScalingStrategy {
    var c = ScalingConfig()
    build(&c)
    return try! ScalingStrategy(id, config: c)
}
// swiftlint:enable force_try

/// The built-in strategies as custom configs — parents for `extend` / `"extends"`.
public enum BuiltInStrategies {
    public static let scaled = builtIn("scaled") { _ in }
    public static let power = builtIn("power") { $0.curve = .power(0.75) }
    public static let logarithmic = builtIn("logarithmic") { $0.curve = .logarithmic(0.4) }
    public static let interpolated = builtIn("interpolated") { $0.curve = .interpolated(0.5) }
    public static let diagonal = builtIn("diagonal") { $0.axis = .diagonal }
    public static let perimeter = builtIn("perimeter") { $0.axis = .perimeter }
    public static let fixed = builtIn("fixed") { $0.curve = .constant(1) }

    public static var all: [ScalingStrategy] { [scaled, power, logarithmic, interpolated, diagonal, perimeter, fixed] }
}

/// Ready-made strategies for common product needs (same ids on every platform).
public enum CustomPresets {
    public static let tabletFriendly = builtIn("tabletFriendly") {
        $0.maxFactor = 1.8
        $0.rules = [.on([.tablet, .desktop], ScalingPatch(curve: .power(0.5)), name: "large")]
    }
    public static let compactFirst = builtIn("compactFirst") {
        $0.reference = ReferenceScreen(width: 360, height: 640)
        $0.curve = .interpolated(0.5)
        $0.minFactor = 0.9
        $0.maxFactor = 1.4
    }
    public static let tvSafe = builtIn("tvSafe") {
        $0.rules = [.on([.tv], ScalingPatch(reference: ReferenceScreen(width: 960, height: 540), axis: .height,
                                            minFactor: 1, maxFactor: 2), name: "tv")]
    }
    public static let wearable = builtIn("wearable") {
        $0.rules = [.on([.watch], ScalingPatch(reference: ReferenceScreen(width: 192, height: 192), axis: .min,
                                               minFactor: 0.85, maxFactor: 1.15), name: "watch")]
    }
    public static let gameHud = builtIn("gameHud") {
        $0.axis = .min
        $0.curve = .power(0.85)
        $0.aspectRatio = true
        $0.minFactor = 0.75
        $0.maxFactor = 2.5
        $0.fontScale = .ignore
    }
    public static let readableText = builtIn("readableText") {
        $0.curve = .logarithmic(0.4)
        $0.fontScale = .clamp(1.3)
    }

    public static var all: [ScalingStrategy] { [tabletFriendly, compactFirst, tvSafe, wearable, gameHud, readableText] }
}

/// Process-wide registry of strategies by id, plus the default used by `16.cdp`.
public enum ScalingStrategies {
    private final class Store: @unchecked Sendable {
        let lock = NSLock()
        var byId: [String: ScalingStrategy] = [:]
        var formulas: [String: ScalingStrategy] = [:]
        var codeIds = 0
        var defaultStrategy: ScalingStrategy?
        var resolver: (@Sendable (DimensConfiguration) -> DeviceClass)?
    }

    private static let store = Store()

    private static func locked<R>(_ body: (Store) -> R) -> R {
        store.lock.lock()
        defer { store.lock.unlock() }
        return body(store)
    }

    /// Replaces device-class detection (`nil` = ``defaultDeviceClass(_:)``).
    public static var deviceClassResolver: (@Sendable (DimensConfiguration) -> DeviceClass)? {
        get { locked { $0.resolver } }
        set { locked { $0.resolver = newValue } }
    }

    /// Strategy used when none is passed (`16.cdp`). Initially ``BuiltInStrategies/scaled`` (= `sdp`).
    public static var defaultStrategy: ScalingStrategy {
        get { locked { $0.defaultStrategy } ?? BuiltInStrategies.scaled }
        set { locked { $0.defaultStrategy = newValue } }
    }

    /// Registers (or replaces) `strategy` under its id.
    @discardableResult
    public static func register(_ strategy: ScalingStrategy) -> ScalingStrategy {
        locked { $0.byId[strategy.id] = strategy }
        return strategy
    }

    public static func unregister(_ id: String) {
        locked { s in
            s.byId[id] = nil
            if s.defaultStrategy?.id == id { s.defaultStrategy = nil }
        }
    }

    /// Registered strategy, built-in or preset for `id`.
    public static subscript(_ id: String) -> ScalingStrategy? {
        if let hit = locked({ $0.byId[id] }) { return hit }
        let lower = id.lowercased()
        return (BuiltInStrategies.all + CustomPresets.all).first { $0.id.lowercased() == lower }
    }

    public static func require(_ id: String) throws -> ScalingStrategy {
        guard let s = self[id] else {
            let known = locked { $0.byId.keys.sorted() }.joined(separator: ", ")
            throw ScalingStrategyError("No scaling strategy '\(id)'. Registered: \(known)")
        }
        return s
    }

    /// Strategies registered by the app (built-ins / presets excluded).
    public static var registered: [ScalingStrategy] { locked { Array($0.byId.values) } }

    /// Parses a strategies document, registers every strategy and applies its `default`.
    @discardableResult
    public static func load(json: String) throws -> [String: ScalingStrategy] {
        try install(ScalingStrategyJSON.parse(json, lookup: { self[$0]?.config }))
    }

    @discardableResult
    public static func load(data: Data) throws -> [String: ScalingStrategy] {
        try install(ScalingStrategyJSON.parse(data, lookup: { self[$0]?.config }))
    }

    /// Loads `name.json` from `bundle` (e.g. `appdimens-strategies`).
    @discardableResult
    public static func load(resource name: String, bundle: Bundle = .main) throws -> [String: ScalingStrategy] {
        guard let url = bundle.url(forResource: name, withExtension: "json") else {
            throw ScalingStrategyError("Resource '\(name).json' not found in bundle")
        }
        return try load(data: Data(contentsOf: url))
    }

    private static func install(_ doc: ScalingStrategyJSON.Document) throws -> [String: ScalingStrategy] {
        // Build everything and resolve the default before registering, so a bad document
        // registers nothing.
        var out: [String: ScalingStrategy] = [:]
        for id in doc.ids {
            out[id] = try ScalingStrategy(id, config: doc.configs[id]!)
        }
        let newDefault = try doc.defaultId.map { try out[$0] ?? require($0) }
        for id in doc.ids { if let s = out[id] { register(s) } }
        if let d = newDefault { defaultStrategy = d }
        return out
    }

    /// JSON document for `strategies` (default: every registered strategy).
    public static func exportJSON(_ strategies: [ScalingStrategy]? = nil) throws -> JSONValue {
        let list = strategies ?? registered.sorted { $0.id < $1.id }
        var doc: [String: JSONValue] = ["version": .number(Double(ScalingStrategyJSON.formatVersion)),
                                        "strategies": .array(try list.map { try $0.toJSON() })]
        if let d = locked({ $0.defaultStrategy }) { doc["default"] = .string(d.id) }
        return .object(doc)
    }

    /// Bound for distinct inline formula texts; past it, strategies are built per call (still correct).
    static let maxSharedFormulas = 256

    /// Strategy whose value is the text `formula` (`"base * pow(sw / 360, 0.8)"`), shared per text
    /// and not registered (id `formula:<text>`). Same as ``scalingFormula(_:id:register:)`` without
    /// an id. Throws the parse error (with its position) for an invalid formula.
    public static func formula(_ formula: String) throws -> ScalingStrategy {
        if let hit = locked({ $0.formulas[formula] }) { return hit }
        let made = try ScalingStrategy.textFormula(id: "formula:\(formula)", formula)
        return locked { s in
            if let hit = s.formulas[formula] { return hit }
            if s.formulas.count >= maxSharedFormulas { return made }
            s.formulas[formula] = made
            return made
        }
    }

    /// Next unique id for a code strategy (`formula#N`, `scale#N`).
    static func nextCodeId(_ prefix: String) -> String {
        let n: Int = locked { s in
            s.codeIds += 1
            return s.codeIds
        }
        return "\(prefix)#\(n)"
    }

    /// Test helper — clears the registry, the default and the resolver.
    public static func resetForTesting() {
        locked { s in
            s.byId = [:]
            s.formulas = [:]
            s.defaultStrategy = nil
            s.resolver = nil
        }
    }
}
