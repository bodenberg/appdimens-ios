# Custom strategies (`AppDimensCustom`)

[Strategy catalog](../STRATEGIES.md) · [Mathematics](../MATHEMATICS-AND-CALCULUS.md#custom-strategies) · [API](../API.md#appdimenscustom)

**Product:** `AppDimensCustom` (depends on `AppDimens`) · Port of Android `appdimens-dynamic-custom`.

When none of the built-in curves fits, or one growth law must be shared by several apps and platforms, define **your own** strategy. The configuration is identical on every AppDimens platform (Android, KMP, Flutter, React Native, Web, Games, .NET) and can be loaded from JSON.

## What it computes

```
ratio  = axis(window) / axis(reference)
factor = clamp( curve(ratio) × multiplier × AR , minFactor, maxFactor )
pt     = transform( clampValue( base × factor , minValue, maxValue ) )
```

Rules override any field per **device class** (`phone`, `tablet`, `desktop`, `tv`, `watch`, `car`, `vr`), **screen range** (smallest width, width, height, aspect ratio), **orientation** and **multi-window**.

## Define

```swift
import AppDimensCustom

let brand = try ScalingStrategy.define("brand",
    reference: ReferenceScreen(width: 360, height: 640),   // design frame (pt)
    curve: .power(0.8),                                    // sublinear growth
    minFactor: 0.85, maxFactor: 1.6,
    fontScale: .clamp(1.3),                                // Dynamic Type followed up to 1.3×
    rules: [
        .on([.tablet, .desktop], ScalingPatch(curve: .logarithmic(0.4)), name: "large"),
        ScalingRule(ScreenCondition(landscape: true, minSmallestWidth: 600), ScalingPatch(multiplier: 0.9)),
        .on([.tv], ScalingPatch(reference: ReferenceScreen(width: 960, height: 540), axis: .height)),
    ])
```

`define` validates the config (it `throws` with a descriptive message) and **registers** the strategy, so `ScalingStrategies["brand"]` finds it. Pass `register: false` for throwaway instances.

## Use

```swift
Text("Title").font(.system(size: 20.csp(brand)))          // final point size (Dynamic Type per policy)
    .padding(16.cdp(brand))                                // points, ambient window
16.cdp(brand, configuration)                               // explicit window (multi-window safe)
brand.dp(16); brand.sp(14); brand.px(8)                    // strategy-first

ScalingStrategies.defaultStrategy = brand                  // 16.cdp / 14.csp use it (scaled = sdp until set)
```

### SwiftUI — per-window and scoped

```swift
struct Card: View {
    @CustomDimension(16) private var padding                 // environment strategy or default
    @CustomDimension(text: 14) private var body              // final text size
    @CustomDimension(48, strategy: CustomPresets.gameHud) private var hud

    var body: some View { … }
}

ContentView()
    .scalingStrategy(brand)        // scope for @CustomDimension
    .appDimens()                   // installs the window configuration
```

`@CustomDimension` reads `appDimensConfiguration` from the environment, so it is correct in multi-window apps on every OS version. The zero-argument `16.cdp` reads the ambient store. That store is observable on iOS 17+, like `16.sdp`.

## Configuration fields

| Field | Swift | JSON | Default |
|---|---|---|---|
| Reference frame | `ReferenceScreen(width:height:)` | `"reference": {"width", "height"}` | 300 × 533 |
| Axis | `.smallestWidth` `.width` `.height` `.min` `.max` `.diagonal` `.perimeter` | `"axis": "height"` | `.smallestWidth` |
| Curve | `.linear` `.power(e)` `.logarithmic(k)` `.interpolated(t)` `.constant(f)` `.breakpoints([Breakpoint(360, 1), …])` `.custom { ratio, screen in … }` | `"curve": {"type": "power", "exponent": 0.8}` … | `.linear` |
| Multiplier | `multiplier: 0.9` | `"multiplier"` | 1 |
| Factor bounds | `minFactor` / `maxFactor` | `"clamp": {"min", "max"}` | none |
| Value bounds (magnitude) | `minValue` / `maxValue` | `"valueClamp": {"min", "max"}` | none |
| Aspect ratio | `aspectRatio: true, sensitivity: 0.004` | `"aspectRatio": {"enabled", "sensitivity"}` | off, k = 0.08/30 |
| Font scale | `.follow` `.ignore` `.clamp(1.3)` | `"follow"` `"ignore"` `{"max": 1.3}` | `.follow` |
| Multi-window | `ignoreMultiWindow: true` | `"ignoreMultiWindow": true` | false |
| Per-value hook | `transform: { base, scaled, screen in … }` | — | none |
| Rules | `rules: [ScalingRule]` | `"rules": [{"when", "set"}]` | none |
| Parent | `extending:` / `parent.extend("x", …)` | `"extends": "power"` | — |

How rules apply:
- Ranges are `min <= v < max`.
- Matching rules apply in order, and a later rule overrides the fields an earlier one set.
- If combined bounds cross, the max bound wins.
- `explain()` lists the applied rules, with `#index` for unnamed ones.

## JSON, presets, built-ins

```swift
try ScalingStrategies.load(resource: "appdimens-strategies")   // bundle JSON; registers + applies "default"
try ScalingStrategies.load(json: text)
let soft = try BuiltInStrategies.power.extend("soft", curve: .power(0.6))
let heights = brand.withAxis(.height)                           // "brand@height", cached
let json = try ScalingStrategyJSON.text(try brand.toJSON())     // export (ScalingStrategies.exportJSON())
```

Presets: `CustomPresets.tabletFriendly`, `compactFirst`, `tvSafe`, `wearable`, `gameHud`, `readableText`. Built-ins: `BuiltInStrategies.scaled`, `power`, `logarithmic`, `interpolated`, `diagonal`, `perimeter`, `fixed`.

Schema: [custom-strategy.schema.json](https://github.com/bodenberg/appdimens-skills/blob/main/schemas/custom-strategy.schema.json). Errors name the path (`brand.rules[0].set.curve.type …`).

## Device class on Apple platforms

The device class is detected in this order:
1. `UiModeType` (`.television`, `.car`, `.watch`, `.desk`, `.vrHeadset`).
2. The platform: macOS / Mac Catalyst → `desktop`, tvOS → `tv`, watchOS → `watch`, visionOS → `vr`.
3. Size: `smallestWidth >= 600` → `tablet` (iPad), otherwise `phone`.

You can override this with `ScalingStrategies.deviceClassResolver = { configuration in … }`.

## Performance and parity

- The factor is memoized per window configuration, so each call is one multiply plus a lock-protected memo check.
- Keep `.custom` curves and `transform` pure.
- `Tests/AppDimensTests/Fixtures/custom-strategy-fixture.json` (Kotlin reference engine) is checked by `CustomStrategyTests` with a relative tolerance of 1e-4. Built-in parity is also checked against `DimenMetrics.powerScale` / `logarithmicScale` / ….
