# API reference

[Documentation hub](README.md) · [Apple integration](APPLE-INTEGRATION.md) · [Strategies](STRATEGIES.md) · [Metal](METAL.md)

Every accessor exists in two forms on any number (`Int`, `Double`, `Float`, `CGFloat`, all fixed-width integers — protocol `DimensNumber`):

| Form | Example | Returns | Window |
|---|---|---|---|
| Ambient (Compose style) | `16.sdp` | `CGFloat` points | `AppDimens.configuration` (set by the provider / updaters) |
| Explicit (Android `code` style) | `16.sdp(configuration)` | `Double` points | the configuration you pass |

## Window configuration

```swift
public struct DimensConfiguration: Hashable, Sendable {
    init(screenWidth: Double, screenHeight: Double, displayScale: Double = 1, fontScale: Double = 1,
         uiMode: UiModeType = .undefined, maximumWindowWidth: Double? = nil,
         maximumWindowHeight: Double? = nil, isInMultiWindowMode: Bool? = nil)
    let metrics: DimenMetrics            // every factor, precomputed
    var smallestScreenWidth, aspectRatio, densityDpi: Double
    var orientation: Orientation         // .portrait / .landscape
    var isMultiWindow: Bool              // explicit flag or window < 95 % of the screen
    func dimension(_ q: DpQualifier, inverter: Inverter = .default) -> Double
    static let reference                 // 300 × 533, @1x
}
```

Platform constructors: `DimensConfiguration.current(in: UIView?)`, `.current(window: UIWindow?)`, `.current(window: NSWindow?)`, `.current(in: NSView?)` (all `@MainActor`).

## Ambient store

| API | Description |
|---|---|
| `AppDimens.configuration` | current snapshot (thread-safe) |
| `AppDimens.update(_:) -> Bool` | replace it (any thread); `false` if unchanged |
| `AppDimens.observe { c in } -> AppDimensObservation` | change callbacks; cancel or release the token to stop |
| `AppDimens.configurationVersion` | monotonic change counter |
| `AppDimens.withConfiguration { c in }` | one coherent snapshot for several values |
| `AppDimens.observationTrackingEnabled` | Swift Observation registration (auto-enabled by `AppDimensProvider`) |
| `AppDimens.startAutomaticUpdates(uiMode:)` / `stopAutomaticUpdates()` | UIKit / AppKit window tracking |
| `AppDimens.refresh(from:)` | re-read one view / window |

## Scaled catalog (module `AppDimens`)

| Family | Axis | Font scale | Inverter variants |
|---|---|---|---|
| `sdp` | smallest width | — | `Ph`, `Lh`, `Pw`, `Lw` |
| `hdp` | height | — | `Lw` (`phToLw`), `Pw` (`lhToPw`) |
| `wdp` | width | — | `Lh` (`pwToLh`), `Ph` (`lwToPh`) |
| `ssp` / `hsp` / `wsp` | as above | × Dynamic Type | same as dp families |
| `sem` / `hem` / `wem` | as above | ignored | same as dp families |
| `sei` / `hei` / `wei` | as above | ignored, **pixels** | — |

Suffixes: `a` aspect ratio, `i` ignore multi-window, `ia` both, `Px` pixels — e.g. `sdpLwia`, `sspaPx`; Android spellings `sdpPxaPh`, `sspPxia` are also available.

Facilitators for `sdp hdp wdp ssp hsp wsp` (`Px`, `Plain` and `PlainPx` variants, ambient or with a trailing configuration):

```swift
func sdpRotate(_ rotationValue: Double, finalQualifierResolver: DpQualifier = .smallWidth,
               orientation: Orientation = .landscape, ignoreMultiWindows: Bool = false,
               applyAspectRatio: Bool = false, customSensitivityK: Double? = nil) -> CGFloat
func sdpMode(_ modeValue: Double, _ uiModeType: UiModeType, finalQualifierResolver: DpQualifier? = nil, …)
func sdpQualifier(_ qualifiedValue: Double, _ qualifierType: DpQualifier, _ qualifierValue: Double, …)
func sdpScreen(_ screenValue: Double, _ uiModeType: UiModeType, _ qualifierType: DpQualifier, _ qualifierValue: Double, …)
// text families add `fontScale: Bool = true`
```

`Plain` variants treat the receiver as an already-resolved length: it passes through unchanged when the condition does not match.

## Builders

`16.scaledDp()`, `16.scaledSp(fontScale:)`, `16.<strategy>Dp()`, `16.<strategy>Sp()`, `16.<strategy>ScaledDp()`, `16.dimen(_ strategy:)`, `16.dimenSp(_:)` → `DimenBuilder` (aliases `DimenScaled`, `ScaledDp`, `ScaledSp`, `DimenPower`, `DimenAuto` …).

```swift
.screen(_ mode: UiModeType, _ qualifier: DpQualifier, _ minimum: Double, customValue:, finalQualifierResolver:, orientation:, inverter:, fontScale:) // priority 1
.screen(_ mode: UiModeType, customValue:, …)                                   // priority 2
.screen(_ qualifier: DpQualifier, _ minimum: Double, customValue:, …)          // priority 3
.screen(_ orientation: Orientation, customValue:, …)                           // priority 4
.applyAspectRatio(_:) .aspectRatio(_:sensitivityK:) .ignoreMultiWindows(_:) .customSensitivity(_:)
.sdp .hdp .wdp .ssp .hsp .wsp .sem .hem .wem .sdpPx .hdpPx .wdpPx   // ambient CGFloat
.sdp(c) … .resolve(c, qualifier:fontScale:) .px(c, qualifier:) .sdpHdpWdpPx(c)
```

