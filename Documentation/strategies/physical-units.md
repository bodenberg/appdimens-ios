# Physical units

[Strategy catalog](../STRATEGIES.md) · [Mathematics](../MATHEMATICS-AND-CALCULUS.md) · [API](../API.md)

## Theory

AppDimens follows the typographic identity `1 inch = 72 points = 2.54 centimeters = 25.4 millimeters`. Apple points are logical units; `displayScale` is pixels per point and is **not** physical pixels per inch (PPI). Therefore point conversion is deterministic, while accurate physical pixels require calibrated PPI supplied by the caller.

| Input | Points | Pixels without calibrated PPI |
|---|---:|---:|
| 1 inch | 72 | `72 × displayScale` |
| 1 centimeter | `72/2.54 ≈ 28.346` | points × scale |
| 1 millimeter | `72/25.4 ≈ 2.835` | points × scale |
| 1 pixel | `1/displayScale` | 1 |

## Swift examples

```swift
import AppDimensDynamic

let c = DimensConfiguration(screenWidth: 390, screenHeight: 844, displayScale: 3)
let tenMillimeters = DimensUnits.points(10, from: .millimeter, configuration: c)
// ≈ 28.346 points

let rasterPixels = DimensUnits.pixels(10, from: .millimeter, configuration: c)
// ≈ 85.039 pixels using displayScale; visually consistent, not calibrated

let printPixels = DimensUnits.pixels(
    10, from: .millimeter, configuration: c, pixelsPerInch: 460
)
// ≈ 181.102 pixels using the supplied physical calibration
```

## Recommended use

Use points for print previews, rulers, PDF-oriented layouts, or specifications defined in typographic units. Supply verified PPI for medical, manufacturing, measurement, or print rasterization. Ordinary app controls should use scaled design tokens and platform accessibility guidance instead.

## Caveats and validation

A point on screen is not guaranteed to occupy `1/72` physical inch. Display zoom, mirroring, external displays, and inaccurate PPI metadata invalidate physical assumptions. Calibrate against a known ruler when real-world accuracy matters. Never claim physical measurement accuracy from `displayScale` alone.
