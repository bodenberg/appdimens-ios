import XCTest
import Foundation
import AppDimensDynamic
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

/// Formula parity with dynamic-android (`calculate*DpCompose`, `DimenMetrics`).
final class KernelTests: XCTestCase {
    let baseline = Fixture.baseline, wide = Fixture.wide, small = Fixture.small

    func testBaselineIsIdentity() {
        XCTAssertEqual(16.sdp(baseline), 16, accuracy: 1e-12)
        XCTAssertEqual(16.wdp(baseline), 16, accuracy: 1e-12)
        XCTAssertEqual(16.hdp(baseline), 16 * 533 / 300, accuracy: 1e-12)
        XCTAssertEqual(16.ssp(baseline), 20, accuracy: 1e-12)
        XCTAssertEqual(16.sem(baseline), 16, accuracy: 1e-12)
        XCTAssertEqual(16.sdpi(baseline), 16, accuracy: 1e-12)
        XCTAssertEqual(16.sdpa(baseline), 16, accuracy: 1e-12)
        XCTAssertEqual(16.sdpPx(baseline), 48, accuracy: 1e-12)
        XCTAssertEqual(16.sei(baseline), 48, accuracy: 1e-12, "sei = sem in pixels")
    }

    func testDefaultInverterNeverSwaps() {
        // Android `Inverter.DEFAULT -> Unit`: hdp is always the window height.
        let landscape = DimensConfiguration(screenWidth: 800, screenHeight: 400)
        XCTAssertEqual(landscape.dimension(.height), 400)
        XCTAssertEqual(landscape.dimension(.width), 800)
        XCTAssertEqual(10.hdp(landscape), 10 * 400 / 300, accuracy: 1e-12)
        XCTAssertEqual(10.wdp(landscape), 10 * 800 / 300, accuracy: 1e-12)
        XCTAssertEqual(AppDimens.scaledDp(10, configuration: landscape, qualifier: .height, applyAspectRatio: true),
                       10 * (1 + 100 * (DimensConstants.adjustmentScale +
                             DimensConstants.sensitivityDefault * landscape.metrics.logNormalizedAspectRatio)),
                       accuracy: 1e-12)
    }

    func testAllEightInverters() {
        let l = DimensConfiguration(screenWidth: 800, screenHeight: 400)
        XCTAssertEqual(l.dimension(.height, inverter: .phToLw), 800)
        XCTAssertEqual(l.dimension(.width, inverter: .pwToLh), 400)
        XCTAssertEqual(l.dimension(.smallWidth, inverter: .swToLh), 400)
        XCTAssertEqual(l.dimension(.smallWidth, inverter: .swToLw), 800)
        XCTAssertEqual(l.dimension(.height, inverter: .lhToPw), 400, "portrait-only inverter is inert in landscape")
        XCTAssertEqual(l.dimension(.smallWidth, inverter: .swToPh), 400)
        let p = DimensConfiguration(screenWidth: 400, screenHeight: 800)
        XCTAssertEqual(p.dimension(.height, inverter: .lhToPw), 400)
        XCTAssertEqual(p.dimension(.width, inverter: .lwToPh), 800)
        XCTAssertEqual(p.dimension(.smallWidth, inverter: .swToPh), 800)
        XCTAssertEqual(p.dimension(.smallWidth, inverter: .swToPw), 400)
        XCTAssertEqual(p.dimension(.height, inverter: .phToLw), 800, "landscape-only inverter is inert in portrait")
    }

    func testInverterCatalogVariants() {
        let landscape = DimensConfiguration(screenWidth: 800, screenHeight: 400)
        XCTAssertEqual(10.hdpLw(landscape), 10 * 800 / 300, accuracy: 1e-12)
        XCTAssertEqual(10.wdpLh(landscape), 10 * 400 / 300, accuracy: 1e-12)
        XCTAssertEqual(10.sdpLw(landscape), 10 * 800 / 300, accuracy: 1e-12)
        let portrait = DimensConfiguration(screenWidth: 800, screenHeight: 1200)
        XCTAssertEqual(10.sdpPh(portrait), 10 * 1200 / 300, accuracy: 1e-12)
        XCTAssertEqual(10.sdpPw(portrait), 10 * 800 / 300, accuracy: 1e-12)
        XCTAssertEqual(10.sdpPxPh(portrait), 10.sdpPhPx(portrait), "Android and iOS Px spellings agree")
    }

