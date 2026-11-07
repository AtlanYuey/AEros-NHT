import SwiftUI
import UIKit

struct MoreView: View {
    @Environment(UserSession.self) private var session
    @Environment(DownloadManager.self) private var downloads
    @State private var showLogin = false

    var body: some View {
        List {
            Section {
                if session.isLoggedIn {
                    NavigationLink {
                        AccountView()
                    } label: {
                        HStack(spacing: 14) {
                            AvatarView(url: session.user?.avatar, size: 56)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(session.user?.username ?? String(localized: "Logged In"))
                                    .font(.title3.weight(.semibold))
                                Text("nhentai account")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                } else {
                    Button {
                        showLogin = true
                    } label: {
                        HStack(spacing: 14) {
                            AvatarView(url: nil, size: 56)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Log In")
                                    .font(.title3.weight(.semibold))
                                    .foregroundStyle(.primary)
                                Text("Sync favorites and post comments")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }

            Section {
                NavigationLink(value: DownloadsRoute()) {
                    SettingsLabel("Downloads", systemImage: "arrow.down.circle.fill", color: .green)
                        .badge(downloads.records.filter { $0.state == .downloading }.count)
                }
            }

            Section {
                NavigationLink { AppearanceSettingsView() } label: {
                    SettingsLabel("Appearance", systemImage: "textformat.size", color: .blue)
                }
                NavigationLink { ReadingSettingsView() } label: {
                    SettingsLabel("Reading", systemImage: "book.fill", color: .orange)
                }
                NavigationLink { GeneralSettingsView() } label: {
                    SettingsLabel("General", systemImage: "gearshape.fill", color: .gray)
                }
                NavigationLink { SyncSettingsView() } label: {
                    SettingsLabel("iCloud Sync", systemImage: "icloud.fill", color: .cyan)
                }
            }

            Section {
                NavigationLink { LanguageSettingsView() } label: {
                    SettingsLabel("Language", systemImage: "globe", color: .teal)
                }
                NavigationLink { AboutView() } label: {
                    SettingsLabel("About", systemImage: "info", color: .indigo)
                }
            }
        }
        .navigationTitle("Me")
        .sheet(isPresented: $showLogin) { LoginView() }
    }
}

struct AvatarView: View {
    let url: URL?
    let size: CGFloat

    var body: some View {
        Group {
            if let url {
                RemoteImage(url: url, targetWidth: size * 2)
            } else {
                Image(systemName: "person.crop.circle.fill")
                    .resizable()
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
    }
}

/// The signed-in account: profile and log out.
struct AccountView: View {
    @Environment(UserSession.self) private var session
    @Environment(\.dismiss) private var dismiss
    @State private var confirmLogout = false

    var body: some View {
        List {
            Section {
                VStack(spacing: 10) {
                    AvatarView(url: session.user?.avatar, size: 96)
                    Text(session.user?.username ?? String(localized: "Logged In"))
                        .font(.title2.bold())
                    Text("nhentai account")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .listRowBackground(Color.clear)
            }
            if let user = session.user {
                Section {
                    LabeledContent("User ID", value: "\(user.id)")
                    Link(destination: NHHost.site.appendingPathComponent("users/\(user.id)/")) {
                        LabeledContent("Profile", value: "nhentai.net")
                    }
                }
            }
            Section {
                Button("Log Out", role: .destructive) { confirmLogout = true }
                    .frame(maxWidth: .infinity)
            }
        }
        .navigationTitle("Account")
        .navigationBarTitleDisplayMode(.inline)
        .task { await session.reload() }
        .confirmationDialog("Log out of nhentai?", isPresented: $confirmLogout, titleVisibility: .visible) {
            Button("Log Out", role: .destructive) {
                session.logout()
                dismiss()
            }
        }
    }
}

/// Galleries saved for offline reading: cards like Favorites, or rows with
/// their progress. A gallery opens on its page (offline too); Read there,
/// or in its menu, opens the pages.
struct DownloadsView: View {
    @Environment(DownloadManager.self) private var downloads
    @Environment(AppSettings.self) private var settings
    @State private var usage: Int64?

    var body: some View {
        Group {
            if settings.libraryStyle == .cards {
                cards
            } else {
                list
            }
        }
        .overlay {
            if downloads.records.isEmpty {
                ContentUnavailableView("No Downloads", systemImage: "arrow.down.circle",
                                       description: Text("Download a gallery from its page to read it offline."))
            }
        }
        .navigationTitle("Downloads")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if let usage, usage > 0 {
                ToolbarItem(placement: .topBarTrailing) {
                    Text(usage, format: .byteCount(style: .file))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .task(id: downloads.records.count) {
            usage = await Task.detached { DownloadManager.diskUsage() }.value
        }
    }

    private var cards: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                GalleryCollection(items: downloads.records.map(\.item))
                    .padding(.top, 8)
            }
            .padding(.bottom, 16)
        }
        .environment(\.galleryCoverBadge) { item in
            AnyView(DownloadBadge(id: item.id))
        }
        .environment(\.galleryMenuItems) { item in
            AnyView(DownloadMenuItems(id: item.id))
        }
    }

    private var list: some View {
        List {
            ForEach(downloads.records) { record in
                DownloadRow(record: record)
                    .swipeActions(edge: .trailing) {
                        Button("Delete", systemImage: "trash", role: .destructive) {
                            downloads.delete(record.id)
                        }
                    }
                    .contextMenu {
                        DownloadMenuItems(id: record.id)
                    }
            }
        }
        .listStyle(.plain)
    }
}

/// Read, pause / resume and delete for a download.
private struct DownloadMenuItems: View {
    let id: Int

    @Environment(DownloadManager.self) private var downloads

    var body: some View {
        if let record = downloads.record(id) {
            if record.completed > 0 {
                NavigationLink(value: ReaderRoute(source: ReaderSource(record: record), page: 0)) {
                    Label("Read", systemImage: "book")
                }
            }
            switch record.state {
            case .downloading, .queued:
                Button("Pause", systemImage: "pause") { downloads.pause(id) }
            case .paused:
                Button("Resume", systemImage: "arrow.clockwise") { downloads.resume(id) }
            case .failed:
                Button("Retry", systemImage: "arrow.clockwise") { downloads.resume(id) }
            case .finished:
                EmptyView()
            }
            Button("Delete", systemImage: "trash", role: .destructive) { downloads.delete(id) }
        }
    }
}

/// A download's progress over its cover until it has finished.
private struct DownloadBadge: View {
    let id: Int

    @Environment(DownloadManager.self) private var downloads

    var body: some View {
        if let record = downloads.record(id), record.state != .finished {
            ZStack {
                Circle().fill(.black.opacity(0.55))
                Circle()
                    .stroke(.white.opacity(0.3), lineWidth: 3)
                    .padding(4)
                Circle()
                    .trim(from: 0, to: record.progress)
                    .stroke(.white, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .padding(4)
                Image(systemName: icon(record.state))
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.white)
            }
            .frame(width: 34, height: 34)
            .padding(6)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
            .animation(.smooth, value: record.progress)
            .accessibilityElement()
            .accessibilityLabel(Text("\(record.completed) / \(record.pages.count)"))
        }
    }

    private func icon(_ state: DownloadRecord.State) -> String {
        switch state {
        case .downloading: "arrow.down"
        case .queued: "clock"
        case .paused: "pause.fill"
        case .failed: "exclamationmark"
        case .finished: "checkmark"
        }
    }
}

private struct DownloadRow: View {
    let record: DownloadRecord

    @Environment(DownloadManager.self) private var downloads

    var body: some View {
        NavigationLink(value: GalleryRoute(id: record.id, preview: record.item)) {
            HStack(spacing: 14) {
                CoverView(item: record.item, aspectRatio: 0.72, cornerRadius: 10, targetWidth: 200)
                    .frame(width: 72)
                VStack(alignment: .leading, spacing: 6) {
                    Text(record.item.prettyTitle)
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(2)
                    switch record.state {
                    case .finished:
                        Label("\(record.pages.count) pages", systemImage: "checkmark.circle.fill")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    default:
                        ProgressView(value: record.progress)
                        HStack {
                            Text("\(record.completed) / \(record.pages.count)")
                                .monospacedDigit()
                            Spacer()
                            stateButton
                        }
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }

    @ViewBuilder
    private var stateButton: some View {
        switch record.state {
        case .downloading, .queued:
            Button("Pause") { downloads.pause(record.id) }
                .buttonStyle(.borderless)
        case .paused:
            Button("Resume") { downloads.resume(record.id) }
                .buttonStyle(.borderless)
        case .failed:
            Button("Retry") { downloads.resume(record.id) }
                .buttonStyle(.borderless)
        case .finished:
            EmptyView()
        }
    }
}

/// A Settings-app style row label with a colored icon tile.
struct SettingsLabel: View {
    let title: LocalizedStringKey
    let systemImage: String
    let color: Color

    init(_ title: LocalizedStringKey, systemImage: String, color: Color) {
        self.title = title
        self.systemImage = systemImage
        self.color = color
    }

    var body: some View {
        Label {
            Text(title)
        } icon: {
            Image(systemName: systemImage)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 30, height: 30)
                .background(color.gradient, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
    }
}

// MARK: - Appearance

struct AppearanceSettingsView: View {
    @Environment(AppSettings.self) private var settings

    var body: some View {
        @Bindable var settings = settings
        Form {
            Section("Theme") {
                Picker("Appearance", selection: $settings.theme) {
                    ForEach(ThemeMode.allCases) { Text($0.title).tag($0) }
                }
                .pickerStyle(.segmented)
                .listRowSeparator(.hidden)
                AccentPicker(selection: $settings.accent)
            }
            Section {
                Picker("List Style", selection: $settings.listStyle) {
                    ForEach(GalleryListStyle.allCases) { style in
                        Label(style.title, systemImage: style.systemImage).tag(style)
                    }
                }
                Picker("History and Downloads", selection: $settings.libraryStyle) {
                    ForEach(LibraryStyle.allCases) { Text($0.title).tag($0) }
                }
                NavigationLink {
                    CardSizeView()
                } label: {
                    LabeledContent("Card Size", value: cardSizeSummary)
                }
                Toggle("Blur Covers", isOn: $settings.blurCovers)
            } header: {
                Text("Gallery List")
            } footer: {
                Text("Card size applies to the grid and waterfall styles.")
            }
            Section {
                Toggle("Hide Tab Bar When Scrolling", isOn: $settings.hideBarsOnScroll)
            } footer: {
                if UIDevice.current.userInterfaceIdiom == .pad {
                    Text("Scrolling down a list slides the tab bar away; scrolling up brings it back.")
                } else {
                    Text("Scrolling down a list shrinks the tab bar to a small button; scrolling up brings it back.")
                }
            }
            if UIDevice.current.userInterfaceIdiom == .pad {
                Section {
                    Toggle("Tab Bar Follows Your Hand", isOn: $settings.followHand)
                    if settings.followHand {
                        Picker("Follow Speed", selection: $settings.followSpeed) {
                            ForEach(FollowSpeed.allCases) { Text($0.title).tag($0) }
                        }
                    } else {
                        Picker("Tab Bar Position", selection: $settings.tabBarPosition) {
                            ForEach(TabBarPosition.allCases) { Text($0.title).tag($0) }
                        }
                    }
                } footer: {
                    Text("The tab bar moves to the side of the screen you touch: Fast at the first touch, Medium after two touches on that side, Slow after four.")
                }
            }
            TagSettingsSection(settings: settings)
        }
        .navigationTitle("Appearance")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var cardSizeSummary: String {
        settings.cardSizePortrait == settings.cardSizeLandscape
            ? settings.cardSizePortrait.title
            : "\(settings.cardSizePortrait.title) / \(settings.cardSizeLandscape.title)"
    }
}

private struct AccentPicker: View {
    @Binding var selection: AccentChoice

    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 14) {
                ForEach(AccentChoice.allCases) { choice in
                    Button {
                        selection = choice
                    } label: {
                        Circle()
                            .fill(choice.color.gradient)
                            .frame(width: 30, height: 30)
                            .overlay {
                                if choice == selection {
                                    Image(systemName: "checkmark")
                                        .font(.caption.weight(.bold))
                                        .foregroundStyle(.white)
                                }
                            }
                            .padding(3)
                            .overlay {
                                Circle().strokeBorder(choice == selection ? choice.color : .clear, lineWidth: 2)
                            }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(choice.rawValue.capitalized)
                }
            }
            .padding(.vertical, 4)
        }
        .scrollIndicators(.hidden)
    }
}

/// Tag display options and the local tag database.
private struct TagSettingsSection: View {
    @Bindable var settings: AppSettings
    @Environment(TagStore.self) private var tagStore

    var body: some View {
        Section {
            Toggle("Show Tags on Cards", isOn: $settings.showTags)
            Toggle("Translate Tags to Chinese", isOn: $settings.translateTags)
            Button {
                Task { await tagStore.update() }
            } label: {
                HStack {
                    Text("Update Tag Database")
                    Spacer()
                    if tagStore.isUpdating {
                        ProgressView()
                    } else if let date = tagStore.lastUpdated {
                        Text(date, format: .relative(presentation: .named))
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .disabled(tagStore.isUpdating)
        } header: {
            Text("Tags")
        } footer: {
            Text("\(tagStore.tagCount) tags, \(tagStore.translationCount) translations (EhTagTranslation). Updated automatically every week.")
        }
    }
}

// MARK: - Card size

struct CardSizeView: View {
    @Environment(AppSettings.self) private var settings

    var body: some View {
        @Bindable var settings = settings
        Form {
            CardSizeSection(title: "Portrait", isLandscape: false, size: $settings.cardSizePortrait)
            CardSizeSection(title: "Landscape · follows split view", isLandscape: true,
                            size: $settings.cardSizeLandscape)
            Section {
            } footer: {
                Text("Columns are calculated from the width of the pane: rotating, Split View and Stage Manager add or remove columns automatically. \u{201C}Standard\u{201D} matches the automatic column count.")
            }
        }
        .navigationTitle("Card Size")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct CardSizeSection: View {
    let title: LocalizedStringKey
    let isLandscape: Bool
    @Binding var size: CardSize

    @Environment(AppSettings.self) private var settings

    var body: some View {
        Section(title) {
            VStack(spacing: 6) {
                Slider(
                    value: Binding(get: { Double(size.rawValue) },
                                   set: { size = CardSize(rawValue: Int($0.rounded())) ?? .standard }),
                    in: 0...4,
                    step: 1
                ) {
                    Text(title)
                } minimumValueLabel: {
                    Image(systemName: "square.grid.4x3.fill").font(.footnote)
                } maximumValueLabel: {
                    Image(systemName: "square.grid.2x2.fill").font(.body)
                }
                .sensoryFeedback(.selection, trigger: size)
                Text(size.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.tint)
            }
            HStack(spacing: 18) {
                MiniScreen(columns: columns, isLandscape: isLandscape, waterfall: settings.listStyle != .grid)
                    .frame(width: isLandscape ? 170 : 78, height: isLandscape ? 82 : 160)
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(columns)")
                        .font(.largeTitle.bold())
                        .contentTransition(.numericText())
                    Text("columns")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            .padding(.vertical, 6)
            .animation(.smooth, value: columns)
        }
    }

    private var columns: Int {
        let screen = UIScreen.main.bounds.size
        let short = min(screen.width, screen.height)
        let long = max(screen.width, screen.height)
        let width = (isLandscape ? long : short) - 32
        return size.columns(width: width, preferred: settings.listStyle.preferredCardWidth, spacing: 12)
    }
}

private struct MiniScreen: View {
    let columns: Int
    let isLandscape: Bool
    let waterfall: Bool

    var body: some View {
        Canvas { context, canvasSize in
            let frame = CGRect(origin: .zero, size: canvasSize)
            let screen = Path(roundedRect: frame.insetBy(dx: 1, dy: 1), cornerRadius: 10)
            context.fill(screen, with: .color(Color(uiColor: .systemBackground)))
            context.stroke(screen, with: .color(Color(uiColor: .separator)), lineWidth: 1)
            context.clip(to: screen)
            let pad: CGFloat = 5
            let gap: CGFloat = 3
            let n = CGFloat(max(1, columns))
            let width = (canvasSize.width - pad * 2 - gap * (n - 1)) / n
            let ratios: [CGFloat] = [1.4, 1.15, 1.55, 1.25, 1.05, 1.45]
            for column in 0..<max(1, columns) {
                var y: CGFloat = pad + 6
                var index = column
                while y < canvasSize.height {
                    let height = width * (waterfall ? ratios[index % ratios.count] : 1.33)
                    let rect = CGRect(x: pad + CGFloat(column) * (width + gap), y: y, width: width, height: height)
                    context.fill(Path(roundedRect: rect, cornerRadius: 2),
                                 with: .color(Color.accentColor.opacity(0.25 + 0.1 * Double(index % 3))))
                    y += height + gap
                    index += columns
                }
            }
        }
    }
}

// MARK: - Reading / General

struct ReadingSettingsView: View {
    @Environment(AppSettings.self) private var settings

    var body: some View {
        Form {
            ReadingSettingsSections(settings: settings)
        }
        .navigationTitle("Reading")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct GeneralSettingsView: View {
    @Environment(AppSettings.self) private var settings
    @State private var cacheSize: Int?
    @State private var confirmClearCache = false

    var body: some View {
        @Bindable var settings = settings
        Form {
            Section("Home") {
                Picker("Language", selection: $settings.homeLanguage) {
                    ForEach(LanguageFilter.allCases) { Text($0.title).tag($0) }
                }
                Picker("Sort", selection: $settings.homeSort) {
                    ForEach(SearchSort.allCases) { Text($0.title).tag($0) }
                }
            }
            Section {
                Picker("Language", selection: $settings.searchLanguage) {
                    ForEach(LanguageFilter.allCases) { Text($0.title).tag($0) }
                }
                Picker("Sort", selection: $settings.searchSort) {
                    ForEach(SearchSort.allCases) { Text($0.title).tag($0) }
                }
                Toggle("Save Search History", isOn: $settings.saveSearchHistory)
            } header: {
                Text("Search")
            } footer: {
                Text("Recent searches show when you start a search and sync through iCloud with your settings. When this is off, new searches aren't saved and the list is hidden.")
            }
            Section {
                Toggle("Detect Gallery Links", isOn: $settings.detectClipboard)
            } footer: {
                Text("When you return to the app, offer to open an nhentai link found on the clipboard. iOS asks for permission to paste.")
            }
            Section {
                LabeledContent("Image Cache") {
                    if let cacheSize {
                        Text(Int64(cacheSize), format: .byteCount(style: .file))
                    } else {
                        ProgressView()
                    }
                }
                Button("Clear Image Cache", role: .destructive) { confirmClearCache = true }
            } header: {
                Text("Storage")
            }
        }
        .navigationTitle("General")
        .navigationBarTitleDisplayMode(.inline)
        .task { await refreshCacheSize() }
        .confirmationDialog("Clear the image cache?", isPresented: $confirmClearCache, titleVisibility: .visible) {
            Button("Clear Image Cache", role: .destructive) {
                ImageSetup.clearCache()
                Task { await refreshCacheSize() }
            }
        }
    }

    private func refreshCacheSize() async {
        cacheSize = await Task.detached { ImageSetup.diskUsage }.value
    }
}

// MARK: - About

struct AboutView: View {
    private var version: String {
        let info = Bundle.main.infoDictionary
        let short = info?["CFBundleShortVersionString"] as? String ?? "-"
        let build = info?["CFBundleVersion"] as? String ?? "-"
        return "\(short) (\(build))"
    }

    @State private var egg = AboutEgg()

    var body: some View {
        List {
            Section {
                VStack(spacing: 10) {
                    AboutIcon(egg: egg)
                    Text(verbatim: "AEros-NHT").font(.title2.bold())
                    Text("Version \(version)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text("A modified version of eros_n by honjow.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .listRowBackground(Color.clear)
            }
            Section {
                Link(destination: URL(string: "https://github.com/AtlanYuey/AEros-NHT")!) {
                    LabeledContent("Source Code", value: "GitHub")
                }
                Link(destination: URL(string: "https://github.com/honjow/eros_n")!) {
                    LabeledContent("Original Project", value: "honjow/eros_n")
                }
                Link(destination: NHHost.site) {
                    LabeledContent("Website", value: "nhentai.net")
                }
            }
            Section {
                NavigationLink {
                    AcknowledgementsView()
                } label: {
                    Text("Open Source Licenses")
                }
            }
        }
        // The easter egg flies over the whole page, not just its row.
        .overlay { AboutEggEffects(egg: egg) }
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
    }
}

/// Licenses of the original project and the components the app uses.
struct AcknowledgementsView: View {
    private struct Item: Identifiable {
        let name: String
        let author: String
        let license: String
        /// License text bundled with the app, or nil for a link.
        let file: String?
        let url: URL

        var id: String { name }
    }

    private let items: [Item] = [
        Item(name: "eros_n", author: "honjow", license: "Apache License 2.0",
             file: "eros_n-LICENSE", url: URL(string: "https://github.com/honjow/eros_n")!),
        Item(name: "Nuke", author: "Alexander Grebenyuk", license: "MIT License",
             file: "Nuke-LICENSE", url: URL(string: "https://github.com/kean/Nuke")!),
        Item(name: "nhentai_tags_fetcher", author: "honjow", license: "MIT License",
             file: "nhentai_tags_fetcher-LICENSE", url: URL(string: "https://github.com/honjow/nhentai_tags_fetcher")!),
        Item(name: "EhTagTranslation Database", author: "EhTagTranslation", license: "CC BY-NC-SA 3.0",
             file: nil, url: URL(string: "https://github.com/EhTagTranslation/Database")!),
    ]

    var body: some View {
        List {
            Section {
                ForEach(items) { item in
                    if let file = item.file {
                        NavigationLink {
                            LicenseTextView(title: item.name, file: file, url: item.url)
                        } label: {
                            row(item)
                        }
                    } else {
                        Link(destination: item.url) {
                            row(item)
                        }
                        .foregroundStyle(.primary)
                    }
                }
            } footer: {
                Text("Tag translations come from the EhTagTranslation database, licensed under CC BY-NC-SA 3.0 (attribution, non-commercial, share alike). They are downloaded when the app updates its tags.")
            }
        }
        .navigationTitle("Open Source Licenses")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func row(_ item: Item) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(verbatim: item.name)
            Text(verbatim: "\(item.author) · \(item.license)")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }
}

private struct LicenseTextView: View {
    let title: String
    let file: String
    let url: URL

    private var text: String {
        guard let path = Bundle.main.url(forResource: file, withExtension: "txt"),
              let text = try? String(contentsOf: path, encoding: .utf8)
        else { return url.absoluteString }
        return text
    }

    var body: some View {
        ScrollView {
            Text(verbatim: text)
                .font(.footnote.monospaced())
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
        }
        .navigationTitle(Text(verbatim: title))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Link(destination: url) {
                    Image(systemName: "safari")
                }
            }
        }
    }
}
