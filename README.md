# AppDimens Dynamic for Apple Platforms

## Dimensões responsivas para Swift, SwiftUI e UIKit

[![Swift 5.9](https://img.shields.io/badge/Swift-5.9-F05138?logo=swift&logoColor=white)](https://www.swift.org)
[![Platforms](https://img.shields.io/badge/platforms-iOS%20%7C%20macOS%20%7C%20tvOS%20%7C%20watchOS%20%7C%20visionOS-blue)](Package.swift)
[![License](https://img.shields.io/badge/license-Apache%202.0-green)](LICENSE)
[![Strategies](https://img.shields.io/badge/estrat%C3%A9gias-14-orange)](Documentation/API.md)

Porte Apple-native da [AppDimens Dynamic para Android](https://github.com/bodenberg/appdimens-dynamic). A biblioteca preserva conceitos familiares — `sdp`, `wdp`, `hdp`, `ssp`, `sem`, qualifiers, inversores, valores adaptativos e estratégias — usando os equivalentes corretos da plataforma Apple: **pontos**, containers, traits, Dynamic Type, Swift Package Manager e value semantics.

> **Começando agora?** Siga [Instalação](#instalação-pelo-xcode) e [Início rápido](#início-rápido--swiftui). Depois consulte a [referência da API](Documentation/API.md), [matemática](Documentation/MATHEMATICS.md), [migração Android → Apple](Documentation/MIGRATION.md) e [auditoria do porte](Documentation/AUDIT.md).

---

## Índice

- [Características](#características)
- [Requisitos](#requisitos)
- [Instalação pelo Xcode](#instalação-pelo-xcode)
- [Produtos e modularidade](#produtos-e-modularidade)
- [Início rápido — SwiftUI](#início-rápido--swiftui)
- [Início rápido — UIKit](#início-rápido--uikit)
- [DimensContext](#dimenscontext)
- [Extensões escaladas](#extensões-escaladas)
- [Qualifiers e inversores](#qualifiers-e-inversores)
- [Aspect ratio e multi-window](#aspect-ratio-e-multi-window)
- [DimenAuto / AdaptiveDimension](#dimenauto--adaptivedimension)
- [As 14 estratégias](#as-14-estratégias)
- [Percentual](#percentual)
- [Unidades físicas](#unidades-físicas)
- [Resize](#resize)
- [SwiftUI](#swiftui)
- [UIKit](#uikit)
- [Metal](#metal)
- [Equivalência Android → Apple](#equivalência-android--apple)
- [Concorrência, cache e desempenho](#concorrência-cache-e-desempenho)
- [Testes](#testes)
- [Limitações da plataforma](#limitações-da-plataforma)

---

## Características

- Baseline compatível com AppDimens Dynamic: largura `300`, altura `533` e aspect ratio de referência `1.78`.
- APIs familiares: `sdp`, `wdp`, `hdp`, `ssp` e `sem`.
- Quatorze famílias: `plain`, `scaled`, `auto`, `density`, `diagonal`, `fill`, `fit`, `fluid`, `interpolated`, `logarithmic`, `percent`, `perimeter`, `power` e `physical`.
- Builder adaptativo imutável com modo de interface, orientação, qualifier e threshold.
- Curva opcional sensível ao aspect ratio.
- Tratamento configurável de multi-window.
- Integração SwiftUI por environment, property wrapper e modifier.
- Integração UIKit baseada nos bounds reais da view/janela.
- Conversão entre pontos e pixels e suporte a milímetros, centímetros e polegadas.
- Busca binária para obter o maior tamanho que cabe.
- Núcleo `Sendable`, determinístico e testável, sem dependência de UIKit ou SwiftUI.

## Requisitos

| Componente | Requisito mínimo |
|---|---|
| Swift | 5.9 |
| Xcode | 15 |
| iOS / tvOS | 13 |
| watchOS | 6 |
| macOS | 10.15 |
| visionOS | 1 |
| Dependências externas | Nenhuma |

## Instalação pelo Xcode

A biblioteca está distribuída pelo GitHub como Swift Package; não é necessário CocoaPods.

1. Abra o projeto no Xcode.
2. Selecione **File › Add Package Dependencies…**.
3. Informe:

   ```text
   https://github.com/bodenberg/appdimens-ios
   ```

4. Selecione uma versão/tag publicada com **Up to Next Major Version**, ou o branch desejado durante desenvolvimento.
5. Adicione ao target um dos produtos descritos abaixo.

Em outro `Package.swift`:

```swift
dependencies: [
    .package(
        url: "https://github.com/bodenberg/appdimens-ios",
        from: "1.0.0"
    )
],
targets: [
    .target(
        name: "MyApp",
        dependencies: [
            .product(name: "AppDimensUI", package: "appdimens-ios")
        ]
    )
]
```

> Enquanto não houver uma tag compatível com `1.0.0`, selecione explicitamente o branch no Xcode ou use `.branch("main")` no manifesto.

## Produtos e modularidade

| Produto | Importe | Conteúdo | Indicado para |
|---|---|---|---|
| `AppDimensCore` | `import AppDimensCore` | contexto, engine e dimensão adaptativa | código de domínio e pacotes sem UI |
| `AppDimensStrategies` | `import AppDimensStrategies` | 14 estratégias, resize e unidades físicas | cálculos avançados sem SwiftUI |
| `AppDimensUI` | `import AppDimensUI` | reexporta Core/Strategies e adiciona SwiftUI/UIKit | aplicativos Apple |
| `AppDimensMetal` | `import AppDimensMetal` | snapshot pré-calculado, ABI de uniforms e binding Metal | jogos, renderers e visualização GPU |
| `AppDimens` | módulos acima | produto conveniente que vincula os três targets | seleção agregada no Xcode |

O grafo é unidirecional: UI → Strategies → Core. O Core não importa frameworks gráficos Apple.

---

## Início rápido — SwiftUI

```swift
import SwiftUI
import AppDimensUI

struct ContentView: View {
    @DynamicDimension(16) private var spacing
    @DynamicDimension(120, strategy: .fit) private var cardWidth

    var body: some View {
        AppDimensProvider(mode: .phone) {
            VStack(spacing: spacing) {
                Text("AppDimens Dynamic")
                    .font(.headline)

                RoundedRectangle(cornerRadius: spacing)
                    .frame(width: cardWidth, height: 48)
            }
            .dynamicPadding(.all, 16)
        }
    }
}
```

`AppDimensProvider` lê o tamanho disponível pelo `GeometryReader` e injeta `DimensContext` no environment. Isso acompanha rotação, sheets e mudanças do container. O parâmetro `mode` declara o modo Apple equivalente ao `UiModeType` Android.

## Início rápido — UIKit

```swift
import UIKit
import AppDimensUI

@MainActor
func configureCard(_ card: UIView, title: UILabel) {
    let context = DimensContext.current(in: card)
    let inset = CGFloat(16.sdp(in: context))

    card.directionalLayoutMargins = NSDirectionalEdgeInsets(
        top: inset,
        leading: inset,
        bottom: inset,
        trailing: inset
    )

    title.font = UIFont
        .systemFont(ofSize: CGFloat(16.ssp(in: context)))
        .appDimensScaled(forTextStyle: .headline)
}
```

Prefira `DimensContext.current(in: view)` depois que a view estiver associada a uma janela. Assim, os bounds representam a janela/container atual em vez de assumir que o aplicativo ocupa toda a tela.

---

## `DimensContext`

`DimensContext` é um snapshot imutável das informações necessárias ao cálculo:

```swift
let context = DimensContext(
    width: 390,              // pontos
    height: 844,             // pontos
    displayScale: 3,         // pixels por ponto
    dynamicTypeScale: 1.12,  // escala tipográfica
    interfaceMode: .phone,
    fullScreenWidth: 390,
    fullScreenHeight: 844
)
```

| Propriedade | Significado |
|---|---|
| `width`, `height` | viewport atual em pontos |
| `displayScale` | escala usada para converter pontos ↔ pixels |
| `dynamicTypeScale` | multiplicador de texto usado por `ssp` |
| `interfaceMode` | phone, pad, television, watch, CarPlay, vision ou Mac |
| `fullScreenWidth`, `fullScreenHeight` | métricas opcionais para detectar uma janela restrita |
| `smallestWidth` | menor lado atual |
| `longestWidth` | maior lado atual |
| `orientation` | derivada de largura × altura |
| `aspectRatio` | maior lado ÷ menor lado |
| `isMultiWindow` | verdadeiro quando o viewport é significativamente menor que a tela informada |

A inicialização manual é especialmente útil em testes, previews, renderização headless e código sem UI. Em uma interface real, use o provider SwiftUI ou `current(in:)` no UIKit.

## Extensões escaladas

```swift
let padding = 16.sdp(in: context)
let columnWidth = 100.wdp(in: context)
let rowHeight = 48.hdp(in: context)
let scalableText = 16.ssp(in: context)
let fixedScaleText = 16.sem(in: context)
```

| API | Eixo de referência | Dynamic Type | Uso típico |
|---|---|---|---|
| `sdp` | menor lado | não | padding, margem, radius e ícones |
| `wdp` | largura atual | não | colunas e componentes horizontais |
| `hdp` | altura atual | não | componentes verticais |
| `ssp` | menor lado | sim | texto responsivo |
| `sem` | menor lado | não | texto cuja escala tipográfica deve permanecer fixa |

As extensões estão disponíveis para inteiros e floating points. O retorno é `Double`; converta para `CGFloat` somente na fronteira com a UI.

## Qualifiers e inversores

Os qualifiers equivalem a `DpQualifier` do Android:

```swift
let options = DimensOptions(qualifier: .width)
let result = Dimens.scale(24, in: context, options: options)
```

| Swift | Android | Mede |
|---|---|---|
| `.smallestWidth` | `SMALL_WIDTH` | menor lado |
| `.width` | `WIDTH` | largura |
| `.height` | `HEIGHT` | altura |

Os inversores disponíveis são `.portraitWidth`, `.portraitHeight`, `.landscapeWidth` e `.landscapeHeight`. Eles permitem selecionar o eixo físico aplicável após a mudança de orientação:

```swift
let rotated = Dimens.scale(
    24,
    in: context,
    options: .init(
        qualifier: .smallestWidth,
        inverter: .landscapeWidth
    )
)
```

## Aspect ratio e multi-window

Ative o ajuste de aspecto pelas opções nomeadas — equivalentes ao sufixo Android `a`:

```swift
let value = Dimens.scale(
    16,
    in: context,
    options: .init(
        qualifier: .smallestWidth,
        aspectRatioAware: true,
        aspectSensitivity: 0.10
    )
)
```

Para o equivalente ao sufixo `i`, use `ignoreMultiWindow: true`. Quando o contexto detectar uma janela restrita, o valor-base será mantido:

```swift
let value = Dimens.scale(
    16,
    in: context,
    options: .init(ignoreMultiWindow: true)
)
```

| Android | Swift |
|---|---|
| sem sufixo | opções padrão |
| `a` | `aspectRatioAware: true` |
| `i` | `ignoreMultiWindow: true` |
| `ia` | ambas as opções |

---

## DimenAuto / `AdaptiveDimension`

O builder `autoScaled` seleciona um valor-base conforme o contexto e somente depois aplica a escala:

```swift
let buttonHeight = 44.autoScaled
    .screen(
        .init(mode: .pad, qualifier: .width, minimum: 700),
        value: 56
    )
    .screen(
        .init(orientation: .landscape),
        value: 40
    )
    .aspectRatio()
    .resolve(in: context)
```

### Regras de resolução

1. Entradas incompatíveis com o contexto são descartadas.
2. A condição mais específica vence: modo → qualifier → orientação.
3. Entre thresholds aplicáveis, o maior mínimo vence.
4. Em empate total, vence a primeira declaração.
5. Se nenhuma condição corresponder, é usado `baseValue`.
6. O valor escolhido é escalado pelo qualifier final.

O builder é um value type imutável: cada chamada retorna uma cópia, permitindo reutilização segura.

```swift
let base = 16.autoScaled
let compact = base.screen(.init(qualifier: .width, minimum: 320), value: 14)
let tablet = base.screen(.init(mode: .pad), value: 24)
```

---

## As 14 estratégias

```swift
let result = 24.dynamic(
    .power,
    in: context,
    options: .init(power: 0.75)
)
```

| Estratégia | Comportamento | Uso típico |
|---|---|---|
| `plain` | mantém o valor original | opt-out explícito |
| `scaled` | escala linear pelo qualifier | layout geral |
| `auto` | mesma curva linear; seleção condicional fica em `AdaptiveDimension` | APIs adaptativas |
| `density` | alias semântico de scaled em pontos | migração Android |
| `diagonal` | razão entre diagonais | mídia e superfícies bidimensionais |
| `fill` | maior razão de largura/altura | preencher uma área |
| `fit` | menor razão de largura/altura | caber inteiramente em uma área |
| `fluid` | interpolação limitada por viewport e escala | crescimento com limites |
| `interpolated` | mistura entre tamanho fixo e linear | responsividade moderada |
| `logarithmic` | crescimento amortecido logarítmico | telas muito grandes |
| `percent` | percentual literal do eixo × valor/100 | layouts proporcionais |
| `perimeter` | razão entre perímetros | escala bidimensional alternativa |
| `power` | curva `ratio^expoente` | escala perceptual configurável |
| `physical` | mantém o valor; conversão fica em `DimensPhysical` | unidades reais |

### Opções das estratégias

```swift
let options = StrategyOptions(
    qualifier: .width,
    inverter: .none,
    aspectRatioAware: false,
    ignoreMultiWindow: false,
    percent: 50,
    fluidRange: 320...768,
    fluidScale: 0.8...1.2,
    power: 0.75,
    interpolation: 0.5
)
```

### Fit e fill

```swift
let fitted = 120.dynamic(.fit, in: context)
let filled = 120.dynamic(.fill, in: context)
```

`fit` usa a menor razão entre viewport e baseline; `fill` usa a maior. Isso corresponde à diferença entre aspect fit e aspect fill.

### Fluid

```swift
let fluid = 16.dynamic(
    .fluid,
    in: context,
    options: .init(
        fluidRange: 320...1024,
        fluidScale: 0.85...1.35
    )
)
```

A interpolação é limitada: abaixo do range aplica a escala mínima; acima dele aplica a máxima.

### Interpolated

```swift
let subtle = 16.dynamic(
    .interpolated,
    in: context,
    options: .init(interpolation: 0.25)
)
```

`0` mantém o tamanho fixo; `1` equivale à escala linear; valores intermediários combinam os dois comportamentos.

### Power e logarithmic

```swift
let perceptual = 24.dynamic(.power, in: context, options: .init(power: 0.75))
let restrained = 24.dynamic(.logarithmic, in: context)
```

Use essas estratégias quando o crescimento linear produzir componentes excessivamente grandes em iPad, Mac, Apple TV ou visionOS.

## Percentual

`percent` usa `StrategyOptions.percent` como fração literal do eixo e o argumento principal como multiplicador percentual:

```swift
let halfWidth = DimensStrategies.resolve(
    100,
    strategy: .percent,
    in: context,
    options: .init(qualifier: .width, percent: 50)
)
```

Com `value = 100`, o resultado acima equivale a 50% da largura. Para 25% da altura, troque o qualifier por `.height` e `percent` por `25`.

## Unidades físicas

Apple não fornece PPI físico confiável por uma API pública universal. Por isso a conversão em pontos é determinística e a conversão em pixels exige PPI informado pelo consumidor:

```swift
let tenMillimetersInPoints = DimensPhysical.points(
    10,
    unit: .millimeters
)

let oneInchInPixels = DimensPhysical.pixels(
    1,
    unit: .inches,
    pixelsPerInch: 460
)
```

| Unidade | Caso |
|---|---|
| milímetros | `.millimeters` |
| centímetros | `.centimeters` |
| polegadas | `.inches` |

Não confunda `displayScale` (pixels por ponto) com PPI (pixels físicos por polegada).

## Resize

`DimensResize.largestFitting` encontra, em `O(log n)`, o maior item de uma progressão que satisfaz o closure:

```swift
let fontSize = DimensResize.largestFitting(
    minimum: 12,
    maximum: 48,
    step: 1
) { candidate in
    measureText(at: candidate).width <= availableWidth
}
```

Pré-condições:

- `minimum <= maximum`;
- `step > 0`;
- `step` finito;
- o predicado deve ser monotônico para que a busca binária seja válida.

---

## SwiftUI

### Provider

```swift
AppDimensProvider(mode: .pad) {
    Dashboard()
}
```

O provider mede o container real e injeta `EnvironmentValues.dimensContext`. Coloque-o próximo da raiz da cena ou do container que deve definir a escala.

### Environment

```swift
struct Card: View {
    @Environment(\.dimensContext) private var dimens

    var body: some View {
        Text("Card")
            .padding(CGFloat(16.sdp(in: dimens)))
    }
}
```

### Property wrapper

```swift
struct Avatar: View {
    @DynamicDimension(64, strategy: .fit) private var size

    var body: some View {
        Image(systemName: "person.crop.circle")
            .frame(width: size, height: size)
    }
}
```

### Modifier

```swift
Text("Conteúdo")
    .dynamicPadding(.horizontal, 16)
```

`dynamicPadding` aceita a estratégia desejada e resolve o valor novamente quando o environment muda.

## UIKit

### Obter o contexto atual

```swift
@MainActor
func updateLayout(for view: UIView) {
    let context = DimensContext.current(in: view)
    view.layer.cornerRadius = CGFloat(12.sdp(in: context))
}
```

`current(in:)` procura a key window da cena quando a view ainda não possui janela e usa `UIScreen.main` apenas como fallback.

### Dynamic Type

```swift
label.font = UIFont.systemFont(ofSize: 17)
    .appDimensScaled(forTextStyle: .body)
```

Para texto, prefira estilos semânticos e `UIFontMetrics`. `ssp` existe para equivalência conceitual com Android, mas não substitui automaticamente todas as regras de acessibilidade tipográfica do UIKit.

## Metal

Adicione o produto `AppDimensMetal` ao target e importe o módulo. O layout de
`AppDimensMetalUniforms` ocupa exatamente 64 bytes, em quatro lanes `float4`, evitando
padding ambíguo entre Swift e Metal Shading Language:

```swift
import AppDimensMetal

let context = DimensContext.current(in: metalView)
let uniforms = AppDimensMetalUniforms(context: context)
let buffer = AppDimensMetal.makeBuffer(device: device, context: context)!

// Atualize o mesmo buffer somente quando viewport/traits mudarem.
AppDimensMetal.update(buffer, context: context)
AppDimensMetal.bind(buffer, to: encoder, vertexIndex: 2, fragmentIndex: 2)
```

No shader, copie a declaração disponibilizada por
`AppDimensMetalUniforms.metalDeclaration`:

```metal
struct AppDimensUniforms {
    float4 viewport; // width, height, smallest, longest
    float4 ratios;   // smallest, width, height, diagonal
    float4 display;  // displayScale, textScale, aspectRatio, isMultiWindow
    float4 reserved;
};
```

Para loops de CPU sensíveis a latência, construa um `DimensSnapshot` apenas quando o
viewport mudar. Ele pré-calcula razões lineares, diagonal e perímetro e possui uma API
batch in-place sem alocações:

```swift
let snapshot = DimensSnapshot(context)
let radius = snapshot.resolve(12, strategy: .power)

input.withUnsafeBufferPointer { source in
    output.withUnsafeMutableBufferPointer { destination in
        snapshot.resolve(source, into: destination, strategy: .scaled)
    }
}
```

Não crie `MTLBuffer` por frame. Retenha um buffer compartilhado, compare o novo
`DimensContext` com o anterior e chame `update` apenas após resize, rotação, troca de
tela ou Dynamic Type. Consulte o [guia Metal](Documentation/METAL.md).

---

## Equivalência Android → Apple

| Android / Compose | Swift / SwiftUI |
|---|---|
| `16.sdp` | `16.sdp(in: context)` ou `@DynamicDimension(16)` |
| `100.wdp` | `100.wdp(in: context)` |
| `48.hdp` | `48.hdp(in: context)` |
| `16.ssp` | `16.ssp(in: context)` |
| `16.sem` | `16.sem(in: context)` |
| `DpQualifier.SMALL_WIDTH` | `DimensQualifier.smallestWidth` |
| `DpQualifier.WIDTH` | `DimensQualifier.width` |
| `DpQualifier.HEIGHT` | `DimensQualifier.height` |
| `UiModeType.TELEVISION` | `DimensInterfaceMode.television` |
| `Orientation.PORTRAIT` | `DimensOrientation.portrait` |
| sufixo `a` | `aspectRatioAware: true` |
| sufixo `i` | `ignoreMultiWindow: true` |
| sufixo `ia` | ambas as opções |
| `autoScaledDp().screen(...)` | `autoScaled.screen(...).resolve(in:)` |
| Compose `AppDimensProvider` | SwiftUI `AppDimensProvider` |
| Android `Configuration` | `DimensContext` |
| `densityDpi` | pontos + `displayScale` explícito |
| artefatos Maven | produtos SwiftPM |

### Diferenças intencionais

1. **dp → pontos:** ambos são unidades lógicas; não se multiplica layout SwiftUI por density.
2. **sp → Dynamic Type:** a plataforma Apple usa categorias e métricas tipográficas, não `fontScale` global idêntico ao Android.
3. **Configuration → container:** uma cena Apple pode ocupar somente parte da tela.
4. **Cache global → value semantics:** o contexto é explícito e não fica stale após rotação ou redimensionamento.
5. **Centenas de sufixos → opções nomeadas:** preserva o significado sem poluir o autocomplete Swift.

## Concorrência, cache e desempenho

- `DimensContext`, opções, enums e condições são `Sendable`.
- Cálculos comuns são `O(1)` e não fazem I/O.
- Não há singleton mutável de tamanho de tela.
- `AdaptiveDimension` usa value semantics.
- `DimensSnapshot` pré-calcula fatores e oferece resolução batch sem alocação.
- Uniforms Metal possuem ABI fixa de 64 bytes e atualização in-place do buffer.
- Resize usa busca binária `O(log n)`.
- O Core compila sem UIKit e SwiftUI, facilitando testes Linux/headless.

Crie um novo contexto quando a geometria mudar em código sem UI. SwiftUI faz isso pelo provider; UIKit deve consultar `current(in:)` no momento adequado do ciclo de layout.

## Testes

Execute na raiz do pacote:

```bash
swift package describe
swift test
swift test --sanitize=thread
swift build -c release
```

A suíte cobre baseline, eixos, texto, pontos/pixels, orientação, multi-window, qualifiers adaptativos, todas as estratégias, fórmulas canônicas, clamps fluidos, resize e unidades físicas.

O workflow macOS em `.github/workflows/ci.yml` adiciona validação com o SDK iOS e `xcodebuild` sem code signing.

## Limitações da plataforma

- Linux valida Core/Strategies e o manifesto, mas não substitui uma compilação real com o SDK Apple.
- PPI físico deve ser fornecido; `UIScreen.scale` não é PPI.
- Safe areas continuam sendo responsabilidade do layout SwiftUI/UIKit.
- O modo de interface passado ao `AppDimensProvider` deve refletir o target/dispositivo atual.
- `DimensContext` representa um snapshot; fora de SwiftUI ele não observa mudanças sozinho.

## Documentação adicional

- [Referência de API](Documentation/API.md)
- [Matemática e equivalência](Documentation/MATHEMATICS.md)
- [Migração Android → Apple](Documentation/MIGRATION.md)
- [Auditoria do porte](Documentation/AUDIT.md)
- [Exemplo SwiftUI](Examples/SwiftUIExample.swift)
- [Exemplo UIKit](Examples/UIKitExample.swift)
- [Integração Metal](Documentation/METAL.md)
- [Changelog](CHANGELOG.md)

## Licença

Apache License 2.0. Consulte [LICENSE](LICENSE).

Este projeto é um porte independente para plataformas Apple. AppDimens Dynamic e seus algoritmos pertencem aos respectivos autores e colaboradores.
