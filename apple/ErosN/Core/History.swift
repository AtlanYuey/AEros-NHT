import Foundation
import SwiftData

/// A gallery the user opened, with the last page read.
@Model
final class HistoryEntry {
    @Attribute(.unique) var gid: Int
    var mediaID: String
    var title: String
    var thumbnail: String?
    var thumbWidth: Int
    var thumbHeight: Int
    var numPages: Int
    var lastPage: Int
    var lastRead: Date

    init(gid: Int, mediaID: String, title: String, thumbnail: String?,
         thumbWidth: Int, thumbHeight: Int, numPages: Int,
         lastPage: Int = 0, lastRead: Date = .now) {
        self.gid = gid
        self.mediaID = mediaID
        self.title = title
        self.thumbnail = thumbnail
        self.thumbWidth = thumbWidth
        self.thumbHeight = thumbHeight
        self.numPages = numPages
        self.lastPage = lastPage
        self.lastRead = lastRead
    }

    var item: GalleryItem {
        GalleryItem(id: gid, mediaID: mediaID, title: title, thumbnail: thumbnail,
                    thumbnailWidth: thumbWidth, thumbnailHeight: thumbHeight)
    }
}

extension ModelContext {
    /// Records that [gallery] was opened (and, when given, the page read).
    func recordHistory(_ gallery: GalleryDetail, page: Int? = nil) {
        recordHistory(item: gallery.asItem, title: gallery.displayTitle,
                      numPages: gallery.numPages, page: page)
    }

    func recordHistory(item: GalleryItem, title: String, numPages: Int, page: Int? = nil) {
        let gid = item.id
        let descriptor = FetchDescriptor<HistoryEntry>(predicate: #Predicate { $0.gid == gid })
        if let entry = try? fetch(descriptor).first {
            entry.lastRead = .now
            entry.title = title
            if numPages > 0 { entry.numPages = numPages }
            if let page { entry.lastPage = page }
        } else {
            insert(HistoryEntry(
                gid: gid, mediaID: item.mediaID, title: title,
                thumbnail: item.thumbnail, thumbWidth: item.thumbnailWidth,
                thumbHeight: item.thumbnailHeight, numPages: numPages,
                lastPage: page ?? 0
            ))
        }
        try? save()
    }

    func lastReadPage(_ gid: Int) -> Int? {
        let descriptor = FetchDescriptor<HistoryEntry>(predicate: #Predicate { $0.gid == gid })
        return (try? fetch(descriptor).first)?.lastPage
    }
}
