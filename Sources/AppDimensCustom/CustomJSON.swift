import Foundation

/// Minimal JSON value used by the strategy codec (keeps booleans and numbers distinct on
/// every platform, unlike `JSONSerialization`'s `NSNumber`).
public enum JSONValue: Equatable, Sendable, Codable {
    case null
    case bool(Bool)
    case number(Double)
    case string(String)
    case array([JSONValue])
    case object([String: JSONValue])

    public init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer()
        if c.decodeNil() { self = .null }
        else if let b = try? c.decode(Bool.self) { self = .bool(b) }
        else if let n = try? c.decode(Double.self) { self = .number(n) }
        else if let s = try? c.decode(String.self) { self = .string(s) }
        else if let a = try? c.decode([JSONValue].self) { self = .array(a) }
        else { self = .object(try c.decode([String: JSONValue].self)) }
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.singleValueContainer()
        switch self {
        case .null: try c.encodeNil()
        case let .bool(b): try c.encode(b)
        case let .number(n): try c.encode(n)
        case let .string(s): try c.encode(s)
        case let .array(a): try c.encode(a)
        case let .object(o): try c.encode(o)
        }
    }

    subscript(key: String) -> JSONValue? {
        if case let .object(o) = self { return o[key] }
        return nil
    }

    var objectValue: [String: JSONValue]? { if case let .object(o) = self { return o }; return nil }
    var arrayValue: [JSONValue]? { if case let .array(a) = self { return a }; return nil }
    var stringValue: String? { if case let .string(s) = self { return s }; return nil }
    var boolValue: Bool? { if case let .bool(b) = self { return b }; return nil }
}

/// JSON codec for the cross-platform strategy format (`custom-strategy.schema.json`).
public enum ScalingStrategyJSON {
    public static let formatVersion = 1

    /// Parsed document: configs by id (declaration order kept in `ids`) and the `default`.
    public struct Document {
        public let ids: [String]
        public let configs: [String: ScalingConfig]
        public let defaultId: String?
    }

    // ── decoding ────────────────────────────────────────────────────────────

    /// Decodes a document (`{"strategies": [...]}`), a single strategy object or an array.
    /// `lookup` resolves `extends` outside the document (registry, built-ins, presets).
    public static func parse(_ text: String, lookup: (String) -> ScalingConfig? = { _ in nil }) throws -> Document {
        guard let data = text.data(using: .utf8) else { throw ScalingStrategyError("Invalid JSON: not UTF-8") }
        return try parse(data, lookup: lookup)
    }

    public static func parse(_ data: Data, lookup: (String) -> ScalingConfig? = { _ in nil }) throws -> Document {
        let root: JSONValue
        do {
            root = try JSONDecoder().decode(JSONValue.self, from: data)
        } catch {
            throw ScalingStrategyError("Invalid JSON: \(error)")
        }
        return try parse(root, lookup: lookup)
    }

    public static func parse(_ root: JSONValue, lookup: (String) -> ScalingConfig? = { _ in nil }) throws -> Document {
        var items: [JSONValue]
        var defaultId: String?
        switch root {
        case let .array(a):
            items = a
        case let .object(o) where o["strategies"] != nil:
            if case let .number(v)? = o["version"], Int(v) > formatVersion {
                throw ScalingStrategyError("Unsupported strategies format version \(Int(v))")
            }
            guard let list = o["strategies"]?.arrayValue else { throw ScalingStrategyError("strategies must be an array") }
            items = list
            defaultId = o["default"]?.stringValue
        case .object:
            items = [root]
        default:
            throw ScalingStrategyError("Expected a JSON object or array")
        }
        var raw: [String: [String: JSONValue]] = [:]
        var order: [String] = []
        for (i, item) in items.enumerated() {
            guard let obj = item.objectValue else { throw ScalingStrategyError("strategies[\(i)] must be an object") }
            guard let id = obj["id"]?.stringValue, !id.trimmingCharacters(in: .whitespaces).isEmpty else {
                throw ScalingStrategyError("strategies[\(i)].id is required")
            }
            if raw[id] != nil { throw ScalingStrategyError("Duplicate strategy id '\(id)'") }
            raw[id] = obj
            order.append(id)
        }
        var built: [String: ScalingConfig] = [:]
        func build(_ id: String, _ stack: [String]) throws -> ScalingConfig {
            if let done = built[id] { return done }
            if stack.contains(id) {
                throw ScalingStrategyError("Cyclic 'extends': \((stack + [id]).joined(separator: " → "))")
            }
            let obj = raw[id]!
            var parent = ScalingConfig()
            if let parentId = obj["extends"]?.stringValue {
                if raw[parentId] != nil {
                    parent = try build(parentId, stack + [id])
                } else if let found = lookup(parentId) {
                    parent = found
                } else {
                    throw ScalingStrategyError("'\(id)' extends unknown strategy '\(parentId)'")
                }
            }
            let cfg = try readConfig(obj, parent: parent, path: id)
            built[id] = cfg
            return cfg
        }
        for id in order { _ = try build(id, []) }
        return Document(ids: order, configs: built, defaultId: defaultId)
    }

