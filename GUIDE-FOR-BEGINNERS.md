# Beginner's guide

## 1. Add the package in Xcode
Open **File → Add Package Dependencies…**, enter `https://github.com/bodenberg/appdimens-ios`, select the exact version `3.1.6`, and add **AppDimensDynamic** to the app target.

## 2. Install once
```swift
import SwiftUI
import AppDimensDynamic

@main struct ExampleApp: App {
    var body: some Scene { WindowGroup { ContentView().appDimens() } }
}
```

## 3. Consume automatic values
```swift
struct ContentView: View {
    @ScaledDimension private var gap: CGFloat = 16
    @ScaledDimension(text: 17) private var title: CGFloat
    var body: some View {
        VStack(spacing: gap) { Text("AppDimens").font(.system(size: title)) }
            .padding(gap)
    }
}
```

## 4. Pick the right axis
Use smallest width for general spacing, `wdp` for width-driven compositions, and `hdp` for vertical rhythm. Start with scaled; change strategy only after visual QA.

## 5. Test representative windows
Validate portrait, landscape, iPad Split View, Stage Manager, large Dynamic Type, and the 300-point baseline. See [documentation hub](Documentation/README.md).
