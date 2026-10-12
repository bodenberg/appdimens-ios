# Physical units

[Strategy catalog](../STRATEGIES.md) · [Mathematics](../MATHEMATICS-AND-CALCULUS.md) · [API](../API.md)

## Theory

AppDimens follows the typographic identity `1 inch = 72 points = 2.54 centimeters = 25.4 millimeters` when you pass `pointsPerInch: 72`. Apple points are logical units, and every conversion takes an explicit `pointsPerInch`. The default is `devicePointsPerInch`, a per-idiom estimate (163 on iPhone, 132 on iPad, 110 on Mac, 160 elsewhere). The ambient `5.mm`, `1.cm` and `1.inch` use that default, so `1.inch` is about 163 points on an iPhone.

`displayScale` is pixels per point and is **not** physical pixels per inch (PPI). Point conversion is deterministic once `pointsPerInch` is fixed, but accurate physical pixels need a calibrated PPI supplied by the caller, divided by `displayScale` to give points per inch.

| Input | Points (72 per inch) | Pixels without calibrated PPI |
|---|---:|---:|
| 1 inch | 72 | `72 × displayScale` |
| 1 centimeter | `72/2.54 ≈ 28.346` | points × scale |
| 1 millimeter | `72/25.4 ≈ 2.835` | points × scale |
| 1 pixel | `1/displayScale` | 1 |

## Swift examples

```swift
import AppDimensDynamic

let c = DimensConfiguration(screenWidth: 390, screenHeight: 844, displayScale: 3)
let tenMillimeters = DimenPhysicalUnits.toDpFromMm(10, pointsPerInch: 72)
// ≈ 28.346 points

let badgeRadius = DimenPhysicalUnits.radiusFromDiameter(10, .mm, c, pointsPerInch: 72)
// ≈ 14.173 points

let rasterPixels = DimenPhysicalUnits.toPxFromMm(10, c, pointsPerInch: 72)
// ≈ 85.039 pixels (28.346 points × displayScale 3); visually consistent, not calibrated

// Calibrated: a 460 PPI panel at 3× has 460 / 3 ≈ 153.33 points per inch.
let printPixels = DimenPhysicalUnits.toPxFromMm(10, c, pointsPerInch: 460.0 / 3.0)
// ≈ 181.102 physical pixels
```

## Recommended use

Use points for print previews, rulers, PDF-oriented layouts, or specifications defined in typographic units. Supply verified PPI for medical, manufacturing, measurement, or print rasterization. Ordinary app controls should use scaled design tokens and platform accessibility guidance instead.

## Caveats and validation

A point on screen is not guaranteed to occupy `1/72` physical inch. Display zoom, mirroring, external displays, and inaccurate PPI metadata invalidate physical assumptions. Calibrate against a known ruler when real-world accuracy matters. Never claim physical measurement accuracy from `displayScale` alone.
