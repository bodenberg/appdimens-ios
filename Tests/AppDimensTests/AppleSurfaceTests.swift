#if canImport(SwiftUI)
import XCTest
import SwiftUI
import AppDimensDynamic
import AppDimensPower
#if canImport(AppKit) && !targetEnvironment(macCatalyst)
import AppKit
#endif

/// Compiles the SwiftUI-facing API exactly as documented (runs on Apple CI).
private struct SurfaceView: View {
    @ScaledDimension(16) private var spacing
    @ScaledDimension(48, .height, strategy: .power, aspectRatio: true) private var row
    @ScaledDimension(text: 18) private var title
    @Environment(\.appDimensConfiguration) private var dimens

    var body: some View {
        VStack(spacing: spacing) {
            Text("Title").font(.system(size: title))
            Text("Body").font(.system(size: 16.ssp))
            Rectangle().frame(width: 100.wdp, height: row)
            Rectangle().frame(width: CGFloat(80.sdpRotate(50, dimens)), height: 30.sdpMode(60, .television))
            Rectangle().frame(width: 16.scaledDp().screen(.smallWidth, 600, customValue: 24).sdp, height: 12.pwsdp)
        }
        .padding(16.sdp)
    }
}

final class AppleSurfaceTests: XCTestCase {
    @MainActor func testSwiftUISurfaceCompilesAndBuilds() {
        let fixed = DimensConfiguration(screenWidth: 390, screenHeight: 844, displayScale: 3)
        _ = SurfaceView().appDimens()
        _ = SurfaceView().appDimens(uiMode: .normal, updatesAmbient: false)
        _ = SurfaceView().appDimensConfiguration(fixed)
        _ = AppDimensProvider { SurfaceView() }
        XCTAssertEqual(ContentSizeCategory.large.appDimensFontScale, 1)
        _ = UiModeType.platformDefault
    }

    #if canImport(AppKit) && !targetEnvironment(macCatalyst)
    @MainActor func testAppKitSurface() {
        let c = DimensConfiguration.current(window: nil)
        XCTAssertGreaterThan(c.screenWidth, 0)
        AppDimens.startAutomaticUpdates()
        AppDimens.stopAutomaticUpdates()
        XCTAssertGreaterThan(NSFont.ssp(16).pointSize, 0)
    }
    #endif
}
#endif
