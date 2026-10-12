#if canImport(SwiftUI)
import SwiftUI

private struct AppDimensConfigurationKey: EnvironmentKey {
    static let defaultValue = DimensConfiguration.reference
}

public extension EnvironmentValues {
    /// The window configuration installed by ``AppDimensProvider`` (Compose
    /// `LocalConfiguration` equivalent). Read it in multi-window apps and pass it
    /// explicitly: `16.sdp(dimens)`.
    var appDimensConfiguration: DimensConfiguration {
        get { self[AppDimensConfigurationKey.self] }
        set { self[AppDimensConfigurationKey.self] = newValue }
    }
}

/// Install once at the root of each window (Android `AppDimensProvider`).
///
/// It measures the full window (safe-area insets — including the keyboard — are
/// added back, so showing the keyboard never rescales the UI), reads display
/// scale and Dynamic Type from the environment, publishes the snapshot to the
/// environment (``EnvironmentValues/appDimensConfiguration``) and to the ambient
/// store used by `16.sdp`.
///
/// ```swift
/// WindowGroup {
///     AppDimensProvider { ContentView() }   // or ContentView().appDimens()
/// }
/// ```
public struct AppDimensProvider<Content: View>: View {
    #if os(macOS) || os(watchOS)
    // `EnvironmentValues.displayScale` is newer than the macOS 10.15 / watchOS 7
    // deployment targets; read the backing scale from the platform instead.
    private var displayScale: CGFloat { _AppDimensScreen.scale() }
    #else
    @Environment(\.displayScale) private var displayScale
    #endif
    @Environment(\.sizeCategory) private var sizeCategory
    private let uiMode: UiModeType?
    private let updatesAmbient: Bool
    private let content: Content

    /// - Parameters:
    ///   - uiMode: Forces a UI mode (otherwise ``UiModeType/platformDefault``).
    ///   - updatesAmbient: Publish to the ambient store used by zero-argument
    ///     accessors (`16.sdp`). Disable for secondary windows/previews that must
    ///     not drive the global snapshot; they still get the environment value.
    public init(uiMode: UiModeType? = nil, updatesAmbient: Bool = true, @ViewBuilder content: () -> Content) {
        self.uiMode = uiMode
        self.updatesAmbient = updatesAmbient
        self.content = content()
    }

    public var body: some View {
        let inputs = _AppDimensProviderInputs(
            displayScale: Double(displayScale), fontScale: sizeCategory.appDimensFontScale,
            uiMode: uiMode ?? .platformDefault, screen: _AppDimensScreen.size(),
            candidates: _AppDimensScreen.candidates(), publish: updatesAmbient)
        let content = self.content
        return GeometryReader { proxy in
            let configuration = inputs.configuration(size: proxy.size, insets: proxy.safeAreaInsets)
            content
                .environment(\.appDimensConfiguration, configuration)
                .frame(width: proxy.size.width, height: proxy.size.height)
        }
    }
}

/// Value snapshot captured on the main actor; turns a GeometryProxy into a configuration.
struct _AppDimensProviderInputs: Sendable {
    let displayScale: Double, fontScale: Double, uiMode: UiModeType
    let screen: CGSize?
    /// Every window with its screen; the provider's own window is the one matching the measured size.
    let candidates: [_AppDimensScreenCandidate]
    let publish: Bool

    func configuration(size: CGSize, insets: EdgeInsets) -> DimensConfiguration {
        // Full window: safe-area insets (status bar, home indicator, keyboard) are added
        // back so the keyboard or bars never rescale the UI — Android window semantics.
        let width = max(1, Double(size.width + insets.leading + insets.trailing))
        let height = max(1, Double(size.height + insets.top + insets.bottom))
        // Bind the maximum bounds to the screen hosting *this* window (not the first active scene).
        let hosting = candidates.first {
            abs(Double($0.window.width) - width) < 1 && abs(Double($0.window.height) - height) < 1
        }?.screen ?? screen
        let configuration = DimensConfiguration(
            screenWidth: width, screenHeight: height, displayScale: displayScale, fontScale: fontScale,
            uiMode: uiMode, maximumWindowWidth: hosting.map { Double($0.width) },
            maximumWindowHeight: hosting.map { Double($0.height) })
        if publish { AppDimens._updateDeferringNotification(configuration) }
        return configuration
    }
}

public extension View {
    /// Wraps the view in an ``AppDimensProvider``.
    func appDimens(uiMode: UiModeType? = nil, updatesAmbient: Bool = true) -> some View {
        AppDimensProvider(uiMode: uiMode, updatesAmbient: updatesAmbient) { self }
    }

