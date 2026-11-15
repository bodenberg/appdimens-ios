# Troubleshooting

## See what a strategy does

```swift
print(brand.explain())                        // ambient window
print(brand.explain(dimens))                  // a given DimensConfiguration (e.g. @Environment(\.appDimensConfiguration))
brand.resolve(screen: ScreenSnapshot(widthDp: 820, heightDp: 1180)).explain("brand")   // any window
```

```
[brand] tablet smallestWidth=820dp / ref 360 = 2.2778 -> logarithmic(0.4) = 1.3293 x 0.9 clamp[0.85, 1.6] => factor 1.1964 rules=[large, #1]
[hud] phone smallestWidth=390dp / ref 300 = 1.3 -> linear = 1.3 => factor 1.3 then formula(base * pow(sw / 360, 0.8))
```

The line reads left to right: device class, axis value and reference (printed with the cross-platform unit name "dp"; the values are points), the curve and its result, multiplier, aspect ratio, bounds, the final factor, the per-value formula (`then formula(…)`) or code hook (`then transform`) when there is one, and the applied rules. `factor()` returns only the number.

## Common errors

Every error is a `ScalingStrategyError`; its `description` is the message below.

| Message | Cause | Fix |
|---|---|---|
| `Invalid expression at 7: unknown variable 'sww' …` | typo in a text formula | use a name from the list in the message, or switch to a [code formula](code-formulas.md), which the compiler checks |
| `'clamp' takes 3 argument(s), got 2` | wrong number of arguments | see the [function table](text-formulas.md#functions) |
| `<path> must be an object` / `must be a boolean` | wrong JSON type | see the [field tables](json.md#strategy-fields) |
| `maxValue must be >= 0` | negative value bound | value bounds limit the magnitude; use a positive number |
| `minFactor must be <= maxFactor` | crossed bounds in the declaration | swap them (crossed bounds produced by rules at runtime let the max win) |
| `No scaling strategy 'x'. Registered: …` | id not registered (`require`) | register it, load the JSON first, or check the id |
| `Resource 'x.json' not found in bundle` | file not in the target | add it to the app target or pass `bundle:` |
| `Custom curve functions cannot be encoded to JSON` · `transform functions cannot be encoded to JSON` | `toJSON()` on a code closure | use the text form for strategies you export |

## Frequent questions

**My closure returns NaN but nothing throws.** On Apple platforms a non-finite factor falls back to 1, so the layout keeps the design values. Check with `explain()` (the factor reads 1) and guard the formula (`s.max(x, 1)`) or clamp the factor.

**My closure result never changes.** The factor is memoized per window. A closure that reads mutable state (a setting, the time) is not re-run until the window changes. Use separate strategies and pick one, or make the setting part of the screen (a rule).

**`16.cdp(product)` and `16.sdp` differ.** Expected: the default reference is 300 pt of smallest width; `ratio` is `sw / 300`. `s.base * s.ratio` (or `BuiltInStrategies.scaled`) gives exactly `sdp`.

**My text formula misses the fast path.** Only `base * E` qualifies. `base * sw / 360` reads as `(base * sw) / 360`; write `base * (sw / 360)`.

**Values are wrong in a second window on iPad, or do not update before iOS 17.** `16.cdp` reads the ambient store. Use `@CustomDimension` or `16.cdp(brand, dimens)` with `@Environment(\.appDimensConfiguration) var dimens`, which follow the view's own window.

**Fonts ignore my strategy.** `csp` follows Dynamic Type by default. Use `fontScale: .ignore` for fixed text, or `.clamp(max)` to cap it. `csp` already returns the final size: pass it to `.system(size:)` without scaling it again.

**The device class is wrong on Mac Catalyst or Apple TV.** Detection uses the `UiModeType`, then the platform, then `sw >= 600`. Set `ScalingStrategies.deviceClassResolver` to override it.

**Are the numbers the same on Android / Flutter / Web?** Yes for everything that can be written as JSON (curves, rules, text formulas): a shared 540-case fixture (`Tests/AppDimensTests/Fixtures/custom-strategy-fixture.json`, checked by `CustomStrategyTests`) checks every platform. Code closures run your own code, so they match as long as the code does. The only difference is error handling: a non-finite factor falls back to 1 here instead of throwing.

[Back to the custom docs](README.md)
