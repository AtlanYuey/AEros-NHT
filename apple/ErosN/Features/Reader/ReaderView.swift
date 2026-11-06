import Nuke
import SwiftData
import SwiftUI
import UIKit

// MARK: - Source

struct ReaderPage: Hashable, Identifiable {
    let index: Int
    let url: URL?
    let aspectRatio: CGFloat
    var id: Int { index }
}

/// What the reader shows: a gallery's pages (local files when downloaded).
struct ReaderSource: Hashable {
    let id: Int
    let title: String
    let pages: [ReaderPage]
    let shareURL: URL
    let item: GalleryItem
    let numPages: Int

    @MainActor
    init(detail: GalleryDetail) {
        id = detail.id
        title = detail.displayTitle
        shareURL = detail.url
        item = detail.asItem
        numPages = detail.numPages
        let downloads = DownloadManager.shared
        pages = detail.pages.enumerated().map { offset, page in
            ReaderPage(index: offset,
                       url: downloads.localURL(gallery: detail.id, page: offset) ?? page.imageURL,
                       aspectRatio: page.aspectRatio)
        }
    }

    @MainActor
    init(record: DownloadRecord) {
        id = record.id
        title = record.title
        shareURL = NHHost.gallery(record.id)
        item = record.item
        numPages = record.pages.count
        let downloads = DownloadManager.shared
        pages = record.pages.enumerated().map { offset, page in
            let ratio = page.width > 0 && page.height > 0 ? CGFloat(page.width) / CGFloat(page.height) : 0.7
            return ReaderPage(index: offset,
                              url: downloads.localURL(gallery: record.id, page: offset) ?? URL(string: page.remote),
                              aspectRatio: ratio)
        }
    }
}

/// Pushes the reader (so the back swipe works).
struct ReaderRoute: Hashable {
    let source: ReaderSource
    let page: Int
}

// MARK: - Reader

struct ReaderView: View {
    let source: ReaderSource

    @State private var page: Int
    @State private var position: Int?
    @State private var chromeVisible = true
    @State private var autoRead = false
    @State private var showSettings = false
    @State private var sliderValue: Double

    @Environment(AppSettings.self) private var settings
    @Environment(\.modelContext) private var modelContext

    @State private var prefetcher = ImagePrefetcher(
        pipeline: .shared, destination: .memoryCache, maxConcurrentRequestCount: 3
    )

    init(route: ReaderRoute) {
        source = route.source
        let start = min(max(0, route.page), max(0, route.source.pages.count - 1))
        _page = State(initialValue: start)
        _position = State(initialValue: start)
        _sliderValue = State(initialValue: Double(start))
    }

    private var pageCount: Int { source.pages.count }
    private var isRTL: Bool { settings.readMode == .rightToLeft }

