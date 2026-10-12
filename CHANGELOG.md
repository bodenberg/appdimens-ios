# Changelog

## 3.2.0 — Android 3.2 parity, zero-argument API, production hardening

### Fixed
- `Inverter.default` no longer swaps height and width in landscape: `hdp`/`wdp` always use the window axis, exactly like Android (`DEFAULT -> Unit`).
- Invalid configuration inputs (zero, negative, NaN, infinite) are normalized to the design reference instead of trapping.
- The SwiftUI provider measures the full window (safe-area and keyboard insets added back), so showing the keyboard no longer rescales the interface.

### Added
- Compose-style zero-argument accessors on every number: `16.sdp`, `16.ssp`, `16.pwsdp`, `25.spaceW` … backed by a thread-safe ambient window snapshot (`AppDimens.configuration`, `update`, `observe`, `configurationVersion`).
- Swift Observation integration: on iOS 17 / macOS 14 / tvOS 17 / watchOS 10 / visionOS, SwiftUI bodies reading `16.sdp` re-evaluate on window changes.
- `AppDimens.startAutomaticUpdates()` for UIKit (tracker view + scene/orientation/Dynamic Type notifications) and AppKit (key-window tracking).
- Android-faithful builders: `scaledDp()`, `scaledSp()`, `<strategy>Dp()`, `<strategy>Sp()`, `<strategy>ScaledDp()`, `dimen(_:)` with priority 1–4 resolution, `finalQualifierResolver`, per-entry inverter and font scale.
- Facilitators with Android signatures for every family and satellite: `Rotate`, `Mode`, `Qualifier`, `Screen` + `Px`, `Plain`, `PlainPx`.
- Android `Px` spellings (`sdpPxPh`, `sspPxa` …) and pixel variants for every inverter.
- Percent `space` family with ambient, `i`, `Px`, `Sp` variants; Android-named physical unit conversions (`toDpFromMm` …, `radiusFromCircumference`) and ambient `5.mm`.
- Metal: 96-byte uniforms with every strategy factor, `metalSource` MSL helpers, `makeLibrary`, `setAppDimensUniforms` for render and compute encoders.
- `DimensFactors` covers every strategy, plus in-place buffer resolution.
- `UIFont.ssp/sem`, `NSFont.ssp`, `UiModeType.platformDefault`, `.appDimensConfiguration(_:)` for previews.
- Test suite: Android Float32 parity, concurrency (torn-read detection), Observation, builders, facilitators, Metal layout, performance. CI: Linux (Swift 5.10 / 6.1), Swift 6 language mode, release performance run, generated-catalog check.

### Changed
- All factors are precomputed once per window (`DimenMetrics`); kernels never evaluate `log`/`pow`/`sqrt` per call.
- Extensions target the `DimensNumber` protocol (all numeric types and `CGFloat`).
- See [Migration](Documentation/MIGRATION.md#from-31x-ios) for source changes from 3.1.x.

## 3.1.6 — complete direct port

- Ported the principal common/core/plain/scaled API with a stable window/scene configuration.
- Ported all Android satellite modules: auto, density, diagonal, fill, fit, fluid, interpolated, logarithmic, percent, perimeter, power, resize and units.
- Added aggregate `AppDimensDynamic` and Apple-specific `AppDimensMetal` products.
- Added automatic SwiftUI/UIKit window discovery and cross-module parity tests.
