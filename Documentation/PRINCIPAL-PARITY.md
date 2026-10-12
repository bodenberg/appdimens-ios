# Android parity

[Documentation hub](README.md) · [Migration](MIGRATION.md) · [Mathematics](MATHEMATICS-AND-CALCULUS.md)

Reference: [appdimens-dynamic](https://github.com/bodenberg/appdimens-dynamic) 3.2.0.

| Area | Android | Apple | Status |
|---|---|---|---|
| Constants | `DesignScaleConstants`, `DimenCache` constants | `DimensConstants` | identical |
| Window snapshot | `DimenMetrics` (eager factors) | `DimenMetrics` (eager factors, `Double`) | identical formulas |
| Scaled kernel | `calculateScaledDpCompose` | `AppDimens.scaledDp` | identical, incl. custom k |
| Inverters | `effectiveQualifier` | `DimensConfiguration.effectiveQualifier` | identical (`DEFAULT` never swaps) |
| Satellites | 11 `calculate<Strategy>DpCompose` | 11 kernels | identical |
| Catalog names | `sdp`…`wemPhia`, `Px`, `sei` | same names | identical (+ `<name>Px` spellings) |
| Facilitators | `Rotate/Mode/Qualifier/Screen` + `Px` + `Plain` | same, same argument order | identical semantics |
| Builders | `DimenScaled`, `ScaledSp`, `Dimen<Strategy>` | `DimenBuilder` (+ aliases) | priorities 1–4, threshold ordering |
| Percent space | `spaceW/H/Sw`, `space(ref)` + variants | same | identical |
| Resize | `ResizeBound`, auto-resize ladders | same | identical ladder semantics |
| Units | `DimenPhysicalUnits` | same names | uses points-per-inch (Apple has no physical DPI API) |
| Provider | `AppDimensProvider` | `AppDimensProvider` / `.appDimens()` | + automatic SwiftUI invalidation |
| Multi-window | `Activity.isInMultiWindowMode` | window vs screen (or explicit flag) | equivalent |
| Font scale | `Configuration.fontScale` | Dynamic Type body ratio | equivalent |
| Results | `Float` | `Double` | agree to Float rounding (tested, 2e-6 relative) |
| Metal | — | `AppDimensMetal` | Apple-only addition |

`AndroidFloatParityTests` recomputes every factor with the Kotlin `Float` code path for twelve windows (240×320 … 1920×1080) and compares.
