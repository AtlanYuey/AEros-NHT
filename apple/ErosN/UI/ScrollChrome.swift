import SwiftUI

/// Scrolling a list down hides the tab bar (when Appearance › Hide Tab Bar
/// When Scrolling is on); scrolling up, or reaching the top, shows it
/// again. The tab bar only slides away: the space it takes stays, and the
/// navigation bar is never touched, so the list never moves.
struct HidesBarsOnScroll: ViewModifier {
    @Environment(AppSettings.self) private var settings
    @State private var chrome = AppChrome.shared
    /// Scroll bookkeeping. A reference, not state: it changes on every
    /// frame and must not redraw anything.
    @State private var tracker = Tracker()

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
            .onChange(of: settings.hideBarsOnScroll) { _, on in
                if !on { setHidden(false) }
            }
            .onDisappear { setHidden(false) }
    }

    private func update(old: ScrollSample, new: ScrollSample) {
        guard settings.hideBarsOnScroll else { return }
        // Inset changes (the large title collapsing) are not the user scrolling.
        if new.topInset != old.topInset {
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
        if tracker.travel > 24 {
            setHidden(true)
        } else if tracker.travel < -24 {
            setHidden(false)
        }
    }

    private func setHidden(_ hidden: Bool) {
        guard chrome.barsHidden != hidden else { return }
        tracker.travel = 0
        withAnimation(.smooth(duration: 0.28)) { chrome.barsHidden = hidden }
    }

    private final class Tracker {
        /// Distance scrolled in the current direction.
        var travel: CGFloat = 0
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
