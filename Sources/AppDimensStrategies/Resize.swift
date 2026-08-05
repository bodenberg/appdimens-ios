import Foundation

public enum DimensResize {
    /// Finds the largest fitting value on an arithmetic grid in O(log n).
    public static func largestFitting(minimum: Double, maximum: Double, step: Double = 1,
                                      fits: (Double) -> Bool) -> Double {
        precondition(minimum <= maximum && step > 0 && step.isFinite)
        let count = Int(floor((maximum - minimum) / step))
        var low = 0, high = count, answer = fits(minimum) ? 0 : -1
        while low <= high {
            let middle = low + (high - low) / 2
            if fits(minimum + Double(middle) * step) { answer = middle; low = middle + 1 } else { high = middle - 1 }
        }
        return answer < 0 ? minimum : minimum + Double(answer) * step
    }
}