    var body: some View {
        content
            .background(Color.black)
            .ignoresSafeArea()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    VStack(spacing: 0) {
                        Text(source.title)
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
                        ShareLink(item: source.shareURL) {
                            Label("Share", systemImage: "square.and.arrow.up")
                        }
                    } label: {
                        Label("Options", systemImage: "ellipsis")
                    }
                }
            }
            .toolbar(chromeVisible ? .visible : .hidden, for: .navigationBar)
            .toolbar(.hidden, for: .tabBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .overlay(alignment: .bottom) {
                if chromeVisible {
                    bottomPanel
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .statusBarHidden(!chromeVisible)
            .persistentSystemOverlays(chromeVisible ? .automatic : .hidden)
            .environment(\.colorScheme, .dark)
            .animation(.smooth(duration: 0.25), value: chromeVisible)
            .onChange(of: page) { _, new in
                sliderValue = Double(new)
                if position != new { position = new }
                prefetch(around: new)
            }
            .task(id: page) {
                // Saved once the page settles, not on every turn (saving
                // refreshes the history list and costs a frame).
                try? await Task.sleep(for: .milliseconds(700))
                guard !Task.isCancelled else { return }
                recordPage()
            }
            .onChange(of: position) { _, new in
                if let new, new != page { page = new }
            }
            .onChange(of: settings.readMode) { position = page }
            .task(id: autoRead) { await runAutoRead() }
            .onAppear { AppChrome.shared.readersOpen += 1 }
            .onDisappear { AppChrome.shared.readersOpen = max(0, AppChrome.shared.readersOpen - 1) }
            .onAppear {
                UIApplication.shared.isIdleTimerDisabled = settings.keepScreenOn
                prefetch(around: page)
                recordPage()
            }
            .onDisappear {
                UIApplication.shared.isIdleTimerDisabled = false
                prefetcher.stopPrefetching()
                recordPage()
            }
            .sheet(isPresented: $showSettings) {
                ReaderSettingsSheet()
                    .presentationDetents([.medium, .large])
            }
    }

    // MARK: Pages

    @ViewBuilder
    private var content: some View {
        if settings.readMode.isPaged {
            PagedReader(pages: source.pages, mode: settings.readMode, page: $page) { fraction in
                handleTap(at: fraction)
            }
            .id(settings.readMode)
        } else {
            ScrollView(.vertical) {
                LazyVStack(spacing: settings.readMode == .verticalGap ? settings.pageGap : 0) {
                    ForEach(source.pages) { page in
                        Color.clear
                            .aspectRatio(page.aspectRatio, contentMode: .fit)
                            .overlay {
                                RemoteImage(url: page.url, contentMode: .fit, targetWidth: 1400)
                            }
                            .id(page.index)
                    }
                }
                .scrollTargetLayout()
            }
            .scrollPosition(id: $position, anchor: .top)
            .scrollIndicators(.hidden)
            .contentShape(Rectangle())
            .onTapGesture { chromeVisible.toggle() }
        }
    }

    private func handleTap(at fraction: CGFloat) {
        guard ReaderTapZones.turnsPage(at: fraction) else {
            chromeVisible.toggle()
            return
        }
        if fraction < 0.5 {
            go(isRTL ? page + 1 : page - 1)
        } else {
            go(isRTL ? page - 1 : page + 1)
        }
    }

    private func recordPage() {
        modelContext.recordHistory(item: source.item, title: source.title,
                                   numPages: source.numPages, page: page)
    }

    private func go(_ target: Int) {
        guard (0..<pageCount).contains(target) else { return }
        if settings.readMode.isPaged {
            page = target
        } else if settings.animatePageTurns {
            withAnimation(.smooth(duration: 0.3)) { position = target }
        } else {
            position = target
        }
    }

    private func prefetch(around index: Int) {
        let upper = min(pageCount, index + 1 + settings.preloadPages)
        let lower = max(0, index - 2)
        guard lower < upper else { return }
        let urls = source.pages[lower..<upper].compactMap(\.url).filter { !$0.isFileURL }
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
                        if !editing { go(Int(sliderValue)) }
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
            if settings.readMode == .verticalGap {
                VStack(alignment: .leading) {
                    LabeledContent("Page Gap") {
                        Text("\(Int(settings.pageGap)) pt")
                            .monospacedDigit()
                    }
                    Slider(value: $settings.pageGap, in: 2...60, step: 2) {
                        Text("Page Gap")
                    }
                }
            }
            Toggle("Tap Edges to Turn Pages", isOn: $settings.tapToTurnPages)
            Toggle("Page Turn Animation", isOn: $settings.animatePageTurns)
            Toggle("Keep Screen On", isOn: $settings.keepScreenOn)
        } footer: {
            Text("Without the animation, tapping an edge shows the next page at once.")
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

// MARK: - Tap zones

/// Which taps turn the page: the outer 30 % on each side, when enabled.
enum ReaderTapZones {
    static let edge: CGFloat = 0.3

    static func turnsPage(at fraction: CGFloat) -> Bool {
        AppSettings.shared.tapToTurnPages && (fraction < edge || fraction > 1 - edge)
    }
}

// MARK: - Paged reader (UIPageViewController)

/// One page at a time, left-to-right, right-to-left or top-to-bottom.
/// UIPageViewController keeps the neighbouring pages alive, so turning a
/// page shows an already decoded image instead of a blank one.
struct PagedReader: UIViewControllerRepresentable {
    let pages: [ReaderPage]
    let mode: ReadMode
    @Binding var page: Int
    let onTap: (CGFloat) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIViewController(context: Context) -> UIPageViewController {
        let controller = UIPageViewController(
            transitionStyle: .scroll,
            navigationOrientation: mode == .verticalPaged ? .vertical : .horizontal,
            options: [.interPageSpacing: 16]
        )
        controller.view.backgroundColor = .black
        controller.dataSource = context.coordinator
        controller.delegate = context.coordinator
        if let first = context.coordinator.controller(for: page) {
            controller.setViewControllers([first], direction: .forward, animated: false)
        }
        return controller
    }

    func updateUIViewController(_ controller: UIPageViewController, context: Context) {
        let coordinator = context.coordinator
        coordinator.parent = self
        // A running page turn picks up the newest page when it ends.
        guard !coordinator.isAnimating,
              let current = (controller.viewControllers?.first as? PageController)?.index,
              current != page
        else { return }
        coordinator.show(page, from: current, in: controller,
                         animated: AppSettings.shared.animatePageTurns && abs(page - current) == 1)
    }

    final class Coordinator: NSObject, UIPageViewControllerDataSource, UIPageViewControllerDelegate {
        var parent: PagedReader
        private(set) var isAnimating = false
        private var animationID = 0
        /// Page controllers near the current page, reused so a tap shows
        /// the very page that was already laid out next to this one.
        private var cache: [Int: PageController] = [:]

        init(_ parent: PagedReader) {
            self.parent = parent
        }

        func controller(for index: Int) -> PageController? {
            guard parent.pages.indices.contains(index) else { return nil }
            if let cached = cache[index] { return cached }
            let controller = PageController(index: index, url: parent.pages[index].url)
            controller.onTap = { [weak self] fraction in self?.parent.onTap(fraction) }
            cache[index] = controller
            let current = parent.page
            cache = cache.filter { abs($0.key - current) <= 3 || $0.key == index }
            return controller
        }

        func show(_ index: Int, from current: Int, in pageController: UIPageViewController, animated: Bool) {
            guard let target = controller(for: index) else { return }
            let forward = index > current
            let direction: UIPageViewController.NavigationDirection
            if parent.mode == .rightToLeft {
                direction = forward ? .reverse : .forward
            } else {
                direction = forward ? .forward : .reverse
            }
            guard animated else {
                pageController.setViewControllers([target], direction: direction, animated: false)
                return
            }
            animationID += 1
            let id = animationID
            isAnimating = true
            pageController.setViewControllers([target], direction: direction, animated: true) { [weak self, weak pageController] _ in
                DispatchQueue.main.async {
                    self?.finishTurn(id, at: index, target: target, direction: direction, in: pageController)
                }
            }
            // In case the completion never comes, taps must keep working.
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self, weak pageController] in
                self?.finishTurn(id, at: index, target: target, direction: direction, in: pageController)
            }
        }

        private func finishTurn(_ id: Int, at index: Int, target: PageController,
                                direction: UIPageViewController.NavigationDirection,
                                in pageController: UIPageViewController?) {
            guard id == animationID, isAnimating, let pageController else { return }
            isAnimating = false
            let wanted = parent.page
            if wanted != index {
                // Tapped again during the turn: go straight there.
                show(wanted, from: index, in: pageController, animated: false)
            } else {
                // Refreshes the neighbours UIPageViewController keeps
                // (they can be stale after an animated jump).
                pageController.setViewControllers([target], direction: direction, animated: false)
            }
        }

        private func neighbour(of controller: UIViewController, _ delta: Int) -> UIViewController? {
            guard let page = controller as? PageController else { return nil }
            let step = parent.mode == .rightToLeft ? -delta : delta
            return self.controller(for: page.index + step)
        }

        func pageViewController(_ pageViewController: UIPageViewController,
                                viewControllerBefore viewController: UIViewController) -> UIViewController? {
            neighbour(of: viewController, -1)
        }

        func pageViewController(_ pageViewController: UIPageViewController,
                                viewControllerAfter viewController: UIViewController) -> UIViewController? {
            neighbour(of: viewController, 1)
        }

        func pageViewController(_ pageViewController: UIPageViewController,
                                didFinishAnimating finished: Bool,
                                previousViewControllers: [UIViewController],
                                transitionCompleted completed: Bool) {
            guard completed, let current = pageViewController.viewControllers?.first as? PageController else {
                return
            }
            if parent.page != current.index {
                parent.page = current.index
            }
        }
    }
}

final class PageController: UIViewController {
    let index: Int
    let url: URL?
    var onTap: ((CGFloat) -> Void)?
    private let zoomView = ZoomableImageView()

    init(index: Int, url: URL?) {
        self.index = index
        self.url = url
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        view = zoomView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        zoomView.onTap = { [weak self] fraction in self?.onTap?(fraction) }
        zoomView.load(url)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        zoomView.resetZoom()
    }
}

// MARK: - Zoomable page

/// A page image that can be pinch-zoomed and double-tapped (UIScrollView).
///
/// Taps on the page-turning edges are handled the moment the finger lifts.
/// Only taps in the middle wait briefly to see whether a second tap
/// (double-tap zoom) follows, instead of every tap waiting for it.
final class ZoomableImageView: UIScrollView, UIScrollViewDelegate {
    private let imageView = UIImageView()
    private let spinner = UIActivityIndicatorView(style: .large)
    private var task: ImageTask?
    private var currentURL: URL?
    private var pendingTap: DispatchWorkItem?
    private var lastTapTime: CFTimeInterval = 0
    private var lastTapPoint: CGPoint = .zero
    var onTap: ((CGFloat) -> Void)?

    private static let doubleTapInterval: CFTimeInterval = 0.28

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

        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleTap(_:))))
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        task?.cancel()
        pendingTap?.cancel()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        if zoomScale == minimumZoomScale {
            imageView.frame = CGRect(origin: .zero, size: bounds.size)
            contentSize = bounds.size
        }
        spinner.center = CGPoint(x: bounds.midX, y: bounds.midY)
    }

    func resetZoom() {
        pendingTap?.cancel()
        pendingTap = nil
        if zoomScale != minimumZoomScale {
            setZoomScale(minimumZoomScale, animated: false)
        }
    }

    func load(_ url: URL?) {
        guard url != currentURL else { return }
        task?.cancel()
        currentURL = url
        imageView.image = nil
        resetZoom()
        guard let url else { return }
        let request = ImageRequest(url: url)
        if let cached = ImagePipeline.shared.cache[request] {
            imageView.image = cached.image
            return
        }
        spinner.startAnimating()
        task = ImagePipeline.shared.loadImage(with: request) { [weak self] result in
            guard let self, self.currentURL == url else { return }
            self.spinner.stopAnimating()
            if case let .success(response) = result {
                UIView.transition(with: self.imageView, duration: 0.15, options: .transitionCrossDissolve) {
                    self.imageView.image = response.image
                }
            }
        }
    }

    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        imageView
    }

    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        let offsetX = max((bounds.width - contentSize.width) / 2, 0)
        let offsetY = max((bounds.height - contentSize.height) / 2, 0)
        imageView.center = CGPoint(x: contentSize.width / 2 + offsetX, y: contentSize.height / 2 + offsetY)
    }

    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        guard bounds.width > 0 else { return }
        let location = gesture.location(in: self)
        // Position on screen (the scroll view's bounds move when zoomed).
        let point = CGPoint(x: location.x - bounds.minX, y: location.y - bounds.minY)
        let fraction = point.x / bounds.width
        let zoomed = zoomScale > minimumZoomScale + 0.01

        if !zoomed, ReaderTapZones.turnsPage(at: fraction) {
            pendingTap?.cancel()
            pendingTap = nil
            onTap?(fraction)
            return
        }

        let now = CACurrentMediaTime()
        let dx = point.x - lastTapPoint.x
        let dy = point.y - lastTapPoint.y
        if let pending = pendingTap, now - lastTapTime < Self.doubleTapInterval, dx * dx + dy * dy < 3600 {
            pending.cancel()
            pendingTap = nil
            toggleZoom(at: gesture.location(in: imageView))
            return
        }

        pendingTap?.cancel()
        lastTapTime = now
        lastTapPoint = point
        let work = DispatchWorkItem { [weak self] in
            self?.pendingTap = nil
            self?.onTap?(0.5)
        }
        pendingTap = work
        DispatchQueue.main.asyncAfter(deadline: .now() + Self.doubleTapInterval, execute: work)
    }

    private func toggleZoom(at point: CGPoint) {
        if zoomScale > minimumZoomScale {
            setZoomScale(minimumZoomScale, animated: true)
        } else {
            let scale: CGFloat = 2.5
            let size = CGSize(width: bounds.width / scale, height: bounds.height / scale)
            zoom(to: CGRect(x: point.x - size.width / 2, y: point.y - size.height / 2,
                            width: size.width, height: size.height), animated: true)
        }
    }
}

// MARK: - Back swipe

/// Keeps the edge swipe-back working when a pushed screen hides its
/// navigation bar (the reader with its controls hidden).
extension UINavigationController: @retroactive UIGestureRecognizerDelegate {
    override open func viewDidLoad() {
        super.viewDidLoad()
        interactivePopGestureRecognizer?.delegate = self
    }

    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        viewControllers.count > 1
    }
}
