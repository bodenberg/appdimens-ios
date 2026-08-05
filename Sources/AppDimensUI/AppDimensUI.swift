@_exported import AppDimensCore
@_exported import AppDimensStrategies

#if canImport(SwiftUI)
import SwiftUI

private struct DimensContextKey: EnvironmentKey {
    static let defaultValue = DimensContext(width: 300, height: 533)
}

public extension EnvironmentValues {
    var dimensContext: DimensContext {
        get { self[DimensContextKey.self] }
        set { self[DimensContextKey.self] = newValue }
    }
}

/// Reads the actual SwiftUI container (including Stage Manager and split view) and injects it below.
public struct AppDimensProvider<Content: View>: View {
    private let mode: DimensInterfaceMode
    private let displayScale: Double
    private let dynamicTypeScale: Double
    private let content: Content

    public init(mode: DimensInterfaceMode = .unspecified, displayScale: Double = 1,
                dynamicTypeScale: Double = 1, @ViewBuilder content: () -> Content) {
        self.mode = mode; self.displayScale = displayScale
        self.dynamicTypeScale = dynamicTypeScale; self.content = content()
    }
    public var body: some View {
        GeometryReader { proxy in
            content.environment(\.dimensContext, DimensContext(width: proxy.size.width,
                height: proxy.size.height, displayScale: displayScale,
                dynamicTypeScale: dynamicTypeScale, interfaceMode: mode))
        }
    }
}

public struct DynamicDimension: DynamicProperty {
    @Environment(\.dimensContext) private var context
    private let value: Double
    private let strategy: DimensStrategy
    private let options: StrategyOptions
    public init(_ value: Double, strategy: DimensStrategy = .scaled, options: StrategyOptions = .init()) {
        self.value = value; self.strategy = strategy; self.options = options
    }
    public var wrappedValue: CGFloat { CGFloat(DimensStrategies.resolve(value, strategy: strategy, in: context, options: options)) }
}

private struct DynamicPadding: ViewModifier {
    @Environment(\.dimensContext) var context
    let edges: Edge.Set; let value: Double; let strategy: DimensStrategy
    func body(content: Content) -> some View {
        content.padding(edges, CGFloat(DimensStrategies.resolve(value, strategy: strategy, in: context)))
    }
}

public extension View {
    func dynamicPadding(_ edges: Edge.Set = .all, _ value: Double,
                        strategy: DimensStrategy = .scaled) -> some View {
        modifier(DynamicPadding(edges: edges, value: value, strategy: strategy))
    }
}

#if canImport(UIKit)
import UIKit

public extension DimensContext {
    @MainActor static func current(in view: UIView? = nil) -> Self {
        let window = view?.window ?? UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows).first(where: \.isKeyWindow)
        let bounds = view?.bounds ?? window?.bounds ?? UIScreen.main.bounds
        let full = window?.screen.bounds ?? UIScreen.main.bounds
        let idiom = UIDevice.current.userInterfaceIdiom
        let mode: DimensInterfaceMode = idiom == .pad ? .pad : idiom == .phone ? .phone : idiom == .tv ? .television : idiom == .carPlay ? .carPlay : .unspecified
        return .init(width: Double(bounds.width), height: Double(bounds.height),
                     displayScale: Double(window?.screen.scale ?? UIScreen.main.scale),
                     interfaceMode: mode, fullScreenWidth: Double(full.width), fullScreenHeight: Double(full.height))
    }
}

public extension UIFont {
    func appDimensScaled(forTextStyle style: UIFont.TextStyle = .body,
                         compatibleWith traits: UITraitCollection? = nil) -> UIFont {
        UIFontMetrics(forTextStyle: style).scaledFont(for: self, compatibleWith: traits)
    }
}
#endif
#endif
