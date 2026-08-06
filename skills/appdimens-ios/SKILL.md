---
name: appdimens-ios
description: Implement, migrate, review, or troubleshoot responsive SwiftUI and UIKit layouts using AppDimens Dynamic for Apple. Use when a request mentions AppDimens, sdp/hdp/wdp/ssp, ScaledDimension, DimensConfiguration, responsive points, multi-window scaling, scaling strategies, resize, physical units, or AppDimens Metal.
---

# AppDimens Dynamic for Apple workflow

## Preflight

1. Read [`references/library-map.md`](references/library-map.md) to select the smallest product and correct API.
2. Read [`references/decision-guide.md`](references/decision-guide.md) before selecting any non-default strategy.
3. Inspect the actual declarations under `Sources/`; never invent a suffix or initializer.
4. Establish whether the UI is SwiftUI, UIKit, headless, or Metal.

## Implement

1. Add the GitHub package and select `AppDimensDynamic` unless binary size requires an individual product.
2. For SwiftUI, install `.appDimens()` once at the `WindowGroup` content root. Never create a configuration from child-view bounds.
3. For UIKit, resolve `DimensConfiguration.current(in:)`; the view is only a route to its `UIWindowScene`.
4. Start with smallest-width `sdp`; use `wdp` or `hdp` only for an axis-driven requirement.
5. Use `ssp` for Dynamic Type-aware text and `sem` only when font scaling must intentionally be disabled.
6. Start with `.scaled`. Select another strategy only against a stated visual acceptance criterion.
7. Use resize only for fit-to-container selection, not as a global scaling curve.
8. Precompute `DimensFactors` for hot loops; update configuration only when window/environment metrics change.

## Validate

Test the 300-point baseline, portrait, landscape, iPad multi-window, large Dynamic Type, and the intended minimum/maximum sizes. Run `swift test --parallel`, `swift test --sanitize=thread`, and `swift build -c release`. For Apple framework changes, run the SDK matrix in `.github/workflows/ci.yml` on macOS.

## Output

State the chosen product, UI stack, qualifier, strategy, multi-window behavior, text-scaling behavior, and tests. Show a complete root-provider example before isolated snippets.
