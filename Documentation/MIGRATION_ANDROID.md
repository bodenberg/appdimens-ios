# Migration from AppDimens Dynamic Android

## Translation table

| Android-style intent | Swift |
|---|---|
| dynamic dimension | `16.dynamic` |
| choose smaller/larger axis | `.screen(.lowest)` / `.screen(.highest)` |
| `sw600dp` | `.when(.minShortestSide(600), value)` |
| `w600dp` / `h600dp` | `.minWidth(600)` / `.minHeight(600)` |
| portrait/landscape | `.orientation(.portrait/.landscape)` |
| combined qualifier | `.when([.idiom(.pad), .orientation(.landscape)], value)` |
| dp result | `.points(in: context)` |
| px result | `.pixels(in: context)` |
| sp result | `.points(in: context, text: true)` |

## Important behavior differences

Do not mechanically convert Android `dp` to iOS pixels. UIKit and SwiftUI consume points. Do not detect a specific iPhone model; use its container and traits. Do not resolve globally during app startup, because iOS can show multiple differently sized windows simultaneously.

Android mutable builder code should become an immutable declaration:

```swift
let cardPadding = 16.dynamic
    .when(.minShortestSide(600), 24)
    .when([.idiom(.pad), .orientation(.landscape)], 28)
```

Each call returns a new value, so sharing `cardPadding` cannot leak changes between screens.

## Typography

Prefer semantic SwiftUI fonts (`.body`, `.headline`) whenever possible. If a design requires a numeric custom size, resolve with `text: true` through `@AppDimension(..., text: true)` so accessibility remains effective. Geometry normally resolves with `text: false`.
