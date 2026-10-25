# Custom strategies: agent reference

Use when the user wants their own scaling (a formula, per-device rules, a shared JSON) instead of a built-in. Docs: [`Documentation/strategies/custom/`](../../../Documentation/strategies/custom/README.md) (start at `README.md`). Product: `AppDimensCustom` (separate from `AppDimensDynamic`), `import AppDimensCustom`.

## Decide the form

1. **A built-in passes visual QA?** Keep it. Custom strategies are for when none fits.
2. **The user describes math** ("scale by width over 360, between 0.85 and 1.8"):
   - multiplies every value → `CustomScaleStrategy { s in s.clamp(s.width / 360, 0.85, 1.8) }`
   - computes the final value from `base` → `scalingFormula { $0.base * $0.pow($0.sw / 360, 0.8) }`
3. **The formula must live in JSON / remote config / design tokens** → text: `try scalingFormula("base * pow(sw / 360, 0.8)")`, `try 16.cdp("…")`, `@CustomDimension(16, formula: "…")`, JSON `"formula"`.
4. **Different behavior per device / screen range / orientation, bounds, font-scale cap** → `try ScalingStrategy.define("id", …, rules: [.on([.tablet], ScalingPatch(…))])` or the JSON document.
5. **Several apps or platforms share it** → the JSON document, loaded once (`try ScalingStrategies.load(resource: "appdimens-strategies")`).

## Cheat sheet

```swift
import AppDimensCustom
// 16.cdp(s): CGFloat pt (ambient) · 16.cdp(s, c): Double pt · 14.csp(s): final text pt · cdpPx / cspPx: px

enum AppStrategies {
    static let product = CustomScaleStrategy { s in s.clamp(s.width / 360, 0.85, 1.8) }
    static let hud = scalingFormula { $0.base * $0.pow($0.sw / 360, 0.8) }
    static let brand = try! ScalingStrategy.define("brand",      // constant config: cannot fail
        reference: ReferenceScreen(width: 360, height: 640), curve: .power(0.8),
        minFactor: 0.85, maxFactor: 1.6, fontScale: .clamp(1.3),
        rules: [.on([.tablet, .desktop], ScalingPatch(curve: .logarithmic(0.4)))])
}
ScalingStrategies.defaultStrategy = AppStrategies.brand   // 16.cdp / 14.csp without argument
ContentView().scalingStrategy(AppStrategies.hud).appDimens()   // scope for @CustomDimension(16)
```

Scope names (code and text; in code read them as `s.name` or `$0.name`): `base` (formula only) `sw width height shortSide longSide diagonal perimeter aspectRatio ratio density fontScale device screen`, flags `phone tablet desktop tv watch car vr landscape portrait multiWindow`, math `pow sqrt ln log10 exp abs round min max clamp lerp smoothstep`. `ratio = sw / 300`, so `s.base * s.ratio` = `sdp`. All values are points.

## Rules an agent must follow

- **Declare strategies once** (`static let` in an `enum AppStrategies`, or JSON). Never build `CustomScaleStrategy { }` / `scalingFormula { }` inside `body`: each call is a new strategy with an empty memo. Inline text (`try 16.cdp("…")`, `@CustomDimension(_:formula:)`) is shared per text and is fine.
- **Closures are pure** and `@Sendable`: no state, settings or time inside. Different state → different strategy or a rule.
- **Prefer a factor** when the math is `base × screen-term`: `CustomScaleStrategy`, a curve, or text shaped `base * (…)` all cost one multiply. `scalingFormula { }` runs on every call. `base * sw / 360` misses the text fast path; write `base * (sw / 360)`.
- **`try` where it throws**: `define`, `extend`, `ScalingStrategy(_:config:)`, every text form, `load`, `require`, `toJSON`. Errors are `ScalingStrategyError` with the position or JSON path. A non-finite factor does **not** throw: it falls back to 1.
- **A `String` argument to `cdp` / `csp` is a formula**, never an id; for an id use `try ScalingStrategies.require("brand")`.
- **Multi-window and iOS < 17**: use `@CustomDimension` or `16.cdp(s, dimens)` with `@Environment(\.appDimensConfiguration)`, not the ambient `16.cdp(s)`. UIKit: `16.cdp(s, .current(in: view))`.
- **Value bounds** (`minValue` / `maxValue`) only for real absolute limits (44 pt tap targets, max text); they must be ≥ 0.
- **Text vs code**: code closures cannot be exported to JSON (`toJSON()` throws); use text when the user mentions JSON, remote config, A/B tests or other platforms.
- **Text sizes**: `csp` returns the final point size; pass it to `.system(size:)` / `UIFont.systemFont(ofSize:)` without scaling it again.

## Verify

- `brand.explain(dimens)` prints the axis, curve, factor, applied rules and formula. `brand.resolve(screen: ScreenSnapshot(widthDp: 820, heightDp: 1180))` checks any window in a test.
- JSON files: `npx appdimens-skills kit custom check <file>` and `kit custom explain --formula "<text>" --devices medium-phone,medium-tablet`.
- `swift test --filter CustomStrategyTests` (includes the 540-case cross-platform fixture). See [troubleshooting](../../../Documentation/strategies/custom/troubleshooting.md).
