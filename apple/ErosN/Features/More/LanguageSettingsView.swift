import SwiftUI
import UIKit

/// The app's own language: the system language, or one picked in the app.
///
/// Stored as the app's `AppleLanguages` preference, the same setting iOS
/// writes when the language is chosen for this app in the Settings app.
/// It takes effect the next time the app starts.
enum AppLanguage {
    struct Option: Identifiable, Hashable {
        let code: String
        /// The language's name in that language.
        let name: String
        var id: String { code }
    }

    /// Languages the app is translated into (nhentai's own languages,
    /// Japanese, English and Chinese, first).
    static let all: [Option] = [
        Option(code: "en", name: "English"),
        Option(code: "ja", name: "日本語"),
        Option(code: "zh-Hans", name: "简体中文"),
        Option(code: "zh-Hant", name: "繁體中文"),
        Option(code: "ko", name: "한국어"),
        Option(code: "es", name: "Español"),
        Option(code: "fr", name: "Français"),
        Option(code: "de", name: "Deutsch"),
        Option(code: "it", name: "Italiano"),
        Option(code: "pt-BR", name: "Português (Brasil)"),
        Option(code: "ru", name: "Русский"),
        Option(code: "vi", name: "Tiếng Việt"),
        Option(code: "th", name: "ไทย"),
        Option(code: "id", name: "Bahasa Indonesia"),
    ]

    private static let key = "AppleLanguages"

    /// The language picked for this app, or "" when it follows the system.
    static var selected: String {
        guard let id = Bundle.main.bundleIdentifier,
              let languages = UserDefaults.standard.persistentDomain(forName: id)?[key] as? [String],
              let first = languages.first
        else { return "" }
        return match(first)?.code ?? ""
    }

    static func select(_ code: String) {
        if code.isEmpty {
            UserDefaults.standard.removeObject(forKey: key)
        } else {
            UserDefaults.standard.set([code], forKey: key)
        }
    }

    /// The device's own preferred language (ignoring this app's choice).
    static var systemLanguage: String? {
        let global = UserDefaults.standard.persistentDomain(forName: UserDefaults.globalDomain)
        return (global?[key] as? [String])?.first ?? Locale.preferredLanguages.first
    }

    private static func match(_ identifier: String) -> Option? {
        all.first { identifier == $0.code }
            ?? all.first { identifier.hasPrefix($0.code + "-") }
            ?? all.first { identifier.hasPrefix(String($0.code.prefix(2))) && $0.code.count == 2 }
    }
}

struct LanguageSettingsView: View {
    @State private var selection = AppLanguage.selected
    @State private var showRestart = false

    var body: some View {
        List {
            Section {
                row(code: "", title: String(localized: "System Language"),
                    subtitle: AppLanguage.systemLanguage.flatMap { Locale.current.localizedString(forIdentifier: $0) })
            }
            Section {
                ForEach(AppLanguage.all) { option in
                    row(code: option.code, title: option.name,
                        subtitle: Locale.current.localizedString(forIdentifier: option.code))
                }
            } footer: {
                Text("The language can also be chosen for this app in the Settings app.")
            }
        }
        .navigationTitle("Language")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Restart to Apply", isPresented: $showRestart) {
            Button("Close App") { closeApp() }
            Button("Later", role: .cancel) {}
        } message: {
            Text("The new language is used the next time AEros-NHT opens.")
        }
    }

    private func row(code: String, title: String, subtitle: String?) -> some View {
        Button {
            guard code != selection else { return }
            selection = code
            AppLanguage.select(code)
            showRestart = true
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(verbatim: title)
                        .foregroundStyle(.primary)
                    if let subtitle, subtitle != title {
                        Text(verbatim: subtitle)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                if code == selection {
                    Image(systemName: "checkmark")
                        .fontWeight(.semibold)
                        .foregroundStyle(.tint)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    /// Goes to the Home Screen and ends the app, so the next launch uses the
    /// new language.
    private func closeApp() {
        UserDefaults.standard.synchronize()
        UIControl().sendAction(#selector(URLSessionTask.suspend), to: UIApplication.shared, for: nil)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            exit(0)
        }
    }
}
