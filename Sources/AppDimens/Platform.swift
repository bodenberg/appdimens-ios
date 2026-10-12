import Foundation
#if canImport(UIKit)
import UIKit
#endif

public extension UiModeType {
    /// The UI mode that best describes the running Apple platform — the Apple
    /// equivalent of Android's `UiModeManager.currentModeType`:
    /// iPhone/iPad → `.normal`, CarPlay → `.car`, Mac (native or Catalyst) → `.desk`,
    /// Apple TV → `.television`, Apple Watch → `.watch`, Vision Pro → `.vrHeadset`.
    @MainActor static var platformDefault: UiModeType {
        #if os(visionOS)
        return .vrHeadset
        #elseif os(watchOS)
        return .watch
        #elseif os(tvOS)
        return .television
        #elseif os(macOS) || targetEnvironment(macCatalyst)
        return .desk
        #elseif canImport(UIKit)
        switch UIDevice.current.userInterfaceIdiom {
        case .phone, .pad: return .normal
        case .carPlay: return .car
        case .tv: return .television
        case .mac: return .desk
        default: return .undefined
        }
        #else
        return .undefined
        #endif
    }
}

/// Dynamic Type → Android `fontScale`. Ratios are the system `body` sizes for each
/// content-size category divided by the default (17 pt), i.e. exactly what Dynamic
/// Type applies to body text.
public enum AppDimensFontScale {
    /// `body` point size per category, `xSmall … accessibilityXXXLarge`.
    public static let bodySizes: [Double] = [14, 15, 16, 17, 19, 21, 23, 28, 33, 40, 47, 53]

    /// Font scale for a category index (`0` = xSmall, `3` = large/default, `11` = AX5).
    @inlinable public static func scale(forCategoryIndex index: Int) -> Double {
        guard bodySizes.indices.contains(index) else { return 1 }
        return bodySizes[index] / 17
    }
}

#if canImport(UIKit) && !os(watchOS)
public extension UIContentSizeCategory {
    /// Android-style font scale for this content size category.
    var appDimensFontScale: Double {
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
        default: return 1
        }
    }
}
#endif
