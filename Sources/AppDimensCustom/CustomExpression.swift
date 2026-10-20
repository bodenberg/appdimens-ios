import Foundation

// Free-form formulas for custom strategies — a small, safe expression language with the same
// grammar, variables, functions and results on every AppDimens platform (reference: Android
// `ScalingExpression`). Booleans are numbers (true = 1, false = 0; non-zero is true).
//
// Operators: `+ - * / % ^` (`^` = power, right-associative; `%` keeps the dividend's sign),
// `== != < <= > >=`, `&& || !`, `cond ? a : b`, parentheses.
// Functions: `min max clamp pow sqrt ln log log10 log2 exp abs sign floor ceil round lerp step smoothstep`.
// Variables: `ScalingExpression.screenVariables`; curves add `ratio axis ref refWidth refHeight`;
// value formulas add `base scaled factor`.

/// A parsed, immutable expression.
public struct ScalingExpression: Sendable, Hashable, CustomStringConvertible {
    public static let screenVariables: Set<String> = [
        "sw", "width", "height", "shortSide", "longSide", "diagonal", "perimeter", "aspectRatio",
        "density", "fontScale", "landscape", "portrait", "multiWindow",
        "phone", "tablet", "desktop", "tv", "watch", "car", "vr", "pi", "e",
    ]
    public static let curveVariables: Set<String> = screenVariables.union(["ratio", "axis", "ref", "refWidth", "refHeight"])
    public static let formulaVariables: Set<String> = curveVariables.union(["base", "scaled", "factor"])

    public let source: String
    let root: ExpressionNode

    /// Parses `source`; every identifier must be in `allowed`. Errors carry the position.
    public static func parse(_ source: String, allowed: Set<String> = formulaVariables) throws -> ScalingExpression {
        var parser = ExpressionParser(source: source, allowed: allowed)
        return ScalingExpression(source: source, root: try parser.parseAll())
    }

    /// Evaluates with a name → value lookup.
    public func evaluate(_ vars: (String) -> Double) -> Double { root.eval(vars) }

    public var description: String { source }

    public static func == (lhs: ScalingExpression, rhs: ScalingExpression) -> Bool { lhs.source == rhs.source }
    public func hash(into hasher: inout Hasher) { hasher.combine(source) }

    /// Variable lookup for `screen` plus the strategy context.
    public static func variables(screen: ScreenSnapshot, ratio: Double, axisDp: Double, refDp: Double,
                                 reference: ReferenceScreen, base: Double = .nan, scaled: Double = .nan,
                                 factor: Double = .nan) -> (String) -> Double {
        let mn = Swift.min(screen.widthDp, screen.heightDp)
        let mx = Swift.max(screen.widthDp, screen.heightDp)
        func flag(_ d: DeviceClass) -> Double { screen.device == d ? 1 : 0 }
        return { name in
            switch name {
            case "sw": return screen.smallestWidthDp
            case "width": return screen.widthDp
            case "height": return screen.heightDp
            case "shortSide": return mn
            case "longSide": return mx
            case "diagonal": return (mn * mn + mx * mx).squareRoot()
            case "perimeter": return mn + mx
            case "aspectRatio": return mn > 0 ? mx / mn : 1
            case "density": return screen.density
            case "fontScale": return screen.fontScale
            case "landscape": return screen.isLandscape ? 1 : 0
            case "portrait": return screen.isLandscape ? 0 : 1
            case "multiWindow": return screen.isMultiWindow ? 1 : 0
            case "phone": return flag(.phone)
            case "tablet": return flag(.tablet)
            case "desktop": return flag(.desktop)
            case "tv": return flag(.tv)
            case "watch": return flag(.watch)
            case "car": return flag(.car)
            case "vr": return flag(.vr)
            case "pi": return Double.pi
            case "e": return exp(1.0)
            case "ratio": return ratio
            case "axis": return axisDp
            case "ref": return refDp
            case "refWidth": return reference.width
            case "refHeight": return reference.height
            case "base": return base
            case "scaled": return scaled
            case "factor": return factor
            default: return .nan
            }
        }
    }
}

