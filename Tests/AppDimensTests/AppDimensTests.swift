import XCTest
import Foundation
import AppDimens
import AppDimensStrategies
import AppDimensAuto
import AppDimensPercent
import AppDimensPower
import AppDimensFluid
import AppDimensDensity
import AppDimensDiagonal
import AppDimensFill
import AppDimensFit
import AppDimensInterpolated
import AppDimensLogarithmic
import AppDimensPerimeter
import AppDimensResize
import AppDimensUnits
@testable import AppDimensDynamic

final class AppDimensTests: XCTestCase {
    let baseline = DimensConfiguration(screenWidth: 300, screenHeight: 533, displayScale: 3, fontScale: 1.25)
    let wide = DimensConfiguration(screenWidth: 800, screenHeight: 600, displayScale: 3, fontScale: 1.25)
    let small = DimensConfiguration(screenWidth: 600, screenHeight: 1032, displayScale: 3, fontScale: 1.25)

    // ── Baseline parity (design reference 300×533 → factor 1) ───────────────

    func testDirectAndroidBaselineParity() {
        XCTAssertEqual(16.sdp(baseline), 16, accuracy: 0.000001)
        XCTAssertEqual(16.wdp(baseline), 16, accuracy: 0.000001)
        XCTAssertEqual(16.hdp(baseline), 16 * 533 / 300, accuracy: 0.000001)
        XCTAssertEqual(16.ssp(baseline), 20, accuracy: 0.000001)
        XCTAssertEqual(16.sem(baseline), 16, accuracy: 0.000001)
        XCTAssertEqual(16.sdpi(baseline), 16)
        XCTAssertEqual(16.sdpa(baseline), 16)
    }

    func testAllEightInverters() {
        let l = DimensConfiguration(screenWidth: 800, screenHeight: 400)
        XCTAssertEqual(l.dimension(.height, inverter: .phToLw), 800)
        XCTAssertEqual(l.dimension(.width, inverter: .pwToLh), 400)
        XCTAssertEqual(l.dimension(.smallWidth, inverter: .swToLh), 400)
        XCTAssertEqual(l.dimension(.smallWidth, inverter: .swToLw), 800)
        let p = DimensConfiguration(screenWidth: 400, screenHeight: 800)
        XCTAssertEqual(p.dimension(.height, inverter: .lhToPw), 400)
        XCTAssertEqual(p.dimension(.width, inverter: .lwToPh), 800)
        XCTAssertEqual(p.dimension(.smallWidth, inverter: .swToPh), 800)
        XCTAssertEqual(p.dimension(.smallWidth, inverter: .swToPw), 400)
    }

    func testMultiWindowAndAspectVariants() {
        let split = DimensConfiguration(screenWidth: 400, screenHeight: 700,
            maximumWindowWidth: 800, maximumWindowHeight: 700)
        XCTAssertTrue(split.isMultiWindow)
        XCTAssertEqual(10.sdpi(split), 10)
        XCTAssertNotEqual(10.sdpa(split), 10.sdp(split))
        let tablet = DimensConfiguration(screenWidth: 800, screenHeight: 1200, uiMode: .normal)
        XCTAssertEqual(10.sdp(tablet), 10 * 800 / 300, accuracy: 0.000001)
    }

    func testConfigurationIsWindowSemanticNotViewSemantic() {
        let window = DimensConfiguration(screenWidth: 390, screenHeight: 844)
        XCTAssertEqual(10.sdp(window), 13)
        XCTAssertEqual(10.sdp(window), 10.sdp(window), "Every child in one window shares this configuration")
    }

    // ── 3.1.7 scaled kernel (isDefaultSw → metrics; else effective qualifier) ─

    func testScaledUsesEffectiveQualifier() {
        let landscape = DimensConfiguration(screenWidth: 800, screenHeight: 400)
        XCTAssertEqual(10.sdp(landscape), 10 * 400 / 300, accuracy: 0.000001)
        XCTAssertEqual(10.hdp(landscape), 10 * 800 / 300, accuracy: 0.000001)
        XCTAssertEqual(10.hdpLw(landscape), 10 * 800 / 300, accuracy: 0.000001, "phToLw maps height to landscape width")
        XCTAssertEqual(10.wdpLh(landscape), 10 * 400 / 300, accuracy: 0.000001, "pwToLh maps width to landscape height")
        let portrait = DimensConfiguration(screenWidth: 800, screenHeight: 1200)
        XCTAssertEqual(10.sdpPh(portrait), 10 * 1200 / 300, accuracy: 0.000001, "swToPh maps sw to portrait height")
        XCTAssertEqual(10.sdpPw(portrait), 10 * 800 / 300, accuracy: 0.000001, "swToPw maps sw to portrait width")
    }