    static func num(_ v: JSONValue?, _ path: String) throws -> Double? {
        switch v {
        case nil, .null?: return nil
        case let .number(n)?:
            guard n.isFinite else { throw ScalingStrategyError("\(path) must be finite") }
            return n
        default: throw ScalingStrategyError("\(path) must be a number")
        }
    }

    static func req(_ v: JSONValue?, _ path: String) throws -> Double {
        guard let n = try num(v, path) else { throw ScalingStrategyError("\(path) is required") }
        return n
    }

    static func readCurve(_ v: JSONValue, _ path: String) throws -> ScalingCurve {
        if case let .string(s) = v { return try readCurve(.object(["type": .string(s)]), path) }
        guard let o = v.objectValue else { throw ScalingStrategyError("\(path) must be an object or string") }
        let type = o["type"]?.stringValue ?? ""
        switch type {
        case "linear": return .linear
        case "power": return .power(try num(o["exponent"], "\(path).exponent") ?? 0.75)
        case "logarithmic": return .logarithmic(try num(o["k"], "\(path).k") ?? 0.4)
        case "interpolated": return .interpolated(try num(o["t"], "\(path).t") ?? 0.5)
        case "constant": return .constant(try num(o["factor"], "\(path).factor") ?? 1)
        case "breakpoints":
            guard let pts = o["points"]?.arrayValue, !pts.isEmpty else {
                throw ScalingStrategyError("\(path).points must be a non-empty array")
            }
            return .breakpoints(try pts.enumerated().map { i, p in
                Breakpoint(try req(p["at"], "\(path).points[\(i)].at"), try req(p["factor"], "\(path).points[\(i)].factor"))
            })
        case "expression":
            guard let src = o["expression"]?.stringValue else { throw ScalingStrategyError("\(path).expression is required") }
            return try at("\(path).expression") { try ScalingCurve.expression(src) }
        default:
            throw ScalingStrategyError("\(path).type '\(type)' is not one of linear, power, logarithmic, interpolated, constant, breakpoints, expression")
        }
    }

    static func at<T>(_ path: String, _ create: () throws -> T) throws -> T {
        do {
            return try create()
        } catch let e as ScalingStrategyError {
            throw ScalingStrategyError("\(path): \(e.description)")
        }
    }

    static func readFontScale(_ v: JSONValue, _ path: String) throws -> FontScalePolicy {
        switch v {
        case .string("follow"): return .follow
        case .string("ignore"): return .ignore
        case let .object(o): return .clamp(try req(o["max"], "\(path).max"))
        default: throw ScalingStrategyError("\(path) must be \"follow\", \"ignore\" or {\"max\": n}")
        }
    }

    static func readPatch(_ o: [String: JSONValue], _ path: String) throws -> ScalingPatch {
        var p = ScalingPatch()
        if let ref = o["reference"]?.objectValue {
            p.reference = ReferenceScreen(width: try num(ref["width"], "\(path).reference.width") ?? 300,
                                          height: try num(ref["height"], "\(path).reference.height") ?? 533)
        }
        if let axis = o["axis"]?.stringValue {
            guard let a = ScalingAxis(rawValue: axis) else {
                throw ScalingStrategyError("\(path).axis: Unknown axis '\(axis)'. Expected one of \(ScalingAxis.allCases.map(\.rawValue).joined(separator: ", "))")
            }
            p.axis = a
        }
        if let curve = o["curve"], curve != .null { p.curve = try readCurve(curve, "\(path).curve") }
        p.multiplier = try num(o["multiplier"], "\(path).multiplier")
        if let clamp = o["clamp"]?.objectValue {
            p.minFactor = try num(clamp["min"], "\(path).clamp.min")
            p.maxFactor = try num(clamp["max"], "\(path).clamp.max")
        }
        if let clamp = o["valueClamp"]?.objectValue {
            p.minValue = try num(clamp["min"], "\(path).valueClamp.min")
            p.maxValue = try num(clamp["max"], "\(path).valueClamp.max")
        }
        switch o["aspectRatio"] {
        case nil, .null?: break
        case let .bool(b)?: p.aspectRatio = b
        case let .object(ar)?:
            p.aspectRatio = ar["enabled"]?.boolValue ?? true
            p.sensitivity = try num(ar["sensitivity"], "\(path).aspectRatio.sensitivity")
        default: throw ScalingStrategyError("\(path).aspectRatio must be a boolean or object")
        }
        if p.sensitivity == nil { p.sensitivity = try num(o["sensitivity"], "\(path).sensitivity") }
        if let fs = o["fontScale"], fs != .null { p.fontScale = try readFontScale(fs, "\(path).fontScale") }
        p.ignoreMultiWindow = o["ignoreMultiWindow"]?.boolValue
        switch o["formula"] {
        case nil, .null?: break
        case let .string(src)?:
            p.formula = try at("\(path).formula") {
                try ScalingExpression.parse(src, allowed: ScalingExpression.formulaVariables)
            }
        default: throw ScalingStrategyError("\(path).formula must be a string")
        }
        return p
    }

