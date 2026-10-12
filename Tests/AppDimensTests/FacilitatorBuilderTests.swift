import XCTest
import AppDimensDynamic
import AppDimensPower
import AppDimensAuto

final class FacilitatorTests: XCTestCase {
    let portrait = Fixture.phone, landscape = Fixture.phoneLandscape, tv = Fixture.tv

    func testRotate() {
        XCTAssertEqual(80.sdpRotate(50, landscape), 50.sdp(landscape), accuracy: 1e-12)
        XCTAssertEqual(80.sdpRotate(50, portrait), 80.sdp(portrait), accuracy: 1e-12)
        XCTAssertEqual(80.sdpRotate(50, orientation: .portrait, portrait), 50.sdp(portrait), accuracy: 1e-12)
        XCTAssertEqual(80.sdpRotate(50, orientation: .default, landscape), 80.sdp(landscape), "DEFAULT never matches")
        XCTAssertEqual(80.hdpRotate(50, landscape), 50.hdp(landscape), accuracy: 1e-12, "final qualifier defaults to the family axis")
        XCTAssertEqual(80.sdpRotate(50, finalQualifierResolver: .width, landscape), 50.wdp(landscape), accuracy: 1e-12)
        XCTAssertEqual(80.sdpRotatePx(50, landscape), 50.sdpPx(landscape), accuracy: 1e-12)
        XCTAssertEqual(16.sspRotate(20, landscape), 20.ssp(landscape), accuracy: 1e-12)
        XCTAssertEqual(16.sspRotate(20, fontScale: false, landscape), 20.sem(landscape), accuracy: 1e-12)
        XCTAssertEqual(80.sdpRotate(50, applyAspectRatio: true, landscape), 50.sdpa(landscape), accuracy: 1e-12)
    }

    func testModeQualifierScreen() {
        XCTAssertEqual(30.sdpMode(200, .television, tv), 200.sdp(tv), accuracy: 1e-12)
        XCTAssertEqual(30.sdpMode(200, .television, portrait), 30.sdp(portrait), accuracy: 1e-12)
        XCTAssertEqual(16.sdpQualifier(24, .smallWidth, 600, Fixture.tablet), 24.sdp(Fixture.tablet), accuracy: 1e-12)
        XCTAssertEqual(16.sdpQualifier(24, .smallWidth, 600, portrait), 16.sdp(portrait), accuracy: 1e-12)
        XCTAssertEqual(16.hdpQualifier(24, .height, 800, portrait), 24.hdp(portrait), accuracy: 1e-12)
        XCTAssertEqual(16.sdpScreen(40, .television, .width, 1280, tv), 40.sdp(tv), accuracy: 1e-12)
        XCTAssertEqual(16.sdpScreen(40, .television, .width, 4000, tv), 16.sdp(tv), accuracy: 1e-12)
        XCTAssertEqual(16.sspMode(28, .television, tv), 28.ssp(tv), accuracy: 1e-12)
        XCTAssertEqual(30.pwsdpMode(200, .television, tv), 200.pwsdp(tv), accuracy: 1e-12)
    }

    func testPlainVariantsPassTheReceiverThrough() {
        let resolved = 16.sdp(portrait) // an already-resolved length
        XCTAssertEqual(resolved.sdpRotatePlain(50, portrait), resolved, "no match → receiver unchanged")
        XCTAssertEqual(resolved.sdpRotatePlain(50, landscape), 50.sdp(landscape), accuracy: 1e-12)
        XCTAssertEqual(resolved.sdpModePlain(10, .television, tv), 10.sdp(tv), accuracy: 1e-12)
        XCTAssertEqual(resolved.sdpModePlain(10, .television, portrait), resolved)
        XCTAssertEqual(AppDimensPlain.rotate(10, branch: 20, orientation: .landscape, configuration: landscape), 20)
        XCTAssertEqual(AppDimensPlain.mode(10, branch: 40, mode: .car, configuration: portrait), 10)
    }

    func testAmbientFacilitators() {
        withAmbient(tv) {
            XCTAssertEqual(Double(30.sdpMode(200, .television)), 200.sdp(tv), accuracy: 1e-9)
            XCTAssertEqual(Double(80.sdpRotate(50)), 50.sdp(tv), accuracy: 1e-9)
            XCTAssertEqual(Double(16.sspScreen(20, .television, .width, 1000)), 20.ssp(tv), accuracy: 1e-9)
        }
    }
}

