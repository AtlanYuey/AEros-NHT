import SwiftData
import SwiftUI

struct HistoryView: View {
    @Query(sort: \HistoryEntry.lastRead, order: .reverse) private var entries: [HistoryEntry]
    @Environment(\.modelContext) private var modelContext
    @State private var searchText = ""
    @State private var confirmClear = false

    private var filtered: [HistoryEntry] {
        let text = searchText.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return entries }
        return entries.filter {
            $0.title.localizedCaseInsensitiveContains(text) || "\($0.gid)" == text
        }
    }

    private struct DaySection: Identifiable {
        let day: Date
        let entries: [HistoryEntry]
        var id: Date { day }
    }

    private var sections: [DaySection] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: filtered) { calendar.startOfDay(for: $0.lastRead) }
        return grouped.keys.sorted(by: >).map { DaySection(day: $0, entries: grouped[$0] ?? []) }
    }

    var body: some View {
        List {
            ForEach(sections) { section in
                Section {
                    ForEach(section.entries) { entry in
                        GalleryRow(item: entry.item, subtitle: subtitle(entry))
                    }
                    .onDelete { offsets in
                        for index in offsets {
                            modelContext.delete(section.entries[index])
                        }
                        try? modelContext.save()
                    }
                } header: {
                    Text(title(for: section.day))
                }
            }
        }
        .listStyle(.plain)
        .overlay {
            if entries.isEmpty {
                ContentUnavailableView("No History", systemImage: "clock",
                                       description: Text("Galleries you open appear here."))
            } else if filtered.isEmpty {
                ContentUnavailableView.search(text: searchText)
            }
        }
        .navigationTitle("History")
        .searchable(text: $searchText, prompt: "Search History")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Clear", systemImage: "trash") { confirmClear = true }
                    .disabled(entries.isEmpty)
            }
        }
        .confirmationDialog("Clear all history?", isPresented: $confirmClear, titleVisibility: .visible) {
            Button("Clear History", role: .destructive) {
                try? modelContext.delete(model: HistoryEntry.self)
                try? modelContext.save()
            }
        }
    }

    private func subtitle(_ entry: HistoryEntry) -> String {
        let time = entry.lastRead.formatted(date: .omitted, time: .shortened)
        guard entry.numPages > 0 else { return time }
        return String(localized: "Page \(entry.lastPage + 1) of \(entry.numPages) · \(time)")
    }

    private func title(for day: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(day) { return String(localized: "Today") }
        if calendar.isDateInYesterday(day) { return String(localized: "Yesterday") }
        return day.formatted(date: .complete, time: .omitted)
    }
}
