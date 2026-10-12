#if canImport(UIKit) && os(iOS)
import XCTest
import UIKit
import SwiftUI
import AppDimensDynamic

/// Runs on the iOS Simulator: real UIWindow, real UIHostingController layout.
@MainActor
final class UIKitIntegrationTests: XCTestCase {
    private final class Probe: @unchecked Sendable { var values: [CGFloat] = [] }

    private struct ProbeView: View {
        let probe: Probe
        var body: some View {
            let value = 30.sdp                 // ambient, Observation-tracked
            probe.values.append(value)
            return Color.clear.frame(width: value, height: value)
        }
    }

    private func spin(_ seconds: TimeInterval = 0.2) {
        RunLoop.main.run(until: Date().addingTimeInterval(seconds))
    }

    override func tearDown() {
        AppDimens.update(.reference)
        AppDimens.observationTrackingEnabled = false
        super.tearDown()
    }

    func testRefreshFromViewReadsItsWindow() {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        let child = UIView(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
        window.addSubview(child)
        AppDimens.refresh(from: child)
        XCTAssertEqual(AppDimens.configuration.screenWidth, 390, "window bounds, not the child view")
        XCTAssertEqual(AppDimens.configuration.screenHeight, 844)
        XCTAssertEqual(Double(16.sdp), 16 * 1.3, accuracy: 1e-9)
        XCTAssertEqual(Double(16.sdp(in: child)), 16 * 1.3, accuracy: 1e-9)

        window.frame = CGRect(x: 0, y: 0, width: 844, height: 390)
        AppDimens.refresh(from: child)
        XCTAssertEqual(AppDimens.configuration.orientation, .landscape)
        XCTAssertEqual(Double(48.hdp), 48 * 390 / 300, accuracy: 1e-9)
        XCTAssertGreaterThan(UIFont.ssp(16).pointSize, 0)
    }

    func testSwiftUIProviderPublishesWindowAndReRendersOnRotation() throws {
        let probe = Probe()
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        let host = UIHostingController(rootView: ProbeView(probe: probe).appDimens())
        window.rootViewController = host
        window.isHidden = false
        host.view.frame = window.bounds
        host.view.setNeedsLayout(); host.view.layoutIfNeeded()
        spin()

        XCTAssertEqual(AppDimens.configuration.screenWidth, 390, accuracy: 0.5, "provider measures the full window")
        XCTAssertEqual(AppDimens.configuration.screenHeight, 844, accuracy: 0.5)
        XCTAssertTrue(AppDimens.observationTrackingEnabled, "installing the provider enables tracking")
        let portrait = try XCTUnwrap(probe.values.last)
        XCTAssertEqual(Double(portrait), 30 * 1.3, accuracy: 0.01)

        // "Rotate": same smallest side keeps sdp; grow the window to an iPad size instead.
        window.frame = CGRect(x: 0, y: 0, width: 1024, height: 768)
        host.view.frame = window.bounds
        host.view.setNeedsLayout(); host.view.layoutIfNeeded()
        spin(0.5)
        host.view.layoutIfNeeded()
        spin(0.2)

        XCTAssertEqual(AppDimens.configuration.screenWidth, 1024, accuracy: 0.5)
        XCTAssertEqual(AppDimens.configuration.orientation, .landscape)
        if #available(iOS 17, *) {
            let resized = try XCTUnwrap(probe.values.last)
            XCTAssertEqual(Double(resized), 30 * 768 / 300, accuracy: 0.01,
                           "body reading 16.sdp re-evaluated automatically (Observation)")
        }
        window.isHidden = true
    }
}
#endif