    func testScaledAspectRatio() {
        let m = small.metrics
        let expected = 10 * (1 + 300 * (DimensConstants.adjustmentScale + DimensConstants.sensitivityDefault * m.logNormalizedAspectRatio))
        XCTAssertEqual(10.sdpa(small), expected, accuracy: 1e-12)
        let custom = 10 * (1 + 300 * (DimensConstants.adjustmentScale + 0.005 * m.logNormalizedAspectRatio))
        XCTAssertEqual(AppDimens.scaledDp(10, configuration: small, applyAspectRatio: true, sensitivityK: 0.005), custom, accuracy: 1e-12)
        let customH = 10 * (1 + (1032 - 300) * (DimensConstants.adjustmentScale + 0.005 * m.logNormalizedAspectRatio))
        XCTAssertEqual(AppDimens.scaledDp(10, configuration: small, qualifier: .height,
            applyAspectRatio: true, sensitivityK: 0.005), customH, accuracy: 1e-12)
    }

    func testMultiWindow() {
        let split = Fixture.split
        XCTAssertTrue(split.isMultiWindow)
        XCTAssertFalse(Fixture.phone.isMultiWindow)
        XCTAssertEqual(10.sdpi(split), 10, "ignore-multi-window returns the raw value when constrained")
        XCTAssertNotEqual(10.sdp(split), 10)
        let explicit = DimensConfiguration(screenWidth: 400, screenHeight: 700, isInMultiWindowMode: true)
        XCTAssertTrue(explicit.isMultiWindow)
        XCTAssertEqual(10.psdpi(explicit), 10)
    }

    func testSatelliteKernels() {
        XCTAssertEqual(16.dsdp(baseline), 48, "density = base × displayScale")
        XCTAssertEqual(16.dgsdp(wide), 16 * (600.0 * 600.0 + 800.0 * 800.0).squareRoot() / 611.6305, accuracy: 1e-9)
        XCTAssertEqual(16.prsdp(wide), 16 * (600 + 800) / 833, accuracy: 1e-12)
        XCTAssertEqual(16.flsdp(wide), 16 * max(600 / 300, 800 / 533), accuracy: 1e-12)
        XCTAssertEqual(16.ftsdp(wide), 16 * min(600 / 300, 800 / 533), accuracy: 1e-12)
        XCTAssertEqual(16.pwsdp(small), 16 * pow(600 / 300, 0.75), accuracy: 1e-12)
        XCTAssertEqual(16.isdp(small), 16 * (1 + (600 / 300 - 1) * 0.5), accuracy: 1e-12)
        XCTAssertEqual(16.logsdp(small), 16 * (1 + 0.4 * log(2)), accuracy: 1e-12)
        XCTAssertEqual(16.logsdp(DimensConfiguration(screenWidth: 200, screenHeight: 400)), 16 * (1 - 0.4 * log(300.0 / 200)), accuracy: 1e-12)
        XCTAssertEqual(16.asdp(small), 16 * (480 / 300 + 0.4 * log(1 + (600 - 480) / 300)), accuracy: 1e-12)
        XCTAssertEqual(16.asdp(baseline), 16, accuracy: 1e-12, "auto linear branch ≤ 480")
        XCTAssertEqual(16.fsdp(baseline), 16 * 0.8, accuracy: 1e-12, "fluid clamps to ×0.8 below 320")
        XCTAssertEqual(16.fsdp(DimensConfiguration(screenWidth: 1000, screenHeight: 1400)), 16 * 1.2, accuracy: 1e-12)
        XCTAssertEqual(16.fsdp(DimensConfiguration(screenWidth: 400, screenHeight: 700)), 16 * (0.8 + 0.4 * 80 / 448), accuracy: 1e-12)
        XCTAssertEqual(16.psdp(small), 16 * 600 / 300, accuracy: 1e-12)
    }

