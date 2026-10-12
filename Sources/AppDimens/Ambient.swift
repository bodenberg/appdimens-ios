import Foundation
#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#elseif canImport(Musl)
import Musl
#endif
#if canImport(Observation)
import Observation
#endif

/// Minimal unfair lock: `os_unfair_lock` on Apple platforms, `pthread_mutex` elsewhere.
/// Uncontended acquire/release costs a few nanoseconds.
@usableFromInline final class _AppDimensLock: @unchecked Sendable {
    #if canImport(Darwin)
    @usableFromInline let pointer: UnsafeMutablePointer<os_unfair_lock>
    @usableFromInline init() {
        pointer = .allocate(capacity: 1)
        pointer.initialize(to: os_unfair_lock())
    }
    @inlinable @inline(__always) func lock() { os_unfair_lock_lock(pointer) }
    @inlinable @inline(__always) func unlock() { os_unfair_lock_unlock(pointer) }
    #else
    @usableFromInline let pointer: UnsafeMutablePointer<pthread_mutex_t>
    @usableFromInline init() {
        pointer = .allocate(capacity: 1)
        pointer.initialize(to: pthread_mutex_t())
        pthread_mutex_init(pointer, nil)
    }
    @inlinable @inline(__always) func lock() { pthread_mutex_lock(pointer) }
    @inlinable @inline(__always) func unlock() { pthread_mutex_unlock(pointer) }
    #endif
    deinit {
        #if !canImport(Darwin)
        pthread_mutex_destroy(pointer)
        #endif
        pointer.deinitialize(count: 1)
        pointer.deallocate()
    }
}

/// Process-wide "current window" snapshot used by the zero-argument accessors
/// (`16.sdp`, `16.ssp`, `16.pwsdp`, …). Equivalent to the per-window fast slot of
/// Android's `DimenCache`: one lock-protected read plus a multiply.
///
/// It is updated automatically by `AppDimensProvider` / `.appDimens()` (SwiftUI)
/// and by `AppDimens.startAutomaticUpdates()` (UIKit / AppKit), or manually with
/// ``AppDimens/update(_:)``. On iOS 17 / macOS 14 / tvOS 17 / watchOS 10 /
/// visionOS 1 and later the store participates in Swift Observation, so any
/// SwiftUI `body` that reads `16.sdp` is re-evaluated automatically when the
/// window changes (exactly like reading `LocalConfiguration` in Compose).
@usableFromInline final class _AppDimensAmbient: @unchecked Sendable {
    @usableFromInline static let shared = _AppDimensAmbient()

    @usableFromInline let lock = _AppDimensLock()
    /// Hot state lives behind a raw pointer: class stored properties would pay
    /// Swift's dynamic exclusivity check (~10–20 ns) on every read.
    @usableFromInline struct State {
        @usableFromInline var value: DimensConfiguration
        @usableFromInline var version: UInt64
        @usableFromInline var trackingEnabled: Bool
    }
    @usableFromInline let state: UnsafeMutablePointer<State> = {
        let p = UnsafeMutablePointer<State>.allocate(capacity: 1)
        p.initialize(to: State(value: .reference, version: 0, trackingEnabled: false))
        return p
    }()
    private var observers: [UInt64: @Sendable (DimensConfiguration) -> Void] = [:]
    private var nextObserverID: UInt64 = 0
    /// Boxed `ObservationRegistrar` (only created where Observation is available).
    @usableFromInline let observable: AnyObject?

    private init() {
        #if canImport(Observation)
        if #available(iOS 17, macOS 14, tvOS 17, watchOS 10, visionOS 1, *) {
            observable = _AppDimensObservable()
        } else {
            observable = nil
        }
        #else
        observable = nil
        #endif
    }

    /// Registers an Observation access (SwiftUI dependency tracking) — main thread only,
    /// because SwiftUI evaluates bodies on the main thread.
    @usableFromInline func trackAccess() {
        #if canImport(Observation)
        #if canImport(Darwin)
        guard pthread_main_np() != 0 else { return }
        #endif
        if #available(iOS 17, macOS 14, tvOS 17, watchOS 10, visionOS 1, *) {
            if let box = observable { unsafeDowncast(box, to: _AppDimensObservable.self).access() }
        }
        #endif
    }

    @inlinable @inline(__always) func read<R>(_ body: (DimensConfiguration) -> R) -> R {
        lock.lock()
        let result = body(state.pointee.value)
        let track = state.pointee.trackingEnabled
        lock.unlock()
        if _slowPath(track) { trackAccess() }
        return result
    }

    @usableFromInline func snapshot() -> DimensConfiguration {
        lock.lock()
        let current = state.pointee.value
        let track = state.pointee.trackingEnabled
        lock.unlock()
        if track { trackAccess() }
        return current
    }

    func setTracking(_ enabled: Bool) {
        lock.lock(); state.pointee.trackingEnabled = enabled; lock.unlock()
    }

    @usableFromInline func currentVersion() -> UInt64 {
        lock.lock(); defer { lock.unlock() }
        return state.pointee.version
    }

    /// Stores `configuration`; returns `false` when it was already current.
    @discardableResult @usableFromInline
    func update(_ configuration: DimensConfiguration, notify: Bool = true) -> Bool {
        lock.lock()
        if state.pointee.value == configuration { lock.unlock(); return false }
        state.pointee.value = configuration
        state.pointee.version &+= 1
        let handlers = Array(observers.values)
        lock.unlock()
        if notify { publish(configuration, handlers: handlers) }
        return true
    }

    /// Re-publishes the current value (used after a silent `update(_:notify: false)`).
    @usableFromInline func publishCurrent() {
        lock.lock()
        let current = state.pointee.value
        let handlers = Array(observers.values)
        lock.unlock()
        publish(current, handlers: handlers)
    }

    private func publish(_ configuration: DimensConfiguration,
                         handlers: [@Sendable (DimensConfiguration) -> Void]) {
        #if canImport(Observation)
        if #available(iOS 17, macOS 14, tvOS 17, watchOS 10, visionOS 1, *) {
            (observable as? _AppDimensObservable)?.changed()
        }
        #endif
        for handler in handlers { handler(configuration) }
    }

    func addObserver(_ handler: @escaping @Sendable (DimensConfiguration) -> Void) -> UInt64 {
        lock.lock(); defer { lock.unlock() }
        nextObserverID &+= 1
        observers[nextObserverID] = handler
        return nextObserverID
    }

    func removeObserver(_ id: UInt64) {
        lock.lock(); defer { lock.unlock() }
        observers[id] = nil
    }
}

