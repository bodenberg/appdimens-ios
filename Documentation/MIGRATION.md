# Android → Apple migration

[Documentation hub](README.md) · [API](API.md)

| Android AppDimens Dynamic | Swift / SwiftUI / UIKit |
|---|---|
| `Configuration` | `DimensConfiguration` |
| `DpQualifier.SMALL_WIDTH` | `.smallWidth` |
| `16.sdp` | `16.sdp(configuration)` or `@ScaledDimension var value: CGFloat = 16` |
| `16.hdp` / `16.wdp` | `16.hdp(configuration)` / `16.wdp(configuration)` |
| `16.ssp` | `16.ssp(configuration)` |
| `scaledDp { … }` | `16.scaledDp.screen(...).rotate(...).resolve(configuration)` |
| Compose provider | `AppDimensProvider { … }` |
| Android window mode | active `UIWindowScene` / SwiftUI root container |
| density | points + `displayScale` only when pixel-aware behavior is requested |

## The invariant

Install one provider at the scene root. Do not calculate from each child view. UIKit helpers use a view only to locate its `UIWindowScene`; child bounds never become the global scaling baseline.

## Deliberate Apple adaptations

Dynamic Type replaces Android font scale. Window scenes replace a process-global display. Points replace density-independent pixels. These adaptations preserve behavior while respecting multi-window iPadOS, Stage Manager and visionOS.
