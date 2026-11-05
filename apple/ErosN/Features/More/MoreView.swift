import SwiftUI
import UIKit

struct MoreView: View {
    @Environment(UserSession.self) private var session
    @State private var showLogin = false
    @State private var confirmLogout = false

    var body: some View {
        List {
            Section {
                if session.isLoggedIn {
                    HStack(spacing: 14) {
                        avatar
                        VStack(alignment: .leading, spacing: 2) {
                            Text(session.user?.username ?? String(localized: "Logged In"))
                                .font(.title3.weight(.semibold))
                            Text("nhentai account")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                    Button("Log Out", role: .destructive) { confirmLogout = true }
                } else {
                    Button {
                        showLogin = true
                    } label: {
                        HStack(spacing: 14) {
                            avatar
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
                NavigationLink { AppearanceSettingsView() } label: {
                    SettingsLabel("Appearance", systemImage: "textformat.size", color: .blue)
                }
                NavigationLink { ReadingSettingsView() } label: {
                    SettingsLabel("Reading", systemImage: "book.fill", color: .orange)
                }
                NavigationLink { GeneralSettingsView() } label: {
                    SettingsLabel("General", systemImage: "gearshape.fill", color: .gray)
                }
            }

            Section {
                NavigationLink { AboutView() } label: {
                    SettingsLabel("About", systemImage: "info", color: .indigo)
                }
            }
        }
        .navigationTitle("More")
        .sheet(isPresented: $showLogin) { LoginView() }
        .confirmationDialog("Log out of nhentai?", isPresented: $confirmLogout, titleVisibility: .visible) {
            Button("Log Out", role: .destructive) { session.logout() }
        }
    }

    private var avatar: some View {
        Group {
            if let url = session.user?.avatar {
                RemoteImage(url: url, targetWidth: 120)
            } else {
                Image(systemName: "person.crop.circle.fill")
                    .resizable()
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: 52, height: 52)
        .clipShape(Circle())
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
                    Image(systemName: "square.grid.2x2.fill")
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
            Section("Search") {
                Picker("Language", selection: $settings.searchLanguage) {
                    ForEach(LanguageFilter.allCases) { Text($0.title).tag($0) }
                }
                Picker("Sort", selection: $settings.searchSort) {
                    ForEach(SearchSort.allCases) { Text($0.title).tag($0) }
                }
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

    var body: some View {
        List {
            Section {
                VStack(spacing: 10) {
                    Image("AboutIcon")
                        .resizable()
                        .frame(width: 88, height: 88)
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    Text("Eros-N").font(.title2.bold())
                    Text("Version \(version)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .listRowBackground(Color.clear)
            }
            Section {
                Link(destination: URL(string: "https://github.com/erosTeam/eros_n")!) {
                    LabeledContent("Source Code", value: "GitHub")
                }
                Link(destination: NHHost.site) {
                    LabeledContent("Website", value: "nhentai.net")
                }
            }
            Section("Acknowledgements") {
                LabeledContent("Nuke", value: "MIT License")
            }
        }
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
    }
}
