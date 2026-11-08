import Foundation
import Observation

/// Which devices share settings.
enum SyncScope: String, CaseIterable, Identifiable {
    /// Every iPhone and iPad on the same Apple Account.
    case allDevices
    /// Only devices of the same kind: iPads with iPads, iPhones with iPhones.
    case sameDeviceType

    var id: String { rawValue }
}

/// Syncs the app settings through the iCloud key-value store.
///
/// Each group of devices has its own set of keys: `all.` for every device,
/// `pad.` / `phone.` for one kind of device. A device reads and writes only
/// the set it belongs to. Whether sync is on and which group to use are
/// stored on the device itself.
@Observable
final class SettingsSync {
    static let shared = SettingsSync()

    @ObservationIgnored private let store = NSUbiquitousKeyValueStore.default
    @ObservationIgnored private var observer: NSObjectProtocol?
    @ObservationIgnored private var deviceGroup = "phone"

    var isEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isEnabled, forKey: "syncEnabled")
            if isEnabled, !oldValue { connect() }
        }
    }

    var scope: SyncScope {
        didSet {
            UserDefaults.standard.set(scope.rawValue, forKey: "syncScope")
            if isEnabled, oldValue != scope { connect() }
        }
    }

    /// False when the app was signed without the iCloud key-value
    /// entitlement (sync can't work then).
    private(set) var isAvailable = true
    private(set) var lastSync: Date?

    private var prefix: String {
        scope == .allDevices ? "all." : "\(deviceGroup)."
    }

    private init() {
        let defaults = UserDefaults.standard
        isEnabled = defaults.object(forKey: "syncEnabled") as? Bool ?? true
        scope = SyncScope(rawValue: defaults.string(forKey: "syncScope") ?? "") ?? .allDevices
        lastSync = defaults.object(forKey: "syncLast") as? Date
    }

    /// Call once at launch, on the main thread.
    func start(isPad: Bool) {
        deviceGroup = isPad ? "pad" : "phone"
        observer = NotificationCenter.default.addObserver(
            forName: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: store,
            queue: .main
        ) { [weak self] note in
            self?.externalChange(note)
        }
        if isEnabled { connect() }
    }

    /// Sends one changed setting (called by AppSettings).
    func settingChanged(_ key: String, _ value: Any) {
        guard isEnabled, isAvailable else { return }
        store.set(value, forKey: prefix + key)
        markSynced()
    }

    /// Sends this device's column counts (Sync Columns was turned on).
    func pushColumns() {
        guard isEnabled, isAvailable else { return }
        for (key, value) in AppSettings.shared.snapshot() where AppSettings.columnKeys.contains(key) {
            store.set(value, forKey: prefix + key)
        }
        markSynced()
    }

    /// Joins the current group: takes its settings when it has any,
    /// otherwise starts it with this device's settings.
    private func connect() {
        isAvailable = store.synchronize()
        guard isAvailable else { return }
        let remote = groupValues()
        if remote.isEmpty {
            for (key, value) in AppSettings.shared.syncedSnapshot() {
                store.set(value, forKey: prefix + key)
            }
            store.synchronize()
        } else {
            AppSettings.shared.apply(remote, fromSync: true)
        }
        markSynced()
    }

    private func groupValues() -> [String: Any] {
        var values: [String: Any] = [:]
        for (key, value) in store.dictionaryRepresentation where key.hasPrefix(prefix) {
            values[String(key.dropFirst(prefix.count))] = value
        }
        return values
    }

    private func externalChange(_ note: Notification) {
        guard isEnabled else { return }
        let reason = note.userInfo?[NSUbiquitousKeyValueStoreChangeReasonKey] as? Int
        if reason == NSUbiquitousKeyValueStoreAccountChange {
            connect()
            return
        }
        guard let keys = note.userInfo?[NSUbiquitousKeyValueStoreChangedKeysKey] as? [String] else { return }
        var changed: [String: Any] = [:]
        for key in keys where key.hasPrefix(prefix) {
            if let value = store.object(forKey: key) {
                changed[String(key.dropFirst(prefix.count))] = value
            }
        }
        guard !changed.isEmpty else { return }
        AppSettings.shared.apply(changed, fromSync: true)
        markSynced()
    }

    private func markSynced() {
        lastSync = .now
        UserDefaults.standard.set(lastSync, forKey: "syncLast")
    }
}
