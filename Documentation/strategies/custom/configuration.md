# Configuration

`try ScalingStrategy.define(id, …)` builds a full strategy: the [code](code-formulas.md) and [text](text-formulas.md) one-liners are shortcuts for the simplest cases of it. Its named parameters are the JSON fields, and every field below also exists in the [JSON format](json.md), on every platform.

```swift
let brand = try ScalingStrategy.define("brand",       // creates AND registers "brand"
    reference: ReferenceScreen(width: 360, height: 640), // design frame (pt)
    axis: .smallestWidth,                                // what to compare
    curve: .power(0.8),                                  // how the ratio becomes a factor
    multiplier: 1.0,
    minFactor: 0.85, maxFactor: 1.6,                     // factor bounds
    minValue: 10, maxValue: 64,                          // pt bounds (value-dependent)
    aspectRatio: true, sensitivity: 0.004,               // long/thin screen correction
    fontScale: .clamp(1.3),                              // csp policy
    ignoreMultiWindow: false,
    rules: [.on([.tablet, .desktop], ScalingPatch(curve: .logarithmic(0.4)), name: "large")])
```

`define` validates the config and `throws` a `ScalingStrategyError` with a descriptive message (`strategy: minFactor must be <= maxFactor`). Pass `register: false` to build a throwaway strategy. `try ScalingStrategy(id, config: ScalingConfig)` wraps a config built by hand (not registered).

## The formula

```
ratio  = axis(window) / axis(reference)
factor = clamp( curve(ratio) × multiplier × AR , minFactor, maxFactor )
scaled = clampValue( base × factor , minValue, maxValue )   // the configured result
value  = formula ? formula(base, scaled, factor) : scaled   // a formula replaces the result (it gets the original base)
```

## Fields

| Field | Swift (`define` / `ScalingConfig` / `ScalingPatch`) | JSON | Default |
|---|---|---|---|
| Reference frame (pt) | `reference: ReferenceScreen(width: 360, height: 640)` | `"reference": {"width": 360, "height": 640}` | 300 × 533 |
| Axis | `axis: .height` | `"axis": "height"` | `.smallestWidth` |
| Curve | `curve: .power(0.8)` | `"curve": {"type": "power", "exponent": 0.8}` | `.linear` |
| Multiplier | `multiplier: 0.9` | `"multiplier": 0.9` | 1 |
| Factor bounds | `minFactor: 0.85, maxFactor: 1.6` | `"clamp": {"min": 0.85, "max": 1.6}` | none |
| Value bounds (pt, ≥ 0) | `minValue: 10, maxValue: 32` | `"valueClamp": {"min": 10, "max": 32}` | none |
| Aspect ratio | `aspectRatio: true, sensitivity: 0.004` | `"aspectRatio": {"enabled": true, "sensitivity": 0.004}` | off, k = 0.08 / 30 |
| Font scale (`csp`) | `fontScale: .follow` · `.ignore` · `.clamp(1.3)` | `"fontScale": "follow"` · `"ignore"` · `{"max": 1.3}` | `.follow` |
| Multi-window | `ignoreMultiWindow: true` | `"ignoreMultiWindow": true` | false |
| Per-value formula | `formula: "max(scaled, base)"` | `"formula": "max(scaled, base)"` | none |
| Per-value code hook | `transform: { base, scaled, screen in … }` | (code only) | none |
| Rules | `rules: [ScalingRule(…), .on(…)]` | `"rules": [{"when": {…}, "set": {…}}]` | none |
| Parent | `extending: BuiltInStrategies.power` · `BuiltInStrategies.power.extend("x", …)` | `"extends": "power"` | none |

