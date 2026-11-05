import Nuke
import NukeUI
import SwiftUI

/// An image from the network, cached on disk (Nuke), with a neutral
/// placeholder while loading.
struct RemoteImage: View {
    let url: URL?
    var contentMode: ContentMode = .fill
    /// Decode at this width (points) to save memory; nil keeps full size.
    var targetWidth: CGFloat? = 400
    var blur: Bool = false

    var body: some View {
        LazyImage(request: request) { state in
            if let image = state.image {
                image
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
                    .blur(radius: blur ? 18 : 0, opaque: true)
                    .transition(.opacity)
            } else if state.error != nil {
                Rectangle()
                    .fill(.quaternary)
                    .overlay {
                        Image(systemName: "photo")
                            .font(.title3)
                            .foregroundStyle(.tertiary)
                    }
            } else {
                Rectangle().fill(.quaternary.opacity(0.6))
            }
        }
        .animation(.easeOut(duration: 0.2), value: url)
    }

    private var request: ImageRequest? {
        guard let url else { return nil }
        var processors: [any ImageProcessing] = []
        if let targetWidth {
            processors.append(.resize(width: targetWidth))
        }
        return ImageRequest(url: url, processors: processors)
    }
}

enum ImageSetup {
    /// Disk-cached pipeline for covers and pages.
    static func configure() {
        ImagePipeline.shared = ImagePipeline(configuration: .withDataCache(
            name: "com.honjow.erosn.images",
            sizeLimit: 600 * 1024 * 1024
        ))
    }

    static func clearCache() {
        ImagePipeline.shared.cache.removeAll()
        URLCache.shared.removeAllCachedResponses()
    }

    static var diskUsage: Int {
        (ImagePipeline.shared.configuration.dataCache as? DataCache)?.totalSize ?? 0
    }
}
