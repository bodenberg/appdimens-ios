import XCTest
import Foundation
import AppDimensDynamic
import AppDimensPower
import AppDimensPercent
#if canImport(Observation)
import Observation
#endif

/// Zero-argument (Compose-style) accessors backed by the ambient window.
final class AmbientTests: XCTestCase {
    func testZeroArgumentAccessorsMatchExplicitConfiguration() {
        let c = Fixture.tablet
        withAmbient(c) {
            XCTAssertEqual(Double(16.sdp), 16.sdp(c))
            XCTAssertEqual(Double(16.hdp), 16.hdp(c))
            XCTAssertEqual(Double(16.wdp), 16.wdp(c))
            XCTAssertEqual(Double(16.ssp), 16.ssp(c))
            XCTAssertEqual(Double(16.sem), 16.sem(c))
            XCTAssertEqual(Double(16.sdpa), 16.sdpa(c))
            XCTAssertEqual(Double(16.sdpPx), 16.sdpPx(c))
            XCTAssertEqual(Double(16.hdpLw), 16.hdpLw(c))
            XCTAssertEqual(Double(16.pwsdp), 16.pwsdp(c))
            XCTAssertEqual(Double(16.pwssp), 16.pwssp(c))
            XCTAssertEqual(Double(1.5.sdp), 1.5.sdp(c))
            XCTAssertEqual(Double(CGFloat(8).sdp), 8.sdp(c))
            XCTAssertEqual(Double(25.spaceW), 25.spaceW(c))
            XCTAssertEqual(AppDimens.configuration, c)
        }
    }

    func testAllNumericReceivers() {
        withAmbient(Fixture.small) {
            let expected = 16.sdp(Fixture.small)
            XCTAssertEqual(Double(Int8(16).sdp), expected)
            XCTAssertEqual(Double(UInt(16).sdp), expected)
            XCTAssertEqual(Double(Int64(16).sdp), expected)
            XCTAssertEqual(Double(Float(16).sdp), expected)
            XCTAssertEqual(Double(Double(16).sdp), expected)
            XCTAssertEqual(Double(CGFloat(16).sdp), expected)
        }
    }

    func testUpdateIsIdempotentAndVersioned() {
        withAmbient(Fixture.phone) {
            let v0 = AppDimens.configurationVersion
            XCTAssertFalse(AppDimens.update(Fixture.phone), "same configuration is not a change")
            XCTAssertEqual(AppDimens.configurationVersion, v0)
            XCTAssertTrue(AppDimens.update(Fixture.phoneLandscape))
            XCTAssertEqual(AppDimens.configurationVersion, v0 &+ 1)
            XCTAssertEqual(DimensConfiguration.current, Fixture.phoneLandscape, "legacy static alias forwards to the ambient store")
        }
    }

    func testObserversAreNotifiedAndCancelled() {
        withAmbient(Fixture.phone) {
            final class Box: @unchecked Sendable { var values: [DimensConfiguration] = [] }
            let box = Box()
            var token: AppDimensObservation? = AppDimens.observe { box.values.append($0) }
            AppDimens.update(Fixture.tablet)
            AppDimens.update(Fixture.tablet)
            XCTAssertEqual(box.values, [Fixture.tablet])
            token?.cancel()
            AppDimens.update(Fixture.wide)
            XCTAssertEqual(box.values.count, 1)
            token = AppDimens.observe { box.values.append($0) }
            token = nil // deallocation cancels too
            AppDimens.update(Fixture.small)
            XCTAssertEqual(box.values.count, 1)
            _ = token
        }
    }

    func testRotationChangesAmbientValues() {
        withAmbient(Fixture.phone) {
            let portraitHeight = 48.hdp
            AppDimens.update(Fixture.phoneLandscape)
            XCTAssertNotEqual(48.hdp, portraitHeight)
            do { let expected: Double = 48 * 390 / 300; XCTAssertEqual(Double(48.hdp), expected, accuracy: 1e-9) }
            do { let expected: Double = 16 * 1.3; XCTAssertEqual(Double(16.sdp), expected, accuracy: 1e-9, "sdp is rotation-invariant") }
        }
    }

    func testConcurrentReadsAndWritesAreCoherent() {
        let a = Fixture.phone, b = Fixture.tablet
        let validA = 16.sdpa(a), validB = 16.sdpa(b)
        withAmbient(a) {
            DispatchQueue.concurrentPerform(iterations: 8) { worker in
                for i in 0..<20_000 {
                    if worker == 0 && i % 10 == 0 {
                        AppDimens.update(i % 20 == 0 ? a : b)
                    } else {
                        let value = Double(16.sdpa)
                        // A torn read would produce a value from neither window.
                        XCTAssertTrue(value == validA || value == validB, "torn read: \(value)")
                    }
                }
            }
        }
    }

    func testWithConfigurationAllowsReentrancy() {
        withAmbient(Fixture.small) {
            let nested = AppDimens.withConfiguration { c in Double(16.sdp) + 16.sdp(c) }
            XCTAssertEqual(nested, 2 * 16.sdp(Fixture.small))
        }
    }

    #if canImport(Observation)
    func testObservationTrackingFiresOnChange() throws {
        guard #available(iOS 17, macOS 14, tvOS 17, watchOS 10, visionOS 1, *) else { throw XCTSkip("Observation unavailable") }
        let previous = AppDimens.observationTrackingEnabled
        AppDimens.observationTrackingEnabled = true
        defer { AppDimens.observationTrackingEnabled = previous }
        withAmbient(Fixture.phone) {
            final class Flag: @unchecked Sendable { var fired = false }
            let flag = Flag()
            withObservationTracking { _ = 16.sdp } onChange: { flag.fired = true }
            AppDimens.update(Fixture.tablet)
            XCTAssertTrue(flag.fired, "reading 16.sdp registers an Observation dependency (SwiftUI auto-invalidation)")
        }
        AppDimens.observationTrackingEnabled = false
        withAmbient(Fixture.phone) {
            final class Flag: @unchecked Sendable { var fired = false }
            let flag = Flag()
            withObservationTracking { _ = 16.sdp } onChange: { flag.fired = true }
            AppDimens.update(Fixture.wide)
            XCTAssertFalse(flag.fired, "tracking disabled → no dependency, no overhead")
        }
    }
    #endif
}
