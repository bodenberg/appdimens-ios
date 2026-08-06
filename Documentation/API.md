# API reference

## Core types

### `DimensConfiguration`

A `Hashable`, `Sendable` snapshot of one Apple window/scene. Geometry is expressed in points.

| Member | Meaning |
|---|---|
| `screenWidth`, `screenHeight` | current window size |
| `smallestScreenWidth` | minimum of width and height |
| `displayScale` | physical pixels per point |
| `fontScale` | Dynamic Type multiplier |
| `uiMode` | Apple adaptation of Android `UiModeType` |
| `maximumWindowWidth/Height` | display bounds used for multi-window detection |
| `orientation`, `aspectRatio`, `isMultiWindow` | derived values |

Use `.current(in:)` in UIKit or `.appDimens()` at the SwiftUI scene root. Construct it manually only for tests, previews, headless code, or renderers.

### Qualifiers

- `.smallWidth`: Android `SMALL_WIDTH`.
- `.width`: current window width.
- `.height`: current window height.

### Inverters

All Android mappings are present: `.phToLw`, `.pwToLh`, `.lhToPw`, `.lwToPh`, `.swToLh`, `.swToLw`, `.swToPh`, `.swToPw`, and `.default`.

## Principal numeric API

```swift
16.sdp(configuration)
16.sdpa(configuration)
16.sdpi(configuration)
16.sdpia(configuration)
16.wdp(configuration)
16.hdp(configuration)
16.ssp(configuration)
16.hsp(configuration)
16.wsp(configuration)
16.sem(configuration)
16.hem(configuration)
16.wem(configuration)
```

Suffixes match Android semantics:

| Suffix | Behavior |
|---|---|
| none | regular scaling |
| `a` | aspect-ratio correction |
| `i` | return the base value in multi-window |
| `ia` | both flags |

## Branch helpers

`AppDimensPlain.rotate/mode/qualifier/screen` selects a raw value without scaling. `AppDimens.rotate`, `.qualified`, and `.mode` select then apply principal scaling.

## Builders

`ScaledDp` is immutable and supports `.screen`, `.mode`, `.rotate`, `.aspectRatio`, `.ignoreMultiWindows`, and `.resolve`.

`AutoDp` resolves conditions by specificity (mode > qualifier > orientation), then threshold and declaration order. `AutoSp` adds optional Dynamic Type scaling.

## Strategy API

```swift
DynamicDimens.resolve(16, strategy: .power, configuration: config)
16.dynamic(.power, config)
16.powerDp(config)
```

`StrategyOptions` configures qualifier, inverter, aspect correction, multi-window, sensitivity, percentage, exponent, interpolation, and fluid ranges.

## Resize

- `ResizeBound.fixedDp`
- `ResizeBound.fixedSp`
- `ResizeBound.percent`
- `DimensResize.steps`
- `DimensResize.largestFitting`

The predicate passed to binary search must be monotonic.

## Units

`DimensUnits.points` and `.pixels` support inch, centimeter, millimeter, point, and pixel. Supply PPI for physically accurate pixel conversion; `displayScale` is not PPI.
