#if canImport(UIKit) && !os(watchOS)
import UIKit

/// Screen size of the active scene (orientation-aware), used for multi-window detection.
enum _AppDimensScreen {
    @MainActor static func size() -> CGSize? {
        #if os(visionOS)
        return nil
        #else
        return _AppDimensUIKit.activeScene()?.screen.bounds.size
        #endif
    }

    @MainActor static func scale() -> CGFloat {
        #if os(visionOS)
        return UITraitCollection.current.displayScale > 0 ? UITraitCollection.current.displayScale : 2
        #else
        return _AppDimensUIKit.activeScene()?.screen.scale ?? 2
        #endif
    }
}

@MainActor enum _AppDimensUIKit {
    static func activeScene() -> UIWindowScene? {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        return scenes.first { $0.activationState == .foregroundActive }
            ?? scenes.first { $0.activationState == .foregroundInactive }
            ?? scenes.first
    }

    static func keyWindow() -> UIWindow? {
        let scene = activeScene()
        return scene?.windows.first { $0.isKeyWindow } ?? scene?.windows.first
    }
}

public extension DimensConfiguration {
    /// Builds the configuration of the window hosting `view` (or of the key window
    /// of the active scene). `view` is used only to find its window: child-view
    /// bounds never affect `sdp`/`wdp`/`hdp`.
    @MainActor static func current(in view: UIView?) -> DimensConfiguration {
        current(window: view?.window ?? _AppDimensUIKit.keyWindow())
    }

    /// Builds the configuration of `window` (Android `Configuration` of an Activity).
    @MainActor static func current(window: UIWindow?, uiMode: UiModeType? = nil) -> DimensConfiguration {
        let scene = window?.windowScene ?? _AppDimensUIKit.activeScene()
        let fallback = CGSize(width: DimensConstants.baseWidthDp, height: DimensConstants.baseHeightDp)
        let size = window?.bounds.size ?? scene?.coordinateSpace.bounds.size ?? fallback
        let traits = window?.traitCollection ?? scene?.traitCollection ?? UITraitCollection.current
        #if os(visionOS)
        let maximum = size
        let scale = traits.displayScale > 0 ? traits.displayScale : 2
        #else
        let maximum = scene?.screen.bounds.size ?? size
        let scale = traits.displayScale > 0 ? traits.displayScale : (scene?.screen.scale ?? 1)
        #endif
        #if os(tvOS)
        let fontScale = 1.0
        #else
        let fontScale = traits.preferredContentSizeCategory.appDimensFontScale
        #endif
        return DimensConfiguration(
            screenWidth: Double(size.width), screenHeight: Double(size.height),
            displayScale: Double(scale), fontScale: fontScale,
            uiMode: uiMode ?? .platformDefault,
            maximumWindowWidth: Double(maximum.width), maximumWindowHeight: Double(maximum.height))
    }
}

/// Invisible view pinned to a window: its layout and trait callbacks keep the
/// ambient configuration in sync with window resizes, rotation, Split View,
/// Stage Manager and Dynamic Type changes.
final class _AppDimensTrackerView: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false
        isHidden = true
        isAccessibilityElement = false
        autoresizingMask = [.flexibleWidth, .flexibleHeight]
    }
    required init?(coder: NSCoder) { nil }

    override func layoutSubviews() {
        super.layoutSubviews()
        refresh()
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        refresh()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        refresh()
    }

    private func refresh() {
        guard let window, window.isKeyWindow || AppDimensUIKitUpdater.followsAllWindows else { return }
        AppDimens.update(.current(window: window, uiMode: AppDimensUIKitUpdater.forcedUiMode))
    }
}

/// UIKit / Mac Catalyst automatic updates for the ambient configuration.
@MainActor public enum AppDimensUIKitUpdater {
    static var observers: [NSObjectProtocol] = []
    static var forcedUiMode: UiModeType?
    static var followsAllWindows = false

    /// Starts tracking the key window. Idempotent.
    static func start(uiMode: UiModeType?) {
        forcedUiMode = uiMode
        attachTrackers()
        guard observers.isEmpty else { return }
        let center = NotificationCenter.default
        var names: [Notification.Name] = [
            UIWindow.didBecomeKeyNotification,
            UIScene.didActivateNotification,
            UIScene.willEnterForegroundNotification,
            UIContentSizeCategory.didChangeNotification,
        ]
        #if os(iOS)
        names.append(UIDevice.orientationDidChangeNotification)
        #endif
        for name in names {
            observers.append(center.addObserver(forName: name, object: nil, queue: .main) { _ in
                MainActor.assumeIsolated { attachTrackers(); AppDimens.refresh() }
            })
        }
        AppDimens.refresh()
    }

    static func stop() {
        for observer in observers { NotificationCenter.default.removeObserver(observer) }
        observers.removeAll()
        for scene in UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }) {
            for window in scene.windows {
                window.subviews.compactMap { $0 as? _AppDimensTrackerView }.forEach { $0.removeFromSuperview() }
            }
        }
    }

    static func attachTrackers() {
        for scene in UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }) {
            for window in scene.windows where !window.subviews.contains(where: { $0 is _AppDimensTrackerView }) {
                let tracker = _AppDimensTrackerView(frame: window.bounds)
                window.insertSubview(tracker, at: 0)
            }
        }
    }
}

public extension AppDimens {
    /// Re-reads the window hosting `view` (or the key window) into the ambient
    /// configuration. Call from `viewWillTransition(to:with:)` /
    /// `traitCollectionDidChange` if you do not use ``startAutomaticUpdates(uiMode:)``.
    @MainActor static func refresh(from view: UIView? = nil) {
        update(.current(in: view))
    }

    /// Keeps the ambient configuration (`16.sdp`) in sync with the key window:
    /// rotation, Split View / Slide Over / Stage Manager resizes, scene activation
    /// and Dynamic Type. Call once, e.g. in `scene(_:willConnectTo:options:)` or
    /// `application(_:didFinishLaunchingWithOptions:)`. Idempotent.
    @MainActor static func startAutomaticUpdates(uiMode: UiModeType? = nil) {
        AppDimensUIKitUpdater.start(uiMode: uiMode)
    }

    /// Stops ``startAutomaticUpdates(uiMode:)``.
    @MainActor static func stopAutomaticUpdates() {
        AppDimensUIKitUpdater.stop()
    }
}

public extension DimensNumber {
    /// UIKit convenience: resolves against the window hosting `view`.
    @MainActor func sdp(in view: UIView) -> CGFloat { CGFloat(sdp(.current(in: view))) }
    @MainActor func hdp(in view: UIView) -> CGFloat { CGFloat(hdp(.current(in: view))) }
    @MainActor func wdp(in view: UIView) -> CGFloat { CGFloat(wdp(.current(in: view))) }
    @MainActor func ssp(in view: UIView) -> CGFloat { CGFloat(ssp(.current(in: view))) }
    @MainActor func sem(in view: UIView) -> CGFloat { CGFloat(sem(.current(in: view))) }
}

public extension UIFont {
    /// System font sized with `ssp` (follows Dynamic Type) — `UIFont.ssp(16, weight: .semibold)`.
    static func ssp(_ size: Double, weight: UIFont.Weight = .regular) -> UIFont {
        .systemFont(ofSize: size.ssp, weight: weight)
    }
    /// System font sized with `sem` (ignores Dynamic Type).
    static func sem(_ size: Double, weight: UIFont.Weight = .regular) -> UIFont {
        .systemFont(ofSize: size.sem, weight: weight)
    }
}
#endif
