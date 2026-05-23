import SwiftUI
import HazakuraLLMManagerCore

// MARK: - Design Token System
// Centralized design tokens for consistent UI across the app.

enum DesignTokens {
    // MARK: - Corner Radii

    enum Radius {
        static let small: CGFloat = 6
        static let medium: CGFloat = 8
        static let large: CGFloat = 12
        static let xlarge: CGFloat = 16
        static let pill: CGFloat = 9999
    }

    // MARK: - Spacing

    enum Spacing {
        static let xxs: CGFloat = 2
        static let xs: CGFloat = 4
        static let sm: CGFloat = 6
        static let md: CGFloat = 8
        static let lg: CGFloat = 10
        static let xl: CGFloat = 12
        static let xxl: CGFloat = 14
        static let xxxl: CGFloat = 16
        static let huge: CGFloat = 20
        static let massive: CGFloat = 24
    }

    // MARK: - Shadows

    enum Shadow {
        struct ShadowConfig {
            let color: Color
            let radius: CGFloat
            let x: CGFloat
            let y: CGFloat
        }

        static let accentGlow: Color = .orange.opacity(0.18)

        static let subtle = ShadowConfig(
            color: .black.opacity(0.06),
            radius: 6, x: 0, y: 3
        )

        static let elevated = ShadowConfig(
            color: .black.opacity(0.12),
            radius: 12, x: 0, y: 6
        )

        static let focusGlow = ShadowConfig(
            color: accentGlow,
            radius: 4, x: 0, y: 2
        )

        static let buttonRest = ShadowConfig(
            color: accentGlow,
            radius: 3, x: 0, y: 1
        )

        static let buttonHover = ShadowConfig(
            color: accentGlow.opacity(0.25),
            radius: 6, x: 0, y: 3
        )

        static let statusDot = ShadowConfig(
            color: .clear,
            radius: 3, x: 0, y: 0
        )
    }

    // MARK: - Opacity Levels

    enum Opacity {
        // Glass and border
        static let borderLow: Double = 0.04
        static let borderNormal: Double = 0.08
        static let borderMedium: Double = 0.1
        static let borderHigh: Double = 0.14
        static let borderHover: Double = 0.2
        static let borderHoverHigh: Double = 0.24

        // Background fills
        static let fillAlmostInvisible: Double = 0.025
        static let fillSubtle: Double = 0.04
        static let fillLight: Double = 0.06
        static let fillMedium: Double = 0.08
        static let fillNoticeable: Double = 0.12
        static let fillCodeBlock: Double = 0.2

        // Text
        static let textPrimary: Double = 0.92
        static let textBody: Double = 0.85
        static let textSecondary: Double = 0.62
        static let textDisabled: Double = 0.52

        // Status badge background
        static let statusBadgeBg: Double = 0.12
    }

    // MARK: - Animation Durations

    enum Animation {
        static let instant: Double = 0.1
        static let snappy: Double = 0.15
        static let smooth: Double = 0.18
        static let defaultDur: Double = 0.2
        static let eased: Double = 0.22
        static let deliberate: Double = 0.3

        static let copyFeedback: Double = 1.6

        static let pulseSlow: Double = 1.0
        static let pulseMedium: Double = 1.2

        static let snapSpring: SwiftUI.Animation = .snappy(duration: 0.3)
        static let smoothSpring: SwiftUI.Animation = .spring(response: 0.3, dampingFraction: 0.85, blendDuration: 0.2)
    }

    // MARK: - Scale Effects

    enum Scale {
        static let pressPrimary: CGFloat = 0.96
        static let pressSecondary: CGFloat = 0.97
        static let hoverPrimary: CGFloat = 1.02
        static let hoverCard: CGFloat = 1.006
        static let pulseLanternMin: CGFloat = 1.0
        static let pulseLanternMax: CGFloat = 1.15
        static let pulseDotMin: CGFloat = 1.0
        static let pulseDotMax: CGFloat = 1.4
    }

    // MARK: - Status Colors

