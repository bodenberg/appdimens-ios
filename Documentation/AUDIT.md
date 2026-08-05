# Auditoria do porte

## Escopo analisado

O porte foi redesenhado após inventário do upstream 3.1.6: artefato principal, treze satélites, APIs `code`/Compose, qualifiers, orientation inverters, builder Auto, cache/configuração, curvas matemáticas, unidades e resize. A antiga implementação iOS foi descartada porque misturava core com SwiftUI/UIKit/Metal, duplicava APIs entre targets e adicionava subsistemas de jogos não pertencentes ao upstream.

## Decisões Apple-native

1. **Pontos como unidade-base:** equivalem conceitualmente a dp, enquanto pixels permanecem opt-in.
2. **Container, não tela global:** essencial para iPad Split View, Stage Manager, sheets, macOS e visionOS.
3. **Sem cache global:** cálculos são O(1), value-semantic e `Sendable`; não há configuração stale nem locks.
4. **Dynamic Type real:** UIKit usa `UIFontMetrics`; SwiftUI pode continuar usando estilos semânticos.
5. **Módulos SwiftPM:** Core não importa UI; Strategies depende só de Core; UI é a camada opcional.
6. **API enxuta:** opções nomeadas substituem a explosão combinatória de sufixos Kotlin, mantendo aliases fundamentais.

## Matriz de paridade

| Família upstream | Estado iOS |
|---|---|
| plain/scaled + dp/sp/em | implementado |
| auto + prioridades/thresholds | implementado |
| density/diagonal/fill/fit/fluid | implementado |
| interpolated/logarithmic/percent/perimeter/power | implementado |
| units | implementado com pontos e PPI injetável |
| resize math | implementado (busca binária) |
| Compose environment | equivalente SwiftUI implementado |
| Android configuration cache | deliberadamente substituído por contexto value-semantic |

Validação automatizada cobre baseline, eixos, texto, conversão de pixels, multi-janela, prioridades, todas as estratégias, fórmulas canônicas, clamps, resize e unidades físicas. A compilação Linux valida que Core/Strategies não dependem acidentalmente de frameworks Apple; a compilação Apple deve ser executada pelo CI/Xcode em macOS.