    func testSatelliteNonDefaultAxisUsesAxisFormula() {
        let c = small // 600 × 1032
        XCTAssertEqual(16.pwhdp(c), 16 * pow(1032 / 300, 0.75), accuracy: 1e-9)
        XCTAssertEqual(16.loghdp(c), 16 * (1 + 0.4 * log(1032 / 300)), accuracy: 1e-9)
        XCTAssertEqual(16.ahdp(c), 16 * (480 / 300 + 0.4 * log(1 + (1032 - 480) / 300)), accuracy: 1e-9)
        XCTAssertEqual(16.fhdp(c), 16 * 1.2, accuracy: 1e-9)
        let linear: Double = 16.0 * 1032.0 / 300.0
        XCTAssertEqual(16.ihdp(c), 16 + (linear - 16) * 0.5, accuracy: 1e-9)
        XCTAssertEqual(16.phdp(c), 16 * 1032 / 300, accuracy: 1e-9)
        // Window-shape satellites ignore the qualifier (Android parity).
        XCTAssertEqual(16.dghdp(c), 16.dgsdp(c))
        XCTAssertEqual(16.flwdp(c), 16.flsdp(c))
    }

    func testSatelliteAspectRatioMultiplier() {
        let m = wide.metrics
        let ar = 1 + DimensConstants.sensitivityDefault * m.logNormalizedAspectRatio
        XCTAssertEqual(16.pwsdpa(wide), 16 * pow(2, 0.75) * ar, accuracy: 1e-12)
        XCTAssertEqual(16.powerDp(wide, options: .init(applyAspectRatio: true, sensitivityK: 0.01)),
                       16 * pow(2, 0.75) * (1 + 0.01 * m.logNormalizedAspectRatio), accuracy: 1e-12)
        XCTAssertEqual(16.dgsdpa(wide), 16.dgsdp(wide) * ar, accuracy: 1e-12)
    }

    func testTextFamilies() {
        XCTAssertEqual(16.ssp(small), 16 * 2 * 1.25, accuracy: 1e-12)
        XCTAssertEqual(16.sem(small), 16 * 2, accuracy: 1e-12)
        XCTAssertEqual(16.hsp(small), 16 * 1032 / 300 * 1.25, accuracy: 1e-12)
        XCTAssertEqual(16.wem(small), 16 * 2, accuracy: 1e-12)
        XCTAssertEqual(16.sspPx(small), 16 * 2 * 1.25 * 3, accuracy: 1e-12)
        XCTAssertEqual(16.sspPxa(small), 16.sspaPx(small))
        XCTAssertEqual(16.pwssp(small), 16 * pow(2, 0.75) * 1.25, accuracy: 1e-12)
        XCTAssertEqual(16.pwsei(small), 16 * pow(2, 0.75) * 3, accuracy: 1e-12)
    }

    func testInvalidInputsAreNormalizedNotTrapped() {
        let c = DimensConfiguration(screenWidth: 0, screenHeight: .nan, displayScale: -1, fontScale: .infinity)
        XCTAssertEqual(c.screenWidth, 300)
        XCTAssertEqual(c.screenHeight, 533)
        XCTAssertEqual(c.displayScale, 1)
        XCTAssertEqual(c.fontScale, 1)
        for strategy in DimensStrategy.allCases {
            XCTAssertTrue(AppDimens.resolve(16, strategy: strategy, configuration: c).isFinite, "\(strategy)")
        }
    }

    func testMetricsArePrecomputedAndEqualityIgnoresDerivedValues() {
        let a = DimensConfiguration(screenWidth: 390, screenHeight: 844, displayScale: 3)
        let b = DimensConfiguration(screenWidth: 390, screenHeight: 844, displayScale: 3)
        XCTAssertEqual(a, b)
        XCTAssertEqual(a.hashValue, b.hashValue)
        XCTAssertEqual(a.metrics.scale, 1.3, accuracy: 1e-12)
        XCTAssertEqual(a.metrics.powerScale, pow(1.3, 0.75), accuracy: 1e-12)
        XCTAssertNotEqual(a, DimensConfiguration(screenWidth: 390, screenHeight: 844, displayScale: 2))
        XCTAssertEqual(DimenMetrics(a), a.metrics)
        XCTAssertEqual(DimenMetrics.default.scale, 1)
    }

