import SwiftUI
import HazakuraLLMManagerCore

struct StatusHeaderView: View {
    @ObservedObject var controller: ServerController
    @Environment(\.locale) private var locale
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var lanternPulse: CGFloat = 1.0

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: "lightbulb.fill")
                .font(.title2)
                .foregroundStyle(lanternColor)
                .scaleEffect(controller.status == .running ? lanternPulse : 1.0)
                .shadow(color: lanternColor.opacity(controller.status == .running ? 0.8 : 0.0), radius: 6)
                .accessibilityHidden(true)
                .onAppear {
                    startLanternPulse()
                }
                .onChange(of: controller.status) { _, _ in
                    startLanternPulse()
                }
                .onChange(of: reduceMotion) { _, _ in
                    startLanternPulse()
                }

            VStack(alignment: .leading, spacing: 4) {
                Text("Hazakura Lantern")
                    .font(.title2.weight(.semibold))

                Text("Local light for llama-server")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if let processIdentifier = controller.processIdentifier {
                Text("pid \(processIdentifier)")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .trailing, spacing: 4) {
                StatusBadge(status: controller.status)

                if controller.status == .loading,
                   let loadingElapsedSeconds = controller.loadingElapsedSeconds {
                    Text(localized("loading_elapsed.seconds", loadingElapsedSeconds))
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private func startLanternPulse() {
        if controller.status == .running {
            lanternPulse = 1.0
            if !reduceMotion {
                withAnimation(
                    .easeInOut(duration: 1.2)
                    .repeatForever(autoreverses: true)
                ) {
                    lanternPulse = 1.15
                }
            }
        } else {
            lanternPulse = 1.0
        }
    }

    private var lanternColor: Color {
        switch controller.status {
        case .running:
            return .orange
        case .starting, .loading, .stopping, .restarting:
            return .yellow
        case .error:
            return .red
        case .stopped:
            return .secondary
        }
    }

    private func localized(_ key: String, _ arguments: CVarArg...) -> String {
        let format = String(
            localized: String.LocalizationValue(key),
            bundle: .module,
            locale: locale
        )

        guard !arguments.isEmpty else {
            return format
        }

        return String(format: format, locale: locale, arguments: arguments)
    }
}

private struct StatusBadge: View {
    var status: ServerStatus
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var pulseScale: CGFloat = 1.0

    var body: some View {
        HStack(spacing: 8) {
            // ステータスを示すインジケータドット
            Circle()
                .fill(foregroundStyle)
                .frame(width: 7, height: 7)
                .scaleEffect(status == .running ? pulseScale : 1.0)
                .opacity(status == .running ? (pulseScale == 1.4 ? 0.5 : 1.0) : 1.0)
                .shadow(color: foregroundStyle.opacity(status == .running ? 0.6 : 0), radius: 3)
                .onAppear {
                    startPulseIfNeeded()
                }
                .onChange(of: status) { _, _ in
                    startPulseIfNeeded()
                }
                .onChange(of: reduceMotion) { _, _ in
                    startPulseIfNeeded()
                }

            Text(LocalizedStringKey(status.title))
                .font(.callout.weight(.medium))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(backgroundStyle, in: Capsule())
        .foregroundStyle(foregroundStyle)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("Process Status"))
        .accessibilityValue(Text(LocalizedStringKey(status.title)))
    }

    private func startPulseIfNeeded() {
        if status == .running {
            pulseScale = 1.0
            if !reduceMotion {
                withAnimation(
                    .easeInOut(duration: 1.0)
                    .repeatForever(autoreverses: true)
                ) {
                    pulseScale = 1.4
                }
            }
        } else {
            pulseScale = 1.0
        }
    }

    private var systemImage: String {
        switch status {
        case .stopped:
            "stop.circle"
        case .starting, .loading:
            "clock"
        case .running:
            "checkmark.circle"
        case .stopping:
            "pause.circle"
        case .restarting:
            "arrow.clockwise.circle"
        case .error:
            "exclamationmark.triangle"
        }
    }

    private var foregroundStyle: Color {
        switch status {
        case .running:
            .green
        case .error:
            .red
        case .starting, .loading, .stopping, .restarting:
            .orange
        case .stopped:
            .secondary
        }
    }

    private var backgroundStyle: Color {
        foregroundStyle.opacity(0.12)
    }
}
