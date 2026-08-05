# AppDimens documentation

## Documentation map

1. [Installation and first use](../README.md#install-from-github-with-xcode)
2. [Complete API](API.md)
3. [Architecture and scaling mathematics](ARCHITECTURE.md)
4. [Migration from Android](MIGRATION_ANDROID.md)
5. [Examples](../Examples)

## Recommended workflow

1. Design against a reference canvas (default `360 × 800` points).
2. Declare reusable values as `DynamicDimension`, rather than resolving them early.
3. Install `.appDimens()` at the SwiftUI root or construct a `DimensionContext` from the actual UIKit view.
4. Prefer `.balanced` for spacing and decoration; `.none` for values that Apple already adapts; `.linear` only when exact proportional scaling is intended.
5. Use qualifiers for layout discontinuities (phone/tablet, compact/regular), not for every device model.
6. Keep minimum tap targets and validate every Dynamic Type accessibility category.

## Common declarations

```swift
let spacing = 16.dynamic
let hero = 240.dynamic.screen(.width).strategy(.linear).limits(max: 420)
let sidebar = 320.dynamic.strategy(.none).when(.horizontalSizeClass(.compact), 0)
let title = 24.dynamic // resolve with text: true
```

The declaration is cheap and reusable. Resolution happens through `points(in:text:)`; it never reads global application state.
