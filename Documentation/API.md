# API reference

## Modules

- `AppDimens`: platform-neutral calculation engine, declarations, context, qualifiers and numeric conveniences.
- `AppDimensUI`: SwiftUI environment/property wrapper/modifiers and UIKit context construction.

## Creation

```swift
AppDimens.dynamic(16)
AppDimens.dy(16)
16.dynamic
16.dy
AppDimens.fixed(1)
1.fixed
```

`DynamicDimension` scales. `FixedDimension` remains constant in points but rounds to the physical pixel grid.

## Fluent declaration

All functions return a modified copy.

- `.reference(width:height:)`: design canvas.
- `.screen(_:)`: `.lowest`, `.highest`, `.width`, or `.height` axis.
- `.strategy(_:)`: `.balanced` (default), `.linear`, `.clamped`, or `.none`.
- `.configured(_:)`: replace the complete configuration.
- `.limits(min:max:)`: final absolute point limits.
- `.when(_:_:)`: override source value when a qualifier matches.
- `.when([qualifiers], value)`: AND/intersection of qualifiers.

Overrides are evaluated in declaration order and the **last matching override wins**. The selected override is still scaled. Use `.strategy(.none)` for literal breakpoint values.

## Context

`DimensionContext` includes container width/height, display scale, Dynamic Type scale, idiom and optional size classes. Create it explicitly in tests and non-UI code. In SwiftUI, `AppDimensProvider` creates it reactively. In UIKit, use `DimensionContext.current(for:)` on the main actor.

## Qualifiers

- Width: `.minWidth`, `.maxWidth`
- Height: `.minHeight`, `.maxHeight`
- Shortest side: `.minShortestSide`, `.maxShortestSide`
- Orientation: `.orientation(.portrait/.landscape)`
- Platform idiom: `.idiom(.phone/.pad/.mac/.tv/.watch/.vision/.carPlay)`
- Size classes: `.horizontalSizeClass`, `.verticalSizeClass`

Unlike Android resource folders, these conditions are typed and composable.

## Resolution

```swift
value.points(in: context)
value.points(in: context, text: true)
value.pixels(in: context)
```

Use points for SwiftUI and UIKit layout. Pixels are for rasterization, bitmap buffers, or APIs explicitly requiring physical pixels. `text: true` applies `dynamicTypeScale` only when `fontScaling == .system`.

## SwiftUI

- `.appDimens()` installs the responsive environment.
- `@AppDimension(...)` resolves a value whenever environment geometry or Dynamic Type changes.
- `.dynamicPadding(...)` / `.dyPadding(...)` resolve padding.
- `.dynamicFrame(...)` / `.dyFrame(...)` resolve frames.

## Utilities

`AppDimens.percentage(_:of:in:)` clamps the percentage to `0...1`. `AppDimens.availableItemCount(container:item:spacing:)` computes a safe non-negative item count.
