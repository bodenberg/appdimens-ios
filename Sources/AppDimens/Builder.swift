import Foundation

/// One conditional entry of a dimension builder — port of Android `CustomDpEntry` /
/// `CustomSpEntry`. Priorities follow Android: 1 = mode + qualifier,
/// 2 = mode, 3 = qualifier, 4 = orientation only.
public struct DimenCustomEntry: Hashable, Sendable {
    public let uiModeType: UiModeType?
    public let qualifierType: DpQualifier?
    public let qualifierValue: Double
    public let orientation: Orientation
    public let customValue: Double
    public let finalQualifierResolver: DpQualifier?
    public let inverter: Inverter
    public let priority: Int
    /// SP builders only: whether the entry follows the system font scale.
    public let fontScale: Bool?

    @inlinable func matches(_ c: DimensConfiguration) -> Bool {
        let orientationMatch: Bool
        switch orientation {
        case .landscape: orientationMatch = c.orientation == .landscape
        case .portrait: orientationMatch = c.orientation == .portrait
        case .default: orientationMatch = true
        }
        guard orientationMatch else { return false }
        if let mode = uiModeType, mode != c.uiMode { return false }
        if let q = qualifierType, c.dimension(q) < qualifierValue { return false }
        return true
    }
}

/// Fluent, immutable conditional-dimension builder — port of Android
/// `DimenScaled` / `ScaledSp` and every satellite builder (`DimenPower`,
/// `DimenAuto`, …). Entries are sorted by priority, then by descending
/// qualifier threshold; the first matching entry wins.
///
/// ```swift
/// let padding = 16.scaledDp()
///     .screen(.television, customValue: 40)
///     .screen(.smallWidth, 600, customValue: 24)
///     .screen(.landscape, customValue: 12)
/// padding.sdp           // CGFloat, ambient window
/// padding.sdp(config)   // Double, explicit window
/// ```
public struct DimenBuilder: Hashable, Sendable {
    public let initialBaseValue: Double
    public let strategy: DimensStrategy
    /// `true` for SP builders (`scaledSp()`): resolves with the font scale.
    public let isText: Bool
    public private(set) var defaultFontScale: Bool
    public private(set) var entries: [DimenCustomEntry] = []
    public private(set) var ignoresMultiWindows = false
    public private(set) var appliesAspectRatio = false
    public private(set) var customSensitivityK: Double?

    public init(_ value: Double, strategy: DimensStrategy = .scaled, text: Bool = false, fontScale: Bool = true) {
        initialBaseValue = value; self.strategy = strategy; isText = text; defaultFontScale = fontScale
    }

    // ── Options ────────────────────────────────────────────────────────────

    public func applyAspectRatio(_ apply: Bool = true) -> Self { var x = self; x.appliesAspectRatio = apply; return x }
    /// SP-builder spelling (`aspectRatio(enable, sensitivityK)`).
    public func aspectRatio(_ enable: Bool = true, sensitivityK: Double? = nil) -> Self {
        var x = self; x.appliesAspectRatio = enable; x.customSensitivityK = sensitivityK; return x
    }
    public func ignoreMultiWindows(_ ignore: Bool = true) -> Self { var x = self; x.ignoresMultiWindows = ignore; return x }
    public func customSensitivity(_ k: Double?) -> Self { var x = self; x.customSensitivityK = k; return x }

    private func adding(_ e: DimenCustomEntry) -> Self {
        var x = self
        x.entries.append(e)
        // Stable sort: priority ascending, qualifier threshold descending.
        x.entries = x.entries.enumerated().sorted { a, b in
            if a.element.priority != b.element.priority { return a.element.priority < b.element.priority }
            if a.element.qualifierValue != b.element.qualifierValue { return a.element.qualifierValue > b.element.qualifierValue }
            return a.offset < b.offset
        }.map(\.element)
        return x
    }

    // ── Entries (Android `screen(...)` overloads) ─────────────────────────