    enum StatusColor {
        static let running: Color = .green
        static let transitional: Color = .orange
        static let error: Color = .red
        static let stopped: Color = .secondary

        static func forStatus(_ status: ServerStatus) -> Color {
            switch status {
            case .running: return running
            case .starting, .loading, .stopping, .restarting: return transitional
            case .error: return error
            case .stopped: return stopped
            }
        }

        static func lanternColor(for status: ServerStatus) -> Color {
            switch status {
            case .running: return .orange
            case .starting, .loading, .stopping, .restarting: return .yellow
            case .error: return .red
            case .stopped: return .secondary
            }
        }
    }

    // MARK: - Aurora Colors

    enum Aurora {
        struct Palette {
            let orb1: Color
            let orb2: Color
            let orb3: Color
        }

        static let running = Palette(
            orb1: .yellow,
            orb2: .orange,
            orb3: Color(red: 0.95, green: 0.75, blue: 0.2)
        )

        static let transitional = Palette(
            orb1: .orange,
            orb2: .yellow,
            orb3: Color(red: 0.9, green: 0.4, blue: 0.1)
        )

        static let error = Palette(
            orb1: .red,
            orb2: Color(red: 0.7, green: 0.1, blue: 0.1),
            orb3: .orange
        )

        static let stopped = Palette(
            orb1: Color(red: 0.85, green: 0.5, blue: 0.15),
            orb2: Color(red: 0.5, green: 0.25, blue: 0.05),
            orb3: Color(red: 0.3, green: 0.15, blue: 0.0)
        )

        static func palette(for status: ServerStatus) -> Palette {
            switch status {
            case .running: return running
            case .starting, .loading, .restarting, .stopping: return transitional
            case .error: return error
            case .stopped: return stopped
            }
        }
    }

    // MARK: - Bento Card

    enum Bento {
        static let cornerRadius: CGFloat = Radius.xlarge
        static let padding: CGFloat = Spacing.xxxl
        static let spacing: CGFloat = Spacing.huge
        static let minCardHeight: CGFloat = 100

        static let gridSpacing: CGFloat = Spacing.xxl
    }

    // MARK: - Font Tokens

    enum Font {
        static let display: SwiftUI.Font = .title2.weight(.semibold)
        static let heading: SwiftUI.Font = .headline.weight(.semibold)
        static let subheading: SwiftUI.Font = .callout.weight(.semibold)
        static let body: SwiftUI.Font = .body
        static let caption: SwiftUI.Font = .caption
        static let captionSmall: SwiftUI.Font = .caption2
        static let codeBody: SwiftUI.Font = .system(.body, design: .monospaced)
        static let codeCaption: SwiftUI.Font = .system(.caption, design: .monospaced)
        static let codeDigit: SwiftUI.Font = .caption.monospacedDigit()
    }
}

// MARK: - Convenience Extensions

extension View {
    /// Apply a design-token shadow.
    func designShadow(_ config: DesignTokens.Shadow.ShadowConfig) -> some View {
        self.shadow(color: config.color, radius: config.radius, x: config.x, y: config.y)
    }

    /// Apply the standard glass border gradient overlay.
    func glassBorder(hovered: Bool = false) -> some View {
        self.overlay(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.large)
                .stroke(
                    LinearGradient(
                        colors: [
                            .white.opacity(hovered ? DesignTokens.Opacity.borderHoverHigh : DesignTokens.Opacity.borderHigh),
                            .white.opacity(hovered ? DesignTokens.Opacity.borderHover : DesignTokens.Opacity.borderLow)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
    }

    /// Apply the standard code block styling.
    func codeBlockStyle() -> some View {
        self
            .font(DesignTokens.Font.codeCaption)
            .textSelection(.enabled)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(.black.opacity(DesignTokens.Opacity.fillCodeBlock), in: RoundedRectangle(cornerRadius: DesignTokens.Radius.small))
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.small)
                    .stroke(Color.white.opacity(DesignTokens.Opacity.borderNormal), lineWidth: 1)
            )
    }
}