    func testLiteralPercent() {
        let c = DimensConfiguration(screenWidth: 360, screenHeight: 720)
        XCTAssertEqual(50.spaceW(c), 180)
        XCTAssertEqual(50.spaceH(c), 360)
        XCTAssertEqual(50.spaceSw(c), 180)
        XCTAssertEqual(50.spaceWPx(c), 180)
        XCTAssertEqual(50.space(200, c), 100)
        XCTAssertEqual(50.spaceWi(Fixture.split), 50, "ignore multi-window returns the raw percent")
        XCTAssertEqual(AppDimens.literalPercentOfReferenceDp(.infinity, referenceDp: 100), 0)
    }
}

/// Bit-level cross-check against the Android Float32 implementation: the Swift
/// port computes in Double, so results must agree with the Kotlin `Float` math
/// to single-precision rounding (relative 1e-6).
final class AndroidFloatParityTests: XCTestCase {
    // Kotlin constants, Float32.
    let INV: Float = 0.0033333334, ADJ: Float = 0.10 / 30, SENS: Float = 0.08 / 30
    let REF_AR: Float = 1.78

    func android(_ w: Int, _ h: Int) -> (sdp: Float, sdpa: Float, hdp: Float, wdp: Float, power: Float, log: Float,
                                        diag: Float, perim: Float, fit: Float, fill: Float, auto: Float, interp: Float, arMul: Float) {
        let sm = Float(min(w, h)), lg = Float(max(w, h))
        let lnAR = Float(Foundation.log(Double((lg / sm) / REF_AR)))
        let sdpa = 1 + (sm - 300) * (ADJ + SENS * lnAR)
        let power = Float(pow(Double(sm / 300), 0.75))
        let logS: Float = sm > 300 ? 1 + 0.4 * Float(Foundation.log(Double(sm * INV))) : 1 - 0.4 * Float(Foundation.log(Double(300 / sm)))
        let diag = (sm * sm + lg * lg).squareRoot() / 611.6305
        let auto: Float = sm <= 480 ? sm * INV : 480 * INV + 0.4 * Float(Foundation.log(Double(1 + (sm - 480) * INV)))
        return (sm * INV, sdpa, Float(h) * INV, Float(w) * INV, power, logS, diag, (sm + lg) / 833,
                min(sm / 300, lg / 533), max(sm / 300, lg / 533), auto, 1 + (sm * INV - 1) * 0.5, 1 + SENS * lnAR)
    }

    func testFactorsMatchAndroidFloat() {
        let windows = [(300, 533), (360, 640), (390, 844), (412, 915), (600, 960), (768, 1024), (820, 1180),
                       (1024, 1366), (1280, 800), (1920, 1080), (240, 320), (844, 390)]
        for (w, h) in windows {
            let a = android(w, h)
            let m = DimensConfiguration(screenWidth: Double(w), screenHeight: Double(h)).metrics
            let pairs: [(String, Float, Double)] = [
                ("sdp", a.sdp, m.scale), ("sdpa", a.sdpa, m.defaultScaledAspectRatioMultiplier),
                ("hdp", a.hdp, m.screenHeightFactor), ("wdp", a.wdp, m.screenWidthFactor),
                ("power", a.power, m.powerScale), ("log", a.log, m.logarithmicScale),
                ("diagonal", a.diag, m.diagonalScale), ("perimeter", a.perim, m.perimeterScale),
                ("fit", a.fit, m.fitScale), ("fill", a.fill, m.fillScale), ("auto", a.auto, m.autoScale),
                ("interpolated", a.interp, m.interpolatedScale), ("arMultiplier", a.arMul, m.defaultAspectRatioMultiplier),
            ]
            for (name, kotlin, swift) in pairs {
                XCTAssertClose(Double(kotlin), swift, relative: 2e-6, "\(name) @ \(w)×\(h)")
            }
        }
    }
}
