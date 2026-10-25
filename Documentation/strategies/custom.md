# Custom strategies (`AppDimensCustom`)

[Strategy catalog](../STRATEGIES.md) · [Mathematics](../MATHEMATICS-AND-CALCULUS.md#custom-strategies) · [API](../API.md#appdimenscustom) · **[Full custom-strategy documentation](custom/README.md)**

**Product:** `AppDimensCustom` (depends on `AppDimens`) · Port of Android `appdimens-dynamic-custom`.

The built-in strategies cover most products. When an app (or a design system shared by several apps) needs its **own** growth law, this product lets you write it. The simplest form is one line of typed Swift; the full form is a configuration that loads from JSON on every AppDimens platform (Android, KMP, Flutter, React Native, Web, Games, .NET) with the same numbers.

```swift
import AppDimensCustom

// Factor: the number that multiplies every value
let product = CustomScaleStrategy { s in s.clamp(s.width / 360, 0.85, 1.80) }
// Formula: the final value (base = the 16 in 16.cdp(hud))
let hud = scalingFormula { $0.base * $0.pow($0.sw / 360, 0.8) }
// Text, for JSON and remote config (throws on a typo)
let remote = try scalingFormula("base * pow(sw / 360, 0.8)")
// Full configuration with rules
let brand = try ScalingStrategy.define("brand",
    reference: ReferenceScreen(width: 360, height: 640),
    curve: .power(0.8),
    minFactor: 0.85, maxFactor: 1.6,
    rules: [.on([.tablet, .desktop], ScalingPatch(curve: .logarithmic(0.4)), name: "large")])

Text("Body").padding(16.cdp(product))                     // CGFloat points, ambient window
Text("Score").font(.system(size: 18.csp(hud)))            // final point size (Dynamic Type per policy)
@CustomDimension(16, strategy: brand) var padding         // SwiftUI view property, per window
view.layoutMargins.left = 16.cdp(brand, .current(in: view))   // UIKit, explicit window
```

## Documentation

| Guide | What it covers |
|---|---|
| [Overview](custom/README.md) | which form to pick, how the pieces fit |
| [Quick start](custom/quick-start.md) | install and first strategy in five minutes |
| [Code formulas](custom/code-formulas.md) | `CustomScaleStrategy { s in … }`, `scalingFormula { … }` and every name on the scope |
| [Text formulas](custom/text-formulas.md) | the formula language: operators, functions, variables, errors, fast path |
| [Configuration](custom/configuration.md) | reference, axes, curves, bounds, aspect ratio, font scale, multi-window, rules, `extend`, built-ins, presets, device class on Apple platforms |
| [JSON format](custom/json.md) | the cross-platform document, loading, exporting, validation |
| [API reference](custom/api-reference.md) | number accessors, `@CustomDimension`, `.scalingStrategy(_:)`, UIKit, registry, debug helpers |
| [Performance](custom/performance.md) | what each form costs, memoization |
| [Cookbook](custom/cookbook.md) | recipes: iPad, Apple TV, Apple Watch, game HUD, readable text, A/B tests |
| [Troubleshooting](custom/troubleshooting.md) | error messages, `explain()`, FAQ |

## When to use it

- A design system shared by several apps that needs one growth law everywhere.
- A product whose UI must behave differently per device class: Apple TV, Apple Watch, CarPlay, iPad, Mac.
- Remote-config or A/B experiments on scaling, by shipping a new JSON.
- Built-ins that are close but need a different reference frame, exponent or bounds.

## Trade-offs

- Strategies are values created at runtime. Keep them in one place (an `enum AppStrategies` or the JSON document).
- Code closures cannot be exported to JSON; their text equivalents can.
- Text entry points and `define` `throw` (`ScalingStrategyError`); a non-finite factor does not throw on Apple platforms, it falls back to 1.
- The aspect-ratio correction always uses the satellite law (`× (1 + k·ln(AR/1.78))`).
- `Tests/AppDimensTests/Fixtures/custom-strategy-fixture.json` (540 cases, Kotlin reference engine) is checked by `CustomStrategyTests` with a relative tolerance of 1e-4.

[Strategy catalog](../STRATEGIES.md)
