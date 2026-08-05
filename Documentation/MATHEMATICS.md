# Matemática e equivalência

Baseline compatível com Android 3.1.6: largura **300**, altura **533**, aspect ratio **1,78**, diagonal `√(300²+533²)` e perímetro `833`. Seja `b` o valor, `d` o eixo, `w/h` o viewport:

| Estratégia | Fórmula |
|---|---|
| scaled | `b × d / 300` |
| aspect-aware | `b × [1 + (d−300) × (1/300 + k×ln((AR/1.78))/300)]` |
| power | `b × (d/300)^0.75` (expoente configurável) |
| logarithmic | `b × [1 ± 0.4×ln(ratio)]` |
| diagonal | `b × √(w²+h²) / √(300²+533²)` |
| perimeter | `b × (w+h)/833` |
| fit/fill | `b × min/max(w/300, h/533)` |
| interpolated | `b × [1 + (d/300−1)×t]` |
| fluid | `b × lerp(0.8, 1.2, clamp((d−320)/(768−320)))` |
| percent | `d × percent/100 × b/100` |

Diferença deliberada: Android converte dp para pixels usando density; Apple desenha layouts em pontos e converte no compositor. `density` é, portanto, alias semântico de `scaled`; pixels somente aparecem quando solicitados explicitamente. Texto usa Dynamic Type/`UIFontMetrics`, não tenta reproduzir `fontScale` global do Android.
