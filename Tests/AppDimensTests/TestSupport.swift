import XCTest
import AppDimensDynamic

/// Window fixtures shared by every test.
enum Fixture {
    /// Design reference: factor 1 everywhere.
    static let baseline = DimensConfiguration(screenWidth: 300, screenHeight: 533, displayScale: 3, fontScale: 1.25)
    static let wide = DimensConfiguration(screenWidth: 800, screenHeight: 600, displayScale: 3, fontScale: 1.25)
    static let small = DimensConfiguration(screenWidth: 600, screenHeight: 1032, displayScale: 3, fontScale: 1.25)
    static let phone = DimensConfiguration(screenWidth: 390, screenHeight: 844, displayScale: 3, fontScale: 1, uiMode: .normal)
    static let phoneLandscape = DimensConfiguration(screenWidth: 844, screenHeight: 390, displayScale: 3, fontScale: 1, uiMode: .normal)
    static let tablet = DimensConfiguration(screenWidth: 820, screenHeight: 1180, displayScale: 2, fontScale: 1.25, uiMode: .normal)
    static let tv = DimensConfiguration(screenWidth: 1920, screenHeight: 1080, displayScale: 1, uiMode: .television)
    static let split = DimensConfiguration(screenWidth: 400, screenHeight: 700, maximumWindowWidth: 800, maximumWindowHeight: 700)

    static let all = [baseline, wide, small, phone, phoneLandscape, tablet, tv, split]
}

/// Serializes tests that mutate the process-wide ambient configuration and
/// restores it afterwards.
func withAmbient(_ configuration: DimensConfiguration, _ body: () throws -> Void) rethrows {
    let previous = AppDimens.configuration
    AppDimens.update(configuration)
    defer { AppDimens.update(previous) }
    try body()
}

func XCTAssertClose(_ a: Double, _ b: Double, relative: Double = 1e-9, _ message: String = "",
                    file: StaticString = #filePath, line: UInt = #line) {
    let tolerance = max(abs(a), abs(b), 1) * relative
    XCTAssertEqual(a, b, accuracy: tolerance, message, file: file, line: line)
}
