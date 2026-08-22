@_exported import AppDimens
import Foundation

/// Screen metric used to resolve [ResizeBound.percent] — matches sdp/wdp/hdp
/// axes (Android `typealias ResizeAxisQualifier = DpQualifier`).
public typealias ResizeAxisQualifier = DpQualifier

/// One end of a resize range or the step granularity — port of Android
/// `ResizeBound` (sealed class → enum with associated values).
public enum ResizeBound: Hashable, Sendable {
    /// Logical dp already chosen by the caller (e.g. `16.sdp` → pass 16).
    case fixedDp(Double)
    /// sp value; converts points with `fontScale` (like `COMPLEX_UNIT_SP`).
    case fixedSp(Double)
    /// `value` is 0–100 of `axis`.
    case percent(Double, ResizeAxisQualifier)

    /// Android `resolveToPx(configuration, density, fontScale)` — px = dp × density.
    @inlinable public func resolveToPx(_ configuration: DimensConfiguration, density: Double, fontScale: Double) -> Double {
        precondition(density > 0, "density must be positive, was \(density)")
        let fs = fontScale > 0 ? fontScale : 1
        switch self {
        case .fixedDp(let dp): return max(0, dp) * density
        case .fixedSp(let sp): return max(0, sp) * density * fs
        case .percent(let p, let axis):
            let axisDp = configuration.dimension(axis)
            return min(max(p, 0), 100) / 100 * axisDp * density
        }
    }

    /// iOS convenience — resolves to points with the configuration's scale.
    @inlinable public func resolveToPoints(_ configuration: DimensConfiguration) -> Double {
        switch self {
        case .fixedDp(let dp): return max(0, dp)
        case .fixedSp(let sp): return max(0, sp) * configuration.fontScale
        case .percent(let p, let axis): return min(max(p, 0), 100) * configuration.dimension(axis) / 100
        }
    }
}

@inlinable public func resizeFixedDp(_ dp: Double) -> ResizeBound { .fixedDp(dp) }
@inlinable public func resizeFixedSp(_ sp: Double) -> ResizeBound { .fixedSp(sp) }
/// % of the smallest screen side (sw).
@inlinable public func resizePercentSw(_ percent: Double) -> ResizeBound { .percent(percent, .smallWidth) }
/// % of the screen width.
@inlinable public func resizePercentW(_ percent: Double) -> ResizeBound { .percent(percent, .width) }
/// % of the screen height.
@inlinable public func resizePercentH(_ percent: Double) -> ResizeBound { .percent(percent, .height) }

/// Basis for `*Percent` auto-resize bounds (Android `AutoResizePercentBasis`).
public enum AutoResizePercentBasis: String, Sendable, CaseIterable {
    case height       /// Inner content height.
    case width        /// Inner content width.
    case minSide      /// `min(inner width, inner height)`.
}

public enum DimensResize {
    /// Generates the step ladder used by auto-resize (bounded to 4096 entries).
    @inlinable public static func steps(minimum: Double, maximum: Double, step: Double) -> [Double] {
        precondition(step > 0 && minimum <= maximum)
        var values: [Double] = []; values.reserveCapacity(min(Int((maximum - minimum) / step) + 2, 4096))
        var x = minimum; while x <= maximum && values.count < 4096 { values.append(x); x += step }
        if values.last != maximum && values.count < 4096 { values.append(maximum) }
        return values
    }

    /// Binary search over an ascending sorted ladder for the largest fitting value.
    @inlinable public static func largestFitting(_ sorted: [Double], fits: (Double) -> Bool) -> Double {
        var l = 0, r = sorted.count - 1, answer: Double = 0
        while l <= r && !sorted.isEmpty { let m = l + (r - l) / 2; if fits(sorted[m]) { answer = sorted[m]; l = m + 1 } else { r = m - 1 } }
        return answer
    }

    /// Engine value of a bound in its own unit: dp for `.fixedDp`, sp for
    /// `.fixedSp`, resolved axis dp for `.percent` (Android ladder semantics —
    /// `resolveToPx` converts to pixels only at the end).
    @inlinable public static func boundEngineValue(_ bound: ResizeBound, configuration: DimensConfiguration) -> Double {
        switch bound {
        case .fixedDp(let dp): return max(0, dp)
        case .fixedSp(let sp): return max(0, sp)
        case .percent(let p, let axis): return min(max(p, 0), 100) * configuration.dimension(axis) / 100
        }
    }

    /// Auto-resize text (Android `autoResizeTextSp`): finds the largest sp in
    /// `min…max` that satisfies `fits`. `fits` receives candidate sp values.
    @inlinable public static func autoResizeText(min minimum: ResizeBound, max maximum: ResizeBound,
        step: ResizeBound = .fixedSp(1), configuration: DimensConfiguration,
        maxLines: Int? = nil, fits: (Double) -> Bool) -> Double {
        let ladder = steps(minimum: boundEngineValue(minimum, configuration: configuration),
            maximum: boundEngineValue(maximum, configuration: configuration),
            step: max(boundEngineValue(step, configuration: configuration), 0.01))
        return largestFitting(ladder, fits: fits)
    }

    /// Percent-bounded auto-resize (Android `autoResizeTextSpPercent`).
    @inlinable public static func autoResizeTextPercent(minPercent: Double, maxPercent: Double,
        stepSp: Double = 2, percentBasis: AutoResizePercentBasis = .height,
        configuration: DimensConfiguration, maxLines: Int? = nil, fits: (Double) -> Bool) -> Double {
        let basis: Double
        switch percentBasis {
        case .height: basis = configuration.screenHeight
        case .width: basis = configuration.screenWidth
        case .minSide: basis = configuration.smallestScreenWidth
        }
        let minSp = minPercent / 100 * basis, maxSp = maxPercent / 100 * basis
        let ladder = steps(minimum: minSp, maximum: maxSp, step: stepSp)
        return largestFitting(ladder, fits: { candidate in
            fits(candidate) && candidate <= maxSp
        })
    }

    /// Auto-resize square size (Android `autoResizeSquareSize`) — largest side
    /// in dp satisfying `fits`.
    @inlinable public static func autoResizeSquareSize(min minimum: ResizeBound, max maximum: ResizeBound,
        step: ResizeBound = .fixedDp(1), configuration: DimensConfiguration,
        fits: (Double) -> Bool) -> Double {
        let ladder = steps(minimum: boundEngineValue(minimum, configuration: configuration),
            maximum: boundEngineValue(maximum, configuration: configuration),
            step: max(boundEngineValue(step, configuration: configuration), 0.01))
        return largestFitting(ladder, fits: fits)
    }

    /// Auto-resize width/height size — same ladder search with explicit bounds.
    @inlinable public static func autoResizeSize(min: ResizeBound, max: ResizeBound,
        step: ResizeBound = .fixedDp(1), configuration: DimensConfiguration,
        fits: (Double) -> Bool) -> Double {
        autoResizeSquareSize(min: min, max: max, step: step, configuration: configuration, fits: fits)
    }
}