    func testScaledAspectRatioOffReference() {
        // sw = 600 → diff = 300; default k = 0.0026666667, ln(normalizedAR) with 600×1032 (AR 1.72)
        let m = small.metrics
        let expected = 10 * (1 + 300 * (DimensConstants.adjustmentScale + DimensConstants.sensitivityDefault * m.logNormalizedAspectRatio))
        XCTAssertEqual(10.sdpa(small), expected, accuracy: 0.000001)
        // Custom sensitivity k replaces the default.
        let custom = 10 * (1 + 300 * (DimensConstants.adjustmentScale + 0.005 * m.logNormalizedAspectRatio))
        XCTAssertEqual(AppDimens.scaledDp(10, configuration: small, applyAspectRatio: true, sensitivityK: 0.005), custom, accuracy: 0.000001)
        // Non-default-SW path with custom k uses the qualifier dimension.
        let customH = 10 * (1 + (1032 - 300) * (DimensConstants.adjustmentScale + 0.005 * m.logNormalizedAspectRatio))
        XCTAssertEqual(AppDimens.scaledDp(10, configuration: small, qualifier: .height,
            applyAspectRatio: true, sensitivityK: 0.005), customH, accuracy: 0.000001, "non-default path uses the effective qualifier dimension")
    }

    // ── Satellite kernel formulas (3.1.7) ───────────────────────────────────

    func testSatelliteKernels() {
        XCTAssertEqual(16.densityDp(baseline), 48, "density = base × densityDpi/160 = ×3 at scale 3")
        let diagonal = 16 * sqrt(600.0 * 600.0 + 800.0 * 800.0) / 611.6305
        XCTAssertEqual(16.diagonalDp(wide), diagonal, accuracy: 0.0001)
        XCTAssertEqual(16.perimeterDp(wide), 16 * (600 + 800) / 833, accuracy: 0.000001)
        XCTAssertEqual(16.fillDp(wide), 16 * max(600 / 300, 800 / 533), accuracy: 0.000001)
        XCTAssertEqual(16.fitDp(wide), 16 * min(600 / 300, 800 / 533), accuracy: 0.000001)
        XCTAssertEqual(16.powerDp(small), 16 * pow(600 / 300, 0.75), accuracy: 0.000001)
        XCTAssertEqual(16.interpolatedDp(small), 16 * (1 + (600 / 300 - 1) * 0.5), accuracy: 0.000001)
        XCTAssertEqual(16.logarithmicDp(small), 16 * (1 + 0.4 * log(600 / 300)), accuracy: 0.000001)
        XCTAssertEqual(16.autoDp(small), 16 * (480 / 300 + 0.4 * log(1 + (600 - 480) / 300)), accuracy: 0.000001)
        XCTAssertEqual(16.autoDp(baseline), 16, "linear branch: dim ≤ 480")
        XCTAssertEqual(16.fluidDp(baseline), 16 * 0.8, "fluid clamps to ×0.8 below 320dp")
        XCTAssertEqual(16.fluidDp(DimensConfiguration(screenWidth: 1000, screenHeight: 1400)), 16 * 1.2, "fluid clamps to ×1.2 above 768dp")
        let mid = DimensConfiguration(screenWidth: 400, screenHeight: 700)
        let fluidMid: Double = 16.0 * (0.8 + 0.4 * Double(400 - 320) / Double(768 - 320))
        XCTAssertEqual(16.fluidDp(mid), fluidMid, accuracy: 0.000001)
    }

    func testPercentSatelliteIsSdpLike() {
        XCTAssertEqual(16.percentDp(baseline), 16)
        XCTAssertEqual(16.percentDp(small), 16 * 600 / 300)
    }

