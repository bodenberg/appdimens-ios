---
name: appdimens-ios
description: Implement, migrate, review, or troubleshoot responsive SwiftUI and UIKit layouts using AppDimens Dynamic for Apple. Use when a request mentions AppDimens, sdp/hdp/wdp/ssp, ScaledDimension, DimensConfiguration, responsive points, multi-window scaling, scaling strategies, resize, physical units, or AppDimens Metal. Also use for custom scaling strategies (AppDimensCustom: ScalingStrategy.define, cdp/csp, @CustomDimension, per-device rules, scaling JSON shared across platforms).
---

# AppDimens Dynamic for Apple workflow

## Preflight

1. Read [`references/library-map.md`](references/library-map.md) to select the smallest product and correct API.
2. Read [`references/decision-guide.md`](references/decision-guide.md) before selecting any non-default strategy.
3. Inspect the actual declarations under `Sources/`; never invent a suffix or initializer.
4. Establish whether the UI is SwiftUI, UIKit, headless, or Metal.

## Implement

1. Add the GitHub package and select `AppDimensDynamic` unless binary size requires an individual product.
2. For SwiftUI, install `.appDimens()` once at the `WindowGroup` content root, then write `16.sdp` / `16.ssp` like Compose. Never create a configuration from child-view bounds. In multi-window apps or iOS < 17, resolve with `@Environment(\.appDimensConfiguration)` + `16.sdp(dimens)` or `@ScaledDimension`.
3. For UIKit/AppKit, call `AppDimens.startAutomaticUpdates()` once, then use `16.sdp`; `16.sdp(in: view)` resolves against a specific window.
4. Start with smallest-width `sdp`; use `wdp` or `hdp` only for an axis-driven requirement.
5. Use `ssp` for Dynamic Type-aware text and `sem` only when font scaling must intentionally be disabled.
6. Start with `.scaled`. Select another strategy only against a stated visual acceptance criterion.
7. Use resize only for fit-to-container selection, not as a global scaling curve.
8. Precompute `DimensFactors` for hot loops; for Metal bind `AppDimensUniforms` and use the `appdimens_*` MSL helpers.
9. Custom strategies (`AppDimensCustom`): use them only when no built-in curve meets the acceptance criteria, or when one law must be shared across platforms.
   - Start from `BuiltInStrategies.*` / `CustomPresets.*` (`extend`) or JSON `"extends"`.
   - Keep strategies in one place: a bundle JSON loaded with `ScalingStrategies.load(resource:)`, or one `Strategies.swift`. Reuse the ids from `appdimens.config.json` (`customStrategies`) when it exists.
   - Express device or screen differences as `ScalingRule`s, not call-site `if`s.
   - When no curve fits, write the law as text: `curve: try .expression("pow(ratio, 0.8) * (tablet ? 0.9 : 1)")` or `formula: "base * pow(sw / 360, 0.7) + 2"` (JSON `"type": "expression"` / `"formula"`; same results on every platform). Variables `sw width height shortSide longSide diagonal perimeter aspectRatio density fontScale`, flags `landscape portrait multiWindow phone tablet desktop tv watch car vr`, `ratio axis ref refWidth refHeight`, `base scaled factor`.
   - Use `@CustomDimension` / `16.cdp(brand, dimens)` per window, `.scalingStrategy(_:)` to scope, and `csp` for text.
   - Verify with `brand.explain(dimens)`. See [`Documentation/strategies/custom.md`](../../Documentation/strategies/custom.md).
10. Regenerate catalogs with `python3 scripts/generate_catalogs.py` after changing the generator; never edit `Catalog.swift` by hand.

## Validate

Test the 300-point baseline, portrait, landscape, iPad multi-window, large Dynamic Type, and the intended minimum/maximum sizes. Run `swift test --parallel`, `swift test --sanitize=thread`, and `swift build -c release`. For Apple framework changes, run the SDK matrix in `.github/workflows/ci.yml` on macOS.

## Output

State the chosen product, UI stack, qualifier, strategy, multi-window behavior, text-scaling behavior, and tests. Show a complete root-provider example before isolated snippets.
