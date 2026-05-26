import SwiftUI
import HazakuraLLMManagerCore

struct DashboardView: View {
    @ObservedObject var controller: ServerController
    var onOpenSetupGuide: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignTokens.Bento.spacing) {
                if let launchSetupHint = controller.launchPreflightHint {
                    setupHintCard(launchSetupHint)
                }

                BentoGridLayout(
                    controller: controller,
                    onOpenSetupGuide: onOpenSetupGuide
                )
            }
            .padding(DesignTokens.Spacing.massive)
        }
    }

    @ViewBuilder
    private func setupHintCard(_ launchSetupHint: String) -> some View {
        HStack(spacing: DesignTokens.Spacing.md) {
            Label(launchSetupHint, systemImage: "info.circle")
                .font(DesignTokens.Font.caption)
                .foregroundStyle(.secondary)

            Spacer()

            Button(action: onOpenSetupGuide) {
                Label("Open Setup Guide", systemImage: "laurel.leading")
                    .font(DesignTokens.Font.caption)
            }
            .buttonStyle(.link)
        }
        .padding(.horizontal, DesignTokens.Spacing.xxxl)
        .padding(.vertical, DesignTokens.Spacing.xxl)
        .background(.thinMaterial)
        .background(Color.clear.background(.background).opacity(DesignTokens.Opacity.fillNoticeable))
        .cornerRadius(DesignTokens.Radius.large)
        .glassBorder()
    }
}

// MARK: - Bento Grid Layout

private struct BentoGridLayout: View {
    @ObservedObject var controller: ServerController
    var onOpenSetupGuide: () -> Void

    private var columns: [GridItem] {
        [
            GridItem(
                .adaptive(minimum: 320),
                spacing: DesignTokens.Bento.gridSpacing,
                alignment: .top
            )
        ]
    }

    var body: some View {
        LazyVGrid(columns: columns, alignment: .leading, spacing: DesignTokens.Bento.gridSpacing) {
            DashboardControlCard(controller: controller)
                .frame(maxWidth: .infinity)
            DashboardHealthCard(controller: controller, onOpenSetupGuide: onOpenSetupGuide)
                .frame(maxWidth: .infinity)
            DashboardEndpointCard(controller: controller)
                .frame(maxWidth: .infinity)
            DashboardCommandCard(controller: controller)
                .frame(maxWidth: .infinity)
        }
    }
}

// MARK: - Control Card

