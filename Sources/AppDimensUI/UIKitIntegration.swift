#if canImport(UIKit)
import UIKit
import AppDimens

public extension DimensionContext {
    @MainActor static func current(for view: UIView, dynamicTypeScale: CGFloat = 1) -> Self {
        let size = view.bounds.size == .zero ? view.window?.bounds.size ?? UIScreen.main.bounds.size : view.bounds.size
        let idiom: DeviceIdiom
        switch view.traitCollection.userInterfaceIdiom { case .phone: idiom = .phone; case .pad: idiom = .pad
        case .tv: idiom = .tv; case .carPlay: idiom = .carPlay; case .mac: idiom = .mac
        default: idiom = .unspecified }
        return .init(width: size.width, height: size.height, displayScale: view.window?.screen.scale ?? UIScreen.main.scale,
                     dynamicTypeScale: dynamicTypeScale, idiom: idiom,
                     horizontalSizeClass: view.traitCollection.horizontalSizeClass.appDimens,
                     verticalSizeClass: view.traitCollection.verticalSizeClass.appDimens)
    }
}
private extension UIUserInterfaceSizeClass {
    var appDimens: AdaptiveSizeClass? { self == .unspecified ? nil : (self == .compact ? .compact : .regular) }
}
#endif
