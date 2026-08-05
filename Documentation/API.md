# Referência de API

## Módulos

| Produto | Conteúdo |
|---|---|
| `AppDimensCore` | contexto, escala linear, texto, pixels e dimensão adaptativa |
| `AppDimensStrategies` | curvas, percentual, unidades físicas e busca de resize |
| `AppDimensUI` | reexportação dos anteriores, ambiente SwiftUI e pontes UIKit |
| `AppDimens` | pacote conveniente com os três módulos |

## Contexto e unidades

`DimensContext` usa **pontos**, não pixels. Inicialize com largura/altura positivas, escala do display, escala de texto e modo de interface. `smallestWidth`, `longestWidth`, `orientation`, `aspectRatio` e `isMultiWindow` são derivados.

- `16.sdp(in:)`: menor eixo, equivalente a `smallestScreenWidthDp`.
- `16.wdp(in:)` / `16.hdp(in:)`: largura/altura atual.
- `16.ssp(in:)`: geometria responsiva × `dynamicTypeScale`.
- `16.sem(in:)`: geometria responsiva sem escala tipográfica.
- `Dimens.pixels` / `Dimens.points`: conversão explícita com `displayScale`.

`Dimens.scale(_:in:options:)` expõe `DimensOptions`: qualificador, inversor de orientação, curva sensível ao aspecto e bypass em multi-janela.

## Valores adaptativos (`DimenAuto`)

```swift
let value = 16.autoScaled
  .screen(.init(mode: .pad, qualifier: .width, minimum: 700), value: 24)
  .screen(.init(orientation: .landscape), value: 20)
  .aspectRatio()
  .resolve(in: context)
```

A condição mais específica vence (modo + qualificador + orientação); entre thresholds iguais, o primeiro declarado vence; entre thresholds diferentes, vence o maior que couber. O builder é um value type imutável.

## Estratégias e opções

`DimensStrategies.resolve(_:strategy:in:options:)` e `.dynamic(_:in:options:)` aceitam `StrategyOptions`. Os controles incluem eixo, inversão, percentual, ranges fluidos, expoente power e peso interpolado.

| Estratégia | Uso típico |
|---|---|
| scaled/auto/density | layout geral compatível com sdp |
| fit/fill | mídia que deve caber/preencher |
| power/logarithmic | crescimento amortecido em telas grandes |
| fluid/interpolated | transição limitada/suave |
| diagonal/perimeter | escala geométrica bidimensional |
| percent | fração do eixo escolhido |
| physical | seleção sem escala; conversão por `DimensPhysical` |

## SwiftUI e UIKit

`AppDimensProvider` injeta `EnvironmentValues.dimensContext` usando `GeometryReader`. `@DynamicDimension` resolve uma propriedade no ambiente. `.dynamicPadding` é o modificador pronto inicial; qualquer API SwiftUI aceita diretamente seu `wrappedValue` em `CGFloat`.

UIKit oferece `DimensContext.current(in:)` no ator principal e `UIFont.appDimensScaled`, que delega a `UIFontMetrics`. Prefira o bounds da view: ele representa popover, sheet e multi-janela corretamente.
