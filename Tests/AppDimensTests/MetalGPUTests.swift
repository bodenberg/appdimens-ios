#if canImport(Metal) && !os(watchOS)
import XCTest
import Metal
import AppDimensDynamic

/// Compiles `AppDimensUniforms.metalSource` on a real GPU and checks every MSL
/// helper against the CPU kernels. Skipped when no Metal device is available.
final class MetalGPUTests: XCTestCase {
    static let kernelSource = """
    kernel void appdimens_probe(constant AppDimensUniforms& u [[buffer(0)]],
                                device float* out [[buffer(1)]],
                                uint id [[thread_position_in_grid]]) {
        if (id != 0) { return; }
        float v = 16.0;
        out[0] = appdimens_sdp(u, v);   out[1] = appdimens_wdp(u, v);
        out[2] = appdimens_hdp(u, v);   out[3] = appdimens_sdpa(u, v);
        out[4] = appdimens_ssp(u, v);   out[5] = appdimens_power(u, v);
        out[6] = appdimens_fluid(u, v); out[7] = appdimens_auto(u, v);
        out[8] = appdimens_interpolated(u, v); out[9] = appdimens_logarithmic(u, v);
        out[10] = appdimens_diagonal(u, v);    out[11] = appdimens_perimeter(u, v);
        out[12] = appdimens_fit(u, v);  out[13] = appdimens_fill(u, v);
        out[14] = appdimens_density(u, v);
        out[15] = appdimens_px(u, appdimens_sdp(u, v));
        out[16] = v * appdimens_power_axis(u.viewport.y);
        out[17] = v * appdimens_log_axis(u.viewport.y);
        out[18] = v * appdimens_auto_axis(u.viewport.y);
        out[19] = v * appdimens_fluid_axis(u.viewport.y);
    }
    """

    func testShaderHelpersMatchCPU() throws {
        guard let device = MTLCreateSystemDefaultDevice() else { throw XCTSkip("No Metal device") }
        let c = DimensConfiguration(screenWidth: 820, screenHeight: 1180, displayScale: 2, fontScale: 1.25)
        let library = try AppDimensMetal.makeLibrary(device: device, additionalSource: Self.kernelSource)
        let function = try XCTUnwrap(library.makeFunction(name: "appdimens_probe"))
        let pipeline = try device.makeComputePipelineState(function: function)
        let queue = try XCTUnwrap(device.makeCommandQueue())
        let out = try XCTUnwrap(device.makeBuffer(length: 20 * MemoryLayout<Float>.stride, options: .storageModeShared))
        let uniforms = try XCTUnwrap(AppDimensMetal.makeBuffer(device: device, configuration: c))

        let commands = try XCTUnwrap(queue.makeCommandBuffer())
        let encoder = try XCTUnwrap(commands.makeComputeCommandEncoder())
        encoder.setComputePipelineState(pipeline)
        encoder.setBuffer(uniforms, offset: 0, index: 0)
        encoder.setBuffer(out, offset: 0, index: 1)
        encoder.dispatchThreads(MTLSize(width: 1, height: 1, depth: 1),
                                threadsPerThreadgroup: MTLSize(width: 1, height: 1, depth: 1))
        encoder.endEncoding()
        commands.commit()
        commands.waitUntilCompleted()
        XCTAssertNil(commands.error)

        let gpu = Array(UnsafeBufferPointer(start: out.contents().bindMemory(to: Float.self, capacity: 20), count: 20))
        let expected: [Double] = [
            16.sdp(c), 16.wdp(c), 16.hdp(c), 16.sdpa(c), 16.ssp(c),
            AppDimens.powerDp(16, configuration: c), AppDimens.fluidDp(16, configuration: c),
            AppDimens.autoDp(16, configuration: c), AppDimens.interpolatedDp(16, configuration: c),
            AppDimens.logarithmicDp(16, configuration: c), AppDimens.diagonalDp(16, configuration: c),
            AppDimens.perimeterDp(16, configuration: c), AppDimens.fitDp(16, configuration: c),
            AppDimens.fillDp(16, configuration: c), AppDimens.densityDp(16, configuration: c),
            16.sdpPx(c),
            AppDimens.powerDp(16, configuration: c, qualifier: .height),
            AppDimens.logarithmicDp(16, configuration: c, qualifier: .height),
            AppDimens.autoDp(16, configuration: c, qualifier: .height),
            AppDimens.fluidDp(16, configuration: c, qualifier: .height),
        ]
        for (i, value) in expected.enumerated() {
            XCTAssertEqual(Double(gpu[i]), value, accuracy: max(1e-4, abs(value) * 1e-5), "helper #\(i)")
        }
    }
}
#endif
