#if canImport(SwiftUI)
import SwiftUI
import AppDimens

/// Resolves a declaration reactively from the nearest `AppDimensProvider`.
@propertyWrapper public struct AppDimension: DynamicProperty {
    @Environment(\.appDimens) private var context
    private let dimension: DynamicDimension
    private let text: Bool
    public init(_ dimension: DynamicDimension, text: Bool = false) { self.dimension = dimension; self.text = text }
    public init(_ value: CGFloat, text: Bool = false) { self.init(value.dynamic, text: text) }
    public var wrappedValue: CGFloat { dimension.points(in: context, text: text) }
}

public extension View {
    func appDimens() -> some View { AppDimensProvider { self } }
    func dynamicPadding(_ dimension: DynamicDimension, _ edges: Edge.Set = .all) -> some View {
        modifier(DynamicPaddingModifier(dimension: dimension, edges: edges))
    }
    func dynamicFrame(width: DynamicDimension? = nil, height: DynamicDimension? = nil,
                      alignment: Alignment = .center) -> some View {
        modifier(DynamicFrameModifier(width: width, height: height, alignment: alignment))
    }
    func dyPadding(_ value: CGFloat, _ edges: Edge.Set = .all) -> some View { dynamicPadding(value.dynamic, edges) }
    func dyFrame(width: CGFloat? = nil, height: CGFloat? = nil) -> some View {
        dynamicFrame(width: width?.dynamic, height: height?.dynamic)
    }
}

private struct DynamicPaddingModifier: ViewModifier {
    @Environment(\.appDimens) var context
    let dimension: DynamicDimension; let edges: Edge.Set
    func body(content: Content) -> some View { content.padding(edges, dimension.points(in: context)) }
}
private struct DynamicFrameModifier: ViewModifier {
    @Environment(\.appDimens) var context
    let width: DynamicDimension?; let height: DynamicDimension?; let alignment: Alignment
    func body(content: Content) -> some View {
        content.frame(width: width?.points(in: context), height: height?.points(in: context), alignment: alignment)
    }
}
#endif
