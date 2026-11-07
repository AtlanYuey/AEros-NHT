import SwiftUI
import UIKit

/// Scrolling a list down hides its navigation bar and the tab bar (when
/// Appearance › Hide Bars When Scrolling is on); scrolling up, or reaching
/// the top, shows them again.
///
/// Hiding the navigation bar would shrink the space above the list, and the
/// list would jump by that much. While the bar is hidden an empty strip of
/// the same height keeps the space (a safe area bar, so on iOS 26 the
/// system's soft edge stays over it): the bar goes, the list doesn't move.
struct HidesBarsOnScroll: ViewModifier {
    @Environment(AppSettings.self) private var settings
    @State private var chrome = AppChrome.shared
    /// Scroll bookkeeping. A reference, not state: it changes on every
    /// frame and must not redraw anything.
    @State private var tracker = Tracker()
    /// Height of the strip that stands in for the hidden navigation bar.
    @State private var reserved: CGFloat = 0

    private var hiding: Bool { settings.hideBarsOnScroll && chrome.barsHidden }

    func body(content: Content) -> some View {
        content
            .onScrollGeometryChange(for: ScrollSample.self) { geometry in
                ScrollSample(
                    offset: geometry.contentOffset.y,
                    topInset: geometry.contentInsets.top,
                    maxOffset: geometry.contentSize.height + geometry.contentInsets.bottom - geometry.containerSize.height
                )
            } action: { old, new in
                update(old: old, new: new)
            }
            .modifier(ReservedTop(height: hiding ? reserved : 0))
            .toolbarVisibility(hiding ? .hidden : .automatic, for: .navigationBar)
            .toolbarVisibility(hiding ? .hidden : .automatic, for: .tabBar)
            .onChange(of: settings.hideBarsOnScroll) { _, on in
                if !on { setHidden(false) }
            }
            .onDisappear { setHidden(false) }
    }

    private func update(old: ScrollSample, new: ScrollSample) {
        guard settings.hideBarsOnScroll else { return }
        // The strip should give the list the same top inset as the bar did.
        // If the first guess was off, correct it (and remember the result).
        if hiding, reserved > 0, !tracker.corrected, abs(new.topInset - tracker.visibleTopInset) > 0.5 {
            tracker.corrected = true
            let base = new.topInset - reserved
            chrome.hiddenTopBase = base
            reserved = max(0, tracker.visibleTopInset - base)
        }
        // Changes of the top inset are not the user scrolling; reacting to
        // them made the bars flip back and forth.
        if new.topInset != old.topInset || Date.now < tracker.settleUntil {
            tracker.travel = 0
            return
        }
        if !chrome.barsHidden { tracker.visibleTopInset = new.topInset }
        // Distance from the top as if the bars were showing, so it doesn't
        // change when they hide.
        let fromTop = new.offset + tracker.visibleTopInset
        if fromTop < 60 {
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
        // Hide only well below the top, so the inset change can't bring the
        // list back near it.
        if tracker.travel > 24, fromTop > 160 {
            setHidden(true)
        } else if tracker.travel < -24 {
            setHidden(false)
        }
    }

    private func setHidden(_ hidden: Bool) {
        guard chrome.barsHidden != hidden else { return }
        tracker.travel = 0
        tracker.settleUntil = .now.addingTimeInterval(0.45)
        if hidden {
            // The space the bar takes: the list's top inset with the bar,
            // less what is left without it (the status bar).
            let base = chrome.hiddenTopBase ?? Self.windowTopInset
            reserved = max(0, tracker.visibleTopInset - base)
            tracker.corrected = false
        }
        withAnimation(.smooth(duration: 0.28)) { chrome.barsHidden = hidden }
    }

    /// The window's top safe area (the status bar), what a list keeps above
    /// it without a navigation bar.
    private static var windowTopInset: CGFloat {
        let window = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first { $0.isKeyWindow }
        return window?.safeAreaInsets.top ?? 0
    }

    private final class Tracker {
        /// Distance scrolled in the current direction.
        var travel: CGFloat = 0
        /// The top inset while the bars show.
        var visibleTopInset: CGFloat = 0
        /// Geometry changes until then come from the bars moving.
        var settleUntil = Date.distantPast
        /// The reserved strip was checked against the inset since the bars hid.
        var corrected = false
    }
}

/// An empty strip at the top that takes the hidden navigation bar's place.
private struct ReservedTop: ViewModifier {
    let height: CGFloat

    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content.safeAreaBar(edge: .top, spacing: 0) {
                if height > 0 { Color.clear.frame(height: height) }
            }
        } else {
            content.safeAreaInset(edge: .top, spacing: 0) {
                if height > 0 { Color.clear.frame(height: height) }
            }
        }
    }
}

private struct ScrollSample: Equatable {
    let offset: CGFloat
    let topInset: CGFloat
    let maxOffset: CGFloat
}

extension View {
    func hidesBarsOnScroll() -> some View {
        modifier(HidesBarsOnScroll())
    }
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