In a `ScalingPatch` (a rule's `set`) the formula is a parsed expression: `ScalingPatch(formula: try ScalingExpression.parse("round(scaled)"))`. A formula replaces a transform and the other way round.

## Axes

| Axis | Swift | JSON | Screen value | Reference value |
|---|---|---|---|---|
| Smallest width | `.smallestWidth` | `smallestWidth` | `sw` | `min(refW, refH)` |
| Width · height | `.width` · `.height` | `width` · `height` | window width · height | `refW` · `refH` |
| Shorter · longer side | `.min` · `.max` | `min` · `max` | shorter · longer side | `min` · `max` of the reference |
| Diagonal | `.diagonal` | `diagonal` | `√(w² + h²)` | `√(refW² + refH²)` |
| Perimeter | `.perimeter` | `perimeter` | `w + h` | `refW + refH` |

The built-in `hdp` divides the height by **300**. A custom `height` axis divides by `reference.height` (533 by default), which is what a designer drawing on a full frame expects.

## Curves

| Curve | Swift (`ScalingCurve`) | JSON | Factor |
|---|---|---|---|
| Linear | `.linear` | `"linear"` | `r` (= `sdp` with the default reference) |
| Power | `.power(0.8)` | `{"type": "power", "exponent": 0.8}` | `r^e` (built-in power uses 0.75) |
| Logarithmic | `.logarithmic(0.4)` | `{"type": "logarithmic", "k": 0.4}` | `1 + k·ln(r)` |
| Interpolated | `.interpolated(0.5)` | `{"type": "interpolated", "t": 0.5}` | `1 + (r − 1)·t` |
| Constant | `.constant(1)` | `{"type": "constant", "factor": 1}` | `f` (`.constant(1)` = plain points) |
| Breakpoints | `.breakpoints([Breakpoint(360, 1), Breakpoint(600, 1.25)])` | `{"type": "breakpoints", "points": [{"at": 360, "factor": 1}, …]}` | piecewise linear over the **absolute** axis value (pt), clamped to the first and last points |
| Text expression | `try .expression("pow(ratio, 0.8)")` (case `.expressionCurve`) | `{"type": "expression", "expression": "…"}` | your formula ([text formulas](text-formulas.md)) |
| Code | `.custom { ratio, screen in … }` | (code only) | your formula, pure |

## Bounds

- `minFactor` / `maxFactor` limit the **factor**. If rules leave `min > max`, the max wins. Declared configs are validated up front.
- `minValue` / `maxValue` limit the **resulting points**. The bounds apply to the magnitude, so a negative offset mirrors a positive one and 0 stays 0; they must be ≥ 0. Value bounds make the strategy value-dependent (`isValueDependent` is `true`).

## Aspect ratio

`aspectRatio: true` multiplies the factor by `1 + k·ln(AR / 1.78)`, where `AR = longSide / shortSide` and the default `k` is the built-in 0.08 / 30 (`customSensitivityDefault`). Raise `sensitivity` for a stronger correction on very long or very square screens.

## Font scale (`csp`)

| Policy | Effect on `14.csp(brand)` |
|---|---|
| `.follow` (default) | follows Dynamic Type, like `ssp` |
| `.ignore` | fixed size; Dynamic Type is ignored |
| `.clamp(1.3)` | follows it up to 1.3×, then stops |

`csp` / `s.sp` return the **final point size** (Apple fonts take the final size: `.font(.system(size: 14.csp(brand)))`, `UIFont.systemFont(ofSize:)`). The font scale is `DimensConfiguration.fontScale`, read from the content size category. `ResolvedScaling.scaleSpUnits(_:)` returns the size before the system scale, for APIs that apply it themselves.

## Multi-window

`ignoreMultiWindow: true` keeps values unscaled in Split View, Slide Over and Stage Manager windows: the factor is 1, and formulas and transforms are skipped. Value bounds still apply. To react to split screen yourself instead, use a rule (`ScreenCondition(multiWindow: true)`) or read `multiWindow` in a formula. Multi-window comes from `DimensConfiguration.isMultiWindow` (the explicit `isInMultiWindowMode` flag, or a window smaller than 95 % of the screen).

## Rules

A rule changes some fields when its condition matches the window.

```swift
try ScalingStrategy.define("brand",
    curve: .power(0.8),
    rules: [
        .on([.tablet, .desktop], ScalingPatch(curve: .logarithmic(0.4)), name: "large"),
        ScalingRule(ScreenCondition(landscape: true, minSmallestWidth: 600), ScalingPatch(multiplier: 0.9)),
        .on([.watch], ScalingPatch(reference: ReferenceScreen(width: 192, height: 192), axis: .min,
                                   minFactor: 0.85, maxFactor: 1.15)),
        ScalingRule(ScreenCondition(landscape: true), ScalingPatch(multiplier: 0.95)),
        ScalingRule(ScreenCondition(multiWindow: true), ScalingPatch(maxFactor: 1.2)),
        ScalingRule(ScreenCondition(minSmallestWidth: 600), ScalingPatch(fontScale: .clamp(1.2))),  // sw >= 600, any UI mode
    ])
```

`ScalingPatch` and `ScreenCondition` take their arguments in declaration order (`reference`, `axis`, `curve`, `multiplier`, `minFactor`, `maxFactor`, … and `devices`, `landscape`, `minSmallestWidth`, …).

| Condition | Swift (`ScreenCondition(…)`) | JSON `when` |
|---|---|---|
| Device class | `devices: [.tv]` (or `.on([.tv], patch)`) | `"device": "tv"` or `["tablet", "desktop"]` |
| Orientation | `landscape: true` · `landscape: false` | `"orientation": "landscape"` · `"portrait"` |
| Smallest width / width / height (pt) | `minSmallestWidth: 600, maxWidth: 1200` (`min…` / `max…` for each) | `"smallestWidth": {"min": 600}`, `"width": {"max": 1200}`, `"height": {…}` |
| Aspect ratio | `minAspectRatio: 2` | `"aspectRatio": {"min": 2}` |
| Split screen | `multiWindow: true` | `"multiWindow": true` |

- A condition matches when **every** field set in it matches. Ranges are `min <= value < max`.
- All matching rules apply **in declaration order**. A later rule overrides the fields an earlier one set; fields a rule leaves out (`nil` in the `ScalingPatch`) keep their current value.
- Applied rule names show in `explain()`. Rules without a name show as `#index`.
- Device classes: `.phone`, `.tablet`, `.desktop`, `.tv`, `.watch`, `.car`, `.vr`. On Apple platforms they are detected in this order: the `UiModeType` (`.television`, `.car`, `.watch`, `.desk`, `.vrHeadset`); the platform (macOS / Mac Catalyst → desktop, tvOS → tv, watchOS → watch, visionOS → vr); then `smallestWidth >= 600` → tablet (iPad), otherwise phone. Replace the detection with `ScalingStrategies.deviceClassResolver = { configuration in … }` (`defaultDeviceClass(_:)` is the built-in one).

## Extending

```swift
let soft = try BuiltInStrategies.power.extend("soft", curve: .power(0.6))
let myTv = try CustomPresets.tvSafe.extend("myTv", rules: [.on([.tv], ScalingPatch(maxFactor: 1.6))])
let heights = brand.withAxis(.height)                    // "brand@height", cached per strategy
let hudText = try brand.extend("hudText", formula: "round(scaled)")
```

`extend` keeps the parent's fields and rules (the parent's rules first) and lets you change any of them; it registers the child unless `register: false`. `define(_:extending:…)` is the same.

