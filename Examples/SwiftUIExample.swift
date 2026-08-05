import SwiftUI
import AppDimens
import AppDimensUI

struct ResponsiveProfileCard: View {
    private let avatar = 72.dynamic.when(.minShortestSide(600), 96).limits(max: 120)
    @AppDimension(16.dynamic.when(.minWidth(600), 24)) private var spacing

    var body: some View {
        VStack(spacing: spacing) {
            Image(systemName: "person.crop.circle.fill").resizable().scaledToFit()
                .dynamicFrame(width: avatar, height: avatar)
            Text("AppDimens Dynamic").font(.headline)
        }
        .dynamicPadding(16.dynamic.when(.horizontalSizeClass(.regular), 24))
    }
}

// Install on the application root: ResponsiveProfileCard().appDimens()
