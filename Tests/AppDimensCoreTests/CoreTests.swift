import XCTest
@testable import AppDimensCore

final class CoreTests: XCTestCase {
    let base = DimensContext(width: 300, height: 533, displayScale: 3, dynamicTypeScale: 1.25, interfaceMode: .phone)
    func testBaselineAndAxes() {
        XCTAssertEqual(16.sdp(in: base), 16, accuracy: 0.0001)
        XCTAssertEqual(10.wdp(in: base), 10, accuracy: 0.0001)
        XCTAssertEqual(10.hdp(in: base), 533 / 30, accuracy: 0.0001)
    }
    func testTextAndPixelConversions() {
        XCTAssertEqual(16.ssp(in: base), 20)
        XCTAssertEqual(16.sem(in: base), 16)
        XCTAssertEqual(Dimens.pixels(10, in: base), 30)
        XCTAssertEqual(Dimens.points(30, in: base), 10)
    }
    func testContextAndMultiWindow() {
        let context = DimensContext(width: 400, height: 300, fullScreenWidth: 800, fullScreenHeight: 600)
        XCTAssertEqual(context.orientation, .landscape)
        XCTAssertTrue(context.isMultiWindow)
        XCTAssertEqual(Dimens.scale(20, in: context, options: .init(ignoreMultiWindow: true)), 20)
    }
    func testAdaptivePriorityAndThresholdOrdering() {
        let value = 10.autoScaled
            .screen(.init(orientation: .portrait), value: 15)
            .screen(.init(mode: .phone), value: 20)
            .screen(.init(mode: .phone, qualifier: .width, minimum: 280), value: 30)
        XCTAssertEqual(value.resolve(in: base), 30)
    }
    func testInvalidContextPreconditionsArePreventedByPublicContract() {
        XCTAssertEqual(Dimens.scale(-10, in: base), -10)
        XCTAssertTrue(Dimens.scale(.infinity, in: base).isInfinite)
    }
}