### Built-ins as configs

`BuiltInStrategies.scaled`, `power`, `logarithmic`, `interpolated`, `diagonal`, `perimeter` and `fixed` (all in `BuiltInStrategies.all`). Their factors match the built-in modules on the default smallest-width path (checked against `DimenMetrics.powerScale` / `logarithmicScale` / … by `CustomStrategyTests`), so they are a safe starting point.

### Presets (`CustomPresets`)

| Preset | Id | What it does |
|---|---|---|
| `tabletFriendly` | `tabletFriendly` | Linear on phones; `power(0.5)` on tablets and desktop; factor ≤ 1.8 |
| `compactFirst` | `compactFirst` | Reference 360×640, `interpolated(0.5)`, factor 0.9–1.4 |
| `tvSafe` | `tvSafe` | On TV: height axis vs 540 pt, factor 1–2 |
| `wearable` | `wearable` | On watch: shorter side vs 192 pt, factor 0.85–1.15 |
| `gameHud` | `gameHud` | Shorter side, `power(0.85)`, aspect ratio on, 0.75–2.5, fixed-size text |
| `readableText` | `readableText` | `logarithmic(0.4)`, font scale capped at 1.3 |

Presets are not registered by default, but `ScalingStrategies["tvSafe"]` and JSON `extends` find them by id (case-insensitive).

[Back to the custom docs](README.md)
