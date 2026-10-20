import XCTest
import Foundation
import AppDimensDynamic
import AppDimensCustom

final class CustomStrategyTests: XCTestCase {
    private let phone = ScreenSnapshot(widthDp: 411, heightDp: 891, smallestWidthDp: 411, density: 2.625)
    private let tablet = ScreenSnapshot(widthDp: 1280, heightDp: 800, smallestWidthDp: 800, density: 2)

    override func setUp() {
        super.setUp()
        ScalingStrategies.resetForTesting()
    }

    // ── engine ────────────────────────────────────────────────────────────────

    func testBuiltInsMatchBuiltInFormulas() {
        for s in [phone, tablet] {
            let sw = s.smallestWidthDp
            XCTAssertEqual(BuiltInStrategies.scaled.resolve(screen: s).factor, sw / 300, accuracy: 1e-12)
            XCTAssertEqual(BuiltInStrategies.power.resolve(screen: s).factor, pow(sw / 300, 0.75), accuracy: 1e-12)
            XCTAssertEqual(BuiltInStrategies.logarithmic.resolve(screen: s).factor, 1 + 0.4 * log(sw / 300), accuracy: 1e-12)
            XCTAssertEqual(BuiltInStrategies.interpolated.resolve(screen: s).factor, 1 + (sw / 300 - 1) * 0.5, accuracy: 1e-12)
            XCTAssertEqual(BuiltInStrategies.perimeter.resolve(screen: s).factor, (s.minDp + s.maxDp) / 833, accuracy: 1e-12)
        }
    }

    func testBuiltInsMatchCoreMetrics() {
        let c = Fixture.phone
        XCTAssertEqual(BuiltInStrategies.power.factor(c), c.metrics.powerScale, accuracy: 1e-9)
        XCTAssertEqual(BuiltInStrategies.interpolated.factor(c), c.metrics.interpolatedScale, accuracy: 1e-9)
        XCTAssertEqual(BuiltInStrategies.logarithmic.factor(c), c.metrics.logarithmicScale, accuracy: 1e-6)
        XCTAssertEqual(BuiltInStrategies.perimeter.factor(c), c.metrics.perimeterScale, accuracy: 1e-9)
    }

    func testRulesApplyInOrderLaterWins() throws {
        let s = try ScalingStrategy.define("rules", rules: [
            .on([.tablet], ScalingPatch(curve: .power(0.5), multiplier: 0.9), name: "tab"),
            ScalingRule(ScreenCondition(landscape: true), ScalingPatch(multiplier: 0.8), name: "land"),
        ], register: false)
        let r = s.resolve(screen: tablet)
        XCTAssertEqual(r.appliedRules, ["tab", "land"])
        XCTAssertEqual(r.factor, pow(800.0 / 300, 0.5) * 0.8, accuracy: 1e-12)
        XCTAssertEqual(s.resolve(screen: phone).factor, 411.0 / 300, accuracy: 1e-12)
    }

    func testClampsAndFontScale() throws {
        let s = try ScalingStrategy.define("c", minValue: 4, maxValue: 20, fontScale: .clamp(1.3), register: false)
        XCTAssertTrue(s.isValueDependent)
        XCTAssertEqual(s.resolve(screen: phone).scale(100), 20)
        XCTAssertEqual(s.resolve(screen: phone).scale(-100), -20)
        XCTAssertEqual(s.resolve(screen: phone).scale(0), 0)
        let big = ScreenSnapshot(widthDp: 411, heightDp: 891, fontScale: 2)
        XCTAssertEqual(s.resolve(screen: big).scaleSpDp(10), 10 * (411.0 / 300) * 1.3, accuracy: 1e-9)
        XCTAssertThrowsError(try ScalingStrategy.define("x", minFactor: 2, maxFactor: 1))
        XCTAssertThrowsError(try ScalingStrategy.define(" "))
    }

    // ── JSON ──────────────────────────────────────────────────────────────────

    func testJSONLoadExtendsDefaultAndRoundTrip() throws {
        let loaded = try ScalingStrategies.load(json: """
        {"version": 1, "default": "brand", "strategies": [
          {"id": "brand", "extends": "tabletFriendly", "curve": {"type": "power", "exponent": 0.8}},
          {"id": "text", "extends": "brand", "fontScale": "ignore", "valueClamp": {"min": 10}}
        ]}
        """)
        XCTAssertTrue(ScalingStrategies.defaultStrategy === loaded["brand"])
        XCTAssertEqual(loaded["text"]?.config.rules.count, 1)
        for s in CustomPresets.all + BuiltInStrategies.all + Array(loaded.values) {
            let back = try ScalingStrategyJSON.parse(try s.toJSON())
            let again = try ScalingStrategy(s.id, config: back.configs[s.id]!)
            XCTAssertEqual(again.resolve(screen: tablet).factor, s.resolve(screen: tablet).factor, s.id)
        }
    }

