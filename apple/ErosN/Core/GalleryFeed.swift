import Foundation
import Observation

/// A paginated list of galleries with pull-to-refresh and infinite scroll.
@MainActor
@Observable
final class GalleryFeed {
    typealias Fetch = (Int) async throws -> PageResponse<GalleryItem>

    private(set) var items: [GalleryItem] = []
    private(set) var isLoading = false
    private(set) var error: String?
    private(set) var hasLoaded = false
    private(set) var total: Int?

    @ObservationIgnored private var page = 0
    @ObservationIgnored private var pageCount = 1
    @ObservationIgnored private var seen = Set<Int>()
    @ObservationIgnored private var generation = 0
    @ObservationIgnored var fetch: Fetch

    init(fetch: @escaping Fetch) {
        self.fetch = fetch
    }

    var canLoadMore: Bool { hasLoaded && page < pageCount }

    func reload() async {
        generation += 1
        let current = generation
        isLoading = true
        error = nil
        do {
            let response = try await fetch(1)
            guard current == generation else { return }
            page = 1
            pageCount = max(1, response.numPages)
            total = response.total
            seen = []
            items = unique(response.result)
        } catch is CancellationError {
        } catch {
            guard current == generation else { return }
            self.error = error.localizedDescription
        }
        if current == generation {
            isLoading = false
            hasLoaded = true
        }
    }

    func loadMoreIfNeeded(after item: GalleryItem) async {
        guard canLoadMore, !isLoading else { return }
        guard let index = items.firstIndex(of: item), index >= items.count - 8 else { return }
        await loadMore()
    }

    func loadMore() async {
        guard canLoadMore, !isLoading else { return }
        let current = generation
        isLoading = true
        do {
            let response = try await fetch(page + 1)
            guard current == generation else { return }
            page += 1
            pageCount = max(page, response.numPages)
            items.append(contentsOf: unique(response.result))
        } catch {
            guard current == generation else { return }
            self.error = error.localizedDescription
        }
        if current == generation {
            isLoading = false
        }
    }

    private func unique(_ list: [GalleryItem]) -> [GalleryItem] {
        list.filter { !$0.blacklisted && seen.insert($0.id).inserted }
    }
}
