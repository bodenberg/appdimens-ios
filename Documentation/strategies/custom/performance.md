# Performance

Custom strategies cost about the same as the built-ins when they only depend on the screen. Which form you pick decides the work done per value.

| Form | Per window | Per value |
|---|---|---|
| `CustomScaleStrategy { … }`, any curve, rules, factor bounds, aspect ratio | closure / curve once | one multiply |
| text formula shaped `base * E` (E reads no value) | `E` once | one multiply |
| `minValue` / `maxValue` | | a few comparisons |
| `scalingFormula { … }`, `transform:` | | your closure, on every call |
| other text formulas | | the parsed formula, on every call |

## How it works

- **Memo per window.** Each strategy keeps the last resolved window (rules applied, factor computed), keyed by the `DimensConfiguration` and the device class, behind an `NSLock`. A new window (rotation, resize, Split View, Dynamic Type, UI mode) resolves again once; every other call is a lock-protected memo check plus one multiply. Strategies are safe to use from any thread.
- **No per-value cache.** A value-dependent strategy runs its formula on each call. Text formulas are parsed once, when the strategy is created; evaluating the parsed tree costs a few operations.
- **Fast path for text.** `base * E` is detected when the formula is parsed; the result is bit for bit the same as evaluating it per value, and `isValueDependent` is `false`.
- **Shared text strategies.** `try 16.cdp("…")`, `try ScalingStrategies.formula("…")` and `@CustomDimension(_:formula:)` look the text up in a table of up to 256 entries, so the same text keeps its memo across calls.
- **One window, many values.** In a hot loop, resolve once and reuse it: `let r = brand.resolve(c)` then `r.scale(16)`, `r.scale(24)`….

## Guidelines

1. Prefer a factor (`CustomScaleStrategy`, a curve, rules) over a per-value formula when the math is "base × something about the screen".
2. Use `minValue` / `maxValue` only for real absolute limits (44 pt tap targets, max text size).
3. Declare strategies once: a `static let` in an `enum AppStrategies`, or a JSON document loaded at launch. A strategy built in `body` has an empty memo, so it resolves the window again on every call.
4. Keep closures pure and cheap. They run on the calling thread, on every memo miss or, for `scalingFormula { }`, on every call.
5. Text formulas inline (`try 16.cdp("…")`) are shared per text, so they are fine in `body`. Building strategies from dynamic strings in a loop is not: past 256 distinct texts each call builds a new strategy.

[Back to the custom docs](README.md)
