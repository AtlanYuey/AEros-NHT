import Foundation
import Observation
import UIKit

/// A downloaded (or downloading) gallery, stored under
/// Application Support/Downloads/<id>/.
struct DownloadRecord: Codable, Identifiable, Hashable {
    enum State: String, Codable {
        case queued, downloading, paused, finished, failed
    }

    struct Page: Codable, Hashable {
        let number: Int
        let remote: String
        let file: String
        let width: Int
        let height: Int
    }

    let id: Int
    let mediaID: String
    var title: String
    var thumbnail: String?
    var thumbWidth: Int
    var thumbHeight: Int
    var pages: [Page]
    var completed: Int
    var state: State
    var added: Date
    /// For the language badge and tags on cards (nil for downloads from before 2.1.0).
    var tagIDs: [Int]? = nil

    var progress: Double {
        pages.isEmpty ? 0 : Double(completed) / Double(pages.count)
    }

    var item: GalleryItem {
        GalleryItem(id: id, mediaID: mediaID, title: title, thumbnail: thumbnail,
                    thumbnailWidth: thumbWidth, thumbnailHeight: thumbHeight,
                    numPages: pages.count, tagIDs: tagIDs ?? [])
    }
}

/// Downloads gallery pages for offline reading (three at a time).
@MainActor
@Observable
final class DownloadManager {
    static let shared = DownloadManager()

    private(set) var records: [DownloadRecord] = []
    @ObservationIgnored private var tasks: [Int: Task<Void, Never>] = [:]
    @ObservationIgnored private var lastSave = Date.distantPast

    private init() {
        records = Self.loadIndex()
        // Downloads interrupted by the app being closed resume as paused.
        for index in records.indices where records[index].state == .downloading || records[index].state == .queued {
            records[index].state = .paused
        }
    }

    // MARK: Queries

    func record(_ id: Int) -> DownloadRecord? {
        records.first { $0.id == id }
    }

    /// Local file of a page if it has been downloaded.
    func localURL(gallery id: Int, page index: Int) -> URL? {
        guard let record = record(id), record.pages.indices.contains(index) else { return nil }
        let url = Self.folder(id).appendingPathComponent(record.pages[index].file)
        return FileManager.default.fileExists(atPath: url.path) ? url : nil
    }

    /// The page of a downloaded gallery without the network: the gallery's
    /// JSON saved with the download, or what the download record knows.
    func offlineDetail(_ id: Int) -> GalleryDetail? {
        guard let record = record(id) else { return nil }
        if let data = try? Data(contentsOf: Self.detailURL(id)),
           let detail = try? NHClient.decodeGallery(data) {
            return detail
        }
        return GalleryDetail(record: record)
    }

    /// Keeps the gallery's JSON ([data], as the API sent it) with its
    /// download, for its page offline.
    func saveDetail(_ data: Data, of detail: GalleryDetail) {
        guard record(detail.id) != nil else { return }
        if record(detail.id)?.tagIDs == nil {
            update(detail.id) { $0.tagIDs = detail.tags.map(\.id) }
            saveIndex()
        }
        let url = Self.detailURL(detail.id)
        Task.detached(priority: .utility) {
            try? FileManager.default.createDirectory(at: url.deletingLastPathComponent(),
                                                     withIntermediateDirectories: true)
            try? data.write(to: url, options: .atomic)
        }
    }

    // MARK: Actions

    /// Downloads [detail]; [data] is its JSON, kept for its page offline.
    func start(_ detail: GalleryDetail, data: Data? = nil) {
        if record(detail.id) == nil {
            let item = detail.asItem
            let pages = detail.pages.enumerated().map { offset, page in
                let ext = (page.path as NSString).pathExtension
                return DownloadRecord.Page(
                    number: page.number,
                    remote: page.imageURL?.absoluteString ?? "",
                    file: String(format: "%04d.%@", offset + 1, ext.isEmpty ? "jpg" : ext),
                    width: page.width,
                    height: page.height
                )
            }
            records.insert(DownloadRecord(
                id: detail.id, mediaID: detail.mediaID, title: detail.displayTitle,
                thumbnail: item.thumbnail, thumbWidth: item.thumbnailWidth,
                thumbHeight: item.thumbnailHeight, pages: pages, completed: 0,
                state: .queued, added: Date(), tagIDs: detail.tags.map(\.id)
            ), at: 0)
            saveIndex()
        }
        if let data { saveDetail(data, of: detail) }
        resume(detail.id)
    }