    func testSatelliteAspectRatioMultiplier() {
        // satellites apply AR = 1 + k·ln(normalizedAR) AFTER their base factor
        let m = wide.metrics
        XCTAssertEqual(16.powerDp(wide, options: .init(applyAspectRatio: true)),
            16 * pow(600 / 300, 0.75) * (1 + DimensConstants.sensitivityDefault * m.logNormalizedAspectRatio),
            accuracy: 0.000001)
        XCTAssertEqual(16.powerDp(wide, options: .init(applyAspectRatio: true, sensitivityK: 0.01)),
            16 * pow(600 / 300, 0.75) * (1 + 0.01 * m.logNormalizedAspectRatio),
            accuracy: 0.000001)
    }

    func testLiteralPercentSpaceAPIs() {
        let c = DimensConfiguration(screenWidth: 360, screenHeight: 720)
        XCTAssertEqual(50.spaceW(c), 180)
        XCTAssertEqual(50.spaceH(c), 360)
        XCTAssertEqual(50.spaceSw(c), 180)
        XCTAssertEqual(50.space(200), 100)
        XCTAssertEqual(AppDimens.literalPercentOfScreenDp(200, qualifier: .width, configuration: c), 720)
        XCTAssertEqual(AppDimens.literalPercentOfReferenceDp(.infinity, referenceDp: 100), 0)
    }

    // ── Principal facilitators and builders ─────────────────────────────────

    func testPrincipalFacilitatorsAndBuilder() {
        let tablet = DimensConfiguration(screenWidth: 800, screenHeight: 1200, fontScale: 1.25, uiMode: .normal)
        XCTAssertEqual(AppDimens.scaledDp(10, configuration: tablet), 10 * 800 / 300, accuracy: 0.000001)
        XCTAssertEqual(10.scaledDp.screen(20, qualifier: .width, minimum: 600)
            .resolve(tablet), 20 * 800 / 300, accuracy: 0.000001)
        XCTAssertEqual(10.scaledSp.screen(20, qualifier: .width, minimum: 600).resolve(tablet), 20 * 800 / 300 * 1.25, accuracy: 0.000001)
        XCTAssertEqual(16.scaledDp.aspectRatio().resolve(wide),
            AppDimens.scaledDp(16, configuration: wide, applyAspectRatio: true), accuracy: 0.000001)
    }
    func testPlainBranchDoesNotScale() {
        XCTAssertEqual(AppDimensPlain.rotate(10, branch: 20, orientation: .portrait,
            configuration: baseline), 20)
        XCTAssertEqual(AppDimensPlain.qualifier(10, branch: 30, qualifier: .width,
            minimum: 300, configuration: baseline), 30)
        XCTAssertEqual(AppDimensPlain.mode(10, branch: 40, mode: .normal, configuration: baseline), 10)
        XCTAssertEqual(AppDimensPlain.screen(10, branch: 40, mode: .normal, qualifier: .width,
            minimum: 300, configuration: baseline), 10)
    }

    // ── Strategies module ───────────────────────────────────────────────────

    func testEveryStrategyModule() {
        for strategy in DimensStrategy.allCases {
            XCTAssertTrue(16.dynamic(strategy, baseline).isFinite, "\(strategy)")
        }
        XCTAssertEqual(16.fitDp(baseline), 16, accuracy: 0.000001)
        XCTAssertEqual(16.fillDp(baseline), 16, accuracy: 0.001)
        XCTAssertEqual(16.dynamic(.scaled, small), 16.sdp(small), accuracy: 0.000001)
        XCTAssertEqual(16.dynamic(.auto, small), 16.autoDp(small), accuracy: 0.000001)
        XCTAssertEqual(16.dynamic(.density, baseline), 48)
    }
    func testPrecomputedFactorsMatchDynamicStrategies() {
        let configuration = DimensConfiguration(screenWidth: 430, screenHeight: 932, displayScale: 3)
        let factors = DimensFactors(configuration)
        for strategy in [DimensStrategy.scaled, .auto, .density, .diagonal, .perimeter, .fill, .fit, .plain, .physical] {
            XCTAssertEqual(factors.resolve(16, strategy: strategy),
                DynamicDimens.resolve(16, strategy: strategy, configuration: configuration),
                accuracy: 0.000_001, "\(strategy)")
        }
    }