final class BuilderTests: XCTestCase {
    func testPriorityOrderMatchesAndroid() {
        let tvWide = DimensConfiguration(screenWidth: 1920, screenHeight: 1080, uiMode: .television)
        let builder = 10.scaledDp()
            .screen(.landscape, customValue: 40)                // priority 4
            .screen(.smallWidth, 600, customValue: 30)          // priority 3
            .screen(.television, customValue: 20)               // priority 2
            .screen(.television, .smallWidth, 1000, customValue: 15) // priority 1
        XCTAssertEqual(builder.sdp(tvWide), 15.sdp(tvWide), accuracy: 1e-12, "mode + qualifier wins")
        let tvSmall = DimensConfiguration(screenWidth: 1280, screenHeight: 720, uiMode: .television)
        XCTAssertEqual(builder.sdp(tvSmall), 20.sdp(tvSmall), accuracy: 1e-12, "then mode")
        let tablet = DimensConfiguration(screenWidth: 1180, screenHeight: 820, uiMode: .normal)
        XCTAssertEqual(builder.sdp(tablet), 30.sdp(tablet), accuracy: 1e-12, "then qualifier")
        XCTAssertEqual(builder.sdp(Fixture.phoneLandscape), 40.sdp(Fixture.phoneLandscape), accuracy: 1e-12, "then orientation")
        XCTAssertEqual(builder.sdp(Fixture.phone), 10.sdp(Fixture.phone), accuracy: 1e-12, "fallback to the base value")
    }

    func testHigherQualifierThresholdWinsWithinPriority() {
        let builder = 10.scaledDp()
            .screen(.smallWidth, 600, customValue: 20)
            .screen(.smallWidth, 800, customValue: 30)
        let c = DimensConfiguration(screenWidth: 900, screenHeight: 1200)
        XCTAssertEqual(builder.sdp(c), 30.sdp(c), accuracy: 1e-12)
        let mid = DimensConfiguration(screenWidth: 700, screenHeight: 1000)
        XCTAssertEqual(builder.sdp(mid), 20.sdp(mid), accuracy: 1e-12)
    }

    func testFinalQualifierInverterAndOptions() {
        let c = Fixture.small
        let b = 10.scaledDp().screen(.smallWidth, 500, customValue: 20, finalQualifierResolver: .height)
        XCTAssertEqual(b.sdp(c), 20.hdp(c), accuracy: 1e-12)
        XCTAssertEqual(10.scaledDp().applyAspectRatio().sdp(c), 10.sdpa(c), accuracy: 1e-12)
        XCTAssertEqual(10.scaledDp().ignoreMultiWindows().sdp(Fixture.split), 10)
        XCTAssertEqual(10.scaledDp().sdpPx(c), 10.sdpPx(c), accuracy: 1e-12)
        XCTAssertEqual(10.scaledDp().hdp(c), 10.hdp(c), accuracy: 1e-12)
    }

    func testTextBuilders() {
        let c = Fixture.small
        XCTAssertEqual(16.scaledSp().ssp(c), 16.ssp(c), accuracy: 1e-12)
        XCTAssertEqual(16.scaledSp().sem(c), 16.sem(c), accuracy: 1e-12)
        XCTAssertEqual(16.scaledSp().screen(.smallWidth, 500, customValue: 20, fontScale: false).ssp(c), 20.sem(c), accuracy: 1e-12)
        XCTAssertEqual(16.scaledSp(fontScale: false).ssp(c), 16.sem(c), accuracy: 1e-12)
    }

    func testSatelliteBuilders() {
        let c = Fixture.small
        XCTAssertEqual(16.powerDp().sdp(c), 16.pwsdp(c), accuracy: 1e-12)
        XCTAssertEqual(16.powerScaledDp().hdp(c), 16.pwhdp(c), accuracy: 1e-12)
        XCTAssertEqual(16.powerSp().ssp(c), 16.pwssp(c), accuracy: 1e-12)
        XCTAssertEqual(16.autoDp().screen(.portrait, customValue: 20).sdp(c), 20.asdp(c), accuracy: 1e-12)
        XCTAssertEqual(16.dimen(.fluid).sdp(c), AppDimens.fluidDp(16, configuration: c), accuracy: 1e-12)
        withAmbient(c) {
            XCTAssertEqual(Double(16.powerDp().sdp), 16.pwsdp(c), accuracy: 1e-12)
        }
    }
}
