#if canImport(SwiftUI)
import SwiftUI
import AppDimens

private struct DimensionContextKey: EnvironmentKey {
    static let defaultValue = DimensionContext(width: 360, height: 800)
}

public extension EnvironmentValues {
    var appDimens: DimensionContext {
        get { self[DimensionContextKey.self] }
        set { self[DimensionContextKey.self] = newValue }
    }
}

/// Reads the actual SwiftUI container (including split-screen/window resizing), never `UIScreen.main`.
public struct AppDimensProvider<Content: View>: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    private let content: () -> Content

    public init(@ViewBuilder content: @escaping () -> Content) { self.content = content }

    public var body: some View {
        GeometryReader { proxy in
            content().environment(\.appDimens, context(size: proxy.size))
        }
    }

    private func context(size: CGSize) -> DimensionContext {
        DimensionContext(width: size.width, height: size.height, displayScale: displayScale,
                         dynamicTypeScale: dynamicTypeSize.appDimensScale, idiom: currentIdiom,
                         horizontalSizeClass: horizontalSizeClass.map(AdaptiveSizeClass.init),
                         verticalSizeClass: verticalSizeClass.map(AdaptiveSizeClass.init))
    }

    private var displayScale: CGFloat {
        #if os(iOS) || os(tvOS) || os(watchOS) || os(visionOS)
        return WKInterfaceDeviceOrUIScreen.scale
        #else
        return 1
        #endif
    }
}

private extension AdaptiveSizeClass {
    init(_ value: UserInterfaceSizeClass) { self = value == .compact ? .compact : .regular }
}

private extension DynamicTypeSize {
    var appDimensScale: CGFloat {
        switch self { case .xSmall: 0.88; case .small: 0.94; case .medium: 0.97; case .large: 1
        case .xLarge: 1.12; case .xxLarge: 1.23; case .xxxLarge: 1.35
        case .accessibility1: 1.64; case .accessibility2: 1.95; case .accessibility3: 2.35
        case .accessibility4: 2.76; case .accessibility5: 3.12; @unknown default: 1 }
    }
}

#if canImport(UIKit)
import UIKit
private enum WKInterfaceDeviceOrUIScreen { static var scale: CGFloat { UIScreen.main.scale } }
private var currentIdiom: DeviceIdiom {
    switch UIDevice.current.userInterfaceIdiom { case .phone: .phone; case .pad: .pad; case .tv: .tv; case .carPlay: .carPlay
    case .mac: .mac; default: .unspecified }
}
#elseif canImport(WatchKit)
import WatchKit
private enum WKInterfaceDeviceOrUIScreen { static var scale: CGFloat { WKInterfaceDevice.current().screenScale } }
private var currentIdiom: DeviceIdiom { .watch }
#else
private var currentIdiom: DeviceIdiom { .mac }
#endif
#endif