    static func readCondition(_ o: [String: JSONValue], _ path: String) throws -> ScreenCondition {
        func range(_ key: String) throws -> (Double?, Double?) {
            guard let r = o[key]?.objectValue else { return (nil, nil) }
            return (try num(r["min"], "\(path).\(key).min"), try num(r["max"], "\(path).\(key).max"))
        }
        var c = ScreenCondition()
        func device(_ s: String) throws -> DeviceClass {
            guard let d = DeviceClass(rawValue: s) else {
                throw ScalingStrategyError("\(path).device: Unknown device '\(s)'. Expected one of \(DeviceClass.allCases.map(\.rawValue).joined(separator: ", "))")
            }
            return d
        }
        switch o["device"] {
        case nil, .null?: break
        case let .string(s)?: c.devices = [try device(s)]
        case let .array(a)?: c.devices = Set(try a.map { try device($0.stringValue ?? "") })
        default: throw ScalingStrategyError("\(path).device must be a string or array")
        }
        switch o["orientation"]?.stringValue {
        case nil: break
        case "landscape"?: c.landscape = true
        case "portrait"?: c.landscape = false
        case let other?: throw ScalingStrategyError("\(path).orientation '\(other)' must be portrait or landscape")
        }
        (c.minSmallestWidth, c.maxSmallestWidth) = try range("smallestWidth")
        (c.minWidth, c.maxWidth) = try range("width")
        (c.minHeight, c.maxHeight) = try range("height")
        (c.minAspectRatio, c.maxAspectRatio) = try range("aspectRatio")
        c.multiWindow = o["multiWindow"]?.boolValue
        return c
    }

    /// Builds a validated config from `o` on top of `parent` (parent rules first).
    static func readConfig(_ o: [String: JSONValue], parent: ScalingConfig, path: String) throws -> ScalingConfig {
        var cfg = parent.applying(try readPatch(o, path))
        if o["clamp"] == JSONValue.null { cfg.minFactor = nil; cfg.maxFactor = nil }
        if o["valueClamp"] == JSONValue.null { cfg.minValue = nil; cfg.maxValue = nil }
        if o["formula"] == JSONValue.null { cfg.formula = nil }
        var rules = parent.rules
        if let list = o["rules"]?.arrayValue {
            for (i, r) in list.enumerated() {
                guard let rule = r.objectValue, let set = rule["set"]?.objectValue else {
                    throw ScalingStrategyError("\(path).rules[\(i)].set is required")
                }
                rules.append(ScalingRule(try readCondition(rule["when"]?.objectValue ?? [:], "\(path).rules[\(i)].when"),
                                         try readPatch(set, "\(path).rules[\(i)].set"),
                                         name: rule["name"]?.stringValue))
            }
        }
        cfg.rules = rules
        try cfg.validate()
        return cfg
    }

    // ── encoding ────────────────────────────────────────────────────────────

    static func curveJSON(_ c: ScalingCurve) throws -> JSONValue {
        switch c {
        case .linear: return .object(["type": .string("linear")])
        case let .power(e): return .object(["type": .string("power"), "exponent": .number(e)])
        case let .logarithmic(k): return .object(["type": .string("logarithmic"), "k": .number(k)])
        case let .interpolated(t): return .object(["type": .string("interpolated"), "t": .number(t)])
        case let .constant(f): return .object(["type": .string("constant"), "factor": .number(f)])
        case let .breakpoints(p):
            return .object(["type": .string("breakpoints"),
                            "points": .array(p.map { .object(["at": .number($0.at), "factor": .number($0.factor)]) })])
        case let .expressionCurve(e): return .object(["type": .string("expression"), "expression": .string(e.source)])
        case .custom: throw ScalingStrategyError("Custom curve functions cannot be encoded to JSON")
        }
    }

