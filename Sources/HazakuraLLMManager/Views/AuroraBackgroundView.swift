import SwiftUI

struct AuroraBackgroundView: View {
    var body: some View {
        TimelineView(.animation) { timeline in
            AuroraBackgroundLayer(date: timeline.date)
        }
        .ignoresSafeArea()
    }
}

private struct AuroraBackgroundLayer: View {
    let date: Date

    var body: some View {
        GeometryReader { geometry in
            let time = date.timeIntervalSinceReferenceDate
            let width = geometry.size.width
            let height = geometry.size.height
            let size = min(width, height)

            ZStack {
                Color(nsColor: .windowBackgroundColor)

                Color.clear
                    .background(.background)
                    .opacity(0.65)

                AuroraOrb(
                    color: .cyan,
                    opacity: 0.35,
                    radius: size * 0.4,
                    diameter: size * 0.8,
                    x: width * (0.3 + 0.15 * CGFloat(sin(time * 0.3))),
                    y: height * (0.35 + 0.1 * CGFloat(cos(time * 0.35))),
                    scale: 1.0 + 0.08 * CGFloat(sin(time * 0.18))
                )

                AuroraOrb(
                    color: .purple,
                    opacity: 0.3,
                    radius: size * 0.45,
                    diameter: size * 0.9,
                    x: width * (0.7 + 0.12 * CGFloat(cos(time * 0.22))),
                    y: height * (0.65 + 0.15 * CGFloat(sin(time * 0.26))),
                    scale: 1.0 + 0.1 * CGFloat(cos(time * 0.14))
                )

                AuroraOrb(
                    color: .pink,
                    opacity: 0.22,
                    radius: size * 0.35,
                    diameter: size * 0.7,
                    x: width * (0.5 + 0.2 * CGFloat(sin(time * 0.4))),
                    y: height * (0.2 + 0.08 * CGFloat(cos(time * 0.44))),
                    scale: 1.0 + 0.07 * CGFloat(sin(time * 0.22))
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
