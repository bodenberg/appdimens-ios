#if canImport(AppKit) && !targetEnvironment(macCatalyst)
import AppKit

/// Visible frame of the screen hosting the key window, used for multi-window detection.
enum _AppDimensScreen {
    @MainActor static func size() -> CGSize? {
        (NSApp?.keyWindow?.screen ?? NSScreen.main)?.visibleFrame.size
    }

    @MainActor static func candidates() -> [_AppDimensScreenCandidate] {
        (NSApp?.windows ?? []).compactMap { window in
            guard let screen = window.screen else { return nil }
            return _AppDimensScreenCandidate(window: window.contentLayoutRect.size, screen: screen.visibleFrame.size)
        }
    }

    @MainActor static func scale() -> CGFloat {
        (NSApp?.keyWindow?.screen ?? NSScreen.main)?.backingScaleFactor ?? 2
    }
}

public extension DimensConfiguration {
    /// Builds the configuration of `window` (or of the key / main window).
    /// The content area (without the title bar) is the AppDimens “screen”.
    @MainActor static func current(window: NSWindow? = nil, uiMode: UiModeType? = nil) -> DimensConfiguration {
        let window = window ?? NSApp?.keyWindow ?? NSApp?.mainWindow
        let fallback = CGSize(width: DimensConstants.baseWidthDp, height: DimensConstants.baseHeightDp)
        let size = window?.contentLayoutRect.size ?? fallback
        let screen = window?.screen ?? NSScreen.main
        let maximum = screen?.visibleFrame.size ?? size
        let scale = window?.backingScaleFactor ?? screen?.backingScaleFactor ?? 1
        return DimensConfiguration(
            screenWidth: Double(size.width), screenHeight: Double(size.height),
            displayScale: Double(scale), fontScale: 1, uiMode: uiMode ?? .platformDefault,
            maximumWindowWidth: Double(maximum.width), maximumWindowHeight: Double(maximum.height))
    }

    /// Builds the configuration of the window hosting `view`.
    @MainActor static func current(in view: NSView?) -> DimensConfiguration {
        current(window: view?.window)
    }
}

/// AppKit automatic updates for the ambient configuration.
@MainActor public enum AppDimensAppKitUpdater {
    static var observers: [NSObjectProtocol] = []
    static var forcedUiMode: UiModeType?

    static func start(uiMode: UiModeType?) {
        forcedUiMode = uiMode
        guard observers.isEmpty else { return }
        let names: [Notification.Name] = [
            NSWindow.didBecomeKeyNotification, NSWindow.didResizeNotification,
            NSWindow.didChangeScreenNotification, NSWindow.didChangeBackingPropertiesNotification,
            NSWindow.didEnterFullScreenNotification, NSWindow.didExitFullScreenNotification,
            NSApplication.didChangeScreenParametersNotification,
        ]
        for name in names {
            observers.append(NotificationCenter.default.addObserver(forName: name, object: nil, queue: .main) { note in
                let window = note.object as? NSWindow
                MainActor.assumeIsolated {
                    if let window, !window.isKeyWindow { return }
                    AppDimens.update(.current(window: window, uiMode: forcedUiMode))
                }
            })
        }
        AppDimens.update(.current(uiMode: forcedUiMode))
    }

    static func stop() {
        for observer in observers { NotificationCenter.default.removeObserver(observer) }
        observers.removeAll()
    }
}

public extension AppDimens {
    /// Re-reads `window` (or the key window) into the ambient configuration.
    @MainActor static func refresh(from window: NSWindow? = nil) {
        update(.current(window: window, uiMode: AppDimensAppKitUpdater.forcedUiMode))
    }

    /// Keeps the ambient configuration (`16.sdp`) in sync with the key window
    /// (resize, full screen, screen / backing-scale changes). Idempotent.
    @MainActor static func startAutomaticUpdates(uiMode: UiModeType? = nil) {
        AppDimensAppKitUpdater.start(uiMode: uiMode)
    }

    @MainActor static func stopAutomaticUpdates() {
        AppDimensAppKitUpdater.stop()
    }
}

public extension NSFont {
    /// System font sized with `ssp`.
    static func ssp(_ size: Double, weight: NSFont.Weight = .regular) -> NSFont {
        .systemFont(ofSize: size.ssp, weight: weight)
    }
}
#endif

#if !canImport(UIKit) && !canImport(AppKit) || os(watchOS)
import Foundation
/// Platforms without a window/screen API (watchOS, Linux): no screen probe.
enum _AppDimensScreen {
    @MainActor static func size() -> CGSize? { nil }
    @MainActor static func candidates() -> [_AppDimensScreenCandidate] { [] }
    /// Every Apple Watch renders at @2x.
    @MainActor static func scale() -> CGFloat { 2 }
}
#endif