    /// Installs a fixed configuration (previews, snapshot tests, fixed-size widgets).
    func appDimensConfiguration(_ configuration: DimensConfiguration, updatesAmbient: Bool = false) -> some View {
        if updatesAmbient { AppDimens.update(configuration) }
        return environment(\.appDimensConfiguration, configuration)
    }
}

/// Resolves a dimension from the window environment of the view that owns it —
/// correct in multi-window apps on every OS version.
///
/// ```swift
/// @ScaledDimension(16) var padding                    // sdp
/// @ScaledDimension(48, .height) var rowHeight         // hdp
/// @ScaledDimension(text: 16) var titleSize            // ssp
/// @ScaledDimension(16, strategy: .power) var gap      // pwsdp
/// ```
@propertyWrapper public struct ScaledDimension: DynamicProperty {
    @Environment(\.appDimensConfiguration) private var configuration
    private let value: Double
    private let qualifier: DpQualifier
    private let strategy: DimensStrategy
    private let isText: Bool, fontScale: Bool, aspect: Bool, ignoreMultiWindow: Bool

    public init(wrappedValue: CGFloat, _ qualifier: DpQualifier = .smallWidth, strategy: DimensStrategy = .scaled,
                aspectRatio: Bool = false, ignoreMultiWindow: Bool = false) {
        self.init(Double(wrappedValue), qualifier, strategy: strategy, aspectRatio: aspectRatio, ignoreMultiWindow: ignoreMultiWindow)
    }

    public init(_ value: Double, _ qualifier: DpQualifier = .smallWidth, strategy: DimensStrategy = .scaled,
                aspectRatio: Bool = false, ignoreMultiWindow: Bool = false) {
        self.value = value; self.qualifier = qualifier; self.strategy = strategy
        isText = false; fontScale = false; aspect = aspectRatio; self.ignoreMultiWindow = ignoreMultiWindow
    }

    public init(text value: Double, _ qualifier: DpQualifier = .smallWidth, strategy: DimensStrategy = .scaled,
                fontScale: Bool = true, aspectRatio: Bool = false, ignoreMultiWindow: Bool = false) {
        self.value = value; self.qualifier = qualifier; self.strategy = strategy
        isText = true; self.fontScale = fontScale; aspect = aspectRatio; self.ignoreMultiWindow = ignoreMultiWindow
    }

    public var wrappedValue: CGFloat {
        let geometry = AppDimens.resolve(value, strategy: strategy, configuration: configuration, qualifier: qualifier,
                                         ignoreMultiWindows: ignoreMultiWindow, applyAspectRatio: aspect)
        return CGFloat(isText && fontScale ? geometry * configuration.fontScale : geometry)
    }

    /// The window configuration the value was resolved against.
    public var projectedValue: DimensConfiguration { configuration }
}

public extension ContentSizeCategory {
    /// Android-style font scale (system body size ÷ 17 pt) for this category.
    var appDimensFontScale: Double {
        #if os(iOS) || os(visionOS) || targetEnvironment(macCatalyst)
        switch self {
        case .extraSmall: return AppDimensFontScale.scale(forCategoryIndex: 0)
        case .small: return AppDimensFontScale.scale(forCategoryIndex: 1)
        case .medium: return AppDimensFontScale.scale(forCategoryIndex: 2)
        case .large: return AppDimensFontScale.scale(forCategoryIndex: 3)
        case .extraLarge: return AppDimensFontScale.scale(forCategoryIndex: 4)
        case .extraExtraLarge: return AppDimensFontScale.scale(forCategoryIndex: 5)
        case .extraExtraExtraLarge: return AppDimensFontScale.scale(forCategoryIndex: 6)
        case .accessibilityMedium: return AppDimensFontScale.scale(forCategoryIndex: 7)
        case .accessibilityLarge: return AppDimensFontScale.scale(forCategoryIndex: 8)
        case .accessibilityExtraLarge: return AppDimensFontScale.scale(forCategoryIndex: 9)
        case .accessibilityExtraExtraLarge: return AppDimensFontScale.scale(forCategoryIndex: 10)
        case .accessibilityExtraExtraExtraLarge: return AppDimensFontScale.scale(forCategoryIndex: 11)
        @unknown default: return 1
        }
        #else
        // macOS, tvOS and watchOS do not apply the iOS Dynamic Type curve to fixed sizes.
        return 1
        #endif
    }
}
#endif
