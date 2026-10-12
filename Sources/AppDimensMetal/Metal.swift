@_exported import AppDimens
@_exported import AppDimensStrategies
import Foundation

/// GPU-side snapshot of a window configuration: every AppDimens factor packed in
/// six `float4`s (96 bytes, 16-byte aligned — matches the MSL `struct
/// AppDimensUniforms` in ``AppDimensUniforms/metalSource``).
///
/// Shaders then resolve dimensions with the same formulas as the CPU:
/// `appdimens_sdp(u, 16.0)`, `appdimens_ssp(u, 14.0)`, `appdimens_power(u, 8.0)`…
@frozen public struct AppDimensUniforms: Sendable, Equatable {
    /// `(width, height, smallestWidth, largestSide)` in points.
    public var viewport: SIMD4<Float>
    /// `(sdp, wdp, hdp, sdpa)` factors (`sw/300`, `w/300`, `h/300`, SDPA multiplier).
    public var scaled: SIMD4<Float>
    /// `(power, fluid, auto, interpolated)` smallest-width factors.
    public var satellitesA: SIMD4<Float>
    /// `(logarithmic, diagonal, perimeter, fit)` factors.
    public var satellitesB: SIMD4<Float>
    /// `(fill, density, aspectRatioMultiplier, logNormalizedAspectRatio)`.
    public var satellitesC: SIMD4<Float>
    /// `(displayScale, fontScale, aspectRatio, isMultiWindow ? 1 : 0)`.
    public var display: SIMD4<Float>

    @inlinable public init(_ c: DimensConfiguration) {
        let m = c.metrics
        viewport = .init(Float(c.screenWidth), Float(c.screenHeight), Float(m.minDimensionDp), Float(m.maxDimensionDp))
        scaled = .init(Float(m.scale), Float(m.screenWidthFactor), Float(m.screenHeightFactor),
                       Float(m.defaultScaledAspectRatioMultiplier))
        satellitesA = .init(Float(m.powerScale), Float(m.fluidScale), Float(m.autoScale), Float(m.interpolatedScale))
        satellitesB = .init(Float(m.logarithmicScale), Float(m.diagonalScale), Float(m.perimeterScale), Float(m.fitScale))
        satellitesC = .init(Float(m.fillScale), Float(m.density), Float(m.defaultAspectRatioMultiplier),
                            Float(m.logNormalizedAspectRatio))
        display = .init(Float(c.displayScale), Float(c.fontScale), Float(c.aspectRatio), c.isMultiWindow ? 1 : 0)
    }

    /// Uniforms of the ambient window.
    public static var current: AppDimensUniforms { AppDimensUniforms(AppDimens.configuration) }

    /// Size in bytes of the GPU struct.
    public static let byteCount = MemoryLayout<AppDimensUniforms>.stride

    /// Default-path factor of `strategy` as stored in the uniforms (for CPU checks).
    @inlinable public func factor(_ strategy: DimensStrategy) -> Float {
        switch strategy {
        case .scaled, .percent: return scaled.x
        case .power: return satellitesA.x
        case .fluid: return satellitesA.y
        case .auto: return satellitesA.z
        case .interpolated: return satellitesA.w
        case .logarithmic: return satellitesB.x
        case .diagonal: return satellitesB.y
        case .perimeter: return satellitesB.z
        case .fit: return satellitesB.w
        case .fill: return satellitesC.x
        case .density: return satellitesC.y
        case .plain, .physical: return 1
        }
    }

    /// Kept for source compatibility with 3.1.x.
    public static let metalDeclaration = """
    struct AppDimensUniforms { float4 viewport; float4 scaled; float4 satellitesA; float4 satellitesB; float4 satellitesC; float4 display; };
    """