indirect enum ExpressionNode: Sendable {
    case number(Double)
    case variable(String)
    case negate(ExpressionNode)
    case not(ExpressionNode)
    case binary(String, ExpressionNode, ExpressionNode)
    case ternary(ExpressionNode, ExpressionNode, ExpressionNode)
    case call(String, [ExpressionNode])

    func eval(_ v: (String) -> Double) -> Double {
        switch self {
        case let .number(n): return n
        case let .variable(name): return v(name)
        case let .negate(a): return -a.eval(v)
        case let .not(a): return a.eval(v) != 0 ? 0 : 1
        case let .ternary(c, a, b): return c.eval(v) != 0 ? a.eval(v) : b.eval(v)
        case let .binary(op, a, b):
            if op == "&&" { return a.eval(v) != 0 && b.eval(v) != 0 ? 1 : 0 }
            if op == "||" { return a.eval(v) != 0 || b.eval(v) != 0 ? 1 : 0 }
            let x = a.eval(v), y = b.eval(v)
            switch op {
            case "+": return x + y
            case "-": return x - y
            case "*": return x * y
            case "/": return x / y
            case "%": return x.truncatingRemainder(dividingBy: y)
            case "^": return pow(x, y)
            case "==": return x == y ? 1 : 0
            case "!=": return x != y ? 1 : 0
            case "<": return x < y ? 1 : 0
            case "<=": return x <= y ? 1 : 0
            case ">": return x > y ? 1 : 0
            default: return x >= y ? 1 : 0
            }
        case let .call(name, args):
            let x = args.map { $0.eval(v) }
            switch name {
            case "min": return x.dropFirst().reduce(x[0]) { Swift.min($0, $1) }
            case "max": return x.dropFirst().reduce(x[0]) { Swift.max($0, $1) }
            case "clamp": return Swift.max(x[1], Swift.min(x[2], x[0]))
            case "pow": return pow(x[0], x[1])
            case "sqrt": return x[0].squareRoot()
            case "ln", "log": return log(x[0])
            case "log10": return log10(x[0])
            case "log2": return log2(x[0])
            case "exp": return exp(x[0])
            case "abs": return abs(x[0])
            case "sign": return x[0].isNaN ? .nan : (x[0] > 0 ? 1 : (x[0] < 0 ? -1 : 0))
            case "floor": return x[0].rounded(.down)
            case "ceil": return x[0].rounded(.up)
            case "round": return (x[0] + 0.5).rounded(.down)
            case "lerp": return x[0] + (x[1] - x[0]) * x[2]
            case "step": return x[1] < x[0] ? 0 : 1
            default:
                let t = Swift.max(0, Swift.min(1, (x[2] - x[0]) / (x[1] - x[0])))
                return t * t * (3 - 2 * t)
            }
        }
    }
}

struct ExpressionParser {
    private static let arity: [String: (Int, Int)] = [
        "min": (1, Int.max), "max": (1, Int.max), "clamp": (3, 3), "pow": (2, 2), "sqrt": (1, 1),
        "ln": (1, 1), "log": (1, 1), "log10": (1, 1), "log2": (1, 1), "exp": (1, 1),
        "abs": (1, 1), "sign": (1, 1), "floor": (1, 1), "ceil": (1, 1), "round": (1, 1),
        "lerp": (3, 3), "step": (2, 2), "smoothstep": (3, 3),
    ]
    private static let comparisons = ["==", "!=", "<=", ">=", "<", ">"]

    private let source: String
    private let chars: [Character]
    private let allowed: Set<String>
    private var i = 0

    init(source: String, allowed: Set<String>) {
        self.source = source
        self.chars = Array(source)
        self.allowed = allowed
    }

    mutating func parseAll() throws -> ExpressionNode {
        if source.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { throw fail("empty expression") }
        let n = try ternary()
        ws()
        if i < chars.count { throw fail("unexpected '\(chars[i])'") }
        return n
    }

    private mutating func ternary() throws -> ExpressionNode {
        let c = try or()
        if !eat("?") { return c }
        let a = try ternary()
        if !eat(":") { throw fail("expected ':'") }
        return .ternary(c, a, try ternary())
    }

    private mutating func or() throws -> ExpressionNode {
        var n = try and()
        while eat("||") { n = .binary("||", n, try and()) }
        return n
    }

    private mutating func and() throws -> ExpressionNode {
        var n = try cmp()
        while eat("&&") { n = .binary("&&", n, try cmp()) }
        return n
    }

    private mutating func cmp() throws -> ExpressionNode {
        let n = try add()
        for op in Self.comparisons {
            if eat(op) { return .binary(op, n, try add()) }
        }
        return n
    }

