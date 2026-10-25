# Text formulas

A text formula is the same math as a [code formula](code-formulas.md), written as a string. Use it when the formula must live outside the code: in the strategies JSON, a design-token file, remote config or an A/B test. The language is identical on every AppDimens platform and gives the same numbers.

```swift
let hud = try scalingFormula("base * pow(sw / 360, 0.8)")        // strategy (shared per text)
let gap = try 16.cdp("base * (tablet ? 0.9 : 1)")                 // inline, ambient window, CGFloat
let pt = try 16.cdp("base * (sw / 360)", configuration)           // inline, explicit window, Double
let shared = try ScalingStrategies.formula("base * ratio")        // registry form (= ScalingStrategy.formula)
@CustomDimension(16, formula: "base * (sw / 360)") var padding     // SwiftUI, per window
```

Every text entry point `throws` a `ScalingStrategyError` on a bad formula, so call it with `try`. Swift resolves the overload by type: `16.cdp(strategy)` takes a `ScalingStrategy`, `try 16.cdp("…")` a formula. `@CustomDimension(_:formula:)` cannot throw: an invalid formula stops in debug builds (`assertionFailure`) and leaves the value unscaled in release builds, so prefer a strategy built with `try scalingFormula("…")` when the text comes from outside.

Inside a full configuration, text appears in two places:

| Where | Swift | JSON | Returns | Extra variables |
|---|---|---|---|---|
| Curve | `curve: try .expression("…")` | `"curve": {"type": "expression", "expression": "…"}` | the **factor** | `ratio axis ref refWidth refHeight` |
| Formula | `formula: "…"` (in `define` / `extend`) · `ScalingPatch(formula: try ScalingExpression.parse("…"))` | `"formula": "…"` | the **final value** | the curve variables + `base scaled factor` |

`try scalingFormula("…")` and `try 16.cdp("…")` build a strategy whose only setting is a formula.

## Language

| | |
|---|---|
| Numbers | `16`, `0.8`, `.5`, `1.5e3` |
| Arithmetic | `+ - * / %` and `^` (power). `%` keeps the sign of the dividend |
| Comparison | `== != < <= > >=` (result 1 or 0) |
| Logic | `&& \|\| !` (non-zero is true) |
| Conditional | `cond ? a : b` |
| Grouping | `( … )` |
| Constants | `pi`, `e`, `true` (1), `false` (0) |

**Precedence**, from loosest to tightest: `? :` · `\|\|` · `&&` · comparisons · `+ -` · `* / %` · unary `- + !` · `^`. `^` is right-associative (`2 ^ 3 ^ 2` = 512), and unary minus binds looser than `^` (`-2 ^ 2` = −4).

### Functions

| Function | Result |
|---|---|
| `min(a, b, …)` · `max(a, b, …)` | smallest · largest argument |
| `clamp(x, lo, hi)` | `x` limited to `[lo, hi]` |
| `pow(x, y)` · `sqrt(x)` · `exp(x)` | power · square root · eˣ |
| `ln(x)` = `log(x)` · `log10(x)` · `log2(x)` | logarithms |
| `abs(x)` · `sign(x)` | absolute value · −1, 0 or 1 |
| `floor(x)` · `ceil(x)` · `round(x)` | rounding (`round` is half up: `floor(x + 0.5)`) |
| `lerp(a, b, t)` | `a + (b − a)·t` |
| `step(edge, x)` | 0 if `x < edge`, else 1 |
| `smoothstep(e0, e1, x)` | smooth 0→1 between `e0` and `e1` |

### Variables

| Variables | Meaning |
|---|---|
| `sw` `width` `height` `shortSide` `longSide` `diagonal` `perimeter` | window measures (pt) |
| `aspectRatio` `density` `fontScale` | long/short side · density · user font scale |
| `phone` `tablet` `desktop` `tv` `watch` `car` `vr` | device class flags (1/0) |
| `landscape` `portrait` `multiWindow` | orientation and split-screen flags (1/0) |
| `ratio` | axis / reference (with the defaults: `sw / 300`, the `sdp` ratio) |
| `axis` · `ref` · `refWidth` · `refHeight` | axis value · reference value · reference frame (pt) |
| `base` | the value you pass (formulas only) |
| `scaled` | `base × factor` after value bounds (formulas only) |
| `factor` | the strategy factor (formulas only) |

The lists are also public as `ScalingExpression.screenVariables`, `curveVariables` and `formulaVariables`. `scaled` and `factor` let a formula post-process the configured strategy: `formula: "max(scaled, base)"` never goes below the design value, and `formula: "round(scaled)"` snaps to whole points.

## Errors

A formula is parsed when the strategy is created, so mistakes throw a `ScalingStrategyError` right away with the position (its `description`):

```
Invalid expression at 7: unknown variable 'sww' (allowed: aspectRatio, axis, base, car, …) in "base * sww"
Invalid expression at 0: 'clamp' takes 3 argument(s), got 2 in "clamp(x, 1)"
```

In JSON the message also carries the path, for example `brand.rules[0].set.curve.expression: Invalid expression at …`. A factor that comes out NaN or infinite (for example, a division by zero) does **not** throw on Apple platforms: it falls back to factor 1 when the window resolves.

## Fast path

A formula shaped `base`, `base * E` or `E * base`, where `E` does not read `base`, `scaled` or `factor`, depends only on the screen. AppDimens evaluates `E` once per window, so each value costs one multiply, and the result is bit for bit the same as evaluating the formula per value. Any other shape works too; it is evaluated on every call (the text is parsed only once).

| Formula | Fast path |
|---|---|
| `base * pow(sw / 360, 0.8)` | yes |
| `base * (sw / 360)` | yes |
| `(tablet ? 0.9 : 1) * base` | yes |
| `base * sw / 360` | no: it reads as `(base * sw) / 360`. Add parentheses: `base * (sw / 360)` |
| `base + 2`, `round(base * ratio)` | no (genuinely per value) |

`ScalingExpression.isProportional` tells you whether a parsed formula qualifies, and `strategy.isValueDependent` is `false` for a fast-path formula.

## Sharing

Without an id, `try scalingFormula("…")`, `try ScalingStrategies.formula("…")`, `try 16.cdp("…")` and `@CustomDimension(_:formula:)` share one strategy per text (id `formula:<text>`, not registered), so they are cheap inside `body`. Up to 256 different texts are shared; beyond that, a new strategy is built per call (still correct, but it re-resolves the window each time). Pass an `id` (`try scalingFormula("…", id: "hud")`) to get your own registered strategy, or `register: false` with the id to keep it unregistered.

[Back to the custom docs](README.md)
