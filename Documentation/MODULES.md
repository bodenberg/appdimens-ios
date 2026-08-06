# Complete module matrix

| Android artifact | SwiftPM product | Swift module | Status |
|---|---|---|---|
| appdimens-dynamic | AppDimens | AppDimens | complete principal scaled/plain/core/common |
| dynamic-auto | AppDimensAuto | AppDimensAuto | AutoDp/AutoSp conditions and priority |
| dynamic-density | AppDimensDensity | AppDimensDensity | density strategy |
| dynamic-diagonal | AppDimensDiagonal | AppDimensDiagonal | diagonal strategy |
| dynamic-fill | AppDimensFill | AppDimensFill | fill strategy |
| dynamic-fit | AppDimensFit | AppDimensFit | fit strategy |
| dynamic-fluid | AppDimensFluid | AppDimensFluid | clamped fluid interpolation |
| dynamic-interpolated | AppDimensInterpolated | AppDimensInterpolated | fixed/linear interpolation |
| dynamic-logarithmic | AppDimensLogarithmic | AppDimensLogarithmic | logarithmic curve |
| dynamic-percent | AppDimensPercent | AppDimensPercent | literal axis percentage |
| dynamic-perimeter | AppDimensPerimeter | AppDimensPerimeter | perimeter ratio |
| dynamic-power | AppDimensPower | AppDimensPower | configurable power curve |
| dynamic-resize | AppDimensResize | AppDimensResize | step table and binary search |
| dynamic-units | AppDimensUnits | AppDimensUnits | points/pixels/physical units |
| Apple extension | AppDimensMetal | AppDimensMetal | stable 64-byte GPU uniforms |
| aggregate/BOM equivalent | AppDimensDynamic | AppDimensDynamic | reexports every module |

Every geometric module consumes the same `DimensConfiguration` window invariant. No satellite reads child-view bounds.
