# Principal artifact parity audit

This phase inventories only Android `library/`, not the satellite modules.

| Android principal area | Apple port |
|---|---|
| `common/DpQualifier` | `DpQualifier` |
| `common/Inverter` (8 mappings + default) | `Inverter` |
| `common/Orientation` | `DimensOrientation` |
| `common/UiModeType` | `UiModeType` adapted to Apple families |
| `core/DesignScaleConstants` | `AppDimens.baseRatio`, reference AR |
| `core/DimenCalculationPlumbing` | `DimensConfiguration.dimension` |
| `code/compose scaled dp` | numeric APIs + `@ScaledDimension` |
| `code/compose scaled sp/em` | `ssp/hsp/wsp` and `sem/hem/wem` |
| `scaledDp()` builder | `ScaledDp` value type |
| `Configuration` / `LocalConfiguration` | shared window/scene `DimensConfiguration` |

## Invariant

For a given window and configuration, a base value has one result. UIKit child bounds are never used as the global configuration. SwiftUI installs one provider at the scene root. Explicit `DimensConfiguration` exists for tests/headless use, not as a routine UI requirement.

## Intentional Apple adaptations

- Android dp maps to Apple points.
- Android density conversion maps to explicit `displayScale`; normal layout remains in points.
- Android font scale maps to Dynamic Type size categories.
- Android `Configuration` maps to the active `UIWindowScene`/SwiftUI root window container.
- Global mutable cache is omitted because the formula is O(1) and the configuration is a small `Hashable`, `Sendable` value.

## Deferred

No satellite strategy is claimed in this phase: auto, density, diagonal, fill, fit, fluid, interpolated, logarithmic, percent, perimeter, power, resize and units remain future work. Metal is also deferred until the principal contract is accepted.
