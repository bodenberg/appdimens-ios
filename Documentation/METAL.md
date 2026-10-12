# Metal

[Documentation hub](README.md) · [API](API.md) · [Performance](PERFORMANCE.md)

`AppDimensMetal` moves one window configuration to the GPU so shaders resolve dimensions with the same formulas as Swift.

## Uniforms

`AppDimensUniforms` is 96 bytes (six `float4`, 16-byte aligned):

| Field | x | y | z | w |
|---|---|---|---|---|
| `viewport` | width | height | smallest side | largest side |
| `scaled` | sdp factor | wdp factor | hdp factor | sdpa multiplier |
| `satellitesA` | power | fluid | auto | interpolated |
| `satellitesB` | logarithmic | diagonal | perimeter | fit |
| `satellitesC` | fill | density | AR multiplier | ln(normalized AR) |
| `display` | displayScale | fontScale | aspect ratio | multi-window (0/1) |

## Shader source

`AppDimensUniforms.metalSource` contains the struct and inline helpers: `appdimens_sdp/wdp/hdp/sdpa/ssp/sem`, one helper per strategy (`appdimens_power`, `appdimens_fluid`, …), `appdimens_ar(u)`, `appdimens_ar_k(u, k)`, `appdimens_px`, `appdimens_pt`, `appdimens_ndc(u, points)` and per-axis formulas (`appdimens_power_axis`, `appdimens_log_axis`, `appdimens_auto_axis`, `appdimens_fluid_axis`).

Compile it at run time together with your shaders:

```swift
let library = try AppDimensMetal.makeLibrary(device: device, additionalSource: """
vertex float4 corner_vertex(uint vid [[vertex_id]], constant AppDimensUniforms& u [[buffer(1)]]) {
    float r = appdimens_sdp(u, 12.0);              // == 12.sdp on the CPU
    return float4(appdimens_ndc(u, float2(r, r)), 0, 1);
}
""")
```

or paste `metalSource` into a `.metal` file of your app target (the header is guarded by `APPDIMENS_METAL_H`).

## Binding

```swift
// Small and per-frame: setBytes (no buffer management)
encoder.setAppDimensUniforms(index: 1)                         // ambient window
encoder.setAppDimensUniforms(AppDimensUniforms(configuration), index: 1)
computeEncoder.setAppDimensUniforms(index: 0)

// Persistent buffer, rewritten only when the window changes
let buffer = AppDimensMetal.makeBuffer(device: device)!
let token = AppDimens.observe { configuration in
    AppDimensMetal.update(buffer, configuration: configuration)
}
```

`update` calls `didModifyRange` for managed buffers on macOS. In an `MTKView` you can also compare `AppDimens.configurationVersion` once per frame.

## Precision

The GPU uses `float`; CPU values are `Double`. Factors agree to ~1e-7 relative, i.e. far below a pixel for any realistic dimension.
