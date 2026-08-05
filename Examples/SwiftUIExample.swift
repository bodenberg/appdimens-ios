import SwiftUI
import AppDimensUI

struct ExampleCard: View {
    @DynamicDimension(16) private var spacing
    @DynamicDimension(120, strategy: .fit) private var width

    var body: some View {
        AppDimensProvider(mode: .phone) {
            VStack(spacing: spacing) {
                Text("AppDimens Dynamic").font(.headline)
                RoundedRectangle(cornerRadius: spacing).frame(width: width, height: 48)
            }.dynamicPadding(16)
        }
    }
}