#if canImport(Observation)
@available(iOS 17, macOS 14, tvOS 17, watchOS 10, visionOS 1, *)
@usableFromInline final class _AppDimensObservable: Observable, @unchecked Sendable {
    private let registrar = ObservationRegistrar()
    /// Tracked key; its value is irrelevant, only access/mutation events matter.
    private var generation = 0
    @usableFromInline init() {}
    @usableFromInline func access() { registrar.access(self, keyPath: \.generation) }
    func changed() { registrar.withMutation(of: self, keyPath: \.generation) { generation &+= 1 } }
}
#endif

/// Token returned by ``AppDimens/observe(_:)``. The observation ends when the
/// token is cancelled or deallocated.
public final class AppDimensObservation: @unchecked Sendable {
    private let id: UInt64
    private var cancelled = false
    private let lock = _AppDimensLock()
    init(id: UInt64) { self.id = id }
    public func cancel() {
        lock.lock(); defer { lock.unlock() }
        guard !cancelled else { return }
        cancelled = true
        _AppDimensAmbient.shared.removeObserver(id)
    }
    deinit { cancel() }
}

public extension AppDimens {
    /// The ambient window configuration used by the zero-argument accessors
    /// (`16.sdp`). Reading it from a SwiftUI `body` on iOS 17+ subscribes the view
    /// to window changes.
    static var configuration: DimensConfiguration { _AppDimensAmbient.shared.snapshot() }

    /// Whether ambient reads register Swift Observation dependencies (iOS 17+ /
    /// macOS 14+). Enabled automatically by `AppDimensProvider`; enable it yourself
    /// if you drive the ambient store manually from a SwiftUI app. Costs ~20 ns per
    /// main-thread read; off by default so UIKit, AppKit and Metal paths stay ~5 ns.
    static var observationTrackingEnabled: Bool {
        get { _AppDimensAmbient.shared.lock.lock(); defer { _AppDimensAmbient.shared.lock.unlock() }
              return _AppDimensAmbient.shared.state.pointee.trackingEnabled }
        set { _AppDimensAmbient.shared.setTracking(newValue) }
    }

    /// Monotonic counter incremented on every ambient change (cheap change detection).
    static var configurationVersion: UInt64 { _AppDimensAmbient.shared.currentVersion() }

    /// Replaces the ambient window configuration. Safe from any thread.
    /// Returns `false` when the configuration did not change.
    @discardableResult
    static func update(_ configuration: DimensConfiguration) -> Bool {
        _AppDimensAmbient.shared.update(configuration)
    }

    /// Stores `configuration` immediately (views evaluated later in the same render
    /// pass read it) and notifies observers on the next main-queue turn. Used by
    /// the SwiftUI provider, which must not publish changes during a view update.
    static func _updateDeferringNotification(_ configuration: DimensConfiguration) {
        _AppDimensAmbient.shared.setTracking(true)
        guard _AppDimensAmbient.shared.update(configuration, notify: false) else { return }
        DispatchQueue.main.async { _AppDimensAmbient.shared.publishCurrent() }
    }

    /// Calls `handler` (on the updating thread) every time the ambient configuration changes.
    static func observe(_ handler: @escaping @Sendable (DimensConfiguration) -> Void) -> AppDimensObservation {
        AppDimensObservation(id: _AppDimensAmbient.shared.addObserver(handler))
    }

    /// Resolves `body` against one coherent ambient snapshot. `body` may freely
    /// call back into AppDimens (the snapshot is copied before it runs).
    @inlinable static func withConfiguration<R>(_ body: (DimensConfiguration) throws -> R) rethrows -> R {
        try body(_AppDimensAmbient.shared.snapshot())
    }

    /// Hot-path accessor used by the generated zero-argument catalogs: `body`
    /// runs while the ambient lock is held, so it must be a pure computation
    /// that never touches AppDimens state. Not intended for direct use.
    @inlinable @inline(__always)
    static func _withAmbient<R>(_ body: (DimensConfiguration) -> R) -> R {
        _AppDimensAmbient.shared.read(body)
    }
}
