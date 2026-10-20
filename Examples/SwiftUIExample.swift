import SwiftUI
import AppDimensDynamic
import AppDimensPower
import AppDimensCustom

// Your own strategy (same JSON shape on every AppDimens platform).
let brand = try! ScalingStrategy.define("brand",
    reference: ReferenceScreen(width: 360, height: 640),
    curve: .power(0.8), minFactor: 0.85, maxFactor: 1.6,
    rules: [.on([.tablet, .desktop], ScalingPatch(curve: .logarithmic(0.4)), name: "large")])

// Install once per window: WindowGroup { ExampleView().appDimens() }
struct ExampleView: View {
    // Per-window values (multi-window safe on every OS version)
    @ScaledDimension(16) private var spacing
    @ScaledDimension(text: 20) private var titleSize
    @Environment(\.appDimensConfiguration) private var dimens

    private let cardPadding = 16.scaledDp()
        .screen(.smallWidth, 600, customValue: 24)
        .screen(.television, customValue: 40)

    var body: some View {
        VStack(alignment: .leading, spacing: spacing) {
            Text("AppDimens").font(.system(size: titleSize, weight: .bold))
            Text("Compose-style accessors").font(.system(size: 16.ssp))   // auto-invalidates on iOS 17+
            HStack(spacing: 8.sdp) {
                ForEach(0..<3) { _ in
                    RoundedRectangle(cornerRadius: 12.sdp)
                        .frame(width: 64.pwsdp, height: 64.pwsdp)              // power curve
                }
            }
            Text("Tablet-only copy")
                .font(.system(size: 14.sspQualifier(18, .smallWidth, 600)))
            Text("Custom strategy")
                .font(.system(size: 14.csp(brand)))                        // your own curve
                .padding(8.cdp(brand))
        }
        .padding(cardPadding.sdp(dimens))
        .frame(maxWidth: 480.wdp(dimens))
    }
}