    /// Metal Shading Language header: the uniforms struct plus inline helpers that
    /// mirror the CPU kernels. Paste it into a `.metal` file or compile it at run
    /// time with ``AppDimensMetal/makeLibrary(device:additionalSource:)``.
    public static let metalSource = """
    #include <metal_stdlib>
    using namespace metal;

    #ifndef APPDIMENS_METAL_H
    #define APPDIMENS_METAL_H

    struct AppDimensUniforms {
        float4 viewport;    // width, height, smallestWidth, largestSide (points)
        float4 scaled;      // sdp, wdp, hdp, sdpa factors
        float4 satellitesA; // power, fluid, auto, interpolated
        float4 satellitesB; // logarithmic, diagonal, perimeter, fit
        float4 satellitesC; // fill, density, aspectRatioMultiplier, logNormalizedAspectRatio
        float4 display;     // displayScale, fontScale, aspectRatio, isMultiWindow
    };

    // Scaled family (points)
    inline float appdimens_sdp(constant AppDimensUniforms& u, float v) { return v * u.scaled.x; }
    inline float appdimens_wdp(constant AppDimensUniforms& u, float v) { return v * u.scaled.y; }
    inline float appdimens_hdp(constant AppDimensUniforms& u, float v) { return v * u.scaled.z; }
    inline float appdimens_sdpa(constant AppDimensUniforms& u, float v) { return v * u.scaled.w; }
    inline float appdimens_ssp(constant AppDimensUniforms& u, float v) { return v * u.scaled.x * u.display.y; }
    inline float appdimens_sem(constant AppDimensUniforms& u, float v) { return v * u.scaled.x; }
    // Satellites (smallest-width default path)
    inline float appdimens_percent(constant AppDimensUniforms& u, float v) { return v * u.scaled.x; }
    inline float appdimens_power(constant AppDimensUniforms& u, float v) { return v * u.satellitesA.x; }
    inline float appdimens_fluid(constant AppDimensUniforms& u, float v) { return v * u.satellitesA.y; }
    inline float appdimens_auto(constant AppDimensUniforms& u, float v) { return v * u.satellitesA.z; }
    inline float appdimens_interpolated(constant AppDimensUniforms& u, float v) { return v * u.satellitesA.w; }
    inline float appdimens_logarithmic(constant AppDimensUniforms& u, float v) { return v * u.satellitesB.x; }
    inline float appdimens_diagonal(constant AppDimensUniforms& u, float v) { return v * u.satellitesB.y; }
    inline float appdimens_perimeter(constant AppDimensUniforms& u, float v) { return v * u.satellitesB.z; }
    inline float appdimens_fit(constant AppDimensUniforms& u, float v) { return v * u.satellitesB.w; }
    inline float appdimens_fill(constant AppDimensUniforms& u, float v) { return v * u.satellitesC.x; }
    inline float appdimens_density(constant AppDimensUniforms& u, float v) { return v * u.satellitesC.y; }
    // Aspect-ratio variant for satellites: appdimens_power(u, v) * appdimens_ar(u)
    inline float appdimens_ar(constant AppDimensUniforms& u) { return u.satellitesC.z; }
    inline float appdimens_ar_k(constant AppDimensUniforms& u, float k) { return 1.0 + k * u.satellitesC.w; }
    // Unit conversions
    inline float appdimens_px(constant AppDimensUniforms& u, float points) { return points * u.display.x; }
    inline float appdimens_pt(constant AppDimensUniforms& u, float pixels) { return pixels / u.display.x; }
    // Points → normalized device coordinates (origin top-left, y down)
    inline float2 appdimens_ndc(constant AppDimensUniforms& u, float2 points) {
        return float2(points.x / u.viewport.x * 2.0 - 1.0, 1.0 - points.y / u.viewport.y * 2.0);
    }
    // Per-axis formulas (any dimension in points)
    inline float appdimens_power_axis(float dim) { return pow(dim / 300.0, 0.75); }
    inline float appdimens_log_axis(float dim) {
        return dim > 300.0 ? 1.0 + 0.4 * log(dim / 300.0) : (dim > 0.0 ? 1.0 - 0.4 * log(300.0 / dim) : 1.0);
    }
    inline float appdimens_auto_axis(float dim) {
        return dim <= 480.0 ? dim / 300.0 : 480.0 / 300.0 + 0.4 * log(1.0 + (dim - 480.0) / 300.0);
    }
    inline float appdimens_fluid_axis(float dim) {
        return dim <= 320.0 ? 0.8 : (dim >= 768.0 ? 1.2 : 0.8 + 0.4 * (dim - 320.0) / 448.0);
    }

    #endif
    """
}

#if canImport(Metal) && !os(watchOS)
import Metal

/// CPU → GPU helpers for the uniforms.
public enum AppDimensMetal {
    /// Allocates a shared buffer holding the uniforms of `configuration`
    /// (defaults to the ambient window).
    public static func makeBuffer(device: MTLDevice, configuration: DimensConfiguration = AppDimens.configuration) -> MTLBuffer? {
        var u = AppDimensUniforms(configuration)
        return withUnsafeBytes(of: &u) { raw -> MTLBuffer? in
            guard let base = raw.baseAddress else { return nil }
            let buffer = device.makeBuffer(bytes: base, length: raw.count, options: .storageModeShared)
            buffer?.label = "AppDimensUniforms"
            return buffer
        }
    }

    /// Rewrites `buffer` in place (call when ``AppDimens/configurationVersion`` changes).
    public static func update(_ buffer: MTLBuffer, configuration: DimensConfiguration = AppDimens.configuration, offset: Int = 0) {
        precondition(offset >= 0 && buffer.length - offset >= AppDimensUniforms.byteCount,
                     "buffer too small for AppDimensUniforms")
        var u = AppDimensUniforms(configuration)
        withUnsafeBytes(of: &u) { raw in
            guard let base = raw.baseAddress else { return }
            (buffer.contents() + offset).copyMemory(from: base, byteCount: raw.count)
        }
        #if os(macOS) || targetEnvironment(macCatalyst)
        if buffer.storageMode == .managed {
            buffer.didModifyRange(offset..<(offset + AppDimensUniforms.byteCount))
        }
        #endif
    }

    /// Compiles ``AppDimensUniforms/metalSource`` (+ your own shader code) into a library.
    public static func makeLibrary(device: MTLDevice, additionalSource: String = "") throws -> MTLLibrary {
        try device.makeLibrary(source: AppDimensUniforms.metalSource + "\n" + additionalSource, options: nil)
    }
}

public extension MTLRenderCommandEncoder {
    /// Binds the uniforms (≤ 4 KB, so `setBytes` — no buffer management) to the
    /// vertex and fragment stages at `index`.
    func setAppDimensUniforms(_ uniforms: AppDimensUniforms = .current, index: Int) {
        var u = uniforms
        setVertexBytes(&u, length: AppDimensUniforms.byteCount, index: index)
        setFragmentBytes(&u, length: AppDimensUniforms.byteCount, index: index)
    }
}

public extension MTLComputeCommandEncoder {
    /// Binds the uniforms to a compute kernel at `index`.
    func setAppDimensUniforms(_ uniforms: AppDimensUniforms = .current, index: Int) {
        var u = uniforms
        setBytes(&u, length: AppDimensUniforms.byteCount, index: index)
    }
}
#endif
