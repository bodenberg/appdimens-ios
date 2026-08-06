@_exported import AppDimens
@_exported import AppDimensStrategies

@frozen public struct AppDimensUniforms: Sendable, Equatable {
    public var viewport, ratios, display, reserved: SIMD4<Float>
    @inlinable public init(_ c: DimensConfiguration) {
        let f = DimensFactors(c)
        viewport = .init(Float(c.screenWidth), Float(c.screenHeight), Float(c.smallestScreenWidth), Float(max(c.screenWidth,c.screenHeight)))
        ratios = .init(Float(f.smallest), Float(f.width), Float(f.height), Float(f.diagonal))
        display = .init(Float(c.displayScale), Float(c.fontScale), Float(c.aspectRatio), c.isMultiWindow ? 1 : 0)
        reserved = .zero
    }
    public static let metalDeclaration = "struct AppDimensUniforms { float4 viewport; float4 ratios; float4 display; float4 reserved; };"
}
#if canImport(Metal) && !os(watchOS)
import Foundation
import Metal
/// CPU-to-GPU buffer helpers for Apple platforms that expose Metal command
/// buffers. watchOS can still use `AppDimensUniforms` as a portable value, but
/// its SDK does not expose the buffer APIs used by this bridge.
public enum AppDimensMetal {
    public static func makeBuffer(device: MTLDevice, configuration: DimensConfiguration) -> MTLBuffer? {
        var u = AppDimensUniforms(configuration)
        return withUnsafeBytes(of: &u) { device.makeBuffer(bytes: $0.baseAddress!, length: $0.count, options: .storageModeShared) }
    }
    public static func update(_ buffer: MTLBuffer, configuration: DimensConfiguration) {
        precondition(buffer.length >= MemoryLayout<AppDimensUniforms>.stride)
        var u = AppDimensUniforms(configuration)
        withUnsafeBytes(of: &u) { buffer.contents().copyMemory(from: $0.baseAddress!, byteCount: $0.count) }
        #if os(macOS)
        if buffer.storageMode == .managed {
            buffer.didModifyRange(0..<MemoryLayout<AppDimensUniforms>.stride)
        }
        #endif
    }
}
#endif
