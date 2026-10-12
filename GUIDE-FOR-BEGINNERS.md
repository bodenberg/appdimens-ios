# Beginner's guide

If you know AppDimens on Android, you already know this library: `16.sdp`, `16.ssp`, `16.hdp` work the same way.

## 1. Add the package in Xcode
Open **File → Add Package Dependencies…**, enter `https://github.com/bodenberg/appdimens-ios`, choose **Up to Next Major** from `3.2.0`, and add **AppDimensDynamic** to the app target.

## 2. Install the provider once
```swift
import SwiftUI
import AppDimensDynamic

@main struct ExampleApp: App {
    var body: some Scene { WindowGroup { ContentView().appDimens() } }
}
```

UIKit apps call `AppDimens.startAutomaticUpdates()` once (for example in `scene(_:willConnectTo:options:)`).

## 3. Write dimensions like on Android
```swift
struct ContentView: View {
    var body: some View {
        VStack(spacing: 12.sdp) {
            Text("AppDimens").font(.system(size: 22.ssp, weight: .bold))
            Text("Responsive on every window").font(.system(size: 16.ssp))
        }
        .padding(16.sdp)
    }
}
```

`16.sdp` is 16 points on the 300-point design reference and grows with the smallest side of the window (20.8 pt on a 390-point-wide iPhone). `ssp` also follows the user's text-size setting; `sem` does not.

## 4. Pick the right axis
Use `sdp` (smallest width) for general spacing, `wdp` for width-driven compositions, and `hdp` for vertical rhythm. Start with the scaled strategy; try `pwsdp` (power) or `asdp` (auto) when tablets look too large.

## 5. Adapt to devices
```swift
30.sdpMode(60, .television)                       // bigger on Apple TV
16.sdpQualifier(24, .smallWidth, 600)             // 24 on iPads and large windows
80.sdpRotate(50)                                   // 50 in landscape
```

## 6. Test representative windows
Validate portrait, landscape, iPad Split View, Stage Manager, large Dynamic Type, and the 300-point baseline. In previews, pin a window with `.appDimensConfiguration(DimensConfiguration(screenWidth: 390, screenHeight: 844, displayScale: 3))`. See the [documentation hub](Documentation/README.md).
