import XCTest
@testable import AppDimensMetal

final class MetalTests: XCTestCase {
    func testUniformABIAndValues() {
        let context = DimensContext(width: 600, height: 1066, displayScale: 2, dynamicTypeScale: 1.25)
        let uniforms = AppDimensMetalUniforms(context: context)
        XCTAssertEqual(MemoryLayout<AppDimensMetalUniforms>.stride, 64)
        XCTAssertEqual(uniforms.viewport, SIMD4<Float>(600, 1066, 600, 1066))
        XCTAssertEqual(uniforms.ratios.x, 2, accuracy: 0.0001)
        XCTAssertEqual(uniforms.display.x, 2)
        XCTAssertEqual(uniforms.display.y, 1.25)
    }

    func testSnapshotMatchesStrategiesAndBatch() {
        let context = DimensContext(width: 390, height: 844)
        let snapshot = DimensSnapshot(context)
        for strategy in DimensStrategy.allCases {
            XCTAssertEqual(snapshot.resolve(24, strategy: strategy),
                           DimensStrategies.resolve(24, strategy: strategy, in: context), accuracy: 0.000001)
        }
        let input = [8.0, 16, 24, 32]
        var output = Array(repeating: 0.0, count: input.count)
        input.withUnsafeBufferPointer { source in output.withUnsafeMutableBufferPointer {
            snapshot.resolve(source, into: $0, strategy: .scaled)
        }}
        XCTAssertEqual(output, input.map { $0 * 1.3 })
    }
}
