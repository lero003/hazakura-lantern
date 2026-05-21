import SwiftUI

// MARK: - Primary Button Style
struct PrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    @State private var isHovered = false

    func makeBody(configuration: Configuration) -> some View {
        let isInteractive = isEnabled
        let isActiveHover = isInteractive && isHovered
        let gradientColors = isInteractive ? [
            Color.orange.opacity(isActiveHover ? 0.95 : 0.85),
            Color(red: 0.95, green: 0.65, blue: 0.15).opacity(isActiveHover ? 0.9 : 0.8),
            Color.yellow.opacity(isActiveHover ? 0.85 : 0.75)
        ] : [
            Color.white.opacity(0.12),
            Color.white.opacity(0.08)
        ]

        configuration.label
            .font(.callout.weight(.semibold))
            .foregroundStyle(isInteractive ? .white : .white.opacity(0.62))
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                LinearGradient(
                    colors: gradientColors,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.white.opacity(isInteractive ? 0.08 : 0.18), lineWidth: 1)
            )
            .cornerRadius(8)
            .shadow(
                color: Color.orange.opacity(isActiveHover ? 0.25 : (isInteractive ? 0.15 : 0)),
                radius: isActiveHover ? 8 : 4,
                x: 0,
                y: isActiveHover ? 4 : 2
            )
            .scaleEffect(
                isInteractive
                    ? (configuration.isPressed ? 0.96 : (isActiveHover ? 1.02 : 1.0))
                    : 1.0
            )
            .saturation(isInteractive ? 1.0 : 0.45)
            .animation(.smooth(duration: 0.2), value: isHovered)
            .animation(.smooth(duration: 0.1), value: configuration.isPressed)
            .onHover { hovering in
                isHovered = isInteractive && hovering
            }
    }
}

// MARK: - Secondary Button Style
struct SecondaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    @State private var isHovered = false

    func makeBody(configuration: Configuration) -> some View {
        let isInteractive = isEnabled
        let isActiveHover = isInteractive && isHovered

        configuration.label
            .font(.callout.weight(.medium))
            .foregroundStyle(.primary.opacity(isInteractive ? 0.85 : 0.52))
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(.white.opacity(isActiveHover ? 0.08 : (isInteractive ? 0.04 : 0.025)))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(
                        Color.white.opacity(isActiveHover ? 0.2 : (isInteractive ? 0.08 : 0.16)),
                        lineWidth: 1
                    )
            )
            .scaleEffect(isInteractive && configuration.isPressed ? 0.97 : 1.0)
            .animation(.smooth(duration: 0.18), value: isHovered)
            .animation(.smooth(duration: 0.1), value: configuration.isPressed)
            .onHover { hovering in
                isHovered = isInteractive && hovering
            }
    }
}

// MARK: - Glass TextField Modifier
struct GlassTextFieldModifier: ViewModifier {
    @FocusState private var isFocused: Bool

    func body(content: Content) -> some View {
        content
            .focused($isFocused)
            .font(.system(.body, design: .monospaced))
            .foregroundStyle(.primary)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(.black.opacity(0.2))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(
                        LinearGradient(
                            colors: isFocused ? [Color.orange, Color(red: 0.95, green: 0.65, blue: 0.15)] : [Color.white.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: isFocused ? 1.5 : 1.0
                    )
            )
            .shadow(
                color: isFocused ? Color.orange.opacity(0.15) : Color.clear,
                radius: 4,
                x: 0,
                y: 2
            )
            .textFieldStyle(.plain) // デフォルトの枠線スタイルを消去
            .animation(.smooth(duration: 0.22), value: isFocused)
    }
}

extension View {
    func glassTextFieldStyle() -> some View {
        self.modifier(GlassTextFieldModifier())
    }
}
