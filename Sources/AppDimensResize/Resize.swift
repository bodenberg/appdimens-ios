@_exported import AppDimens

public enum ResizeBound: Hashable, Sendable {
    case fixedDp(Double), fixedSp(Double), percent(Double, DpQualifier)
    @inlinable public func points(_ c: DimensConfiguration) -> Double {
        switch self { case .fixedDp(let x): return max(0, x); case .fixedSp(let x): return max(0, x) * c.fontScale
        case .percent(let p, let q): return min(max(p, 0), 100) * c.dimension(q) / 100 }
    }
}
public enum DimensResize {
    @inlinable public static func steps(minimum: Double, maximum: Double, step: Double) -> [Double] {
        precondition(step > 0 && minimum <= maximum)
        var values: [Double] = []; values.reserveCapacity(min(Int((maximum - minimum) / step) + 2, 4096))
        var x = minimum; while x <= maximum && values.count < 4096 { values.append(x); x += step }
        if values.last != maximum && values.count < 4096 { values.append(maximum) }; return values
    }
    @inlinable public static func largestFitting(_ sorted: [Double], fits: (Double) -> Bool) -> Double {
        var l = 0, r = sorted.count - 1, answer: Double = 0
        while l <= r && !sorted.isEmpty { let m = l + (r-l)/2; if fits(sorted[m]) { answer = sorted[m]; l = m+1 } else { r = m-1 } }
        return answer
    }
}
