# Cookbook

Ready-to-use strategies. Each one shows the code form and, where it matters, the JSON form. Declare them as `static let` in one place (for example `enum AppStrategies`).

## Grow on iPhone, calm down on iPad

```swift
let calm = CustomScaleStrategy { s in s.sw < 600 ? s.ratio : 2 + (s.sw - 600) / 1000 }
```

```swift
let calm = CustomPresets.tabletFriendly        // linear on phones, power(0.5) on iPad and Mac, ≤ 1.8
```

## Design frame of 360 pt, never below 85% or above 160%

```swift
let brand = CustomScaleStrategy { s in s.clamp(s.sw / 360, 0.85, 1.6) }
```

```json
{ "id": "brand", "reference": { "width": 360, "height": 640 }, "clamp": { "min": 0.85, "max": 1.6 } }
```

## Sublinear growth (big screens grow slower)

```swift
let soft = CustomScaleStrategy { s in s.pow(s.sw / 360, 0.75) }
```

```json
{ "id": "soft", "reference": { "width": 360, "height": 640 }, "curve": { "type": "power", "exponent": 0.75 } }
```

## Apple TV: scale by height, 10-foot UI

```swift
let living = CustomScaleStrategy { s in s.tv ? s.clamp(s.height / 540, 1, 2) : s.ratio }
```

```json
{ "id": "living", "rules": [ { "when": { "device": "tv" },
  "set": { "axis": "height", "reference": { "width": 960, "height": 540 }, "clamp": { "min": 1, "max": 2 } } } ] }
```

## Apple Watch: almost fixed sizes

```swift
let wrist = CustomScaleStrategy { s in s.watch ? s.clamp(s.shortSide / 192, 0.85, 1.15) : s.ratio }
```

## Game HUD: shorter side, aspect-ratio aware

```swift
let hud = try ScalingStrategy.define("hud",
    axis: .min,
    curve: .power(0.85),
    minFactor: 0.75, maxFactor: 2.5,
    aspectRatio: true,
    fontScale: .ignore)                  // HUD text never follows Dynamic Type
```

## Readable text: grow slowly, cap Dynamic Type

```swift
let body = try ScalingStrategy.define("body", curve: .logarithmic(0.4), fontScale: .clamp(1.3))
Text("…").font(.system(size: 16.csp(body)))
```

## Minimum tap target

```swift
let touch = try ScalingStrategy.define("touch", minValue: 44)
Button("OK") { }.frame(minWidth: 40.cdp(touch), minHeight: 40.cdp(touch))   // never below 44 pt
```

## Whole points only

```swift
let snap = scalingFormula { s in s.round(s.base * s.ratio) }
```

```json
{ "id": "snap", "formula": "round(base * ratio)" }
```

## Never smaller than the design value

```swift
let floor = scalingFormula { s in s.max(s.base * s.ratio, s.base) }
```

## Split View and Stage Manager: keep the design values

```swift
let steady = try ScalingStrategy.define("steady", ignoreMultiWindow: true)
```

## Landscape iPhone: a bit smaller

```swift
let brand = try ScalingStrategy.define("brand",
    curve: .power(0.8),
    rules: [ScalingRule(ScreenCondition(landscape: true, maxSmallestWidth: 600), ScalingPatch(multiplier: 0.9))])
```

## A/B test or remote config

```swift
let json: String = fetchRemoteStrategies()            // your remote-config value: a strategies document
do {
    try ScalingStrategies.load(json: json)               // atomic: a bad document changes nothing
} catch {
    print("bad strategies JSON: \(error)")               // ScalingStrategyError with the path
}
let brand = ScalingStrategies["brand"] ?? BuiltInStrategies.scaled
Text("Hi").padding(16.cdp(brand))
```

## One growth law for a design system

Ship a single `appdimens-strategies.json` with the design tokens, load it in every app (`ScalingStrategies.load(resource:)` on Apple platforms, `loadAsset` on Android, `loadJson` elsewhere), and use the ids only. Android, Flutter, React Native, Web, KMP, Games and .NET read the same file and get the same numbers.

[Back to the custom docs](README.md)
