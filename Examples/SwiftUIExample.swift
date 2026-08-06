import SwiftUI
import AppDimens

struct ExampleView: View {
    @ScaledDimension(16) private var spacing
    var body: some View { VStack(spacing: spacing) { Text("AppDimens") } }
}
// Install once: ExampleView().appDimens()
