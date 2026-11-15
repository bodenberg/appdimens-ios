# Library map

| Need | Product/import | Main API |
|---|---|---|
| Complete library | `AppDimensDynamic` | all exports below except satellite catalogs |
| Core scaling | `AppDimens` | `16.sdp`, `hdp`, `wdp`, `ssp`, `sem`, facilitators, `scaledDp()` builder, `AppDimensProvider`, `AppDimens.configuration` |
| Runtime strategy | `AppDimensStrategies` | `16.dynamic(.power)`, `DynamicDimens`, `StrategyOptions`, `DimensFactors` |
| Satellite curves | `AppDimensPower`, `AppDimensAuto`, `AppDimensFluid`, `AppDimensPercent` … | `pwsdp`, `asdp`, `fsdp`, `psdp`, `spaceW` …, `powerDp()` builders |
| Fit candidates | `AppDimensResize` | `DimensResize`, `ResizeBound` |
| Units | `AppDimensUnits` | `DimenPhysicalUnits`, `5.mm` |
| Custom | `AppDimensCustom` | `CustomScaleStrategy { s in … }` (factor), `scalingFormula { $0.base * … }` (value), text `try scalingFormula("…")` / `try 16.cdp("…")`, `ScalingStrategy.define`, `ScalingStrategies`, `CustomPresets`, `16.cdp(brand)`, `14.csp(brand)`, `@CustomDimension`, `.scalingStrategy(_:)` |
| GPU uniforms | `AppDimensMetal` | `AppDimensUniforms`, `AppDimensMetal`, `setAppDimensUniforms` |

Source of truth: `Package.swift` and declarations under `Sources/`. User docs: `Documentation/README.md`. Custom strategies: [`custom.md`](custom.md) (agent notes) and [`Documentation/strategies/custom/`](../../../Documentation/strategies/custom/README.md) (guides).
