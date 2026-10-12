import XCTest
import Foundation
import AppDimensDynamic
import AppDimensResize
import AppDimensUnits
import AppDimensPercent
import AppDimensPower
import AppDimensAuto

final class StrategyModuleTests: XCTestCase {
    func testDynamicMatchesCatalogs() {
        let c = Fixture.small
        XCTAssertEqual(16.dynamic(.scaled, c), 16.sdp(c), accuracy: 1e-12)
        XCTAssertEqual(16.dynamic(.power, c), 16.pwsdp(c), accuracy: 1e-12)
        XCTAssertEqual(16.dynamic(.percent, c), 16.psdp(c), accuracy: 1e-12)
        XCTAssertEqual(16.dynamic(.auto, c), 16.asdp(c), accuracy: 1e-12)
        XCTAssertEqual(16.dynamic(.plain, c), 16)
        XCTAssertEqual(16.dynamic(.density, Fixture.baseline), 48)
        XCTAssertEqual(16.dynamic(.scaled, c, options: .init(qualifier: .height)), 16.hdp(c), accuracy: 1e-12)
        withAmbient(c) { XCTAssertEqual(Double(16.dynamic(.power)), 16.pwsdp(c), accuracy: 1e-12) }
    }

    func testPrecomputedFactorsMatchKernelsForEveryStrategy() {
        for c in Fixture.all {
            let factors = DimensFactors(c)
            for strategy in DimensStrategy.allCases {
                let expected = c.isMultiWindow ? AppDimens.resolve(16, strategy: strategy, configuration: c)
                                               : DynamicDimens.resolve(16, strategy: strategy, configuration: c)
                XCTAssertClose(factors.resolve(16, strategy: strategy), expected, relative: 1e-12, "\(strategy) @ \(c)")
            }
            var buffer = [1.0, 2.0, 4.0]
            factors.resolve(&buffer, strategy: .power)
            do { let expected: Double = 4 * c.metrics.powerScale; XCTAssertEqual(buffer[2], expected, accuracy: 1e-12) }
        }
    }
}

final class ResizeUnitsTests: XCTestCase {
    let baseline = Fixture.baseline

    func testResizeLadder() {
        let steps = DimensResize.steps(minimum: 10, maximum: 20, step: 2)
        XCTAssertEqual(steps, [10, 12, 14, 16, 18, 20])
        XCTAssertEqual(DimensResize.largestFitting(steps) { $0 <= 16 }, 16)
        XCTAssertEqual(DimensResize.largestFitting([]) { _ in true }, 0)
        XCTAssertEqual(DimensResize.autoResizeText(min: .fixedSp(10), max: .fixedSp(20), configuration: baseline) { $0 <= 16 }, 16)
        XCTAssertEqual(resizeFixedSp(10).resolveToPx(baseline, density: 3, fontScale: 1.25), 37.5)
        XCTAssertEqual(resizePercentW(50).resolveToPoints(baseline), 150)
        XCTAssertEqual(resizePercentH(200).resolveToPoints(baseline), 533, "percent is clamped to 0…100")
    }

    func testPhysicalUnits() {
        XCTAssertEqual(DimenPhysicalUnits.toInch(1), 160)
        XCTAssertEqual(DimenPhysicalUnits.toMm(25.4), 160, accuracy: 1e-12)
        XCTAssertEqual(DimenPhysicalUnits.toDpFromInch(1, pointsPerInch: 163), 163)
        XCTAssertEqual(DimenPhysicalUnits.toDpFromMm(25.4, pointsPerInch: 163), 163, accuracy: 1e-9)
        XCTAssertEqual(DimenPhysicalUnits.toDpFromCm(2.54, pointsPerInch: 163), 163, accuracy: 1e-9)
        XCTAssertEqual(DimenPhysicalUnits.toPxFromInch(1, baseline, pointsPerInch: 160), 480)
        XCTAssertEqual(DimenPhysicalUnits.toSpFromInch(1, baseline, pointsPerInch: 160), 128)
        XCTAssertEqual(DimenPhysicalUnits.unitSizeInDp(type: .sp, configuration: baseline), 1.25)
        XCTAssertEqual(DimenPhysicalUnits.radiusFromDiameter(10, .dp, baseline), 5)
        XCTAssertEqual(DimenPhysicalUnits.radiusFromCircumference(2 * .pi * 10, .dp, baseline), 10, accuracy: 1e-12)
        XCTAssertEqual(25.4.mmToInch(), 1)
        XCTAssertEqual(1.inchToMm(), 25.4)
        XCTAssertEqual(16.radius(.dp, baseline), 8)
        XCTAssertEqual(Double(1.inch), DimenPhysicalUnits.devicePointsPerInch)
    }
}

final class MetalUniformsTests: XCTestCase {
    func testLayoutMatchesMetalStruct() {
        XCTAssertEqual(MemoryLayout<AppDimensUniforms>.size, 96)
        XCTAssertEqual(MemoryLayout<AppDimensUniforms>.stride, 96)
        XCTAssertEqual(MemoryLayout<AppDimensUniforms>.alignment, 16)
        XCTAssertEqual(AppDimensUniforms.byteCount, 96)
        XCTAssertTrue(AppDimensUniforms.metalSource.contains("struct AppDimensUniforms"))
    }

    func testUniformsCarryEveryFactor() {
        for c in Fixture.all {
            let u = AppDimensUniforms(c)
            XCTAssertEqual(u.viewport.x, Float(c.screenWidth))
            XCTAssertEqual(u.viewport.y, Float(c.screenHeight))
            for strategy in DimensStrategy.allCases {
                XCTAssertClose(Double(u.factor(strategy)) * 16,
                               DimensFactors(c).resolve(16, strategy: strategy), relative: 1e-6, "\(strategy)")
            }
            XCTAssertEqual(u.display.x, Float(c.displayScale))
            XCTAssertEqual(u.display.y, Float(c.fontScale))
            XCTAssertEqual(u.display.w, c.isMultiWindow ? 1 : 0)
            XCTAssertEqual(u.scaled.w, Float(c.metrics.defaultScaledAspectRatioMultiplier), accuracy: 1e-6)
        }
    }
}
