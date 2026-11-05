import Nuke
import SwiftData
import SwiftUI
import UIKit

struct ReaderView: View {
    let gallery: GalleryDetail

    @State private var page: Int
    @State private var position: Int?
    @State private var chromeVisible = true
    @State private var autoRead = false
    @State private var showSettings = false
    @State private var sliderValue: Double

    @Environment(AppSettings.self) private var settings
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var prefetcher = ImagePrefetcher(pipeline: .shared, destination: .memoryCache, maxConcurrentRequestCount: 3)

    init(gallery: GalleryDetail, startPage: Int) {
        self.gallery = gallery
        _page = State(initialValue: startPage)
        _position = State(initialValue: startPage)
        _sliderValue = State(initialValue: Double(startPage))
    }

    private var pageCount: Int { gallery.pages.count }
    private var isRTL: Bool { settings.readMode == .rightToLeft }

    var body: some View {
        NavigationStack {
            pager
                .background(Color.black)
                .ignoresSafeArea()
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Close", systemImage: "xmark") { dismiss() }
                    }
                    ToolbarItem(placement: .principal) {
                        VStack(spacing: 0) {
                            Text(gallery.displayTitle)
                                .font(.subheadline.weight(.semibold))
                                .lineLimit(1)
                            Text("\(page + 1) / \(pageCount)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .monospacedDigit()
                        }
                        .frame(maxWidth: 240)
                    }
                    ToolbarItem(placement: .primaryAction) {
                        Menu {
                            Picker("Reading Direction", selection: Binding(
                                get: { settings.readMode },
                                set: { settings.readMode = $0 }
                            )) {
                                ForEach(ReadMode.allCases) { mode in
                                    Label(mode.title, systemImage: mode.systemImage).tag(mode)
                                }
                            }
                            Button("Reader Settings", systemImage: "slider.horizontal.3") {
                                showSettings = true
                            }
                            ShareLink(item: gallery.url) {
                                Label("Share", systemImage: "square.and.arrow.up")
                            }
                        } label: {
                            Label("Options", systemImage: "ellipsis")
                        }
                    }
                }
                .toolbar(chromeVisible ? .visible : .hidden, for: .navigationBar)
                .navigationBarTitleDisplayMode(.inline)
                .overlay(alignment: .bottom) {
                    if chromeVisible {
                        bottomPanel
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
                .statusBarHidden(!chromeVisible)
                .persistentSystemOverlays(chromeVisible ? .automatic : .hidden)
        }
        .preferredColorScheme(.dark)
        .animation(.smooth(duration: 0.25), value: chromeVisible)
        .onChange(of: position) { _, new in
            guard let new else { return }
            page = new
            sliderValue = Double(new)
            prefetch(around: new)
            modelContext.recordHistory(gallery, page: new)
        }
        .task(id: autoRead) { await runAutoRead() }
        .onAppear {
            UIApplication.shared.isIdleTimerDisabled = settings.keepScreenOn
            prefetch(around: page)
        }
        .onDisappear {
            UIApplication.shared.isIdleTimerDisabled = false
            prefetcher.stopPrefetching()
        }
        .sheet(isPresented: $showSettings) {
            ReaderSettingsSheet()
                .presentationDetents([.medium, .large])
        }
    }

    // MARK: Pages

    @ViewBuilder
    private var pager: some View {
        switch settings.readMode {
        case .vertical:
            ScrollView(.vertical) {
                LazyVStack(spacing: 0) {
                    ForEach(gallery.pages.indices, id: \.self) { index in
                        let page = gallery.pages[index]
                        Color.clear
                            .aspectRatio(page.aspectRatio, contentMode: .fit)
                            .overlay {
                                RemoteImage(url: page.imageURL, contentMode: .fit, targetWidth: 1400)
                            }
                            .id(index)
                    }
                }
                .scrollTargetLayout()
            }
            .scrollPosition(id: $position, anchor: .top)
            .scrollIndicators(.hidden)
            .contentShape(Rectangle())
            .onTapGesture { chromeVisible.toggle() }
        case .leftToRight, .rightToLeft:
            ScrollView(.horizontal) {
                LazyHStack(spacing: 0) {
                    ForEach(gallery.pages.indices, id: \.self) { index in
                        ZoomablePage(url: gallery.pages[index].imageURL) { fraction in
                            handleTap(at: fraction)
                        }
                        .containerRelativeFrame([.horizontal, .vertical])
                        .id(index)
                    }
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.paging)
            .scrollPosition(id: $position)
            .scrollIndicators(.hidden)
            .environment(\.layoutDirection, isRTL ? .rightToLeft : .leftToRight)
        }
    }

    private func handleTap(at fraction: CGFloat) {
        guard settings.tapToTurnPages else {
            chromeVisible.toggle()
            return
        }
        if fraction < 0.3 {
            go(isRTL ? page + 1 : page - 1)
        } else if fraction > 0.7 {
            go(isRTL ? page - 1 : page + 1)
        } else {
            chromeVisible.toggle()
        }
    }

    private func go(_ target: Int, animated: Bool = true) {
        guard (0..<pageCount).contains(target) else { return }
        if animated {
            withAnimation(.smooth(duration: 0.3)) { position = target }
        } else {
            position = target
        }
    }

    private func prefetch(around index: Int) {
        let upper = min(pageCount, index + 1 + settings.preloadPages)
        let lower = max(0, index - 1)
        guard lower < upper else { return }
        let urls = gallery.pages[lower..<upper].compactMap(\.imageURL)
        prefetcher.startPrefetching(with: urls)
    }

    private func runAutoRead() async {
        guard autoRead else { return }
        chromeVisible = false
        while !Task.isCancelled {
            try? await Task.sleep(for: .seconds(settings.autoReadInterval))
            guard !Task.isCancelled else { return }
            if page + 1 >= pageCount {
                autoRead = false
                return
            }
            go(page + 1)
        }
    }

    // MARK: Bottom panel

    private var bottomPanel: some View {
        VStack(spacing: 10) {
            HStack(spacing: 12) {
                Text("\(page + 1)")
                    .font(.footnote.monospacedDigit())
                    .frame(minWidth: 28)
                Slider(
                    value: $sliderValue,
                    in: 0...Double(max(1, pageCount - 1)),
                    step: 1,
                    onEditingChanged: { editing in
                        if !editing { go(Int(sliderValue), animated: false) }
                    }
                )
                .environment(\.layoutDirection, isRTL ? .rightToLeft : .leftToRight)
                Text("\(pageCount)")
                    .font(.footnote.monospacedDigit())
                    .frame(minWidth: 28)
            }
            HStack {
                Button {
                    go(isRTL ? page + 1 : page - 1)
                } label: {
                    Image(systemName: "chevron.left")
                }
                Spacer()
                Button {
                    autoRead.toggle()
                } label: {
                    Label(autoRead ? "Stop Auto Read" as LocalizedStringKey : "Auto Read",
                          systemImage: autoRead ? "pause.fill" : "play.fill")
                }
                Spacer()
                Button {
                    showSettings = true
                } label: {
                    Image(systemName: "slider.horizontal.3")
                }
                Spacer()
                Button {
                    go(isRTL ? page - 1 : page + 1)
                } label: {
                    Image(systemName: "chevron.right")
                }
            }
            .font(.body.weight(.medium))
            .labelStyle(.titleAndIcon)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .modifier(GlassPanel())
        .padding(.horizontal, 12)
        .padding(.bottom, 8)
        .frame(maxWidth: 640)
    }
}

/// A floating panel: Liquid Glass on iOS 26, material before.
struct GlassPanel: ViewModifier {
    var cornerRadius: CGFloat = 28

    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content.glassEffect(.regular, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        } else {
            content.background(.regularMaterial, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        }
    }
}

struct ReaderSettingsSheet: View {
    @Environment(AppSettings.self) private var settings
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        @Bindable var settings = settings
        NavigationStack {
            Form {
                ReadingSettingsSections(settings: settings)
            }
            .navigationTitle("Reader Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done", systemImage: "checkmark") { dismiss() }
                }
            }
        }
    }
}

