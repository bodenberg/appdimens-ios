# Custom strategies (`AppDimensCustom`)

[Strategy catalog](../STRATEGIES.md) · [Mathematics](../MATHEMATICS-AND-CALCULUS.md#custom-strategies) · [API](../API.md#appdimenscustom)

**Product:** `AppDimensCustom` (depends on `AppDimens`) · Port of Android `appdimens-dynamic-custom`.

When none of the built-in curves fits, or one growth law must be shared by several apps and platforms, define **your own** strategy. The configuration is identical on every AppDimens platform (Android, KMP, Flutter, React Native, Web, Games, .NET) and can be loaded from JSON.

## What it computes

```
ratio  = axis(window) / axis(reference)
factor = clamp( curve(ratio) × multiplier × AR , minFactor, maxFactor )
pt     = formula( clampValue( base × factor , minValue, maxValue ) )
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
| Curve | `.linear` `.power(e)` `.logarithmic(k)` `.interpolated(t)` `.constant(f)` `.breakpoints([Breakpoint(360, 1), …])` `try .expression("…")` (free-form text, see below) `.custom { ratio, screen in … }` | `"curve": {"type": "power", "exponent": 0.8}` … | `.linear` |
| Multiplier | `multiplier: 0.9` | `"multiplier"` | 1 |
| Factor bounds | `minFactor` / `maxFactor` | `"clamp": {"min", "max"}` | none |
| Value bounds (magnitude) | `minValue` / `maxValue` | `"valueClamp": {"min", "max"}` | none |
| Aspect ratio | `aspectRatio: true, sensitivity: 0.004` | `"aspectRatio": {"enabled", "sensitivity"}` | off, k = 0.08/30 |
| Font scale | `.follow` `.ignore` `.clamp(1.3)` | `"follow"` `"ignore"` `{"max": 1.3}` | `.follow` |
| Multi-window | `ignoreMultiWindow: true` | `"ignoreMultiWindow": true` | false |
| Per-value formula | `formula: "max(scaled, base)"` | `"formula": "max(scaled, base)"` | none |
| Per-value hook (code) | `transform: { base, scaled, screen in … }` | — | none |
| Rules | `rules: [ScalingRule]` | `"rules": [{"when", "set"}]` | none |
| Parent | `extending:` / `parent.extend("x", …)` | `"extends": "power"` | — |

How rules apply:
- Ranges are `min <= v < max`.
- Matching rules apply in order, and a later rule overrides the fields an earlier one set.
- If combined bounds cross, the max bound wins.
- `explain()` lists the applied rules, with `#index` for unnamed ones.

## Free-form formulas (no limits from the built-in curves)

You are not limited to the built-in curves. Write the formula yourself, as **text** that also works in JSON and gives the same result on every AppDimens platform:

- **Curve expression** returns the **factor** from the screen. It is computed once per window, like any curve, and stays on the one-multiply fast path.
  `"curve": {"type": "expression", "expression": "pow(ratio, 0.8) * (tablet ? 0.9 : 1)"}`
- **Formula** returns the **final value** for each input. It can use `base`, `scaled` and `factor`, and replaces or post-processes the result. The strategy then becomes value-dependent, so results are cached per window.
  `"formula": "base * pow(sw / 360, 0.7) + 2"` · `"formula": "max(scaled, base)"`

| | |
|---|---|
| Operators | `+ - * / % ^` (`^` = power, right-associative; `%` keeps the dividend's sign), `== != < <= > >=`, `&& \|\| !`, `cond ? a : b`, `( )` |
| Functions | `min(a, b, …)` `max(a, b, …)` `clamp(x, lo, hi)` `pow` `sqrt` `ln`/`log` `log10` `log2` `exp` `abs` `sign` `floor` `ceil` `round` (half up) `lerp(a, b, t)` `step(edge, x)` `smoothstep(e0, e1, x)` |
| Screen variables | `sw` `width` `height` `shortSide` `longSide` `diagonal` `perimeter` `aspectRatio` `density` `fontScale`; flags (1/0): `landscape` `portrait` `multiWindow` `phone` `tablet` `desktop` `tv` `watch` `car` `vr`; constants `pi` `e`, `true` / `false` |
| Curve variables | screen variables + `ratio` (axis / reference), `axis` (dp), `ref` (reference dp), `refWidth`, `refHeight` |
| Formula variables | curve variables + `base` (input), `scaled` (base × factor after `valueClamp`), `factor` |

Expressions are parsed when the strategy is created. Unknown variables or functions, wrong arity and syntax errors fail early with the position and the JSON path (e.g. `brand.rules[0].set.curve.expression`). On Apple platforms a non-finite factor (for example, a division by zero) falls back to factor 1, so a layout pass is never poisoned. Rules can swap expressions per device like any other field, and `"formula": null` clears an inherited formula.

For anything the language cannot express, use a code-only closure: `.custom { ratio, screen in … }` (factor) or `transform: { base, scaled, screen in … }` (value). Both have full access to your code, but they cannot be serialized to JSON.

```swift
let hud = try ScalingStrategy.define("hud",
    curve: try .expression("clamp(pow(shortSide / 360, 0.85) * (1 + 0.05 * log(aspectRatio / 1.78)), 0.8, 2)"),
    formula: "round(scaled)",                                  // whole points only
    rules: [.on([.tv], ScalingPatch(curve: try .expression("height / 540")))])
```

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
