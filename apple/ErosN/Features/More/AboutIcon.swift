import SwiftUI

/// The app icon on the About page, with a small easter egg: long press it
/// and it spins, hearts and sparkles burst out of it and it pulls a face.
/// Every fifth time it turns rainbow.
struct AboutIcon: View {
    @State private var spin: Double = 0
    @State private var pressing = false
    @State private var hue: Double = 0
    @State private var bursts: [Burst] = []
    @State private var bubble: Bubble?
    @State private var count = 0

    private static let faces = [
        "(≧▽≦)", "(｡•̀ᴗ-)✧", "ヾ(＾∇＾)", "(〃▽〃)", "ฅ^•ﻌ•^ฅ",
        "(*/ω＼*)", "( ˘ ³˘)♥", "(ノ´ヮ`)ノ*: ･ﾟ", "(=^･ω･^=)", "(*≧ω≦)",
    ]

    var body: some View {
        Image("AboutIcon")
            .resizable()
            .frame(width: 88, height: 88)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .hueRotation(.degrees(hue))
            .rotation3DEffect(.degrees(spin), axis: (x: 0, y: 1, z: 0), perspective: 0.5)
            .scaleEffect(pressing ? 0.88 : 1)
            .overlay {
                ForEach(bursts) { BurstView(burst: $0) }
            }
            .overlay(alignment: .top) {
                if let bubble {
                    Text(verbatim: bubble.text)
                        .font(.subheadline.weight(.semibold))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(.regularMaterial, in: Capsule())
                        .fixedSize()
                        .offset(y: -42)
                        .id(bubble.id)
                        .transition(.scale(scale: 0.3, anchor: .bottom).combined(with: .opacity))
                }
            }
            .onLongPressGesture(minimumDuration: 0.45) {
                celebrate()
            } onPressingChanged: { isPressing in
                withAnimation(.spring(duration: 0.3, bounce: 0.4)) { pressing = isPressing }
            }
            .sensoryFeedback(.success, trigger: count)
    }

    private func celebrate() {
        count += 1
        let rainbow = count % 5 == 0
        withAnimation(.spring(duration: 0.9, bounce: 0.35)) { spin += 360 }
        if rainbow {
            withAnimation(.linear(duration: 2.4)) { hue += 720 }
        }
        let burst = Burst(rainbow: rainbow)
        bursts.append(burst)
        let shown = Bubble(text: rainbow ? "🌈 (ﾉ◕ヮ◕)ﾉ*:･ﾟ✧" : Self.faces.randomElement() ?? "(≧▽≦)")
        withAnimation(.spring(duration: 0.35, bounce: 0.45)) { bubble = shown }
        Task {
            try? await Task.sleep(for: .seconds(rainbow ? 2.4 : 1.6))
            withAnimation(.easeOut(duration: 0.25)) {
                if bubble?.id == shown.id { bubble = nil }
            }
            bursts.removeAll { $0.id == burst.id }
        }
    }
}

private struct Bubble: Identifiable {
    let id = UUID()
    let text: String
}

private struct Burst: Identifiable {
    struct Particle: Identifiable {
        let id: Int
        let emoji: String
        let angle: Double
        let distance: CGFloat
        let size: CGFloat
        let spin: Double
    }

    let id = UUID()
    let particles: [Particle]

    init(rainbow: Bool) {
        let emoji = rainbow
            ? ["🌈", "🦄", "💜", "💙", "💚", "💛", "🧡", "❤️"]
            : ["💗", "✨", "🌸", "💫", "⭐️", "💖"]
        let count = rainbow ? 22 : 16
        particles = (0..<count).map { index in
            Particle(
                id: index,
                emoji: emoji.randomElement() ?? "✨",
                angle: Double(index) / Double(count) * 2 * .pi + .random(in: -0.25...0.25),
                distance: .random(in: 70...150),
                size: .random(in: 14...24),
                spin: .random(in: -200...200)
            )
        }
    }
}

private struct BurstView: View {
    let burst: Burst
    @State private var flown = false
    @State private var faded = false

    var body: some View {
        ZStack {
            ForEach(burst.particles) { particle in
                Text(verbatim: particle.emoji)
                    .font(.system(size: particle.size))
                    .rotationEffect(.degrees(flown ? particle.spin : 0))
                    .scaleEffect(flown ? 1 : 0.2)
                    .offset(
                        x: flown ? cos(particle.angle) * particle.distance : 0,
                        y: flown ? sin(particle.angle) * particle.distance : 0
                    )
                    .opacity(faded ? 0 : 1)
            }
        }
        .allowsHitTesting(false)
        .onAppear {
            withAnimation(.easeOut(duration: 1.0)) { flown = true }
            withAnimation(.easeIn(duration: 0.45).delay(0.6)) { faded = true }
        }
    }
}
