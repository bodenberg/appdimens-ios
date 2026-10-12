# Migration

[Documentation hub](README.md) · [API](API.md)

## From Android

| Android | Apple |
|---|---|
| `implementation("io.github.bodenberg:appdimens-dynamic")` | product `AppDimens` (or `AppDimensDynamic`) |
| `appdimens-dynamic-<strategy>` | product `AppDimens<Strategy>` |
| `AppDimensProvider { App() }` | `AppDimensProvider { ContentView() }` / `.appDimens()` |
| `16.sdp` (`Dp`) | `16.sdp` (`CGFloat` points) |
| `16.ssp` (`TextUnit`) | `.font(.system(size: 16.ssp))` |
| `16.sdp(context)` (px) | `16.sdpPx` or `16.sdp(configuration)` (points) |
| `LocalConfiguration.current` | `@Environment(\.appDimensConfiguration)` |
| `DimenCache.invalidateOnConfigChange` | not needed — snapshots are values; UIKit: `AppDimens.startAutomaticUpdates()` |
| `UiModeType.TELEVISION` | `.television` |
| `Orientation.LANDSCAPE` | `.landscape` |
| `DpQualifier.SMALL_WIDTH` | `.smallWidth` |
| `Inverter.SW_TO_LH` | `.swToLh` |
| `30.sdpMode(200, UiModeType.TELEVISION)` | `30.sdpMode(200, .television)` |
| `16.sdpQualifier(24, DpQualifier.SMALL_WIDTH, 600)` | `16.sdpQualifier(24, .smallWidth, 600)` |
| `16.scaledDp().screen(UiModeType.TELEVISION, 40)` | `16.scaledDp().screen(.television, customValue: 40)` |
| `16.scaledDp().screen(DpQualifier.SMALL_WIDTH, 600, 24)` | `16.scaledDp().screen(.smallWidth, 600, customValue: 24)` |
| `25.spaceW` | `25.spaceW` |

## From 3.1.x (iOS)

* **`hdp`/`wdp` in landscape:** 3.1.x swapped height→width for `Inverter.default` in landscape; Android never does. `hdp` now always uses the window height. Use `hdpLw` for the swap.
* Builders are functions, as on Android: `16.scaledDp` → `16.scaledDp()`, `16.scaledSp` → `16.scaledSp()`, `16.autoScaledDp` → `16.autoDp()` / `16.autoScaledDp()`, `16.autoSp` → `16.autoSp()`. `AutoCondition` is replaced by the `screen(…)` overloads; `.rotate`, `.mode`, `.qualifier` and `.screen(_:qualifier:minimum:)` remain as shorthands. Resolution now follows Android priorities 1–4.
* Facilitators use Android argument order: `16.sdpMode(200, .television, c)`, `16.sdpRotate(50, orientation: .portrait, c)`, `16.sdpQualifier(24, .width, 600, c)`, `16.sdpScreen(24, .television, .width, 600, c)`; they gained `finalQualifierResolver`, `ignoreMultiWindows`, `applyAspectRatio`, `customSensitivityK` (and `fontScale` for text).
* `DimensConfiguration.current` is now the ambient snapshot (`AppDimens.configuration`); invalid inputs are normalized instead of trapping.
* `DimensStrategy` moved to the core module (still re-exported by `AppDimensStrategies`).
* `16.sdp(in: view)` requires a non-optional view; use `16.sdp` for the key window.
* Metal uniforms grew from 64 to 96 bytes; update `.metal` struct declarations from `AppDimensUniforms.metalSource`.
* Literal-percent `spaceW`/`spaceH`/`spaceSw`/`space` moved to `AppDimensPercent` (Android module), and gained ambient variants.
* Extensions moved from `BinaryInteger`/`BinaryFloatingPoint` to `DimensNumber` (all standard numeric types and `CGFloat` conform).
