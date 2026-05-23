import SwiftUI

struct GlassGroupBoxStyle: GroupBoxStyle {
    @State private var isHovered = false

    func makeBody(configuration: Configuration) -> some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.lg) {
            configuration.label
                .font(DesignTokens.Font.heading)
                .foregroundStyle(.primary.opacity(DesignTokens.Opacity.textPrimary))
            configuration.content
        }
        .padding(DesignTokens.Spacing.xxxl)
        .background(.thinMaterial)
        .background(Color.clear.background(.background).opacity(DesignTokens.Opacity.fillNoticeable))
        .cornerRadius(DesignTokens.Radius.large)
        .glassBorder(hovered: isHovered)
        .designShadow(isHovered ? DesignTokens.Shadow.elevated : DesignTokens.Shadow.subtle)
        .scaleEffect(isHovered ? DesignTokens.Scale.hoverCard : 1.0)
        .animation(.smooth(duration: DesignTokens.Animation.eased), value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}
