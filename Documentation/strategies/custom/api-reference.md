# API reference

Everything is in `import AppDimensCustom`, which re-exports `AppDimens`. Values are points (pt) unless the name says `Px`. Ambient forms (no configuration argument) read `AppDimens.configuration` and return `CGFloat`; explicit forms take a `DimensConfiguration` and return `Double`, like `16.sdp` / `16.sdp(c)`.

## Building strategies

| Function | Returns | Notes |
|---|---|---|
| `CustomScaleStrategy(id:register:) { s in factor }` | `ScalingStrategy` | programmable factor, `ScreenScope` parameter ([code formulas](code-formulas.md)) |
| `scalingFormula(id:register:) { s in value }` · `ScalingStrategy.formula { … }` | `ScalingStrategy` | code formula, `FormulaScope` parameter |
| `try scalingFormula("text", id:register:)` | `ScalingStrategy` | text formula, shared per text without an id ([text formulas](text-formulas.md)) |
| `try ScalingStrategy.define(_:extending:reference:axis:curve:multiplier:minFactor:maxFactor:minValue:maxValue:aspectRatio:sensitivity:fontScale:ignoreMultiWindow:transform:formula:rules:register:)` | `ScalingStrategy` | full configuration ([configuration](configuration.md)); registers unless `register: false` |
| `try strategy.extend(_:…)` | `ScalingStrategy` | child of an existing strategy (same parameters) |
| `strategy.withAxis(_:)` | `ScalingStrategy` | same strategy on another axis, id `"<id>@<axis>"`, cached per strategy |
| `try ScalingStrategy(_:config:)` | `ScalingStrategy` | wrap a `ScalingConfig` built by hand (not registered) |
| `BuiltInStrategies.scaled` … `fixed` · `CustomPresets.tvSafe` … | `ScalingStrategy` | ready-made parents |

## Registry: `ScalingStrategies`

| Member | Notes |
|---|---|
| `defaultStrategy` | strategy used by `16.cdp` / `14.csp` and `@CustomDimension` without a scope; initially `BuiltInStrategies.scaled` |
| `register(_:)` · `unregister(_:)` | add or replace · remove (also clears the default if it had that id) |
| `ScalingStrategies["id"]` · `try require(_:)` | lookup, including built-ins and presets |
| `registered` | strategies registered by the app |
| `try formula(_:)` | shared text-formula strategy (id `formula:<text>`, not registered) |
| `try load(json:)` · `try load(data:)` · `try load(resource:bundle:)` | register a [JSON document](json.md) and apply its `default`; atomic |
| `try exportJSON(_:)` | encode strategies as a document (`JSONValue`) |
| `deviceClassResolver` | replace the device-class detection: `@Sendable (DimensConfiguration) -> DeviceClass` |
| `resetForTesting()` | clear the registry, the default and the resolver (tests) |

## Number accessors (`DimensNumber`: `Int`, `Double`, `CGFloat`…)

| Call | Returns |
|---|---|
| `16.cdp` · `16.cdp(strategy)` · `try 16.cdp("text")` | `CGFloat` pt, ambient window |
| `16.cdp(c)` · `16.cdp(strategy, c)` · `try 16.cdp("text", c)` | `Double` pt, explicit window |
| `16.cdpPx` · `16.cdpPx(strategy)` · `try 16.cdpPx("text")` | `CGFloat` physical px, ambient |
| `14.csp` · `14.csp(strategy)` · `try 14.csp("text")` | `CGFloat` final text point size (font-scale policy applied), ambient |
| `14.csp(c)` · `14.csp(strategy, c)` · `try 14.csp("text", c)` | `Double` final text point size, explicit |
| `14.cspPx` · `14.cspPx(strategy)` · `try 14.cspPx("text")` | `CGFloat` text physical px, ambient |

There is no lookup by id in the accessors: pass `try ScalingStrategies.require("brand")`. A `String` argument is always a formula.

## SwiftUI

| API | Notes |
|---|---|
| `@CustomDimension(16)` · `@CustomDimension(16, strategy: s)` | pt for the view's own window (`\.appDimensConfiguration`), correct in multi-window apps on every OS version |
| `@CustomDimension(text: 14)` · `@CustomDimension(text: 14, strategy: s)` | final text point size |
| `@CustomDimension(16, formula: "…")` · `@CustomDimension(text: 14, formula: "…")` | text formula, shared per text (does not throw; see [text formulas](text-formulas.md)) |
| `.scalingStrategy(s)` · `\.scalingStrategy` | scope for `@CustomDimension` without an explicit strategy |

Install the window once with `.appDimens()` (or `AppDimensProvider`). Without an explicit strategy, `@CustomDimension` uses the nearest `.scalingStrategy(_:)`, then `ScalingStrategies.defaultStrategy`. `16.cdp` always uses the default and reads the ambient store, which is observable on iOS 17+.

## UIKit / AppKit

```swift
let c = DimensConfiguration.current(in: view)          // @MainActor; UIView or NSView
view.layoutMargins.left = 16.cdp(brand, c)
label.font = .systemFont(ofSize: 14.csp(brand, c))
```

## Strategy members

| Member | Notes |
|---|---|
| `id` · `config` · `isValueDependent` | identity · full `ScalingConfig` · whether results depend on the value |
| `dp(_:_:)` · `px(_:_:)` | pt · physical px (`Double`; configuration defaults to the ambient one) |
| `sp(_:_:)` · `spPx(_:_:)` | final text pt · text px |
| `factor(_:)` · `explain(_:)` | debug, for the ambient or a given configuration |
| `resolve(_:)` → `ResolvedScaling` | memoized per window: `factor`, `appliedRules`, `screen`, `scale(_:)`, `scaleSpDp(_:)`, `scaleSpUnits(_:)`, `explain(_:)` |
| `resolve(screen:)` | platform-free resolution (tests, previews), not memoized |
| `try toJSON()` | export (throws for code closures) |

`ScreenSnapshot(widthDp:heightDp:smallestWidthDp:density:fontScale:isLandscape:isMultiWindow:device:)` builds a window by hand, for tests and previews (only the width and height are required; values are points). `screenSnapshot(_:)` converts a `DimensConfiguration`, `defaultDeviceClass(_:)` is the built-in detection, and `ScalingEngine.resolve(_:_:)` is the pure engine function.

## Model and JSON types

`ScalingConfig`, `ScalingPatch`, `ScalingRule` (`.on(_:_:name:)`), `ScreenCondition`, `ScalingCurve`, `ScalingExpression` (`parse(_:allowed:)`, `evaluate`, `isProportional`, `screenVariables` / `curveVariables` / `formulaVariables`), `FontScalePolicy`, `ReferenceScreen`, `Breakpoint`, `ScalingAxis`, `DeviceClass`, `ValueTransform`, `ScalingStrategyError`, `ScalingStrategyJSON` (`parse`, `encode`, `text`, `formatVersion`, `Document`), `JSONValue`. The summary list is also in the main [API reference](../../API.md#appdimenscustom).

[Back to the custom docs](README.md)
