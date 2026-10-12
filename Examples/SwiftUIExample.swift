import SwiftUI
import AppDimensDynamic
import AppDimensPower

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
        }
        .padding(cardPadding.sdp(dimens))
        .frame(maxWidth: 480.wdp(dimens))
    }
}
