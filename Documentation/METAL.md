# Integração Metal e caminho de alta performance

## Objetivo

`AppDimensMetal` leva métricas responsivas para vertex/fragment shaders sem colocar
Metal dentro do Core. O módulo também expõe `DimensSnapshot`, útil em render loops de
CPU que resolvem muitas dimensões para o mesmo viewport.

## Instalação

No Xcode, marque o produto `AppDimensMetal` no target que contém o renderer:

```swift
import AppDimensMetal
```

O módulo reexporta `AppDimensCore` e `AppDimensStrategies`.

## ABI CPU ↔ GPU

`AppDimensMetalUniforms` contém quatro `SIMD4<Float>` e possui stride de 64 bytes:

| Lane | x | y | z | w |
|---|---|---|---|---|
| `viewport` | width | height | smallest | longest |
| `ratios` | smallest/base | width/base | height/base | diagonal/base |
| `display` | displayScale | Dynamic Type scale | aspect ratio | multi-window 0/1 |
| `reserved` | reservado | reservado | reservado | reservado |

Use no `.metal`:

```metal
struct AppDimensUniforms {
    float4 viewport;
    float4 ratios;
    float4 display;
    float4 reserved;
};

vertex VertexOut vertexMain(
    VertexIn in [[stage_in]],
    constant AppDimensUniforms &dimens [[buffer(2)]]) {
    float responsiveRadius = 12.0 * dimens.ratios.x;
    // ...
}
```

## Ciclo de vida eficiente

Crie o buffer uma vez:

```swift
let dimensBuffer = AppDimensMetal.makeBuffer(
    device: device,
    context: context
)!
```

Atualize somente quando o contexto mudar:

```swift
if newContext != previousContext {
    AppDimensMetal.update(dimensBuffer, context: newContext)
    previousContext = newContext
}
```

Faça binding sem cópia adicional:

```swift
AppDimensMetal.bind(
    dimensBuffer,
    to: renderEncoder,
    vertexIndex: 2,
    fragmentIndex: 2
)
```

Em macOS com buffer `.managed`, `update` chama `didModifyRange`; em buffers `.shared`,
a escrita já fica visível ao dispositivo.

## Snapshot para CPU

```swift
let snapshot = DimensSnapshot(context)
let width = snapshot.resolve(100, strategy: .fit)
```

O snapshot evita recalcular razões de largura, altura, diagonal e perímetro. A fast
path é usada quando não há inverter, correção de aspecto ou bypass multi-window;
configurações avançadas voltam automaticamente ao resolver canônico para preservar
exatidão.

Para arrays, prefira os buffers in-place:

```swift
source.withUnsafeBufferPointer { input in
    destination.withUnsafeMutableBufferPointer { output in
        snapshot.resolve(input, into: output, strategy: .scaled)
    }
}
```

Essa API não cria arrays temporários. O chamador controla e reutiliza a memória.

## Recomendações por frame

1. Não consulte `UIApplication`, `UIScreen` ou traits dentro do draw loop.
2. Não crie `DimensContext`, `DimensSnapshot` ou `MTLBuffer` para cada objeto.
3. Recalcule uma vez após resize, rotação, mudança de display ou Dynamic Type.
4. Compartilhe o mesmo buffer entre passes que usam as mesmas métricas.
5. Use um índice de buffer constante no Swift e no shader.
6. Use `Float` na fronteira GPU; mantenha `Double` somente nos cálculos de layout CPU.

## Segurança e validação

- `AppDimensMetalUniforms` é `Sendable` e não retém objetos Metal.
- O update valida que o buffer possui no mínimo 64 bytes.
- Os testes verificam stride, lanes, paridade do snapshot com as estratégias canônicas
  e resolução batch.
- As APIs Metal são compiladas somente quando `canImport(Metal)`; os tipos de uniforms
  e testes matemáticos continuam disponíveis em CI Linux/headless.
