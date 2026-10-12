import XCTest
import Foundation
import AppDimensDynamic
import AppDimensPercent
import AppDimensPower

/// Every worked number published in Documentation/strategies/*.md, recomputed
/// through the real API. If a doc and the library disagree, this fails.
final class DocumentationExamplesTests: XCTestCase {
    let c = DimensConfiguration(screenWidth: 390, screenHeight: 844, displayScale: 3)

    func check(_ value: Double, _ documented: Double, _ tolerance: Double, _ doc: String,
               file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertEqual(value, documented, accuracy: tolerance, doc, file: file, line: line)
    }

    func testScaled() {
        check(16.sdp(c), 20.8, 1e-9, "scaled.md sdp")
        check(120.wdp(c), 156, 1e-9, "scaled.md wdp")
        check(44.hdp(c), 123.79, 0.005, "scaled.md hdp")
        check(16.sdpa(c), 21.55, 0.005, "scaled.md sdpa")
        check(c.metrics.defaultScaledAspectRatioMultiplier, 1.3469, 0.00005, "scaled.md multiplier")
    }

    func testPercent() {
        check(16.psdp(c), 20.8, 1e-9, "percent.md psdp")
        check(25.spaceW(c), 97.5, 1e-9, "percent.md spaceW")
        check(50.spaceH(c), 422, 1e-9, "percent.md spaceH")
        check(Double(10.space(200)), 20, 1e-9, "percent.md space")
        check(10.spaceW(c), 39, 1e-9, "percent.md 10 %")
        check(25.spaceH(c), 211, 1e-9, "percent.md 25 % height")
    }

    func testPower() {
        check(24.powerDp(c), 29.22, 0.005, "power.md")
        check(24.pwsdp(c), 29.22, 0.005, "power.md catalog")
        let f = DimensFactors(c)
        check(f.resolve(16, strategy: .power), 19.48, 0.005, "power.md 16")
        check(f.resolve(32, strategy: .power), 38.96, 0.005, "power.md 32")
        check(pow(2, 0.75), 1.68, 0.005, "power.md doubling")
    }

    func testFluid() {
        let landscape = DimensConfiguration(screenWidth: 844, screenHeight: 390, displayScale: 3)
        check(24.fluidDp(landscape), 20.7, 0.005, "fluid.md gutter")
        check(DynamicDimens.resolve(24, strategy: .fluid, configuration: landscape,
                                    options: StrategyOptions(qualifier: .width)), 28.8, 1e-9, "fluid.md width")
        check(DimenMetrics.fluid(544), 1.0, 1e-12, "fluid.md midpoint")
    }

    func testAuto() {
        let phone = DimensConfiguration(screenWidth: 390, screenHeight: 844, displayScale: 3)
        let tablet = DimensConfiguration(screenWidth: 1024, screenHeight: 768, displayScale: 2)
        let padding = 16.autoDp()
            .screen(.desk, customValue: 32)
            .screen(.smallWidth, 600, customValue: 24)
            .screen(.landscape, customValue: 12)
        check(padding.sdp(phone), 20.8, 1e-9, "auto.md phone")
        check(padding.sdp(tablet), 44.86, 0.005, "auto.md tablet")
        let label = 15.autoSp().screen(.width, 700, customValue: 17)
        check(label.ssp(tablet), 31.78, 0.005, "auto.md label")
    }

    func testWindowShapeStrategies() {
        check(16.densityDp(c), 48, 1e-9, "density.md")
        check(64.dynamic(.density, c), 192, 1e-9, "density.md buffer")
        check(16.sdpPx(c), 62.4, 1e-9, "density.md sdpPx")
        check(18.diagonalDp(c), 27.36, 0.005, "diagonal.md")
        check(300.fillDp(c), 475.05, 0.01, "fill.md")
        check(240.fillDp(c), 380.04, 0.01, "fill.md hero")
        check(180.fitDp(c), 234, 1e-9, "fit.md")
        check(20.perimeterDp(c), 29.63, 0.005, "perimeter.md")
        check(16.interpolatedDp(c), 18.4, 1e-9, "interpolated.md")
        check(28.logarithmicDp(c), 30.94, 0.005, "logarithmic.md")
    }

    func testPhysicalUnits() {
        check(DimenPhysicalUnits.toDpFromMm(10, pointsPerInch: 72), 28.346, 0.0005, "physical-units.md mm")
        check(DimenPhysicalUnits.radiusFromDiameter(10, .mm, c, pointsPerInch: 72), 14.173, 0.0005, "physical-units.md radius")
        check(DimenPhysicalUnits.toPxFromMm(10, c, pointsPerInch: 72), 85.039, 0.0005, "physical-units.md px")
        check(DimenPhysicalUnits.toPxFromMm(10, c, pointsPerInch: 460.0 / 3.0), 181.102, 0.0005, "physical-units.md calibrated")
    }

    func testReadmeAndGuide() {
        check(16.sdp(c), 20.8, 1e-9, "README sdp")
        check(16.hdp(c), 45.01, 0.005, "README hdp")
        check(16.sdpPx(c), 62.4, 1e-9, "README sdpPx")
        check(16 * pow(1.3, 0.75), 19.48, 0.005, "MATHEMATICS power example")
    }
}