    /// Priority 1 — UI mode **and** qualifier threshold (optionally orientation).
    public func screen(_ uiModeType: UiModeType, _ qualifierType: DpQualifier, _ qualifierValue: Double,
                       customValue: Double, finalQualifierResolver: DpQualifier? = nil,
                       orientation: Orientation = .default, inverter: Inverter = .default,
                       fontScale: Bool? = nil) -> Self {
        adding(.init(uiModeType: uiModeType, qualifierType: qualifierType, qualifierValue: qualifierValue,
                     orientation: orientation, customValue: customValue, finalQualifierResolver: finalQualifierResolver,
                     inverter: inverter, priority: 1, fontScale: fontScale))
    }

    /// Priority 2 — UI mode (optionally orientation).
    public func screen(_ uiModeType: UiModeType, customValue: Double, finalQualifierResolver: DpQualifier? = nil,
                       orientation: Orientation = .default, inverter: Inverter = .default,
                       fontScale: Bool? = nil) -> Self {
        adding(.init(uiModeType: uiModeType, qualifierType: nil, qualifierValue: 0, orientation: orientation,
                     customValue: customValue, finalQualifierResolver: finalQualifierResolver,
                     inverter: inverter, priority: 2, fontScale: fontScale))
    }

    /// Priority 3 — qualifier threshold (e.g. `.smallWidth, 600`), optionally orientation.
    public func screen(_ qualifierType: DpQualifier, _ qualifierValue: Double, customValue: Double,
                       finalQualifierResolver: DpQualifier? = nil, orientation: Orientation = .default,
                       inverter: Inverter = .default, fontScale: Bool? = nil) -> Self {
        adding(.init(uiModeType: nil, qualifierType: qualifierType, qualifierValue: qualifierValue,
                     orientation: orientation, customValue: customValue, finalQualifierResolver: finalQualifierResolver,
                     inverter: inverter, priority: 3, fontScale: fontScale))
    }

    /// Priority 4 — orientation only.
    public func screen(_ orientation: Orientation, customValue: Double, finalQualifierResolver: DpQualifier? = nil,
                       inverter: Inverter = .default, fontScale: Bool? = nil) -> Self {
        adding(.init(uiModeType: nil, qualifierType: nil, qualifierValue: 0, orientation: orientation,
                     customValue: customValue, finalQualifierResolver: finalQualifierResolver,
                     inverter: inverter, priority: 4, fontScale: fontScale))
    }

    // Short iOS spellings (kept from 3.1.6).
    public func mode(_ value: Double, _ mode: UiModeType) -> Self { screen(mode, customValue: value) }
    public func rotate(_ value: Double, _ orientation: Orientation = .landscape) -> Self { screen(orientation, customValue: value) }
    public func qualifier(_ value: Double, _ qualifier: DpQualifier, minimum: Double) -> Self {
        screen(qualifier, minimum, customValue: value)
    }
    public func screen(_ value: Double, qualifier: DpQualifier, minimum: Double) -> Self {
        screen(qualifier, minimum, customValue: value)
    }

    // ── Resolution ─────────────────────────────────────────────────────────

    /// The entry that matches `configuration`, if any.
    public func matchingEntry(_ configuration: DimensConfiguration) -> DimenCustomEntry? {
        entries.first { $0.matches(configuration) }
    }

    /// Resolves in points. `qualifier` is the axis used when no entry overrides it;
    /// `fontScale` overrides the SP font-scale behaviour (`sei`/`hei`/`wei` pass `false`).
    public func resolve(_ configuration: DimensConfiguration, qualifier: DpQualifier = .smallWidth,
                        fontScale: Bool? = nil) -> Double {
        let entry = matchingEntry(configuration)
        let geometry = AppDimens.resolve(entry?.customValue ?? initialBaseValue, strategy: strategy,
            configuration: configuration, qualifier: entry?.finalQualifierResolver ?? qualifier,
            inverter: entry?.inverter ?? .default, ignoreMultiWindows: ignoresMultiWindows,
            applyAspectRatio: appliesAspectRatio, sensitivityK: customSensitivityK)
        guard isText else { return geometry }
        let applyFont = fontScale ?? entry?.fontScale ?? defaultFontScale
        return applyFont ? geometry * configuration.fontScale : geometry
    }

