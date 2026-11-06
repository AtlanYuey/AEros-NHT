import SwiftUI
import UIKit
import UniformTypeIdentifiers

/// iCloud sync of the settings, plus export / import as a file.
struct SyncSettingsView: View {
    @State private var sync = SettingsSync.shared
    @State private var importing = false
    @State private var message: String?

    private var isPad: Bool { UIDevice.current.userInterfaceIdiom == .pad }

    var body: some View {
        @Bindable var sync = sync
        Form {
            Section {
                Toggle("Sync Settings with iCloud", isOn: $sync.isEnabled)
                if sync.isEnabled {
                    Picker("Sync With", selection: $sync.scope) {
                        Text("All Devices").tag(SyncScope.allDevices)
                        if isPad {
                            Text("Other iPads Only").tag(SyncScope.sameDeviceType)
                        } else {
                            Text("Other iPhones Only").tag(SyncScope.sameDeviceType)
                        }
                    }
                }
            } footer: {
                VStack(alignment: .leading, spacing: 6) {
                    if sync.isEnabled && !sync.isAvailable {
                        Text("iCloud isn't available to this copy of the app: the certificate it was signed with doesn't include iCloud, so the settings stay on this device. Export and import them below instead.")
                            .foregroundStyle(.orange)
                    } else if isPad {
                        Text("Settings follow your Apple Account to your other devices. Choose whether this iPad shares them with your iPhone, or only with your other iPads.")
                    } else {
                        Text("Settings follow your Apple Account to your other devices. Choose whether this iPhone shares them with your iPad, or only with your other iPhones.")
                    }
                    if sync.isEnabled, sync.isAvailable, let date = sync.lastSync {
                        Text("Last synced: \(date.formatted(date: .abbreviated, time: .shortened))")
                    }
                }
            }

            Section {
                ShareLink(item: SettingsFile(), preview: SharePreview("Eros-N Settings")) {
                    Label("Export Settings", systemImage: "square.and.arrow.up")
                }
                Button {
                    importing = true
                } label: {
                    Label("Import Settings", systemImage: "square.and.arrow.down")
                }
            } footer: {
                Text("Save the settings as a file, for example in iCloud Drive, and import it on another device.")
            }
        }
        .navigationTitle("iCloud Sync")
        .navigationBarTitleDisplayMode(.inline)
        .fileImporter(isPresented: $importing, allowedContentTypes: [.json]) { result in
            importSettings(result)
        }
        .alert("Import Settings", isPresented: Binding(
            get: { message != nil },
            set: { if !$0 { message = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(message ?? "")
        }
    }

    private func importSettings(_ result: Result<URL, Error>) {
        do {
            let url = try result.get()
            let access = url.startAccessingSecurityScopedResource()
            defer { if access { url.stopAccessingSecurityScopedResource() } }
            let data = try Data(contentsOf: url)
            guard let values = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                throw CocoaError(.fileReadCorruptFile)
            }
            AppSettings.shared.apply(values, fromSync: false)
            message = String(localized: "The settings were imported.")
        } catch {
            message = error.localizedDescription
        }
    }
}

/// The settings as a JSON file, for the share sheet ("Save to Files").
struct SettingsFile: Transferable {
    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(exportedContentType: .json) { _ in
            let url = FileManager.default.temporaryDirectory
                .appendingPathComponent("Eros-N Settings.json")
            let data = try JSONSerialization.data(
                withJSONObject: AppSettings.shared.snapshot(),
                options: [.prettyPrinted, .sortedKeys]
            )
            try data.write(to: url, options: .atomic)
            return SentTransferredFile(url)
        }
    }
}