    private mutating func add() throws -> ExpressionNode {
        var n = try mul()
        while true {
            if eat("+") { n = .binary("+", n, try mul()) }
            else if eat("-") { n = .binary("-", n, try mul()) }
            else { return n }
        }
    }

    private mutating func mul() throws -> ExpressionNode {
        var n = try unary()
        while true {
            if eat("*") { n = .binary("*", n, try unary()) }
            else if eat("/") { n = .binary("/", n, try unary()) }
            else if eat("%") { n = .binary("%", n, try unary()) }
            else { return n }
        }
    }

    private mutating func unary() throws -> ExpressionNode {
        if eat("-") { return .negate(try unary()) }
        if eat("+") { return try unary() }
        if peekIs("!") && !peekIs("!=") {
            _ = eat("!")
            return .not(try unary())
        }
        return try power()
    }

    private mutating func power() throws -> ExpressionNode {
        let n = try primary()
        return eat("^") ? .binary("^", n, try unary()) : n
    }

    private static func isDigit(_ c: Character) -> Bool { c >= "0" && c <= "9" }
    private static func isIdentStart(_ c: Character) -> Bool { (c >= "a" && c <= "z") || (c >= "A" && c <= "Z") || c == "_" }
    private static func isIdent(_ c: Character) -> Bool { isIdentStart(c) || isDigit(c) }

    private mutating func primary() throws -> ExpressionNode {
        ws()
        guard i < chars.count else { throw fail("unexpected end") }
        let c = chars[i]
        if c == "(" {
            i += 1
            let n = try ternary()
            if !eat(")") { throw fail("expected ')'") }
            return n
        }
        if Self.isDigit(c) || c == "." { return try number() }
        if Self.isIdentStart(c) {
            let start = i
            while i < chars.count && Self.isIdent(chars[i]) { i += 1 }
            let name = String(chars[start..<i])
            if eat("(") { return try call(name, start) }
            if name == "true" { return .number(1) }
            if name == "false" { return .number(0) }
            guard allowed.contains(name) else {
                i = start
                throw fail("unknown variable '\(name)' (allowed: \(allowed.sorted().joined(separator: ", ")))")
            }
            return .variable(name)
        }
        throw fail("unexpected '\(c)'")
    }

    private mutating func call(_ name: String, _ start: Int) throws -> ExpressionNode {
        var args: [ExpressionNode] = []
        if !eat(")") {
            repeat { args.append(try ternary()) } while eat(",")
            if !eat(")") { throw fail("expected ')'") }
        }
        guard let arity = Self.arity[name] else {
            i = start
            throw fail("unknown function '\(name)'")
        }
        if args.count < arity.0 || args.count > arity.1 {
            i = start
            let n = arity.0 == arity.1 ? "\(arity.0)" : "\(arity.0)+"
            throw fail("'\(name)' takes \(n) argument(s), got \(args.count)")
        }
        return .call(name, args)
    }

    private mutating func number() throws -> ExpressionNode {
        let start = i
        while i < chars.count && (Self.isDigit(chars[i]) || chars[i] == ".") { i += 1 }
        if i < chars.count && (chars[i] == "e" || chars[i] == "E") {
            let save = i
            i += 1
            if i < chars.count && (chars[i] == "+" || chars[i] == "-") { i += 1 }
            if i < chars.count && Self.isDigit(chars[i]) {
                while i < chars.count && Self.isDigit(chars[i]) { i += 1 }
            } else {
                i = save
            }
        }
        let text = String(chars[start..<i])
        guard let v = Double(text) else {
            i = start
            throw fail("bad number '\(text)'")
        }
        return .number(v)
    }

    private mutating func ws() {
        while i < chars.count && chars[i].isWhitespace { i += 1 }
    }

    private mutating func peekIs(_ token: String) -> Bool {
        ws()
        let t = Array(token)
        guard i + t.count <= chars.count else { return false }
        return Array(chars[i..<(i + t.count)]) == t
    }

    private mutating func eat(_ token: String) -> Bool {
        guard peekIs(token) else { return false }
        i += token.count
        return true
    }

    private func fail(_ message: String) -> ScalingStrategyError {
        ScalingStrategyError("Invalid expression at \(i): \(message) in \"\(source)\"")
    }
}