    static func range(_ min: Double?, _ max: Double?) -> JSONValue {
        var o: [String: JSONValue] = [:]
        if let min = min { o["min"] = .number(min) }
        if let max = max { o["max"] = .number(max) }
        return .object(o)
    }

    static func patchJSON(_ p: ScalingPatch, defaults: Bool) throws -> [String: JSONValue] {
        if p.transform != nil { throw ScalingStrategyError("transform functions cannot be encoded to JSON") }
        var o: [String: JSONValue] = [:]
        if let r = p.reference, !defaults || r != .standard {
            o["reference"] = .object(["width": .number(r.width), "height": .number(r.height)])
        }
        if let a = p.axis, !defaults || a != .smallestWidth { o["axis"] = .string(a.rawValue) }
        if let c = p.curve { o["curve"] = try curveJSON(c) }
        if let m = p.multiplier, !defaults || m != 1 { o["multiplier"] = .number(m) }
        if p.minFactor != nil || p.maxFactor != nil { o["clamp"] = range(p.minFactor, p.maxFactor) }
        if p.minValue != nil || p.maxValue != nil { o["valueClamp"] = range(p.minValue, p.maxValue) }
        if let ar = p.aspectRatio, !defaults || ar || p.sensitivity != nil {
            var a: [String: JSONValue] = ["enabled": .bool(ar)]
            if let s = p.sensitivity { a["sensitivity"] = .number(s) }
            o["aspectRatio"] = .object(a)
        }
        if let f = p.fontScale, !defaults || f != .follow {
            switch f {
            case .follow: o["fontScale"] = .string("follow")
            case .ignore: o["fontScale"] = .string("ignore")
            case let .clamp(max): o["fontScale"] = .object(["max": .number(max)])
            }
        }
        if let mw = p.ignoreMultiWindow, !defaults || mw { o["ignoreMultiWindow"] = .bool(mw) }
        if let f = p.formula { o["formula"] = .string(f.source) }
        return o
    }

    static func conditionJSON(_ c: ScreenCondition) -> JSONValue {
        var o: [String: JSONValue] = [:]
        if let d = c.devices {
            o["device"] = .array(DeviceClass.allCases.filter { d.contains($0) }.map { .string($0.rawValue) })
        }
        if let l = c.landscape { o["orientation"] = .string(l ? "landscape" : "portrait") }
        if c.minSmallestWidth != nil || c.maxSmallestWidth != nil { o["smallestWidth"] = range(c.minSmallestWidth, c.maxSmallestWidth) }
        if c.minWidth != nil || c.maxWidth != nil { o["width"] = range(c.minWidth, c.maxWidth) }
        if c.minHeight != nil || c.maxHeight != nil { o["height"] = range(c.minHeight, c.maxHeight) }
        if c.minAspectRatio != nil || c.maxAspectRatio != nil { o["aspectRatio"] = range(c.minAspectRatio, c.maxAspectRatio) }
        if let mw = c.multiWindow { o["multiWindow"] = .bool(mw) }
        return .object(o)
    }

    /// JSON value for one strategy (throws for function curves / transforms).
    public static func encode(id: String, _ c: ScalingConfig) throws -> JSONValue {
        var p = ScalingPatch(reference: c.reference, axis: c.axis, curve: c.curve, multiplier: c.multiplier,
                             minFactor: c.minFactor, maxFactor: c.maxFactor, minValue: c.minValue,
                             maxValue: c.maxValue, aspectRatio: c.aspectRatio, sensitivity: c.sensitivity,
                             fontScale: c.fontScale, ignoreMultiWindow: c.ignoreMultiWindow)
        p.transform = c.transform
        p.formula = c.formula
        var o = try patchJSON(p, defaults: true)
        o["id"] = .string(id)
        if !c.rules.isEmpty {
            o["rules"] = .array(try c.rules.map { r in
                var rule: [String: JSONValue] = ["when": conditionJSON(r.condition), "set": .object(try patchJSON(r.patch, defaults: false))]
                if let n = r.name { rule["name"] = .string(n) }
                return .object(rule)
            })
        }
        return .object(o)
    }

    /// Serialized JSON text for `value` (sorted keys).
    public static func text(_ value: JSONValue) throws -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        return String(decoding: try encoder.encode(value), as: UTF8.self)
    }
}
