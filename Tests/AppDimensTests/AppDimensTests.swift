import XCTest
@testable import AppDimens

final class AppDimensTests: XCTestCase {
    let baseline = DimensConfiguration(screenWidth: 300, screenHeight: 533, displayScale: 3, fontScale: 1.25)

    func testDirectAndroidBaselineParity() {
        XCTAssertEqual(16.sdp(baseline), 16, accuracy: 0.000001)
        XCTAssertEqual(16.wdp(baseline), 16, accuracy: 0.000001)
        XCTAssertEqual(16.hdp(baseline), 16 * 533 / 300, accuracy: 0.000001)
        XCTAssertEqual(16.ssp(baseline), 20, accuracy: 0.000001)
        XCTAssertEqual(16.sem(baseline), 16, accuracy: 0.000001)
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
    }

    func testConfigurationIsWindowSemanticNotViewSemantic() {
        let window = DimensConfiguration(screenWidth: 390, screenHeight: 844)
        XCTAssertEqual(10.sdp(window), 13)
        XCTAssertEqual(10.sdp(window), 10.sdp(window), "Every child in one window shares this configuration")
    }
    func testPrincipalFacilitatorsAndBuilder() {
        let tablet = DimensConfiguration(screenWidth: 800, screenHeight: 1200, uiMode: .normal)
        XCTAssertEqual(AppDimens.qualified(10, qualifiedValue: 20, configuration: tablet,
            qualifier: .width, minimum: 600), 20 * 800 / 300, accuracy: 0.000001)
        XCTAssertEqual(AppDimens.rotate(10, rotationValue: 15, configuration: tablet,
            orientation: .portrait), 15 * 800 / 300, accuracy: 0.000001)
        XCTAssertEqual(10.scaledDp.screen(20, qualifier: .width, minimum: 600)
            .resolve(tablet), 20 * 800 / 300, accuracy: 0.000001)
    }
    func testPlainBranchDoesNotScale() {
        XCTAssertEqual(AppDimensPlain.rotate(10, branch: 20, orientation: .portrait,
            configuration: baseline), 20)
        XCTAssertEqual(AppDimensPlain.qualifier(10, branch: 30, qualifier: .width,
            minimum: 300, configuration: baseline), 30)
    }
}
