# Code formulas

Two one-line entry points let you write the scaling math in plain Swift. The closure receives a typed **scope** whose names match the [text language](text-formulas.md), so you only learn them once. Xcode autocompletes them, and a typo fails at compile time. Read the names through the closure parameter: `s in s.sw` or `$0.sw`.

| | `CustomScaleStrategy { s in … }` | `scalingFormula { … }` |
|---|---|---|
| You return | the **factor** (every value is multiplied by it) | the **final value** |
| Scope | `ScreenScope` | `FormulaScope` (= `ScreenScope` + `base`) |
| Runs | once per window | once per value, on every call |
| Cost per value | one multiply | your closure |
| JSON | no (use a text `expression` curve) | no (use a text `formula`) |

## `CustomScaleStrategy { s in … }`: programmable factor

```swift
let product = CustomScaleStrategy { s in s.clamp(s.width / 360, 0.85, 1.80) }
let living = CustomScaleStrategy { s in s.tv ? s.height / 540 : s.ratio }
let steps = CustomScaleStrategy { s in
    switch s.sw {
    case ..<360: return 0.9
    case ..<600: return s.sw / 400
    default: return 1.5 + (s.sw - 600) / 2000
    }
}
```

- Signature: `func CustomScaleStrategy(id: String? = nil, register: Bool? = nil, _ factor: @escaping @Sendable (ScreenScope) -> Double) -> ScalingStrategy`. It does not throw.
- `register` defaults to `id != nil`. Without an `id` a unique `scale#N` id is generated and the strategy is not registered. With an id it is registered, so `ScalingStrategies["product"]` finds it.
- A non-finite factor (NaN, infinity) **falls back to 1** when the window resolves, so a broken closure never poisons a layout pass (Android and Flutter throw instead).

## `scalingFormula { … }`: the final value

```swift
let hud = scalingFormula { $0.base * $0.pow($0.sw / 360, 0.8) }
let card = scalingFormula { s in s.tablet ? s.base * 1.2 : s.base * s.ratio }
let snap = scalingFormula { s in s.round(s.base * s.sw / 360) }         // whole points only
let floor = scalingFormula { s in s.max(s.base * s.ratio, s.base) }     // never smaller than the design value
```

- Signature: `func scalingFormula(id: String? = nil, register: Bool? = nil, _ formula: @escaping @Sendable (FormulaScope) -> Double) -> ScalingStrategy`. `ScalingStrategy.formula { … }` is the same.
- `base` is the value you pass: in `16.cdp(hud)` it is `16`. For `csp`, the result then follows the font-scale policy (see [font scale](configuration.md#font-scale-csp)).
- Without an `id`, a unique `formula#N` id is generated.

## Names on the scope

Both scopes adopt the `ScalingScope` protocol.

| Name | Type | Meaning |
|---|---|---|
| `base` | `Double` | the value being scaled (`scalingFormula { }` only) |
| `sw` | `Double` | smallest width of the window (pt) |
| `width` · `height` | `Double` | window width · height (pt) |
| `shortSide` · `longSide` | `Double` | shorter · longer side (pt) |
| `diagonal` · `perimeter` | `Double` | `√(w² + h²)` · `w + h` (pt) |
| `aspectRatio` | `Double` | `longSide / shortSide` |
| `ratio` | `Double` | `sw / 300`, the ratio `sdp` uses (`s.base * s.ratio` is exactly `sdp`) |
| `density` · `fontScale` | `Double` | display scale · Dynamic Type scale |
| `phone` `tablet` `desktop` `tv` `watch` `car` `vr` | `Bool` | device class of the window |
| `landscape` · `portrait` · `multiWindow` | `Bool` | orientation · split screen / Slide Over / Stage Manager window |
| `device` | `DeviceClass` | the device class itself (for `switch`) |
| `screen` | `ScreenSnapshot` | the whole snapshot (`widthDp`, `heightDp`, `smallestWidthDp`, `isLandscape`…) |
| `pow(x, e)` `sqrt` `ln` `log10` `exp` `abs` | `Double` | math with the text-language names |
| `round(x)` | `Double` | half up: `floor(x + 0.5)` |
| `min(a, b)` `max(a, b)` `clamp(x, lo, hi)` | `Double` | bounds (two arguments for `min` / `max`) |
| `lerp(a, b, t)` · `smoothstep(e0, e1, x)` | `Double` | blending |

The snapshot keeps the cross-platform field names (`widthDp`…); on Apple platforms the values are points. The device class comes from the `UiModeType`, the platform (macOS / Mac Catalyst, tvOS, watchOS, visionOS) and the smallest width (`sw ≥ 600` is an iPad); see [rules](configuration.md#rules).

## Rules for the closure

- **Keep it pure.** It must not read mutable state, preferences or time: the factor is memoized per window. Use a different strategy (or a rule) for a different state. The closure is `@Sendable` and may run on any thread.
- **Declare it once.** Every call to `CustomScaleStrategy { }` or `scalingFormula { }` creates a new strategy with its own memo and a new `scale#N` / `formula#N` id. Use a `static let` (or a property of a long-lived object), never a fresh closure in `body`.
- **Prefer the factor form when you can.** If your formula is `base × (something about the screen)`, write the something as a `CustomScaleStrategy`: it runs once per window and each value costs one multiply, while a `scalingFormula { }` closure runs on every call.

## When to use something else

- The formula must live in JSON, a design-token file or remote config: [Text formulas](text-formulas.md).
- You need rules per device, bounds or a font-scale policy on top of a curve: [Configuration](configuration.md). The full configuration also accepts code: `curve: .custom { ratio, screen in … }` and `transform: { base, scaled, screen in … }`.

[Back to the custom docs](README.md)