    func resume(_ id: Int) {
        guard tasks[id] == nil, let index = records.firstIndex(where: { $0.id == id }),
              records[index].state != .finished else { return }
        records[index].state = .downloading
        saveIndex()
        tasks[id] = Task { [weak self] in
            await self?.run(id)
        }
    }

    func pause(_ id: Int) {
        tasks[id]?.cancel()
        tasks[id] = nil
        update(id) { $0.state = .paused }
        saveIndex()
    }

    func delete(_ id: Int) {
        tasks[id]?.cancel()
        tasks[id] = nil
        records.removeAll { $0.id == id }
        try? FileManager.default.removeItem(at: Self.folder(id))
        saveIndex()
    }

    // MARK: Worker

    private func run(_ id: Int) async {
        guard let record = record(id) else { return }
        let folder = Self.folder(id)
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        var failures = 0
        let pending = record.pages.filter {
            !FileManager.default.fileExists(atPath: folder.appendingPathComponent($0.file).path)
        }
        update(id) { $0.completed = $0.pages.count - pending.count }

        await withTaskGroup(of: Bool.self) { group in
            var iterator = pending.makeIterator()
            func addNext() -> Bool {
                guard let page = iterator.next() else { return false }
                group.addTask {
                    await Self.fetch(page, to: folder.appendingPathComponent(page.file))
                }
                return true
            }
            for _ in 0..<3 {
                if !addNext() { break }
            }
            for await ok in group {
                if Task.isCancelled { group.cancelAll(); break }
                if ok {
                    update(id) { $0.completed += 1 }
                } else {
                    failures += 1
                }
                if Date().timeIntervalSince(lastSave) > 2 { saveIndex() }
                _ = addNext()
            }
        }

        tasks[id] = nil
        guard !Task.isCancelled else { return }
        update(id) { record in
            record.state = failures == 0 && record.completed >= record.pages.count ? .finished : .failed
        }
        saveIndex()
    }

    nonisolated private static func fetch(_ page: DownloadRecord.Page, to file: URL) async -> Bool {
        guard let url = URL(string: page.remote) else { return false }
        for attempt in 0..<3 {
            if Task.isCancelled { return false }
            do {
                let (data, response) = try await URLSession.shared.data(from: url)
                guard let http = response as? HTTPURLResponse, http.statusCode == 200, !data.isEmpty else {
                    throw URLError(.badServerResponse)
                }
                try data.write(to: file, options: .atomic)
                return true
            } catch {
                try? await Task.sleep(for: .seconds(Double(attempt + 1)))
            }
        }
        return false
    }

    private func update(_ id: Int, _ change: (inout DownloadRecord) -> Void) {
        guard let index = records.firstIndex(where: { $0.id == id }) else { return }
        change(&records[index])
    }

    // MARK: Storage

    nonisolated static var root: URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Downloads", isDirectory: true)
    }

    nonisolated static func folder(_ id: Int) -> URL {
        root.appendingPathComponent("\(id)", isDirectory: true)
    }

    nonisolated private static func detailURL(_ id: Int) -> URL {
        folder(id).appendingPathComponent("gallery.json")
    }

    nonisolated private static var indexURL: URL {
        root.appendingPathComponent("index.json")
    }

    nonisolated private static func loadIndex() -> [DownloadRecord] {
        guard let data = try? Data(contentsOf: indexURL) else { return [] }
        return (try? JSONDecoder().decode([DownloadRecord].self, from: data)) ?? []
    }

    private func saveIndex() {
        lastSave = Date()
        let records = records
        Task.detached(priority: .utility) {
            try? FileManager.default.createDirectory(at: Self.root, withIntermediateDirectories: true)
            if let data = try? JSONEncoder().encode(records) {
                try? data.write(to: Self.indexURL, options: .atomic)
            }
        }
    }

    /// Bytes used by downloads.
    nonisolated static func diskUsage() -> Int64 {
        guard let enumerator = FileManager.default.enumerator(
            at: root, includingPropertiesForKeys: [.fileSizeKey]
        ) else { return 0 }
        var total: Int64 = 0
        for case let url as URL in enumerator {
            total += Int64((try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0)
        }
        return total
    }
}
