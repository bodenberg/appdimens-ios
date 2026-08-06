@_exported import AppDimensCore
@_exported import AppDimensStrategies

/// GPU ABI with four 16-byte lanes. Its layout is stable for a matching Metal
/// `struct AppDimensUniforms { float4 viewport; float4 ratios; float4 display; float4 reserved; }`.
@frozen public struct AppDimensMetalUniforms: Sendable, Equatable {
    public var viewport: SIMD4<Float>
    public var ratios: SIMD4<Float>
    public var display: SIMD4<Float>
    public var reserved: SIMD4<Float>

    @inlinable public init(context: DimensContext) {
        let snapshot = DimensSnapshot(context)
        viewport = .init(Float(context.width), Float(context.height), Float(context.smallestWidth), Float(context.longestWidth))
        ratios = .init(Float(snapshot.smallestRatio), Float(snapshot.widthRatio), Float(snapshot.heightRatio), Float(snapshot.diagonalRatio))
        display = .init(Float(context.displayScale), Float(context.dynamicTypeScale), Float(context.aspectRatio), Float(context.isMultiWindow ? 1 : 0))
        reserved = .zero
    }

    public static let metalDeclaration = """
    struct AppDimensUniforms {
        float4 viewport; // width, height, smallest, longest
        float4 ratios;   // smallest, width, height, diagonal
        float4 display;  // displayScale, textScale, aspectRatio, isMultiWindow
        float4 reserved;
    };
    """
}

#if canImport(Metal)
import Foundation
import Metal

public enum AppDimensMetal {
    /// Creates a shared buffer once. Retain and update it on viewport changes.
    @inlinable public static func makeBuffer(device: MTLDevice, context: DimensContext,
                                             label: String = "AppDimens uniforms") -> MTLBuffer? {
        var uniforms = AppDimensMetalUniforms(context: context)
        let buffer = withUnsafeBytes(of: &uniforms) { bytes in
            device.makeBuffer(bytes: bytes.baseAddress!, length: bytes.count, options: .storageModeShared)
        }
        buffer?.label = label
        return buffer
    }

    /// Allocation-free update for an existing shared buffer.
    @inlinable public static func update(_ buffer: MTLBuffer, context: DimensContext) {
        precondition(buffer.length >= MemoryLayout<AppDimensMetalUniforms>.stride)
        var uniforms = AppDimensMetalUniforms(context: context)
        withUnsafeBytes(of: &uniforms) { bytes in buffer.contents().copyMemory(from: bytes.baseAddress!, byteCount: bytes.count) }
        #if os(macOS)
        if buffer.storageMode == .managed {
            buffer.didModifyRange(NSRange(location: 0, length: MemoryLayout<AppDimensMetalUniforms>.stride))
        }
        #endif
    }

    @inlinable public static func bind(_ buffer: MTLBuffer, to encoder: MTLRenderCommandEncoder,
                                       vertexIndex: Int? = nil, fragmentIndex: Int? = nil) {
        if let vertexIndex { encoder.setVertexBuffer(buffer, offset: 0, index: vertexIndex) }
        if let fragmentIndex { encoder.setFragmentBuffer(buffer, offset: 0, index: fragmentIndex) }
    }
}
#endif
