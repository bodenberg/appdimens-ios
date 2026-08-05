# AppDimens Dynamic for iOS

Porte nativo, modular e sem dependências da [AppDimens Dynamic 3.1.6 para Android](https://github.com/bodenberg/appdimens-dynamic), feito para **Swift, SwiftUI e UIKit**. A biblioteca preserva a linguagem conhecida (`sdp`, `wdp`, `hdp`, `ssp`, qualificadores e estratégias), mas usa pontos, containers e Dynamic Type — os conceitos corretos da plataforma Apple — em vez de simular APIs Android.

## Requisitos

- Swift 5.9 / Xcode 15 ou superior.
- iOS/tvOS 13, watchOS 6, macOS 10.15 ou visionOS 1.
- Nenhuma dependência externa.

## Instalação pelo Xcode (GitHub/Swift Package Manager)

1. Abra seu projeto no Xcode.
2. Selecione **File › Add Package Dependencies…**.
3. Cole `https://github.com/bodenberg/appdimens-ios`.
4. Escolha **Up to Next Major Version** e a versão publicada desejada (ou o branch durante desenvolvimento).
5. Adicione `AppDimens` ao target. Para binários menores, escolha apenas `AppDimensCore`, `AppDimensStrategies` ou `AppDimensUI`.

Em outro `Package.swift`:

```swift
.package(url: "https://github.com/bodenberg/appdimens-ios", from: "1.0.0")
// target: .product(name: "AppDimens", package: "appdimens-ios")
```

## Início rápido

```swift
import AppDimensUI

let context = DimensContext(width: 390, height: 844, displayScale: 3)
let padding = 16.sdp(in: context) // menor eixo, equivalente ao 16.sdp Android
let width = 100.wdp(in: context)
let height = 48.hdp(in: context)
let font = 16.ssp(in: context)    // inclui escala tipográfica declarada no contexto
```

SwiftUI pode obter o container real automaticamente:

```swift
AppDimensProvider(mode: .phone) {
    ContentView().dynamicPadding(16)
}
```

Para valores reutilizáveis dentro de uma `View`, use `@DynamicDimension(16) var spacing`. Em UIKit, use `DimensContext.current(in: view)` e `UIFont.appDimensScaled()` para respeitar Dynamic Type.

## Estratégias

```swift
let icon = 24.dynamic(.power, in: context)
let cover = 120.dynamic(.fill, in: context)
let halfWidth = DimensStrategies.resolve(100, strategy: .percent, in: context,
    options: .init(percent: 50))
```

As 14 famílias do Android estão representadas: `plain`, `scaled`, `auto`, `density`, `diagonal`, `fill`, `fit`, `fluid`, `interpolated`, `logarithmic`, `percent`, `perimeter`, `power` e `physical`. Consulte [a referência completa](Documentation/API.md), [a matemática](Documentation/MATHEMATICS.md), [a migração Android–iOS](Documentation/MIGRATION.md) e [a arquitetura/auditoria](Documentation/AUDIT.md).

## Por que contexto explícito?

No iPad, uma janela pode ocupar somente parte da tela; no macOS e visionOS não existe uma “tela do app” única. O núcleo recebe `DimensContext`, portanto é determinístico, testável, seguro para concorrência e correto em Split View/Stage Manager. `AppDimensProvider` automatiza isso no SwiftUI sem singleton ou cache obsoleto.

## Licença

Apache License 2.0. Este é um porte independente; AppDimens e seus algoritmos pertencem aos respectivos autores.
