import XCTest
import Foundation
import AppDimensDynamic
import AppDimensPower

/// Hot-path cost of the main entry points. Run in release for real numbers:
/// `swift test -c release --filter PerformanceTests`.
final class PerformanceTests: XCTestCase {
    static let iterations = 1_000_000

    func testExplicitConfigurationSdp() {
        let c = Fixture.tablet
        measure {
            var sum = 0.0
            for i in 0..<Self.iterations { sum += (i & 63).sdp(c) }
            XCTAssertTrue(sum.isFinite)
        }
    }

    func testAmbientSdp() {
        withAmbient(Fixture.tablet) {
            measure {
                var sum: CGFloat = 0
                for i in 0..<Self.iterations { sum += (i & 63).sdp }
                XCTAssertTrue(sum.isFinite)
            }
        }
    }

    func testAmbientAspectRatioSatellite() {
        withAmbient(Fixture.tablet) {
            measure {
                var sum: CGFloat = 0
                for i in 0..<Self.iterations { sum += (i & 63).pwsdpa }
                XCTAssertTrue(sum.isFinite)
            }
        }
    }

    func testPrecomputedFactors() {
        let factors = DimensFactors(Fixture.tablet)
        measure {
            var sum = 0.0
            for i in 0..<Self.iterations { sum += factors.resolve(Double(i & 63), strategy: .power) }
            XCTAssertTrue(sum.isFinite)
        }
    }

    func testConfigurationConstruction() {
        measure {
            var sum = 0.0
            for i in 0..<100_000 {
                sum += DimensConfiguration(screenWidth: Double(320 + (i & 255)), screenHeight: 800, displayScale: 3).metrics.powerScale
            }
            XCTAssertTrue(sum.isFinite)
        }
    }
}