    func testJSONErrorsAreDescriptive() {
        func message(_ json: String) -> String {
            do {
                _ = try ScalingStrategyJSON.parse(json)
                return ""
            } catch {
                return "\(error)"
            }
        }
        XCTAssertTrue(message(#"[{"id":"a","extends":"b"},{"id":"b","extends":"a"}]"#).contains("Cyclic"))
        XCTAssertTrue(message(#"{"id":"a","curve":{"type":"wave"}}"#).contains("type 'wave'"))
        XCTAssertTrue(message(#"{"id":"a","extends":"nope"}"#).contains("unknown strategy 'nope'"))
        XCTAssertTrue(message(#"{"id": a}"#).contains("Invalid JSON"))
        XCTAssertThrowsError(try ScalingStrategies.require("missing"))
    }

    func testCrossPlatformFixture() throws {
        let url = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
            .appendingPathComponent("Fixtures/custom-strategy-fixture.json")
        let root = try JSONDecoder().decode(JSONValue.self, from: Data(contentsOf: url))
        guard case let .object(fixture) = root, case let .number(tolerance)? = fixture["tolerance"],
              let document = fixture["document"], case let .object(screens)? = fixture["screens"],
              case let .array(cases)? = fixture["cases"] else {
            return XCTFail("malformed fixture")
        }
        let configs = try ScalingStrategyJSON.parse(document, lookup: { ScalingStrategies[$0]?.config }).configs
        func number(_ v: JSONValue?) -> Double { if case let .number(n)? = v { return n }; return .nan }
        func bool(_ v: JSONValue?) -> Bool { if case let .bool(b)? = v { return b }; return false }
        func string(_ v: JSONValue?) -> String { if case let .string(s)? = v { return s }; return "" }
        var snapshots: [String: ScreenSnapshot] = [:]
        for (key, value) in screens {
            guard case let .object(s) = value else { continue }
            snapshots[key] = ScreenSnapshot(widthDp: number(s["width"]), heightDp: number(s["height"]),
                                            smallestWidthDp: number(s["smallestWidth"]), density: number(s["density"]),
                                            fontScale: number(s["fontScale"]), isLandscape: bool(s["landscape"]),
                                            isMultiWindow: bool(s["multiWindow"]),
                                            device: DeviceClass(rawValue: string(s["device"])))
        }
        XCTAssertGreaterThan(cases.count, 100)
        for item in cases {
            guard case let .object(c) = item else { continue }
            let id = string(c["strategy"]), screen = string(c["screen"]), base = number(c["base"])
            let r = try ScalingStrategy(id, config: configs[id]!).resolve(screen: snapshots[screen]!)
            let label = "\(id)@\(screen)x\(base)"
            for (expected, actual) in [(number(c["factor"]), r.factor), (number(c["dp"]), r.scale(base)),
                                       (number(c["spDp"]), r.scaleSpDp(base))] {
                XCTAssertEqual(actual, expected, accuracy: tolerance * max(1, abs(expected)), label)
            }
            var rules: [String] = []
            if case let .array(list)? = c["rules"] { rules = list.map { string($0) } }
            XCTAssertEqual(r.appliedRules, rules, label)
        }
    }

    // ── free-form expressions ─────────────────────────────────────────────────

    private func eval(_ src: String, _ screen: ScreenSnapshot? = nil) throws -> Double {
        try ScalingExpression.parse(src).evaluate(
            ScalingExpression.variables(screen: screen ?? phone, ratio: 1.5, axisDp: 411, refDp: 300,
                                        reference: .standard, base: 16, scaled: 20, factor: 1.25))
    }

    func testExpressionsEvaluate() throws {
        let cases: [(String, Double)] = [
            ("1 + 2 * 3", 7), ("(1 + 2) * 3", 9), ("2 ^ 3 ^ 2", 512), ("-2 ^ 2", -4), ("-7 % 3", -1),
            ("1 < 2 && 2 <= 2 && !(3 == 4) && 3 != 4", 1), ("0 || 5", 1), ("0 ? 2 : 1 ? 3 : 4", 3),
            ("true && !false", 1), ("1.5e3", 1500), ("min(3, 1, 2) + max(3, 1, 2)", 4), ("clamp(5, 0, 2)", 2),
            ("round(2.5) + round(-2.5)", 1), ("smoothstep(0, 10, 5)", 0.5), ("step(1, 1) + lerp(10, 20, 0.5)", 16),
            ("sw", 411), ("phone && portrait && !landscape && !tablet", 1), ("base + scaled + ratio", 37.5),
        ]
        for (src, expected) in cases {
            XCTAssertEqual(try eval(src), expected, accuracy: 1e-9, src)
        }
    }

    func testExpressionParseErrors() {
        let cases: [(String, String)] = [
            ("sw +", "unexpected end"), ("foo * 2", "unknown variable 'foo'"), ("wave(1)", "unknown function 'wave'"),
            ("clamp(1, 2)", "'clamp' takes 3"), ("(1 + 2", "expected ')'"), ("1 ? 2", "expected ':'"), ("", "empty"),
        ]
        for (src, message) in cases {
            XCTAssertThrowsError(try ScalingExpression.parse(src), src) { error in
                XCTAssertTrue("\(error)".contains(message), "\(src): \(error)")
            }
        }
        XCTAssertThrowsError(try ScalingCurve.expression("base"))
    }

    func testExpressionCurveAndFormula() throws {
        let curve = try ScalingStrategy.define("e", curve: try .expression("pow(ratio, 0.75)"), register: false)
        XCTAssertFalse(curve.isValueDependent)
        XCTAssertEqual(curve.resolve(screen: tablet).factor, BuiltInStrategies.power.resolve(screen: tablet).factor, accuracy: 1e-9)
        let free = try ScalingStrategy.define("f", formula: "base * pow(sw / 360, 0.7) + 2", register: false)
        XCTAssertTrue(free.isValueDependent)
        XCTAssertEqual(free.resolve(screen: tablet).scale(16), 16 * pow(800.0 / 360, 0.7) + 2, accuracy: 1e-9)

        let loaded = try ScalingStrategies.load(json: """
        [{"id": "a", "curve": {"type": "expression", "expression": "ratio * (tablet ? 0.9 : 1)"}, "formula": "max(scaled, 12)"},
         {"id": "b", "extends": "a", "formula": null}]
        """)
        let a = try XCTUnwrap(loaded["a"])
        let back = try ScalingStrategyJSON.parse(try a.toJSON()).configs["a"]!
        XCTAssertEqual(try ScalingStrategy("a2", config: back).resolve(screen: tablet).scale(4),
                       a.resolve(screen: tablet).scale(4), accuracy: 1e-9)
        XCTAssertEqual(a.resolve(screen: phone).scale(1), 12)
        XCTAssertFalse(try XCTUnwrap(loaded["b"]).isValueDependent)
        XCTAssertThrowsError(try ScalingStrategyJSON.parse(#"{"id":"x","curve":{"type":"expression","expression":"base"}}"#)) { error in
            XCTAssertTrue("\(error)".contains("x.curve.expression"), "\(error)")
            XCTAssertTrue("\(error)".contains("unknown variable 'base'"), "\(error)")
        }
    }

    // ── Apple binding ─────────────────────────────────────────────────────────

    func testNumberExtensionsAndDefault() throws {
        let c = Fixture.phone
        XCTAssertEqual(16.cdp(c), 16.sdp(c), accuracy: 1e-9)       // default = scaled = sdp
        let brand = try ScalingStrategy.define("brand", curve: .power(0.8))
        XCTAssertEqual(16.cdp(brand, c), 16 * pow(390.0 / 300, 0.8), accuracy: 1e-9)
        XCTAssertTrue(ScalingStrategies["brand"] === brand)
        ScalingStrategies.defaultStrategy = brand
        XCTAssertEqual(16.cdp(c), 16.cdp(brand, c))
        withAmbient(Fixture.tablet) {
            XCTAssertEqual(Double(16.cdp), 16 * pow(820.0 / 300, 0.8), accuracy: 1e-9)
            XCTAssertEqual(Double(14.csp(brand)), 14 * pow(820.0 / 300, 0.8) * 1.25, accuracy: 1e-9)
        }
    }

    func testDeviceClassFromUiModeAndResolver() {
        XCTAssertEqual(screenSnapshot(Fixture.tv).device, .tv)
        XCTAssertEqual(CustomPresets.tvSafe.resolve(Fixture.tv).appliedRules, ["tv"])
        ScalingStrategies.deviceClassResolver = { _ in .watch }
        XCTAssertEqual(screenSnapshot(Fixture.tv).device, .watch)
    }

    func testExtendWithAxisExplain() throws {
        let soft = try BuiltInStrategies.power.extend("soft", curve: .power(0.6))
        XCTAssertTrue(ScalingStrategies["soft"] === soft)
        XCTAssertTrue(soft.withAxis(.height) === soft.withAxis(.height))
        XCTAssertEqual(soft.withAxis(.height).id, "soft@height")
        XCTAssertTrue(soft.explain(Fixture.phone).contains("[soft]"))
    }
}
