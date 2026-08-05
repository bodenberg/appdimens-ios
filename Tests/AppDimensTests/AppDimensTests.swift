import XCTest
@testable import AppDimens

final class AppDimensTests: XCTestCase {
    let phone = DimensionContext(width: 360, height: 800, displayScale: 3, idiom: .phone)

    func testReferenceSizeKeepsBaseValue() {
        XCTAssertEqual(16.dynamic.points(in: phone), 16)
    }

    func testBalancedScalingDampensLargeScreens() {
        let tablet = DimensionContext(width: 720, height: 1000, displayScale: 2, idiom: .pad)
        XCTAssertEqual(100.dynamic.points(in: tablet), 141.5, accuracy: 0.001)
        XCTAssertLessThan(100.dynamic.points(in: tablet), 200)
    }

    func testStrategiesAndAxes() {
        let configuration = DimensionConfiguration(axis: .width, strategy: .linear, maximumScale: 3, pixelRounding: .none)
        XCTAssertEqual(10.dynamic.configured(configuration).points(in: .init(width: 720, height: 800)), 20)
        XCTAssertEqual(10.dynamic.configured(configuration).strategy(.none).points(in: .init(width: 720, height: 800)), 10)
    }

    func testClampingAndPixelRounding() {
        let context = DimensionContext(width: 390, height: 844, displayScale: 3)
        XCTAssertEqual(10.dynamic.limits(min: 12, max: 14).points(in: context), 12)
        XCTAssertEqual(10.1.fixed.points(in: context), 10, accuracy: 0.001)
    }

    func testQualifierLastMatchWinsAndIntersections() {
        let value = 16.dynamic.strategy(.none)
            .when(.idiom(.phone), 18)
            .when([.idiom(.phone), .minWidth(390)], 20)
        XCTAssertEqual(value.points(in: phone), 18)
        XCTAssertEqual(value.points(in: .init(width: 390, height: 844, idiom: .phone)), 20)
    }

    func testOrientationAndSizeClassQualifiers() {
        let context = DimensionContext(width: 800, height: 360, idiom: .pad, horizontalSizeClass: .regular)
        XCTAssertTrue(DimensionQualifier.orientation(.landscape).matches(context))
        XCTAssertTrue(DimensionQualifier.horizontalSizeClass(.regular).matches(context))
        XCTAssertFalse(DimensionQualifier.orientation(.portrait).matches(context))
    }

    func testTextScalingCanFollowDynamicType() {
        var config = DimensionConfiguration.default
        config.fontScaling = .system
        let context = DimensionContext(width: 360, height: 800, dynamicTypeScale: 2)
        XCTAssertEqual(12.dynamic.configured(config).points(in: context, text: true), 24)
        XCTAssertEqual(12.dynamic.configured(config).points(in: context), 12)
    }

    func testPercentageAndAvailableItems() {
        XCTAssertEqual(AppDimens.percentage(0.25, of: .width, in: phone), 90)
        XCTAssertEqual(AppDimens.percentage(2, of: .width, in: phone), 360)
        XCTAssertEqual(AppDimens.availableItemCount(container: 320, item: 100, spacing: 10), 3)
        XCTAssertEqual(AppDimens.availableItemCount(container: 320, item: 0), 0)
    }

    func testValueSemanticsDoNotMutateOriginal() {
        let original = 16.dynamic
        let changed = original.screen(.width).strategy(.linear).when(.idiom(.phone), 20)
        XCTAssertTrue(original.overrides.isEmpty)
        XCTAssertEqual(original.configuration.axis, .lowest)
        XCTAssertEqual(changed.points(in: phone), 20)
    }

    func testPixelsArePointsTimesDisplayScale() {
        XCTAssertEqual(8.dynamic.pixels(in: phone), 24)
        XCTAssertEqual(8.fixed.pixels(in: phone), 24)
    }
}
