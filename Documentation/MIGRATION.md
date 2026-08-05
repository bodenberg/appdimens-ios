# Migração Android → Apple

| Android/Compose | Swift/SwiftUI |
|---|---|
| `16.sdp` | `16.sdp(in: context)` ou `@DynamicDimension(16)` |
| `100.wdp`, `48.hdp` | `100.wdp(in:)`, `48.hdp(in:)` |
| `16.ssp` | `16.ssp(in:)`; em UI prefira Dynamic Type |
| `16.sem` | `16.sem(in:)` |
| `AppDimensProvider` | `AppDimensProvider` |
| `UiModeType.TELEVISION` | `DimensInterfaceMode.television` |
| `DpQualifier.SMALL_WIDTH` | `DimensQualifier.smallestWidth` |
| `16.autoScaledDp().screen(...)` | `16.autoScaled.screen(...).resolve(in:)` |
| módulo Maven | produto SwiftPM |

Não porte `Context`, `Configuration`, density DPI ou cache global. Passe `DimensContext`, deixe SwiftUI observar seu container e UIKit obter bounds na main actor. Safe areas são responsabilidade normal do layout SwiftUI/UIKit e não devem ser subtraídas silenciosamente pela biblioteca.

### Sufixos Android

Os sufixos `a`, `i` e `ia` tornam-se opções nomeadas (`aspectRatioAware`, `ignoreMultiWindow`). Inversores como `sdpPh` tornam-se `DimensOptions(qualifier: .smallestWidth, inverter: .portraitHeight)`. Isso mantém a interpretação familiar sem multiplicar centenas de símbolos pouco descobríveis no autocomplete Swift.