private struct DashboardControlCard: View {
    @ObservedObject var controller: ServerController

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.xxl) {
            HStack {
                Label("Server", systemImage: "server.rack")
                    .font(DesignTokens.Font.heading)

                Spacer()

                StatusPill(controller: controller)
            }

            processSummary

            Divider()

            ViewThatFits(in: .horizontal) {
                controlButtons

                VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                    controlButtons
                }
            }

            if let message = controller.lastErrorMessage {
                Label(message, systemImage: "exclamationmark.triangle")
                    .foregroundStyle(.red)
                    .font(DesignTokens.Font.caption)
                    .lineLimit(2)
            }
        }
        .padding(DesignTokens.Bento.padding)
        .background(.thinMaterial)
        .background(Color.clear.background(.background).opacity(DesignTokens.Opacity.fillNoticeable))
        .cornerRadius(DesignTokens.Bento.cornerRadius)
        .glassBorder()
        .designShadow(DesignTokens.Shadow.subtle)
    }

    private var processSummary: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            metricRow(
                title: "Process",
                value: controller.processIdentifier.map { "pid \($0)" } ?? localized("Not running")
            )
            metricRow(
                title: "Memory",
                value: memorySummary
            )
        }
    }

    private var controlButtons: some View {
        HStack(spacing: DesignTokens.Spacing.xl) {
            Button {
                controller.start()
            } label: {
                Label("Start", systemImage: "play.fill")
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(!controller.canStart)

            Button {
                controller.stop()
            } label: {
                Label("Stop", systemImage: "stop.fill")
            }
            .buttonStyle(SecondaryButtonStyle())
            .disabled(!controller.canStop)

            Button {
                controller.restart()
            } label: {
                Label("Restart", systemImage: "arrow.clockwise")
            }
            .buttonStyle(SecondaryButtonStyle())
            .disabled(!controller.canRestart)
        }
    }

    private var memorySummary: String {
        guard controller.processIdentifier != nil else {
            return localized("Not running")
        }

        guard let bytes = controller.processResidentMemoryBytes else {
            return localized("Unavailable")
        }

        return ByteCountFormatter.string(fromByteCount: Int64(bytes), countStyle: .memory)
    }

    private func localized(_ key: String.LocalizationValue) -> String {
        String(localized: key, bundle: .module)
    }

    private func metricRow(title: LocalizedStringKey, value: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: DesignTokens.Spacing.md) {
            Text(title)
                .font(DesignTokens.Font.caption)
                .foregroundStyle(.secondary)
                .frame(width: 64, alignment: .leading)

            Text(value)
                .font(DesignTokens.Font.codeCaption)
                .textSelection(.enabled)
                .lineLimit(1)
                .truncationMode(.middle)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

// MARK: - Status Pill

private struct StatusPill: View {
    @ObservedObject var controller: ServerController
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var pulseScale: CGFloat = DesignTokens.Scale.pulseDotMin

    var body: some View {
        HStack(spacing: DesignTokens.Spacing.sm) {
            Circle()
                .fill(statusColor)
                .frame(width: 7, height: 7)
                .scaleEffect(controller.status == .running ? pulseScale : 1.0)
                .opacity(controller.status == .running ? (pulseScale == DesignTokens.Scale.pulseDotMax ? 0.5 : 1.0) : 1.0)
                .shadow(color: statusColor.opacity(controller.status == .running ? 0.6 : 0), radius: 3)
                .onAppear { startPulseIfNeeded() }
                .onChange(of: controller.status) { _, _ in startPulseIfNeeded() }
                .onChange(of: reduceMotion) { _, _ in startPulseIfNeeded() }

            Text(LocalizedStringKey(controller.status.title))
                .font(DesignTokens.Font.subheading)
        }
        .padding(.horizontal, DesignTokens.Spacing.xl)
        .padding(.vertical, DesignTokens.Spacing.sm)
        .background(statusColor.opacity(DesignTokens.Opacity.statusBadgeBg), in: Capsule())
        .foregroundStyle(statusColor)
    }

    private var statusColor: Color {
        DesignTokens.StatusColor.forStatus(controller.status)
    }

    private func startPulseIfNeeded() {
        if controller.status == .running {
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
}

// MARK: - Health Card

private struct DashboardHealthCard: View {
    @ObservedObject var controller: ServerController
    var onOpenSetupGuide: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.xl) {
            Label("Endpoint Health", systemImage: "heart")
                .font(DesignTokens.Font.subheading)
                .foregroundStyle(.primary.opacity(DesignTokens.Opacity.textPrimary))

            HStack(alignment: .top, spacing: DesignTokens.Spacing.xl) {
                Label {
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                        Text(controller.endpointHealthStatus.localizedTitle)
                            .font(DesignTokens.Font.body)

                        if let detail = controller.endpointHealthStatus.localizedDetail {
                            Text(detail)
                                .font(DesignTokens.Font.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                } icon: {
                    Image(systemName: controller.endpointHealthStatus.systemImageName)
                        .foregroundStyle(healthColor)
                }

                Spacer()

                Button {
                    controller.checkEndpointHealth()
                } label: {
                    Label("Check Health", systemImage: "waveform.path.ecg")
                }
                .buttonStyle(SecondaryButtonStyle())
                .disabled(!controller.canCheckEndpointHealth)
            }
        }
        .padding(DesignTokens.Bento.padding)
        .background(.thinMaterial)
        .background(Color.clear.background(.background).opacity(DesignTokens.Opacity.fillNoticeable))
        .cornerRadius(DesignTokens.Bento.cornerRadius)
        .glassBorder()
        .designShadow(DesignTokens.Shadow.subtle)
    }

    private var healthColor: Color {
        switch controller.endpointHealthStatus.tone {
        case .neutral: return .secondary
        case .inProgress: return .orange
        case .success: return .green
        case .failure: return .red
        }
    }
}

// MARK: - Endpoint Card

private struct DashboardEndpointCard: View {
    @ObservedObject var controller: ServerController

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.xl) {
            Label("Endpoint", systemImage: "link")
                .font(DesignTokens.Font.subheading)
                .foregroundStyle(.primary.opacity(DesignTokens.Opacity.textPrimary))

            if let endpoint = controller.runtimeEndpoint {
                endpointURLRow(endpoint)
                endpointDetailsRow(endpoint)
            } else {
                Label(
                    controller.runtimeEndpointErrorMessage
                        ?? "Endpoint is not available for the current configuration.",
                    systemImage: "exclamationmark.triangle"
                )
                .font(DesignTokens.Font.caption)
                .foregroundStyle(.secondary)
            }
        }
        .padding(DesignTokens.Bento.padding)
        .background(.thinMaterial)
        .background(Color.clear.background(.background).opacity(DesignTokens.Opacity.fillNoticeable))
        .cornerRadius(DesignTokens.Bento.cornerRadius)
        .glassBorder()
        .designShadow(DesignTokens.Shadow.subtle)
    }

    private func endpointURLRow(_ endpoint: HazakuraLLMManagerCore.RuntimeEndpoint) -> some View {
        HStack(spacing: DesignTokens.Spacing.md) {
            Text(endpoint.apiBaseURLString)
                .codeBlockStyle()
                .frame(maxWidth: .infinity, alignment: .leading)

            BentoCopyButton(
                title: "Copy",
                systemImage: "doc.on.doc",
                value: endpoint.apiBaseURLString
            )
        }
    }

    private func endpointDetailsRow(_ endpoint: HazakuraLLMManagerCore.RuntimeEndpoint) -> some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            detailRow(title: "Model ID", value: endpoint.modelID, copyValue: endpoint.modelID)
            detailRow(title: "Model Name", value: endpoint.modelName)

            Label("API key is not required unless llama-server is started with --api-key.", systemImage: "lock.open")
                .font(DesignTokens.Font.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func detailRow(
        title: LocalizedStringKey,
        value: String,
        copyValue: String? = nil
    ) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: DesignTokens.Spacing.md) {
            Text(title)
                .font(DesignTokens.Font.caption)
                .foregroundStyle(.secondary)
                .frame(width: 78, alignment: .leading)

            Text(value)
                .font(DesignTokens.Font.codeCaption)
                .textSelection(.enabled)
                .lineLimit(1)
                .truncationMode(.middle)
                .frame(maxWidth: .infinity, alignment: .leading)

            if let copyValue {
                BentoCopyButton(
                    title: "Copy",
                    systemImage: "doc.on.doc",
                    value: copyValue
                )
            }
        }
    }
}

// MARK: - Command Card

private struct DashboardCommandCard: View {
    @ObservedObject var controller: ServerController

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.xl) {
            Label("Launch Command", systemImage: "terminal")
                .font(DesignTokens.Font.subheading)
                .foregroundStyle(.primary.opacity(DesignTokens.Opacity.textPrimary))

            HStack(spacing: DesignTokens.Spacing.md) {
                Text(controller.launchCommandPreview)
                    .codeBlockStyle()
                    .foregroundStyle(.primary.opacity(DesignTokens.Opacity.textBody))
                    .frame(maxWidth: .infinity, alignment: .leading)

                BentoCopyButton(
                    title: "Copy",
                    systemImage: "doc.on.doc",
                    value: controller.launchCommandPreview
                )
            }
        }
        .padding(DesignTokens.Bento.padding)
        .background(.thinMaterial)
        .background(Color.clear.background(.background).opacity(DesignTokens.Opacity.fillNoticeable))
        .cornerRadius(DesignTokens.Bento.cornerRadius)
        .glassBorder()
        .designShadow(DesignTokens.Shadow.subtle)
    }
}

// MARK: - Bento Copy Button

private struct BentoCopyButton: View {
    let title: LocalizedStringKey
    let systemImage: String
    let value: String?

    @State private var didCopy = false
    @State private var copyGeneration = 0

    var body: some View {
        VStack(alignment: .trailing, spacing: DesignTokens.Spacing.xxs) {
            Button {
                copyValue()
            } label: {
                Label(title, systemImage: systemImage)
            }
            .buttonStyle(SecondaryButtonStyle())
            .disabled(value == nil)

            Text("Copied!")
                .font(DesignTokens.Font.captionSmall)
                .foregroundStyle(.green)
                .opacity(didCopy ? 1 : 0)
                .accessibilityHidden(!didCopy)
                .frame(height: 12, alignment: .trailing)
        }
    }

    private func copyValue() {
        guard let value else { return }

        PasteboardWriter.copy(value)
        copyGeneration += 1
        let generation = copyGeneration

        withAnimation(.easeInOut(duration: DesignTokens.Animation.snappy)) {
            didCopy = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + DesignTokens.Animation.copyFeedback) {
            guard copyGeneration == generation else { return }

            withAnimation(.easeInOut(duration: DesignTokens.Animation.defaultDur)) {
                didCopy = false
            }
        }
    }
}
