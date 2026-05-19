import SwiftUI

struct GlassGroupBoxStyle: GroupBoxStyle {
    @State private var isHovered = false

    func makeBody(configuration: Configuration) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            configuration.label
                .font(.headline.weight(.semibold))
                .foregroundStyle(.primary.opacity(0.92))
            configuration.content
        }
        .padding(16)
        .background(.thinMaterial) // すりガラスを少し厚めに
        .background(Color.clear.background(.background).opacity(0.12)) // 不透明背景を重ねてコントラスト比を担保
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    LinearGradient(
                        colors: [
                            .white.opacity(isHovered ? 0.24 : 0.14),
                            .white.opacity(isHovered ? 0.08 : 0.04)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(
            color: Color.black.opacity(isHovered ? 0.12 : 0.06),
            radius: isHovered ? 12 : 6,
            x: 0,
            y: isHovered ? 6 : 3
        )
        .scaleEffect(isHovered ? 1.006 : 1.0)
        .animation(.smooth(duration: 0.22), value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}
