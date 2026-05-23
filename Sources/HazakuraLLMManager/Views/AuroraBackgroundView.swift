import SwiftUI
import HazakuraLLMManagerCore

struct AuroraBackgroundView: View {
    let status: ServerStatus
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        if reduceMotion {
            AuroraBackgroundStaticLayer(status: status)
                .ignoresSafeArea()
        } else {
            TimelineView(.animation(paused: !status.animatesAuroraBackground)) { timeline in
                AuroraBackgroundLayer(date: timeline.date, status: status)
            }
            .ignoresSafeArea()
        }
    }
}

private struct AuroraBackgroundLayer: View {
    let date: Date
    let status: ServerStatus

    var body: some View {
        GeometryReader { geometry in
            let time = date.timeIntervalSinceReferenceDate
            let width = geometry.size.width
            let height = geometry.size.height
            let size = min(width, height)

            let colors = DesignTokens.Aurora.palette(for: status)

            ZStack {
                Color(nsColor: .windowBackgroundColor)

                Color.clear
                    .background(.background)
                    .opacity(0.65)

                AuroraOrb(
                    color: colors.orb1,
                    opacity: 0.35,
                    radius: size * 0.4,
                    diameter: size * 0.8,
                    x: width * (0.3 + 0.15 * CGFloat(sin(time * 0.3))),
                    y: height * (0.35 + 0.1 * CGFloat(cos(time * 0.35))),
                    scale: 1.0 + 0.08 * CGFloat(sin(time * 0.18))
                )

                AuroraOrb(
                    color: colors.orb2,
                    opacity: 0.3,
                    radius: size * 0.45,
                    diameter: size * 0.9,
                    x: width * (0.7 + 0.12 * CGFloat(cos(time * 0.22))),
                    y: height * (0.65 + 0.15 * CGFloat(sin(time * 0.26))),
                    scale: 1.0 + 0.1 * CGFloat(cos(time * 0.14))
                )

                AuroraOrb(
                    color: colors.orb3,
                    opacity: 0.22,
                    radius: size * 0.35,
                    diameter: size * 0.7,
                    x: width * (0.5 + 0.2 * CGFloat(sin(time * 0.4))),
                    y: height * (0.2 + 0.08 * CGFloat(cos(time * 0.44))),
                    scale: 1.0 + 0.07 * CGFloat(sin(time * 0.22))
                )
            }
            .blur(radius: size * 0.12 + 45)
            .animation(.easeInOut(duration: 1.5), value: status)
            .drawingGroup()
        }
    }
}

private struct AuroraBackgroundStaticLayer: View {
    let status: ServerStatus

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            let size = min(width, height)

            let colors = DesignTokens.Aurora.palette(for: status)

            ZStack {
                Color(nsColor: .windowBackgroundColor)

                Color.clear
                    .background(.background)
                    .opacity(0.65)

                AuroraOrb(
                    color: colors.orb1,
                    opacity: 0.35,
                    radius: size * 0.4,
                    diameter: size * 0.8,
                    x: width * 0.45,
                    y: height * 0.45,
                    scale: 1.0
                )

                AuroraOrb(
                    color: colors.orb2,
                    opacity: 0.3,
                    radius: size * 0.45,
                    diameter: size * 0.9,
                    x: width * 0.55,
                    y: height * 0.55,
                    scale: 1.0
                )

                AuroraOrb(
                    color: colors.orb3,
                    opacity: 0.22,
                    radius: size * 0.35,
                    diameter: size * 0.7,
                    x: width * 0.5,
                    y: height * 0.5,
                    scale: 1.0
                )
            }
            .blur(radius: size * 0.12 + 45)
            .drawingGroup()
        }
    }
}

private struct AuroraOrb: View {
    let color: Color
    let opacity: Double
    let radius: CGFloat
    let diameter: CGFloat
    let x: CGFloat
    let y: CGFloat
    let scale: CGFloat

    var body: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [color.opacity(opacity), Color.clear],
                    center: .center,
                    startRadius: 0,
                    endRadius: radius
                )
            )
            .frame(width: diameter)
            .position(x: x, y: y)
            .scaleEffect(scale)
    }
}

private extension ServerStatus {
    var animatesAuroraBackground: Bool {
        switch self {
        case .stopped:
            false
        case .starting, .loading, .running, .stopping, .restarting, .error:
            true
        }
    }
}
