# Constraint resize

[Strategy catalog](../STRATEGIES.md) · [Mathematics](../MATHEMATICS-AND-CALCULUS.md) · [API](../API.md)

## What it is

Resize chooses the largest candidate that satisfies a measured constraint. Unlike scaling strategies, it does not infer a size from the window; the caller defines both candidates and the meaning of "fits." Typical uses are auto-sized labels, badges, chart annotations, and squares constrained by a container.

## Algorithm and proof obligation

`steps(minimum:maximum:step:)` creates ascending candidates, includes the exact maximum when the step does not land on it, and caps the table at 4,096 entries. `largestFitting` performs binary search in `O(log n)` and returns `0` when none fit.

The predicate **must be monotonic**: once a candidate fails, every larger candidate must also fail. Binary search is not correct for predicates that alternate between pass and fail.

## SwiftUI text example

```swift
import SwiftUI
import AppDimensDynamic

func bestFontSize(availableWidth: CGFloat, text: String) -> Double {
    let candidates = DimensResize.steps(minimum: 12, maximum: 36, step: 1)
    return DimensResize.largestFitting(candidates) { size in
        // Replace with your CoreText/TextKit measurement in production.
        let estimatedWidth = Double(text.count) * size * 0.55
        return estimatedWidth <= Double(availableWidth)
    }
}

struct TitleView: View {
    var body: some View {
        let title = "Responsive title"
        Text(title)
            .font(.system(size: CGFloat(bestFontSize(availableWidth: 240, text: title))))
    }
}
```

The same search is available as `DimensResize.autoResizeText`, which takes `ResizeBound` limits and returns sp. Its candidates are sp values, so multiply by `fontScale` to measure in points:

```swift
let c = DimensConfiguration(screenWidth: 390, screenHeight: 844, fontScale: 1.2)
let text = "Responsive title"
let sp = DimensResize.autoResizeText(min: .fixedSp(10), max: .fixedSp(24), step: .fixedSp(1), configuration: c) { candidate in
    Double(text.count) * candidate * c.fontScale * 0.55 <= 240
}
```

## Fixed and percentage bounds

```swift
let c = DimensConfiguration(screenWidth: 390, screenHeight: 844, fontScale: 1.2)
ResizeBound.fixedDp(44).resolveToPoints(c)            // 44.0
ResizeBound.fixedSp(20).resolveToPoints(c)            // 24.0 (20 × fontScale 1.2)
ResizeBound.percent(50, .width).resolveToPoints(c)    // 195.0 (50 % of 390)
```

`resizeFixedDp(44)`, `resizeFixedSp(20)` and `resizePercentW(50)` build the same bounds. Percent bounds clamp the percentage to `0...100`; fixed bounds clamp negative values to zero.

## Recommendation and trade-offs

Use the coarsest step that meets visual requirements, cache results until text/style/constraint changes, and use real text measurement for production typography. Return behavior for "nothing fits" must be handled explicitly; `largestFitting` returns `0`. Resize is ideal for measured constraints; fluid is better when a predictable visual ramp is sufficient. Validate empty strings, long localized text, accessibility sizes, and the minimum candidate failing.
