import Observation
import SwiftUI
import UIKit
import UIKit.UIGestureRecognizerSubclass

/// App-wide chrome state (the reader hides the iPad tab bar).
@MainActor
@Observable
final class AppChrome {
    static let shared = AppChrome()

    var readersOpen = 0
    var hidesTabBar: Bool { readersOpen > 0 }
}

/// Follows the hand in use: the side of the screen touched last. Touches
/// near the middle keep the current side.
@MainActor
@Observable
final class HandTracker {
    static let shared = HandTracker()

    enum Side: String {
        case leading, center, trailing
    }

    private(set) var side: Side

    private init() {
        side = Side(rawValue: UserDefaults.standard.string(forKey: "handSide") ?? "") ?? .trailing
    }

    /// A touch at [fraction] of the screen width (0 = left edge).
    func record(_ fraction: CGFloat) {
        let next: Side
        if fraction > 0.6 {
            next = .trailing
        } else if fraction < 0.4 {
            next = .leading
        } else {
            return
        }
        guard next != side else { return }
        side = next
        UserDefaults.standard.set(next.rawValue, forKey: "handSide")
    }
}

/// Watches touches anywhere in the window without taking part in them.
private final class TouchRecorder: UIGestureRecognizer {
    var onTouch: (@MainActor (CGPoint, CGFloat) -> Void)?

    override init(target: Any?, action: Selector?) {
        super.init(target: target, action: action)
        cancelsTouchesInView = false
        delaysTouchesBegan = false
        delaysTouchesEnded = false
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        if let touch = touches.first, let view, view.bounds.width > 0 {
            onTouch?(touch.location(in: view), view.bounds.width)
        }
        state = .failed
    }
}

/// Installs a [TouchRecorder] on the window that hosts it.
private struct TouchObserver: UIViewRepresentable {
    let onTouch: @MainActor (CGPoint, CGFloat) -> Void

    func makeUIView(context: Context) -> ObserverView {
        let view = ObserverView()
        view.onTouch = onTouch
        view.isUserInteractionEnabled = false
        return view
    }

    func updateUIView(_ view: ObserverView, context: Context) {
        view.onTouch = onTouch
    }

    final class ObserverView: UIView {
        var onTouch: (@MainActor (CGPoint, CGFloat) -> Void)?
        private weak var recorder: TouchRecorder?

        override func didMoveToWindow() {
            super.didMoveToWindow()
            guard let window, recorder == nil else { return }
            let recorder = TouchRecorder(target: nil, action: nil)
            recorder.onTouch = { [weak self] point, width in self?.onTouch?(point, width) }
            window.addGestureRecognizer(recorder)
            self.recorder = recorder
        }
    }
}

/// iPad: the tabs with a floating glass tab bar at the bottom (left,
/// center or right; automatically on the side of the hand in use) instead
/// of the tab bar at the top. Search is on the Home page.
struct PadRootView: View {
    @Binding var selection: AppTab

    @Environment(AppSettings.self) private var settings
    @State private var chrome = AppChrome.shared
    @State private var hand = HandTracker.shared
    /// Where the bar is (window coordinates); touches on it don't move it.
    @State private var barFrame: CGRect = .zero

    var body: some View {
        ZStack {
            tab(.home) { HomeView() }
            tab(.favorites) { FavoritesView() }
            tab(.history) { HistoryView() }
            tab(.more) { MoreView() }
        }
        .modifier(BottomBar(alignment: alignment, visible: !chrome.hidesTabBar) {
            PadTabBar(selection: $selection)
                .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { barFrame = $0 }
                .padding(.horizontal, 20)
                .padding(.bottom, 6)
        })
        .background(TouchObserver { point, width in
            guard !chrome.hidesTabBar, width > 0, !barFrame.insetBy(dx: -10, dy: -10).contains(point) else { return }
            hand.record(point.x / width)
        })
        .animation(.spring(duration: 0.3, bounce: 0.15), value: alignment)
        .animation(.smooth(duration: 0.25), value: chrome.hidesTabBar)
    }

