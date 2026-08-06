# SwiftUI and UIKit integration

## SwiftUI

Install exactly once at the `WindowGroup` root:

```swift
@main struct DemoApp: App {
    var body: some Scene {
        WindowGroup { ContentView().appDimens() }
    }
}
```

The provider observes window geometry, display scale, and Dynamic Type. Descendants consume the shared configuration:

```swift
struct Card: View {
    @ScaledDimension(16) private var spacing
    @ScaledDimension(320, .width) private var width
    @ScaledDimension(text: 17) private var text

    var body: some View {
        VStack(spacing: spacing) { Text("Title").font(.system(size: text)) }
            .frame(maxWidth: width)
    }
}
```

Do not install a provider around each card: principal dimensions are window-relative, not view-relative.

## UIKit

```swift
@MainActor
func layout(_ child: UIView) {
    child.layer.cornerRadius = 12.sdp(in: child)
    let config = DimensConfiguration.current(in: child)
    let width = 100.wdp(config)
}
```

The child is used only to locate its `UIWindowScene`; `child.bounds` never changes global scaling. Re-resolve after scene resize, rotation, display move, or content-size-category change.

## Multi-window

On iPad Split View and Stage Manager, the active window is the Android `Configuration` equivalent. The physical display is used only to detect a constrained window. This guarantees consistency within a scene while adapting between scenes.