/// Shared by the reader sheet and the Reading settings page.
struct ReadingSettingsSections: View {
    @Bindable var settings: AppSettings

    var body: some View {
        Section {
            Picker("Reading Direction", selection: $settings.readMode) {
                ForEach(ReadMode.allCases) { mode in
                    Label(mode.title, systemImage: mode.systemImage).tag(mode)
                }
            }
            Toggle("Tap Edges to Turn Pages", isOn: $settings.tapToTurnPages)
            Toggle("Keep Screen On", isOn: $settings.keepScreenOn)
        }
        Section {
            VStack(alignment: .leading) {
                LabeledContent("Auto Read Interval") {
                    Text(settings.autoReadInterval, format: .number.precision(.fractionLength(1)))
                        + Text(" s")
                }
                Slider(value: $settings.autoReadInterval, in: 1...10, step: 0.5) {
                    Text("Auto Read Interval")
                } minimumValueLabel: {
                    Image(systemName: "hare")
                } maximumValueLabel: {
                    Image(systemName: "tortoise")
                }
            }
            Stepper(value: $settings.preloadPages, in: 1...10) {
                LabeledContent("Preload Pages", value: "\(settings.preloadPages)")
            }
        } footer: {
            Text("Pages ahead of the current one are downloaded in advance.")
        }
    }
}