    private var alignment: HorizontalAlignment {
        let position: TabBarPosition
        if settings.tabBarPosition == .automatic {
            switch hand.side {
            case .leading: position = .leading
            case .center: position = .center
            case .trailing: position = .trailing
            }
        } else {
            position = settings.tabBarPosition
        }
        switch position {
        case .leading: return .leading
        case .trailing: return .trailing
        default: return .center
        }
    }

    /// Every tab keeps its own navigation stack; only the selected one shows.
    private func tab<Content: View>(_ value: AppTab, @ViewBuilder content: () -> Content) -> some View {
        // There is no search tab on iPad: Home has the search field.
        let selected = selection == value || (value == .home && selection == .search)
        return NavigationStack {
            content().galleryDestinations()
        }
        .opacity(selected ? 1 : 0)
        .allowsHitTesting(selected)
        .accessibilityHidden(!selected)
        .zIndex(selected ? 1 : 0)
    }
}

/// The bar as a bottom bar of the content (iOS 26 safe area bar, so scroll
/// edges blur under it), or a safe area inset before.
private struct BottomBar<Bar: View>: ViewModifier {
    let alignment: HorizontalAlignment
    let visible: Bool
    @ViewBuilder let bar: () -> Bar

    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content.safeAreaBar(edge: .bottom, alignment: alignment, spacing: 0) {
                if visible { bar().transition(.move(edge: .bottom).combined(with: .opacity)) }
            }
        } else {
            content.safeAreaInset(edge: .bottom, alignment: alignment, spacing: 0) {
                if visible { bar().transition(.move(edge: .bottom).combined(with: .opacity)) }
            }
        }
    }
}

/// Floating tab bar: a glass capsule with the tabs.
struct PadTabBar: View {
    @Binding var selection: AppTab
    @Namespace private var namespace

    private struct Item {
        let tab: AppTab
        let title: LocalizedStringKey
        let icon: String
    }

    private let items = [
        Item(tab: .home, title: "Home", icon: "house"),
        Item(tab: .favorites, title: "Favorites", icon: "heart"),
        Item(tab: .history, title: "History", icon: "clock"),
        Item(tab: .more, title: "More", icon: "ellipsis.circle"),
    ]

    var body: some View {
        GlassGroup {
            HStack(spacing: 2) {
                ForEach(items, id: \.tab) { item in
                    tabButton(item)
                }
            }
            .padding(4)
            .modifier(GlassBackground(shape: Capsule()))
        }
        .sensoryFeedback(.selection, trigger: selection)
    }

    private func tabButton(_ item: Item) -> some View {
        let selected = selection == item.tab || (item.tab == .home && selection == .search)
        return Button {
            select(item.tab)
        } label: {
            VStack(spacing: 3) {
                Image(systemName: selected ? "\(item.icon).fill" : item.icon)
                    .font(.system(size: 20, weight: .medium))
                    .frame(height: 24)
                Text(item.title)
                    .font(.caption2.weight(.semibold))
                    .lineLimit(1)
            }
            .foregroundStyle(selected ? AnyShapeStyle(.tint) : AnyShapeStyle(.primary))
            .frame(width: 84, height: 54)
            .background {
                if selected {
                    Capsule()
                        .fill(Color.primary.opacity(0.1))
                        .matchedGeometryEffect(id: "selection", in: namespace)
                }
            }
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    private func select(_ tab: AppTab) {
        withAnimation(.spring(duration: 0.35, bounce: 0.25)) {
            selection = tab
        }
    }
}

/// Liquid Glass on iOS 26, a material before.
private struct GlassBackground<S: Shape>: ViewModifier {
    let shape: S

    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content.glassEffect(.regular.interactive(), in: shape)
        } else {
            content
                .background(.regularMaterial, in: shape)
                .shadow(color: .black.opacity(0.15), radius: 12, y: 4)
        }
    }
}

/// Groups glass shapes so they blend like system bars (iOS 26).
private struct GlassGroup<Content: View>: View {
    @ViewBuilder let content: () -> Content

    var body: some View {
        if #available(iOS 26.0, *) {
            GlassEffectContainer(spacing: 12) { content() }
        } else {
            content()
        }
    }
}
