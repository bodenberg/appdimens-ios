import XCTest
import AppDimensCore
@testable import AppDimensStrategies

final class StrategyTests: XCTestCase {
    let base = DimensContext(width: 300, height: 533)
    func testAllStrategiesReturnFiniteAtBaseline() {
        for strategy in DimensStrategy.allCases {
            XCTAssertTrue(DimensStrategies.resolve(16, strategy: strategy, in: base).isFinite, "\(strategy)")
        }
    }
    func testCanonicalFormulaBaselines() {
        XCTAssertEqual(DimensStrategies.resolve(10, strategy: .diagonal, in: base), 10, accuracy: 0.0001)
        XCTAssertEqual(DimensStrategies.resolve(10, strategy: .perimeter, in: base), 10, accuracy: 0.0001)
        XCTAssertEqual(DimensStrategies.resolve(10, strategy: .power, in: base), 10, accuracy: 0.0001)
        XCTAssertEqual(DimensStrategies.resolve(10, strategy: .logarithmic, in: base), 10, accuracy: 0.0001)
        XCTAssertEqual(DimensStrategies.resolve(100, strategy: .percent, in: base, options: .init(percent: 50)), 150)
    }
    func testFitFillAndInterpolation() {
        let wide = DimensContext(width: 600, height: 533)
        XCTAssertEqual(10.dynamic(.fit, in: wide), 10, accuracy: 0.0001)
        XCTAssertEqual(10.dynamic(.fill, in: wide), 20, accuracy: 0.0001)
        XCTAssertEqual(10.dynamic(.interpolated, in: wide, options: .init(qualifier: .width)), 15, accuracy: 0.0001)
    }
    func testFluidClamping() {
        XCTAssertEqual(10.dynamic(.fluid, in: DimensContext(width: 200, height: 300)), 8)
        XCTAssertEqual(10.dynamic(.fluid, in: DimensContext(width: 800, height: 900)), 12)
    }
    func testResizeBinarySearch() {
        XCTAssertEqual(DimensResize.largestFitting(minimum: 8, maximum: 40, step: 0.5) { $0 <= 23.5 }, 23.5)
    }
    func testPhysicalUnits() {
        XCTAssertEqual(DimensPhysical.points(1, unit: .inches), 72)
        XCTAssertEqual(DimensPhysical.pixels(2.54, unit: .centimeters, pixelsPerInch: 300), 300, accuracy: 0.0001)
    }
}
