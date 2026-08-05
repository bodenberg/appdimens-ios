import Foundation
#if canImport(CoreGraphics)
import CoreGraphics
#endif

public extension CGFloat {
    var dynamic: DynamicDimension { AppDimens.dynamic(self) }
    var fixed: FixedDimension { AppDimens.fixed(self) }
    var dy: DynamicDimension { dynamic }
    var fx: FixedDimension { fixed }
}
public extension BinaryInteger {
    var dynamic: DynamicDimension { AppDimens.dynamic(Int(self)) }
    var fixed: FixedDimension { AppDimens.fixed(Int(self)) }
    var dy: DynamicDimension { dynamic }
    var fx: FixedDimension { fixed }
}
