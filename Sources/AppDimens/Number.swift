import Foundation

/// Numeric receiver of every AppDimens accessor (`16.sdp`, `1.5.ssp`, `x.hdp(config)`)
/// — the Swift counterpart of Kotlin's `Number` receiver. Conformances cover the
/// standard integer and floating-point types plus `CGFloat`.
public protocol DimensNumber {
    /// The receiver as a `Double` (the precision used by every kernel).
    var dimensValue: Double { get }
}

extension Int: DimensNumber { @inlinable public var dimensValue: Double { Double(self) } }
extension Int8: DimensNumber { @inlinable public var dimensValue: Double { Double(self) } }
extension Int16: DimensNumber { @inlinable public var dimensValue: Double { Double(self) } }
extension Int32: DimensNumber { @inlinable public var dimensValue: Double { Double(self) } }
extension Int64: DimensNumber { @inlinable public var dimensValue: Double { Double(self) } }
extension UInt: DimensNumber { @inlinable public var dimensValue: Double { Double(self) } }
extension UInt8: DimensNumber { @inlinable public var dimensValue: Double { Double(self) } }
extension UInt16: DimensNumber { @inlinable public var dimensValue: Double { Double(self) } }
extension UInt32: DimensNumber { @inlinable public var dimensValue: Double { Double(self) } }
extension UInt64: DimensNumber { @inlinable public var dimensValue: Double { Double(self) } }
extension Double: DimensNumber { @inlinable public var dimensValue: Double { self } }
extension Float: DimensNumber { @inlinable public var dimensValue: Double { Double(self) } }
extension CGFloat: DimensNumber { @inlinable public var dimensValue: Double { Double(self) } }
