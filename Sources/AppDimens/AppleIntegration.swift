#if canImport(SwiftUI)
import SwiftUI

private struct AppDimensConfigurationKey: EnvironmentKey {
    static let defaultValue = DimensConfiguration(screenWidth: 300, screenHeight: 533)
}
public extension EnvironmentValues {
    var appDimensConfiguration: DimensConfiguration {
        get { self[AppDimensConfigurationKey.self] }
        set { self[AppDimensConfigurationKey.self] = newValue }
    }
}

/// Install once at the WindowGroup root. It observes the window container and all
/// relevant environment metrics; callers never pass screen or view dimensions.
public struct AppDimensProvider<Content: View>: View {
    #if os(macOS) || os(watchOS)
    // EnvironmentValues.displayScale is newer than our macOS 10.15/watchOS 6
    // deployment targets. Keep those targets source-compatible without an
    // availability branch in every body evaluation.
    private let displayScale = 1.0
    #else
    @Environment(\.displayScale) private var displayScale
    #endif
    @Environment(\.sizeCategory) private var sizeCategory
    private let content: Content
    public init(@ViewBuilder content: () -> Content) { self.content = content() }

    public var body: some View {
        GeometryReader { proxy in
            content.environment(\.appDimensConfiguration,
                DimensConfiguration(screenWidth: max(1, Double(proxy.size.width)),
                    screenHeight: max(1, Double(proxy.size.height)), displayScale: Double(displayScale),
                    fontScale: sizeCategory.appDimensScale, uiMode: .automaticApple))
                .frame(width: proxy.size.width, height: proxy.size.height)
        }
    }
}

public extension View { func appDimens() -> some View { AppDimensProvider { self } } }

@propertyWrapper public struct ScaledDimension: DynamicProperty {
    @Environment(\.appDimensConfiguration) private var configuration
    private let value: Double, qualifier: DpQualifier
    private let font: Bool, fontScale: Bool, aspect: Bool, ignoreMultiWindow: Bool
    public init(wrappedValue: CGFloat, _ qualifier: DpQualifier = .smallWidth,
                aspectRatio: Bool = false, ignoreMultiWindow: Bool = false) {
        value = Double(wrappedValue); self.qualifier = qualifier; font = false; fontScale = false
        aspect = aspectRatio; self.ignoreMultiWindow = ignoreMultiWindow
    }
    public init(text wrappedValue: Double, _ qualifier: DpQualifier = .smallWidth,
                fontScale: Bool = true, aspectRatio: Bool = false, ignoreMultiWindow: Bool = false) {
        value = wrappedValue; self.qualifier = qualifier; font = true; self.fontScale = fontScale
        aspect = aspectRatio; self.ignoreMultiWindow = ignoreMultiWindow
    }
    public var wrappedValue: CGFloat {
        let result = font ? AppDimens.sp(value, configuration: configuration, qualifier: qualifier,
            fontScale: fontScale, ignoreMultiWindows: ignoreMultiWindow, applyAspectRatio: aspect) :
            AppDimens.dp(value, configuration: configuration, qualifier: qualifier,
                ignoreMultiWindows: ignoreMultiWindow, applyAspectRatio: aspect)
        return CGFloat(result)
    }
}

private extension ContentSizeCategory {
    var appDimensScale: Double {
        #if os(iOS) || os(visionOS)
        switch self {
        case .extraSmall: return 0.82; case .small: return 0.88; case .medium: return 0.94
        case .large: return 1; case .extraLarge: return 1.12; case .extraExtraLarge: return 1.23
        case .extraExtraExtraLarge: return 1.35; case .accessibilityMedium: return 1.64
        case .accessibilityLarge: return 1.95; case .accessibilityExtraLarge: return 2.35
        case .accessibilityExtraExtraLarge: return 2.76; case .accessibilityExtraExtraExtraLarge: return 3.12
        @unknown default: return 1
        }
        #else
        // These platforms do not expose the same complete accessibility curve.
        return 1
        #endif
    }
}
#endif

#if canImport(UIKit)
import UIKit

private extension UiModeType {
    static var automaticApple: UiModeType {
        #if os(visionOS)
        return .vision
        #elseif targetEnvironment(macCatalyst)
        return .mac
        #elseif os(tvOS)
        return .television
        #else
        let idiom = UIDevice.current.userInterfaceIdiom
        switch idiom {
        case .phone, .pad: return .normal
        case .carPlay: return .car
        default: return .undefined
        }
        #endif
    }
}

public extension DimensConfiguration {
    /// Resolves the hosting UIWindowScene. `view` is used only to find its window;
    /// child-view bounds never affect global sdp/wdp/hdp values.
    @MainActor static func current(in view: UIView? = nil) -> Self {
        let scene = view?.window?.windowScene ?? UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }.first { $0.activationState == .foregroundActive }
        let window = view?.window ?? scene?.windows.first(where: \.isKeyWindow)
        let fallback = CGRect(x: 0, y: 0, width: 300, height: 533)
        let sceneBounds = scene?.coordinateSpace.bounds
        #if os(visionOS)
        let bounds = window?.bounds ?? sceneBounds ?? fallback
        let maximum = bounds
        let traits = window?.traitCollection ?? UITraitCollection()
        let scale = traits.displayScale > 0 ? traits.displayScale : 1
        #else
        let bounds = window?.bounds ?? sceneBounds ?? fallback
        let maximum = scene?.screen.bounds ?? bounds
        let traits = window?.traitCollection ?? UITraitCollection()
        let scale = scene?.screen.scale ?? (traits.displayScale > 0 ? traits.displayScale : 1)
        #endif
        let font = UIFont.preferredFont(forTextStyle: .body, compatibleWith: traits).pointSize / 17
        return .init(screenWidth: Double(bounds.width), screenHeight: Double(bounds.height),
            displayScale: Double(scale), fontScale: Double(font),
            uiMode: .automaticApple, maximumWindowWidth: Double(maximum.width), maximumWindowHeight: Double(maximum.height))
    }
}

public extension BinaryInteger {
    @MainActor func sdp(in view: UIView? = nil) -> CGFloat { CGFloat(sdp(.current(in: view))) }
    @MainActor func wdp(in view: UIView? = nil) -> CGFloat { CGFloat(wdp(.current(in: view))) }
    @MainActor func hdp(in view: UIView? = nil) -> CGFloat { CGFloat(hdp(.current(in: view))) }
    @MainActor func ssp(in view: UIView? = nil) -> CGFloat { CGFloat(ssp(.current(in: view))) }
    @MainActor func sem(in view: UIView? = nil) -> CGFloat { CGFloat(sem(.current(in: view))) }
}
public extension BinaryFloatingPoint {
    @MainActor func sdp(in view: UIView? = nil) -> CGFloat { CGFloat(sdp(.current(in: view))) }
    @MainActor func wdp(in view: UIView? = nil) -> CGFloat { CGFloat(wdp(.current(in: view))) }
    @MainActor func hdp(in view: UIView? = nil) -> CGFloat { CGFloat(hdp(.current(in: view))) }
    @MainActor func ssp(in view: UIView? = nil) -> CGFloat { CGFloat(ssp(.current(in: view))) }
    @MainActor func sem(in view: UIView? = nil) -> CGFloat { CGFloat(sem(.current(in: view))) }
}
#endif

#if !canImport(UIKit)
private extension UiModeType {
    static var automaticApple: UiModeType {
        #if os(macOS)
        return .mac
        #elseif os(visionOS)
        return .vision
        #elseif os(watchOS)
        return .watch
        #elseif os(tvOS)
        return .television
        #else
        return .undefined
        #endif
    }
}
#endif
