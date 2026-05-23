import SwiftUI
import HazakuraLLMManagerCore

struct StatusHeaderView: View {
    @ObservedObject var controller: ServerController
    @Environment(\.locale) private var locale
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var lanternPulse: CGFloat = DesignTokens.Scale.pulseLanternMin

    var body: some View {
        HStack(spacing: DesignTokens.Spacing.xl) {
            Image(systemName: "lightbulb.fill")
                .font(.title2)
                .foregroundStyle(lanternColor)
                .scaleEffect(controller.status == .running ? lanternPulse : 1.0)
                .shadow(color: lanternColor.opacity(controller.status == .running ? 0.8 : 0.0), radius: 6)
                .accessibilityHidden(true)
                .onAppear { startLanternPulse() }
                .onChange(of: controller.status) { _, _ in startLanternPulse() }
                .onChange(of: reduceMotion) { _, _ in startLanternPulse() }

            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                Text("Hazakura Lantern")
                    .font(DesignTokens.Font.display)

                Text("Local light for llama-server")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if let pid = controller.processIdentifier {
                Text("pid \(pid)")
                    .font(DesignTokens.Font.codeDigit)
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .trailing, spacing: DesignTokens.Spacing.xs) {
                StatusBadge(status: controller.status)

                if controller.status == .loading,
                   let elapsed = controller.loadingElapsedSeconds {
                    Text(localized("loading_elapsed.seconds", elapsed))
                        .font(DesignTokens.Font.codeDigit)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private func startLanternPulse() {
        if controller.status == .running {
            lanternPulse = DesignTokens.Scale.pulseLanternMin
            if !reduceMotion {
                withAnimation(
                    .easeInOut(duration: DesignTokens.Animation.pulseMedium)
                    .repeatForever(autoreverses: true)
                ) {
                    lanternPulse = DesignTokens.Scale.pulseLanternMax
                }
            }
        } else {
            lanternPulse = DesignTokens.Scale.pulseLanternMin
        }
    }

    private var lanternColor: Color {
        DesignTokens.StatusColor.lanternColor(for: controller.status)
    }

    private func localized(_ key: String, _ arguments: CVarArg...) -> String {
        let format = String(
            localized: String.LocalizationValue(key),
            bundle: .module,
            locale: locale
        )

        guard !arguments.isEmpty else { return format }
        return String(format: format, locale: locale, arguments: arguments)
    }
}

private struct StatusBadge: View {
    var status: ServerStatus
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var pulseScale: CGFloat = DesignTokens.Scale.pulseDotMin

    var body: some View {
        HStack(spacing: DesignTokens.Spacing.sm) {
            Circle()
                .fill(foregroundStyle)
                .frame(width: 7, height: 7)
                .scaleEffect(status == .running ? pulseScale : 1.0)
                .opacity(status == .running ? (pulseScale == DesignTokens.Scale.pulseDotMax ? 0.5 : 1.0) : 1.0)
                .shadow(color: foregroundStyle.opacity(status == .running ? 0.6 : 0), radius: 3)
                .onAppear { startPulseIfNeeded() }
                .onChange(of: status) { _, _ in startPulseIfNeeded() }
                .onChange(of: reduceMotion) { _, _ in startPulseIfNeeded() }

            Text(LocalizedStringKey(status.title))
                .font(DesignTokens.Font.subheading)
        }
        .padding(.horizontal, DesignTokens.Spacing.xl)
        .padding(.vertical, DesignTokens.Spacing.sm)
        .background(foregroundStyle.opacity(DesignTokens.Opacity.statusBadgeBg), in: Capsule())
        .foregroundStyle(foregroundStyle)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("Process Status"))
        .accessibilityValue(Text(LocalizedStringKey(status.title)))
    }

    private func startPulseIfNeeded() {
        if status == .running {
            pulseScale = DesignTokens.Scale.pulseDotMin
            if !reduceMotion {
                withAnimation(
                    .easeInOut(duration: DesignTokens.Animation.pulseSlow)
                    .repeatForever(autoreverses: true)
                ) {
                    pulseScale = DesignTokens.Scale.pulseDotMax
                }
            }
        } else {
            pulseScale = DesignTokens.Scale.pulseDotMin
        }
    }

    private var foregroundStyle: Color {
        DesignTokens.StatusColor.forStatus(status)
    }
}