// MARK: - Zoomable page

/// A page image that can be pinch-zoomed and double-tapped (UIScrollView).
struct ZoomablePage: UIViewRepresentable {
    let url: URL?
    let onTap: (CGFloat) -> Void

    func makeUIView(context: Context) -> ZoomableImageView {
        ZoomableImageView()
    }

    func updateUIView(_ view: ZoomableImageView, context: Context) {
        view.onTap = onTap
        view.load(url)
    }

    static func dismantleUIView(_ view: ZoomableImageView, coordinator: ()) {
        view.cancel()
    }
}

final class ZoomableImageView: UIScrollView, UIScrollViewDelegate {
    private let imageView = UIImageView()
    private let spinner = UIActivityIndicatorView(style: .large)
    private var task: ImageTask?
    private var currentURL: URL?
    var onTap: ((CGFloat) -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        delegate = self
        minimumZoomScale = 1
        maximumZoomScale = 4
        bouncesZoom = true
        showsVerticalScrollIndicator = false
        showsHorizontalScrollIndicator = false
        contentInsetAdjustmentBehavior = .never
        decelerationRate = .fast
        backgroundColor = .black

        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        addSubview(imageView)

        spinner.color = .lightGray
        spinner.hidesWhenStopped = true
        addSubview(spinner)

        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap(_:)))
        doubleTap.numberOfTapsRequired = 2
        addGestureRecognizer(doubleTap)
        let singleTap = UITapGestureRecognizer(target: self, action: #selector(handleSingleTap(_:)))
        singleTap.require(toFail: doubleTap)
        addGestureRecognizer(singleTap)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        if zoomScale == minimumZoomScale {
            imageView.frame = CGRect(origin: .zero, size: bounds.size)
            contentSize = bounds.size
        }
        spinner.center = CGPoint(x: bounds.midX, y: bounds.midY)
    }

    func load(_ url: URL?) {
        guard url != currentURL else { return }
        cancel()
        currentURL = url
        imageView.image = nil
        setZoomScale(minimumZoomScale, animated: false)
        guard let url else { return }
        if let cached = ImagePipeline.shared.cache[ImageRequest(url: url)] {
            imageView.image = cached.image
            return
        }
        spinner.startAnimating()
        task = ImagePipeline.shared.loadImage(with: ImageRequest(url: url)) { [weak self] result in
            guard let self, self.currentURL == url else { return }
            self.spinner.stopAnimating()
            if case let .success(response) = result {
                UIView.transition(with: self.imageView, duration: 0.2, options: .transitionCrossDissolve) {
                    self.imageView.image = response.image
                }
            }
        }
    }

    func cancel() {
        task?.cancel()
        task = nil
    }

    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        imageView
    }

    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        let offsetX = max((bounds.width - contentSize.width) / 2, 0)
        let offsetY = max((bounds.height - contentSize.height) / 2, 0)
        imageView.center = CGPoint(x: contentSize.width / 2 + offsetX, y: contentSize.height / 2 + offsetY)
    }

    @objc private func handleDoubleTap(_ gesture: UITapGestureRecognizer) {
        if zoomScale > minimumZoomScale {
            setZoomScale(minimumZoomScale, animated: true)
        } else {
            let point = gesture.location(in: imageView)
            let scale: CGFloat = 2.5
            let size = CGSize(width: bounds.width / scale, height: bounds.height / scale)
            zoom(to: CGRect(x: point.x - size.width / 2, y: point.y - size.height / 2,
                            width: size.width, height: size.height), animated: true)
        }
    }

    @objc private func handleSingleTap(_ gesture: UITapGestureRecognizer) {
        guard bounds.width > 0 else { return }
        var fraction = gesture.location(in: self).x / bounds.width
        if zoomScale > minimumZoomScale {
            fraction = 0.5
        }
        if effectiveUserInterfaceLayoutDirection == .rightToLeft {
            fraction = 1 - fraction
        }
        onTap?(fraction)
    }
}
