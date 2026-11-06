import SwiftUI

/// Scrolling a list down hides its navigation bar and the tab bar (when
/// Appearance › Hide Bars When Scrolling is on); scrolling up, or reaching
/// the top, shows them again. While they are hidden, a short blur stays
/// behind the status bar and at the bottom edge.
struct HidesBarsOnScroll: ViewModifier {
    @Environment(AppSettings.self) private var settings
    @State private var chrome = AppChrome.shared
    /// Distance scrolled in the current direction.
    @State private var travel: CGFloat = 0

    private var hiding: Bool { settings.hideBarsOnScroll && chrome.barsHidden }

    func body(content: Content) -> some View {
        content
            .onScrollGeometryChange(for: ScrollSample.self) { geometry in
                ScrollSample(
                    offset: geometry.contentOffset.y + geometry.contentInsets.top,
                    maxOffset: geometry.contentSize.height + geometry.contentInsets.top
                        + geometry.contentInsets.bottom - geometry.containerSize.height
                )
            } action: { old, new in
                update(old: old, new: new)
            }
            .toolbarVisibility(hiding ? .hidden : .automatic, for: .navigationBar)
            .toolbarVisibility(hiding ? .hidden : .automatic, for: .tabBar)
            .overlay(alignment: .top) {
                if hiding { EdgeBlur(edge: .top, extra: 6) }
            }
            .overlay(alignment: .bottom) {
                if hiding { EdgeBlur(edge: .bottom, extra: 30) }
            }
            .onChange(of: settings.hideBarsOnScroll) { _, on in
                if !on { setHidden(false) }
            }
            .onDisappear { setHidden(false) }
    }

    private func update(old: ScrollSample, new: ScrollSample) {
        guard settings.hideBarsOnScroll else { return }
        // Near the top (and pulling to refresh) the bars always show.
        if new.offset < 60 {
            travel = 0
            setHidden(false)
            return
        }
        // The bounce at the end of the list is not a scroll up.
        guard new.offset <= new.maxOffset, old.offset <= old.maxOffset else { return }
        let delta = new.offset - old.offset
        guard delta != 0 else { return }
        if (delta > 0) != (travel > 0) { travel = 0 }
        travel += delta
        if travel > 24 {
            setHidden(true)
        } else if travel < -24 {
            setHidden(false)
        }
    }

    private func setHidden(_ hidden: Bool) {
        guard chrome.barsHidden != hidden else { return }
        withAnimation(.smooth(duration: 0.28)) { chrome.barsHidden = hidden }
    }
}

private struct ScrollSample: Equatable {
    let offset: CGFloat
    let maxOffset: CGFloat
}

extension View {
    func hidesBarsOnScroll() -> some View {
        modifier(HidesBarsOnScroll())
    }
}

/// A short progressive blur at the top or bottom edge, over the safe area
/// and [extra] points more (instead of the taller blur under the bars).
struct EdgeBlur: View {
    let edge: VerticalEdge
    var extra: CGFloat = 0

    var body: some View {
        GeometryReader { geometry in
            let inset = edge == .top ? geometry.safeAreaInsets.top : geometry.safeAreaInsets.bottom
            VStack(spacing: 0) {
                if edge == .bottom { Spacer(minLength: 0) }
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .mask {
                        LinearGradient(
                            stops: [
                                .init(color: .black, location: 0),
                                .init(color: .black, location: 0.45),
                                .init(color: .clear, location: 1),
                            ],
                            startPoint: edge == .top ? .top : .bottom,
                            endPoint: edge == .top ? .bottom : .top
                        )
                    }
                    .frame(height: inset + extra)
                if edge == .top { Spacer(minLength: 0) }
            }
            .ignoresSafeArea()
        }
        .allowsHitTesting(false)
        .transition(.opacity)
    }
}

/// The round glass search button that stays while the bars are hidden
/// (when Hide Search Too is off).
struct FloatingSearchButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 21, weight: .medium))
                .foregroundStyle(.primary)
                .frame(width: 62, height: 62)
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text("Search"))
        .modifier(FloatingGlass())
        .transition(.scale(scale: 0.6).combined(with: .opacity))
    }
}

private struct FloatingGlass: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content.glassEffect(.regular.interactive(), in: Circle())
        } else {
            content
                .background(.regularMaterial, in: Circle())
                .shadow(color: .black.opacity(0.15), radius: 12, y: 4)
        }
    }
}
