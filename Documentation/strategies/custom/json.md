# JSON format

One JSON document describes any number of strategies. The same file loads on every AppDimens platform and gives the same numbers, so a design system can ship it as a design token, through remote config or for an A/B test.

```swift
try ScalingStrategies.load(resource: "appdimens-strategies")   // appdimens-strategies.json in Bundle.main; registers all + applies "default"
try ScalingStrategies.load(json: text)                          // same, from a String
try ScalingStrategies.load(data: data)                          // same, from Data
let brand = try ScalingStrategies.require("brand")
let json = try ScalingStrategyJSON.text(try brand.toJSON())     // export one strategy (sorted keys)
let doc = try ScalingStrategyJSON.text(try ScalingStrategies.exportJSON())   // every registered strategy
```

Add the file to the app target (or pass `bundle:` for a package resource bundle). The input can be a document, a single strategy object, or an array of strategy objects. Each `load` returns the strategies it registered, as `[String: ScalingStrategy]` (`@discardableResult`).

## Document

```json
{
  "$schema": "https://github.com/bodenberg/appdimens-skills/schemas/custom-strategy.schema.json",
  "version": 1,
  "default": "brand",
  "strategies": [
    {
      "id": "brand",
      "reference": { "width": 360, "height": 640 },
      "curve": { "type": "power", "exponent": 0.8 },
      "clamp": { "min": 0.85, "max": 1.6 },
      "fontScale": { "max": 1.3 },
      "rules": [
        { "name": "large", "when": { "device": ["tablet", "desktop"] },
          "set": { "curve": { "type": "logarithmic", "k": 0.4 } } },
        { "when": { "smallestWidth": { "min": 600 }, "orientation": "landscape" },
          "set": { "multiplier": 0.9 } }
      ]
    },
    { "id": "brandText", "extends": "brand", "valueClamp": { "min": 10, "max": 32 } },
    { "id": "hud", "formula": "base * pow(sw / 360, 0.8)" }
  ]
}
```

| Key | Meaning |
|---|---|
| `version` | format version, currently 1 (`ScalingStrategyJson.formatVersion`) |
| `default` | id that becomes `ScalingStrategies.defaultStrategy` (optional) |
| `strategies[]` | the strategies, each with a unique `id` |

## Strategy fields

| Field | Example | Notes |
|---|---|---|
| `id` | `"brand"` | required, unique in the document |
| `extends` | `"power"` | another strategy of the document, a registered one, a built-in (`scaled` `power` `logarithmic` `interpolated` `diagonal` `perimeter` `fixed`) or a preset (`tabletFriendly`…). The parent's rules come first |
| `reference` | `{"width": 360, "height": 640}` | design frame (pt) |
| `axis` | `"smallestWidth"` | `smallestWidth` `width` `height` `min` `max` `diagonal` `perimeter` |
| `curve` | `"linear"` or `{"type": …}` | see the [curve table](configuration.md#curves) |
| `multiplier` | `0.9` | |
| `clamp` | `{"min": 0.85, "max": 1.6}` | factor bounds; `null` clears inherited bounds |
| `valueClamp` | `{"min": 10, "max": 32}` | pt bounds, ≥ 0; `null` clears |
| `aspectRatio` | `true` or `{"enabled": true, "sensitivity": 0.004}` | |
| `sensitivity` | `0.004` | aspect-ratio k on its own (useful in a rule) |
| `fontScale` | `"follow"` · `"ignore"` · `{"max": 1.3}` | `csp` policy |
| `ignoreMultiWindow` | `true` | |
| `formula` | `"max(scaled, base)"` | per-value [text formula](text-formulas.md); `null` clears an inherited one |
| `rules` | `[{"name": …, "when": {…}, "set": {…}}]` | `set` takes any field above except `id`, `extends` and `rules` |

## Rule conditions (`when`)

| Key | Example |
|---|---|
| `device` | `"tv"` or `["tablet", "desktop"]` (`phone` `tablet` `desktop` `tv` `watch` `car` `vr`) |
| `orientation` | `"landscape"` or `"portrait"` |
| `smallestWidth` · `width` · `height` · `aspectRatio` | `{"min": 600, "max": 840}`, with `min <= value < max` |
| `multiWindow` | `true` |

An omitted `when` matches every screen.

## Validation

Loading is strict and atomic: the whole document is parsed, validated and turned into strategies before anything is registered, so on any error **nothing** is registered and the default does not change. Every error is a `ScalingStrategyError` whose `description` carries the JSON path. Examples:

| Input | Error |
|---|---|
| `"curve": {"type": "cubic"}` | `brand.curve.type 'cubic' is not one of linear, power, logarithmic, interpolated, constant, breakpoints, expression` |
| `"when": "tablet"` | `brand.rules[0].when must be an object` |
| `"width": 600` in a condition | `brand.rules[0].when.width must be an object with min/max` |
| `"ignoreMultiWindow": "true"` | `brand.ignoreMultiWindow must be a boolean` |
| `"axis": "diag"` | `brand.axis: Unknown axis 'diag'. Expected one of smallestWidth, width, height, min, max, diagonal, perimeter` |
| `"valueClamp": {"max": -1}` | `strategy: maxValue must be >= 0` |
| `"formula": "base * sww"` | `brand.formula: Invalid expression at 7: unknown variable 'sww' …` |
| `"default": "missing"` | `No scaling strategy 'missing'. Registered: …`; nothing is registered |
| duplicate ids · `extends` cycles · unknown parent | `Duplicate strategy id 'brand'` · `Cyclic 'extends': a → b → a` · `'x' extends unknown strategy 'y'` |
| missing bundle file | `Resource 'appdimens-strategies.json' not found in bundle` |

To validate without registering, call `try ScalingStrategyJSON.parse(text, lookup: { ScalingStrategies[$0]?.config })`; it returns a `Document` (`ids`, `configs`, `defaultId`). Check a file before shipping it with the AppDimens kit (`npx appdimens-skills kit custom check <file>`), which uses the same engine and the [JSON schema](https://github.com/bodenberg/appdimens-skills/blob/main/schemas/custom-strategy.schema.json).

## Export

`strategy.toJSON()` returns one strategy object as a `JSONValue`, and `ScalingStrategies.exportJSON(_:)` a whole document with `version`, `default` and `strategies` (default: every registered strategy, sorted by id). `ScalingStrategyJSON.text(_:)` turns either into a string. A document reloads unchanged. Code closures (`CustomScaleStrategy { }`, `scalingFormula { }`, `.custom { }`, `transform:`) cannot be exported and throw (`Custom curve functions cannot be encoded to JSON` · `transform functions cannot be encoded to JSON`). Use their text equivalents when you need JSON.

[Back to the custom docs](README.md)
