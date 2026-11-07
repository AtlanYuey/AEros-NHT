import Observation
import SwiftUI
import UIKit
import UIKit.UIGestureRecognizerSubclass

/// App-wide chrome state: the reader hides the tab bar, and scrolling a
/// list down can slide it away (Appearance › Hide Tab Bar When Scrolling).
@MainActor
@Observable
final class AppChrome {
    static let shared = AppChrome()

    var readersOpen = 0
    var hidesTabBar: Bool { readersOpen > 0 }

    /// A list was scrolled down: the tab bar slides away (keeping its space).
    var barsHidden = false
}

/// Follows the hand in use: the side of the screen touched last ([record]'s
/// `touches` in a row on the other side move it). Touches near the middle
/// keep the current side.
@MainActor
@Observable
final class HandTracker {
    static let shared = HandTracker()

    enum Side: String {
        case leading, center, trailing
    }

    private(set) var side: Side
    @ObservationIgnored private var pending: Side?
    @ObservationIgnored private var streak = 0

    private init() {
        side = Side(rawValue: UserDefaults.standard.string(forKey: "handSide") ?? "") ?? .trailing
    }

    /// A touch at [fraction] of the screen width (0 = left edge).
    func record(_ fraction: CGFloat, touches: Int) {
        let next: Side
        if fraction > 0.6 {
            next = .trailing
        } else if fraction < 0.4 {
            next = .leading
        } else {
            return
        }
        guard next != side else {
            pending = nil
            streak = 0
            return
        }
        if pending == next {
            streak += 1
        } else {
            pending = next
            streak = 1
        }
        guard streak >= touches else { return }
        pending = nil
        streak = 0
        side = next
        UserDefaults.standard.set(next.rawValue, forKey: "handSide")
    }
}

/// A touch seen by [TouchObserver].
struct TouchInfo {
    /// In window coordinates.
    let location: CGPoint
    let windowSize: CGSize
    let safeArea: UIEdgeInsets
}

/// Watches touches anywhere in the window without taking part in them.
private final class TouchRecorder: UIGestureRecognizer {
    var onTouch: (@MainActor (TouchInfo) -> Void)?

    override init(target: Any?, action: Selector?) {
        super.init(target: target, action: action)
        cancelsTouchesInView = false
        delaysTouchesBegan = false
        delaysTouchesEnded = false
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        if let touch = touches.first, let view, view.bounds.width > 0 {
            onTouch?(TouchInfo(location: touch.location(in: view), windowSize: view.bounds.size,
                               safeArea: view.safeAreaInsets))
        }
        state = .failed
    }
}

/// Installs a [TouchRecorder] on the window that hosts it, and removes it
/// when the view leaves the window.
struct TouchObserver: UIViewRepresentable {
    let onTouch: @MainActor (TouchInfo) -> Void

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
        var onTouch: (@MainActor (TouchInfo) -> Void)?
        private var recorder: TouchRecorder?

        override func didMoveToWindow() {
            super.didMoveToWindow()
            if let recorder, recorder.view !== window {
                recorder.view?.removeGestureRecognizer(recorder)
                self.recorder = nil
            }
            guard let window, recorder == nil else { return }
            let recorder = TouchRecorder(target: nil, action: nil)
            recorder.onTouch = { [weak self] touch in self?.onTouch?(touch) }
            window.addGestureRecognizer(recorder)
            self.recorder = recorder
        }
    }
}

/// The tabs with a floating glass tab bar at the bottom (on iPad left,
/// center or right, or following the hand in use; centered on iPhone).
/// Search is on the Home page.
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
        .modifier(BottomBar(alignment: alignment, visible: !chrome.hidesTabBar, collapsed: barsHidden) {
            PadTabBar(selection: $selection)
                .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { barFrame = $0 }
                .padding(.horizontal, isPad ? 20 : 16)
                .padding(.bottom, 6)
        })
        .background(TouchObserver { touch in
            guard isPad, settings.followHand, !chrome.hidesTabBar, !chrome.barsHidden,
                  !barFrame.insetBy(dx: -10, dy: -10).contains(touch.location) else { return }
            hand.record(touch.location.x / touch.windowSize.width, touches: settings.followSpeed.touches)
        })
        .onChange(of: selection) { chrome.barsHidden = false }
        .animation(.spring(duration: settings.followSpeed.duration, bounce: 0.15), value: alignment)
        .animation(.smooth(duration: 0.25), value: chrome.hidesTabBar)
    }

    private var barsHidden: Bool { settings.hideBarsOnScroll && chrome.barsHidden }
    private var isPad: Bool { UIDevice.current.userInterfaceIdiom == .pad }

    private var alignment: HorizontalAlignment {
        // iPhone: always centered (the position settings are for iPad).
        guard isPad else { return .center }
        let position: TabBarPosition
        if settings.followHand {
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
        // There is no search tab: Home has the search.
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
/// edges blur under it), or a safe area inset before. [collapsed] slides
/// the bar away but keeps its space, so the lists don't move.
private struct BottomBar<Bar: View>: ViewModifier {
    let alignment: HorizontalAlignment
    let visible: Bool
    let collapsed: Bool
    @ViewBuilder let bar: () -> Bar

    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content.safeAreaBar(edge: .bottom, alignment: alignment, spacing: 0) { placedBar }
        } else {
            content.safeAreaInset(edge: .bottom, alignment: alignment, spacing: 0) { placedBar }
        }
    }

    @ViewBuilder private var placedBar: some View {
        if visible {
            bar()
                .offset(y: collapsed ? 140 : 0)
                .opacity(collapsed ? 0 : 1)
                .allowsHitTesting(!collapsed)
                .accessibilityHidden(collapsed)
                .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }
}

/// Floating tab bar: a glass capsule with the tabs.
struct PadTabBar: View {
    @Binding var selection: AppTab
    @Namespace private var namespace
    /// Narrow screens (iPhone): the tabs share the width instead of a fixed one each.
    @Environment(\.horizontalSizeClass) private var sizeClass

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
            .frame(maxWidth: sizeClass == .compact ? 420 : nil)
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
            .frame(width: sizeClass == .compact ? nil : 84, height: 54)
            .frame(maxWidth: sizeClass == .compact ? .infinity : nil)
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
