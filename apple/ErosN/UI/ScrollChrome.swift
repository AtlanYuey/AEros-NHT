import SwiftUI

/// Scrolling a list down hides the bars (when Appearance › Hide Bars When
/// Scrolling is on); scrolling up, or reaching the top, shows them again.
///
/// The navigation bar itself stays: only its title and buttons fade out
/// ([ScrollHidingTitle], `AppChrome.barsHidden` in the toolbars), so the
/// space above the list never changes. Changing it (hiding the bar) made
/// the list jump, and the lazily laid out columns lose their place.
struct HidesBarsOnScroll: ViewModifier {
    @Environment(AppSettings.self) private var settings
    @State private var chrome = AppChrome.shared
    /// Scroll bookkeeping. A reference, not state: it changes on every
    /// frame and must not redraw anything.
    @State private var tracker = Tracker()

    private var hiding: Bool { settings.hideBarsOnScroll && chrome.barsHidden }

    func body(content: Content) -> some View {
        content
            .onScrollGeometryChange(for: ScrollSample.self) { geometry in
                ScrollSample(
                    offset: geometry.contentOffset.y + geometry.contentInsets.top,
                    topInset: geometry.contentInsets.top,
                    maxOffset: geometry.contentSize.height + geometry.contentInsets.top
                        + geometry.contentInsets.bottom - geometry.containerSize.height
                )
            } action: { old, new in
                update(old: old, new: new)
            }
            .toolbarVisibility(hiding ? .hidden : .automatic, for: .tabBar)
            .onChange(of: settings.hideBarsOnScroll) { _, on in
                if !on { setHidden(false) }
            }
            .onDisappear { setHidden(false) }
    }

    private func update(old: ScrollSample, new: ScrollSample) {
        guard settings.hideBarsOnScroll else { return }
        // Inset changes (the large title collapsing, the tab bar) are not the
        // user scrolling.
        if new.topInset != old.topInset || Date.now < tracker.settleUntil {
            tracker.travel = 0
            return
        }
        if new.offset < 60 {
            tracker.travel = 0
            setHidden(false)
            return
        }
        // The bounce at the end of the list is not a scroll up.
        guard new.offset <= new.maxOffset, old.offset <= old.maxOffset else { return }
        let delta = new.offset - old.offset
        guard delta != 0 else { return }
        if (delta > 0) != (tracker.travel > 0) { tracker.travel = 0 }
        tracker.travel += delta
        if tracker.travel > 24, new.offset > 160 {
            setHidden(true)
        } else if tracker.travel < -24 {
            setHidden(false)
        }
    }

    private func setHidden(_ hidden: Bool) {
        guard chrome.barsHidden != hidden else { return }
        tracker.travel = 0
        tracker.settleUntil = .now.addingTimeInterval(0.35)
        withAnimation(.smooth(duration: 0.25)) { chrome.barsHidden = hidden }
    }

    private final class Tracker {
        /// Distance scrolled in the current direction.
        var travel: CGFloat = 0
        /// Geometry changes until then come from the bars moving.
        var settleUntil = Date.distantPast
    }
}

private struct ScrollSample: Equatable {
    let offset: CGFloat
    let topInset: CGFloat
    let maxOffset: CGFloat
}

/// A list's navigation title, emptied while its bars are hidden (the bar
/// stays, so nothing moves).
struct ScrollHidingTitle: ViewModifier {
    let title: Text

    @Environment(AppSettings.self) private var settings
    @State private var chrome = AppChrome.shared

    func body(content: Content) -> some View {
        content.navigationTitle(settings.hideBarsOnScroll && chrome.barsHidden ? Text(verbatim: "") : title)
    }
}

extension View {
    func hidesBarsOnScroll() -> some View {
        modifier(HidesBarsOnScroll())
    }

    /// The navigation title of a list whose bars hide on scroll.
    func scrollHidingTitle(_ title: LocalizedStringKey) -> some View {
        modifier(ScrollHidingTitle(title: Text(title)))
    }

    func scrollHidingTitle(verbatim title: String) -> some View {
        modifier(ScrollHidingTitle(title: Text(verbatim: title)))
    }
}

extension AppChrome {
    /// Whether list bars are hidden right now (their buttons are left out).
    var listBarsHidden: Bool { AppSettings.shared.hideBarsOnScroll && barsHidden }
}

/// The round glass search button that stays while the bars are hidden
/// (when Hide Search Too is off).
struct FloatingSearchButton: View {
    var size: CGFloat = 62
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: size * 0.34, weight: .medium))
                .foregroundStyle(.primary)
                .frame(width: size, height: size)
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
