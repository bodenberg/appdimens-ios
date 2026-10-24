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

    // ── just write the formula ────────────────────────────────────────────────

    func testTextFormulaIsTheFinalValue() throws {
        let s = try scalingFormula("base * pow(sw / 360, 0.8)")
        XCTAssertEqual(s.resolve(screen: phone).scale(16), 16 * pow(411.0 / 360, 0.8))
        XCTAssertEqual(try scalingFormula("base + 2").resolve(screen: phone).scale(16), 18)
        // ratio = sw / 300, like sdp
        XCTAssertEqual(try scalingFormula("base * ratio").resolve(screen: phone).scale(16), 16 * 411.0 / 300, accuracy: 1e-9)
        XCTAssertEqual(try scalingFormula("base * (tablet ? 0.9 : 1)").resolve(screen: tablet).scale(16), 16 * 0.9, accuracy: 1e-12)
    }

    func testProportionalFormulaFastPathMatchesSlowPathBitForBit() throws {
        for src in ["base", "base * pow(sw / 360, 0.8)", "(sw / 360) * base", "base * (tablet ? 0.9 : 1.1)"] {
            let fast = try scalingFormula(src)
            XCTAssertFalse(fast.isValueDependent, src)
            // Same text, but not proportional (`+ 0` forces the per-value path): identical numbers.
            let slow = try scalingFormula("\(src) + 0")
            XCTAssertTrue(slow.isValueDependent, src)
            for screen in [phone, tablet] {
                for base in [1.0, 16, 48, -8, 0.5] {
                    XCTAssertEqual(fast.resolve(screen: screen).scale(base), slow.resolve(screen: screen).scale(base),
                                   "\(src) x \(base)")
                }
            }
        }
        // Reads the value inside E → not proportional.
        XCTAssertTrue(try scalingFormula("base * min(base, 20)").isValueDependent)
        XCTAssertTrue(try scalingFormula("max(base * sw / 360, base)").isValueDependent)
        // `(base * sw) / 360` is evaluated as written (per value), so it is not on the fast path.
        XCTAssertTrue(try scalingFormula("base * sw / 360").isValueDependent)
    }

    func testProportionalFormulaInsideDefineAndJSONIsScreenOnly() throws {
        let defined = try ScalingStrategy.define("p", formula: "base * (sw / 360)", register: false)
        XCTAssertFalse(defined.isValueDependent)
        let json = try XCTUnwrap(try ScalingStrategies.load(json: #"{"strategies":[{"id":"j","formula":"base * 1.1"}]}"#)["j"])
        XCTAssertFalse(json.isValueDependent)
        XCTAssertEqual(json.resolve(screen: phone).scale(16), 16 * 1.1, accuracy: 1e-12)
        XCTAssertTrue(try ScalingStrategy.define("v", formula: "round(scaled)", register: false).isValueDependent)
        XCTAssertTrue(defined.resolve(screen: phone).explain("p").contains("then formula(base * (sw / 360))"))
    }

    func testTextFormulaIsSharedPerTextUnlessIdIsGiven() throws {
        XCTAssertTrue(try scalingFormula("base * 2") === scalingFormula("base * 2"))
        XCTAssertTrue(try ScalingStrategies.formula("base * 2") === scalingFormula("base * 2"))
        XCTAssertTrue(try ScalingStrategy.formula("base * 2") === scalingFormula("base * 2"))
        XCTAssertEqual(try scalingFormula("base * 2").id, "formula:base * 2")
        XCTAssertNil(ScalingStrategies["formula:base * 2"])
        let named = try scalingFormula("base * 2", id: "double")
        XCTAssertFalse(try named === scalingFormula("base * 2"))
        XCTAssertTrue(ScalingStrategies["double"] === named) // an id registers by default
    }

    func testCodeFormulaHasNoLimits() throws {
        let s = scalingFormula { $0.base * $0.pow($0.sw / 360, 0.8) + ($0.landscape ? 2 : 0) }
        XCTAssertEqual(s.resolve(screen: phone).scale(16), 16 * pow(411.0 / 360, 0.8), accuracy: 1e-9)
        XCTAssertEqual(s.resolve(screen: tablet).scale(16), 16 * pow(800.0 / 360, 0.8) + 2, accuracy: 1e-9)
        XCTAssertTrue(s.isValueDependent)
        XCTAssertTrue(s.id.hasPrefix("formula#"))
        XCTAssertNotEqual(scalingFormula { $0.base }.id, s.id)
        XCTAssertThrowsError(try s.toJSON())
        let named = scalingFormula(id: "hud") { $0.base * 3 }
        XCTAssertTrue(ScalingStrategies["hud"] === named)
        XCTAssertTrue(named.resolve(screen: phone).explain("hud").contains("then transform"))
        let viaType = ScalingStrategy.formula { $0.base + 1 }
        XCTAssertEqual(viaType.resolve(screen: phone).scale(16), 17)
    }

    func testProgrammableFactorIsScreenOnlyAndMultipliesEveryValue() {
        let product = CustomScaleStrategy { s in s.clamp(s.width / 360, 0.85, 1.80) }
        XCTAssertFalse(product.isValueDependent)
        XCTAssertEqual(product.resolve(screen: phone).factor, 411.0 / 360, accuracy: 1e-12)
        XCTAssertEqual(product.resolve(screen: tablet).factor, 1.8) // 1280 / 360 clamped
        XCTAssertEqual(product.resolve(screen: phone).scale(16), 16 * 411.0 / 360, accuracy: 1e-9)
        XCTAssertTrue(product.id.hasPrefix("scale#"))
        let named = CustomScaleStrategy(id: "product") { _ in 1.25 }
        XCTAssertTrue(ScalingStrategies["product"] === named)
        XCTAssertEqual(named.resolve(screen: phone).scale(16), 20)
        // A non-finite factor never poisons a layout pass: it falls back to 1.
        XCTAssertEqual(CustomScaleStrategy { _ in .nan }.resolve(screen: phone).factor, 1)
    }

    func testCodeScopeMatchesTheTextLanguage() throws {
        // Same names, same numbers: the code form and the text form agree.
        let pairs: [(ScalingStrategy, String)] = [
            (scalingFormula { $0.base * $0.pow($0.sw / 360, 0.8) }, "base * pow(sw / 360, 0.8)"),
            (scalingFormula { $0.base * $0.ratio }, "base * ratio"),
            (scalingFormula { s in s.base * (s.tablet ? 0.9 : 1) * s.clamp(s.width / 360, 0.85, 1.6) },
             "base * (tablet ? 0.9 : 1) * clamp(width / 360, 0.85, 1.6)"),
            (scalingFormula { s in s.round(s.base * s.lerp(1, s.aspectRatio, 0.1)) },
             "round(base * lerp(1, aspectRatio, 0.1))"),
            (scalingFormula { s in s.base * s.smoothstep(300, 900, s.longSide) + s.sqrt(s.diagonal) },
             "base * smoothstep(300, 900, longSide) + sqrt(diagonal)"),
        ]
        for (code, text) in pairs {
            let fromText = try scalingFormula(text)
            for screen in [phone, tablet] {
                for base in [1.0, 16, 48] {
                    XCTAssertEqual(code.resolve(screen: screen).scale(base), fromText.resolve(screen: screen).scale(base),
                                   accuracy: 1e-4, text)
                }
            }
        }
        let tvScreen = ScreenSnapshot(widthDp: 960, heightDp: 540, smallestWidthDp: 540, density: 2,
                                      isLandscape: true, device: .tv)
        let factor = CustomScaleStrategy { s in s.tv ? s.height / 540 : s.ratio }
        XCTAssertEqual(factor.resolve(screen: tvScreen).factor, 1)
        XCTAssertEqual(factor.resolve(screen: phone).factor, 411.0 / 300, accuracy: 1e-12)
    }

    func testTextFormulaErrorsAreReportedEarly() {
        XCTAssertThrowsError(try scalingFormula("base * sww")) { error in
            XCTAssertTrue("\(error)".contains("unknown variable 'sww'"), "\(error)")
        }
        XCTAssertThrowsError(try 16.cdp("base * sww"))
    }

    func testFontScaleIsFollowedForText() throws {
        let big = ScreenSnapshot(widthDp: 411, heightDp: 891, smallestWidthDp: 411, fontScale: 1.5)
        XCTAssertEqual(try scalingFormula("base * 2").resolve(screen: big).scaleSpDp(16), 16 * 2 * 1.5, accuracy: 1e-9)
    }

    func testNumberExtensionsTakeTheFormulaText() throws {
        let c = Fixture.phone
        let s = try scalingFormula("base * (sw / 360)")
        XCTAssertEqual(try 16.cdp("base * (sw / 360)", c), s.dp(16, c))
        XCTAssertEqual(try 14.csp("base * (sw / 360)", c), s.sp(14, c))
        withAmbient(Fixture.tablet) {
            XCTAssertEqual(try? 16.cdp("base * (sw / 360)"), CGFloat(s.dp(16)))
            XCTAssertEqual(try? 8.cdpPx("base"), CGFloat(try scalingFormula("base").px(8)))
            XCTAssertEqual(try? 14.csp("base"), CGFloat(try scalingFormula("base").sp(14)))
            XCTAssertEqual(try? 14.cspPx("base"), CGFloat(try scalingFormula("base").spPx(14)))
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
