# Changelog

## Unreleased

- Produto modular `AppDimensMetal` com ABI CPU/GPU estável de 64 bytes, criação,
  atualização in-place e binding de buffers de uniforms.
- `DimensSnapshot` para pré-calcular fatores e resolver lotes sem alocações no hot path.
- Fronteira equatable no provider SwiftUI para não propagar contextos idênticos.
- Testes de layout dos uniforms, paridade matemática e processamento batch.

## 1.0.0

- Reescrita integral como porte nativo do AppDimens Dynamic 3.1.6.
- Core determinístico, quatorze estratégias, Auto qualifiers, unidades e resize.
- Integrações SwiftUI/UIKit e distribuição modular pelo Swift Package Manager.
- Documentação de API, matemática, migração, arquitetura e instalação pelo Xcode.
