import SwiftUI
import HazakuraLLMManagerCore

struct StatusHeaderView: View {
    @ObservedObject var controller: ServerController

    var body: some View {
        HStack(spacing: 14) {
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

            StatusBadge(status: controller.status)
        }
    }
}

private struct StatusBadge: View {
    var status: ServerStatus

    var body: some View {
        Label(status.title, systemImage: systemImage)
            .font(.callout.weight(.medium))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(backgroundStyle, in: Capsule())
            .foregroundStyle(foregroundStyle)
    }

    private var systemImage: String {
        switch status {
        case .stopped:
            "stop.circle"
        case .starting:
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
        case .starting, .stopping, .restarting:
            .orange
        case .stopped:
            .secondary
        }
    }

    private var backgroundStyle: Color {
        foregroundStyle.opacity(0.12)
    }
}