    /// Resolves in pixels (`points × displayScale`).
    public func px(_ configuration: DimensConfiguration, qualifier: DpQualifier = .smallWidth) -> Double {
        resolve(configuration, qualifier: qualifier) * configuration.displayScale
    }

    // Explicit-configuration accessors (Android `sdp(context)` family; results in points).
    public func sdp(_ c: DimensConfiguration) -> Double { resolve(c, qualifier: .smallWidth) }
    public func hdp(_ c: DimensConfiguration) -> Double { resolve(c, qualifier: .height) }
    public func wdp(_ c: DimensConfiguration) -> Double { resolve(c, qualifier: .width) }
    public func ssp(_ c: DimensConfiguration) -> Double { resolve(c, qualifier: .smallWidth) }
    public func hsp(_ c: DimensConfiguration) -> Double { resolve(c, qualifier: .height) }
    public func wsp(_ c: DimensConfiguration) -> Double { resolve(c, qualifier: .width) }
    public func sem(_ c: DimensConfiguration) -> Double { resolve(c, qualifier: .smallWidth, fontScale: false) }
    public func hem(_ c: DimensConfiguration) -> Double { resolve(c, qualifier: .height, fontScale: false) }
    public func wem(_ c: DimensConfiguration) -> Double { resolve(c, qualifier: .width, fontScale: false) }
    public func sdpPx(_ c: DimensConfiguration) -> Double { px(c, qualifier: .smallWidth) }
    public func hdpPx(_ c: DimensConfiguration) -> Double { px(c, qualifier: .height) }
    public func wdpPx(_ c: DimensConfiguration) -> Double { px(c, qualifier: .width) }
    /// Android `sdpHdpWdpPx` — the three axes in pixels from one snapshot.
    public func sdpHdpWdpPx(_ c: DimensConfiguration) -> (Double, Double, Double) { (sdpPx(c), hdpPx(c), wdpPx(c)) }

    // Ambient accessors (Compose-style `value.sdp`).
    public var sdp: CGFloat { CGFloat(sdp(AppDimens.configuration)) }
    public var hdp: CGFloat { CGFloat(hdp(AppDimens.configuration)) }
    public var wdp: CGFloat { CGFloat(wdp(AppDimens.configuration)) }
    public var ssp: CGFloat { CGFloat(ssp(AppDimens.configuration)) }
    public var hsp: CGFloat { CGFloat(hsp(AppDimens.configuration)) }
    public var wsp: CGFloat { CGFloat(wsp(AppDimens.configuration)) }
    public var sem: CGFloat { CGFloat(sem(AppDimens.configuration)) }
    public var hem: CGFloat { CGFloat(hem(AppDimens.configuration)) }
    public var wem: CGFloat { CGFloat(wem(AppDimens.configuration)) }
    public var sdpPx: CGFloat { CGFloat(sdpPx(AppDimens.configuration)) }
    public var hdpPx: CGFloat { CGFloat(hdpPx(AppDimens.configuration)) }
    public var wdpPx: CGFloat { CGFloat(wdpPx(AppDimens.configuration)) }
}


/// Android names for the scaled builders.
public typealias DimenScaled = DimenBuilder
public typealias ScaledDp = DimenBuilder
public typealias ScaledSp = DimenBuilder

public extension DimensNumber {
    /// Android `Number.scaledDp()` — conditional SDP builder.
    @inlinable func scaledDp() -> DimenBuilder { DimenBuilder(dimensValue) }
    /// Android `Number.scaledSp()` — conditional SSP builder.
    @inlinable func scaledSp(fontScale: Bool = true) -> DimenBuilder { DimenBuilder(dimensValue, text: true, fontScale: fontScale) }
    /// Builder for any strategy (`16.dimen(.power).screen(...)`).
    @inlinable func dimen(_ strategy: DimensStrategy) -> DimenBuilder { DimenBuilder(dimensValue, strategy: strategy) }
    @inlinable func dimenSp(_ strategy: DimensStrategy, fontScale: Bool = true) -> DimenBuilder {
        DimenBuilder(dimensValue, strategy: strategy, text: true, fontScale: fontScale)
    }
}