    #if os(watchOS)
    #else
    func testPrecomputedFactorsMatchDynamicStrategiesAll() {
        let configuration = DimensConfiguration(screenWidth: 430, screenHeight: 932, displayScale: 3)
        for strategy in DimensStrategy.allCases {
            XCTAssertEqual(DimensFactors(configuration).resolve(16, strategy: strategy),
                DynamicDimens.resolve(16, strategy: strategy, configuration: configuration),
                accuracy: 0.000_001, "\(strategy)")
        }
    }
    #endif

    // ── Satellite catalogs (Android-familiar naming) ────────────────────────

    func testSatelliteCatalogs() {
        XCTAssertEqual(16.psdp(baseline), 16)
        XCTAssertEqual(16.pwdp(small), 16 * 600 / 300, accuracy: 0.000001)
        XCTAssertEqual(16.fsdp(baseline), 12.8, accuracy: 0.000001)
        XCTAssertEqual(16.asdp(baseline), 16)
        XCTAssertEqual(16.dsdp(baseline), 48)
        XCTAssertEqual(16.dgsdp(wide), 16 * sqrt(600.0 * 600.0 + 800.0 * 800.0) / 611.6305, accuracy: 0.0001)
        XCTAssertEqual(16.flsdp(wide), 16 * max(600 / 300, 800 / 533), accuracy: 0.000001)
        XCTAssertEqual(16.ftsdp(wide), 16 * min(600 / 300, 800 / 533), accuracy: 0.000001)
        XCTAssertEqual(16.isdp(small), 16 * (1 + (600 / 300 - 1) * 0.5), accuracy: 0.000001)
        XCTAssertEqual(16.logsdp(small), 16 * (1 + 0.4 * log(2)), accuracy: 0.000001)
        XCTAssertEqual(16.prsdp(wide), 16 * (600 + 800) / 833, accuracy: 0.000001)
        XCTAssertEqual(16.psdpa(baseline), 16, "AR multiplier = 1 at the reference")
        XCTAssertEqual(16.fssp(baseline), 12.8 * 1.25, accuracy: 0.000001)
        XCTAssertEqual(16.fsem(baseline), 12.8, accuracy: 0.000001)
    }

    // ── Auto module ─────────────────────────────────────────────────────────

    func testAutoModulePriority() {
        let value = 10.autoScaledDp
            .rotate(15, .portrait)
            .qualifier(20, .width, minimum: 300)
            .screen(30, condition: .init(mode: .undefined, qualifier: .width, minimum: 300))
        XCTAssertEqual(value.resolve(baseline), 30)
        XCTAssertEqual(10.autoSp.resolve(baseline), 12.5, "autoSp without branches is base × fontScale")
        XCTAssertEqual(10.autoScaledDp.aspectRatio().resolve(wide),
            AppDimens.autoDp(10, configuration: wide, applyAspectRatio: true), accuracy: 0.000001)
    }

    // ── Resize / Units / Metal ──────────────────────────────────────────────

    func testResizeUnitsAndMetalABI() {
        let steps = DimensResize.steps(minimum: 10, maximum: 20, step: 2)
        XCTAssertEqual(DimensResize.largestFitting(steps) { $0 <= 16 }, 16)
        XCTAssertEqual(DimensResize.autoResizeText(min: .fixedSp(10), max: .fixedSp(20),
            configuration: baseline) { $0 <= 16 }, 16)
        XCTAssertEqual(resizeFixedSp(10).resolveToPx(baseline, density: 3, fontScale: 1.25), 37.5)
        XCTAssertEqual(resizePercentW(50).resolveToPoints(baseline), 150)
        XCTAssertEqual(DimenPhysicalUnits.toInch(1), 160)
        XCTAssertEqual(DimenPhysicalUnits.toMm(25.4), 160, accuracy: 0.000001)
        XCTAssertEqual(DimenPhysicalUnits.unitSizeInDp(type: .sp, configuration: baseline), 1.25)
        XCTAssertEqual(25.4.mmToInch(), 1)
        XCTAssertEqual(16.radius(.dp, baseline), 8)
        #if !os(watchOS)
        XCTAssertEqual(MemoryLayout<AppDimensUniforms>.stride, 64)
        #endif
    }

    #if !os(watchOS)
func testMetalUniforms() {
        let u = AppDimensUniforms(baseline)
        XCTAssertEqual(u.viewport.x, 300)
        XCTAssertEqual(u.viewport.y, 533)
        XCTAssertEqual(u.display.z, 533.0 / 300.0, accuracy: 0.000001)
    }
    #endif
}