## Kernels

`AppDimens.scaledDp`, `scaledSp`, `percentDp`, `powerDp`, `fluidDp`, `autoDp`, `densityDp`, `diagonalDp`, `perimeterDp`, `fillDp`, `fitDp`, `interpolatedDp`, `logarithmicDp`, `resolve(_:strategy:…)`, `sp(_:strategy:…)`, `toDynamicScaledDp`, `literalPercentOfScreenDp`, `literalPercentOfReferenceDp` — all take `(value, configuration:, qualifier:, inverter:, ignoreMultiWindows:, applyAspectRatio:, sensitivityK:)`.

## Strategies module

`DimensStrategy` (in core), `StrategyOptions`, `DynamicDimens.resolve`, `16.dynamic(.power)` / `16.dynamic(.power, c, options:)`, named `16.powerDp(c, options:)`…, and `DimensFactors` (per-window factor table: `resolve(_:strategy:)`, `resolve(&buffer, strategy:)`, `factor(_:)`).

## SwiftUI

`AppDimensProvider(uiMode:updatesAmbient:content:)`, `.appDimens(uiMode:updatesAmbient:)`, `.appDimensConfiguration(_:updatesAmbient:)`, `EnvironmentValues.appDimensConfiguration`, `@ScaledDimension(_:_:strategy:aspectRatio:ignoreMultiWindow:)`, `@ScaledDimension(text:…)` (projected value = the window configuration), `ContentSizeCategory.appDimensFontScale`.

## UIKit / AppKit

`16.sdp(in: view)` (+ `hdp`, `wdp`, `ssp`, `sem`), `UIFont.ssp(_:weight:)`, `UIFont.sem(_:weight:)`, `NSFont.ssp(_:weight:)`, `UIContentSizeCategory.appDimensFontScale`, `UiModeType.platformDefault`.

## Other modules

* Percent: `spaceW`, `spaceH`, `spaceSw` (+`i`, `Px`, `Pxi`, `Sp…`), `space(_ reference:)`, `spacePx`, explicit `spaceW(c)`.
* Units: `DimenPhysicalUnits.toDpFromMm/Cm/Inch`, `toPxFrom…`, `toSpFrom…`, `radiusFromDiameter`, `radiusFromCircumference`, `unitSizeInDp`, `devicePointsPerInch`, ambient `5.mm`, `1.cm`, `1.inch`, `mmPx`…, conversions `mmToCm()`….
* Resize: `ResizeBound` (`.fixedDp`, `.fixedSp`, `.percent`), `resizeFixedDp/Sp`, `resizePercentSw/W/H`, `DimensResize.steps`, `largestFitting`, `autoResizeText`, `autoResizeTextPercent`, `autoResizeSquareSize`, `autoResizeSize`.
* Metal: see [Metal](METAL.md).

## AppDimensCustom

* **Define:** `ScalingStrategy.define(_:extending:reference:axis:curve:multiplier:minFactor:maxFactor:minValue:maxValue:aspectRatio:sensitivity:fontScale:ignoreMultiWindow:transform:rules:register:) throws`, or `ScalingStrategy(_:config:) throws`.
* **Model:** `ScalingConfig`, `ScalingPatch`, `ScalingRule` (`.on(_:_:name:)`), `ScreenCondition`, `ScalingCurve` (`.linear`, `.power`, `.logarithmic`, `.interpolated`, `.constant`, `.breakpoints`, `.custom`), `FontScalePolicy`, `ReferenceScreen`, `ScalingAxis`, `DeviceClass`, `ScreenSnapshot`.
* **Strategy:** `resolve(_:)` / `resolve(screen:)` → `ResolvedScaling` (`factor`, `appliedRules`, `scale`, `scaleSpDp`, `explain`). Also `factor`, `dp`, `px`, `sp`, `spPx`, `explain`, `extend`, `withAxis`, `toJSON`.
* **Registry:**
  - `ScalingStrategies[id]`, `require(_:)`, `register`, `unregister`, `registered`.
  - `defaultStrategy`, `deviceClassResolver`.
  - `load(json:)`, `load(data:)`, `load(resource:bundle:)`, `exportJSON(_:)`.
* **Numbers:** `16.cdp`, `16.cdpPx`, `14.csp`, `14.cspPx` (default strategy, ambient), `16.cdp(c)`, `16.cdp(strategy)`, `16.cdp(strategy, c)`, `14.csp(strategy[, c])`, `cdpPx(strategy)`, `cspPx(strategy)`.
* **SwiftUI:** `@CustomDimension(_:strategy:)`, `@CustomDimension(text:strategy:)`, `.scalingStrategy(_:)`, `\.scalingStrategy`.
* **Presets / built-ins / JSON:** `CustomPresets.*`, `BuiltInStrategies.*`, `ScalingStrategyJSON.parse` / `encode` / `text`, `JSONValue`.
* Guide: [custom strategies](strategies/custom.md).
