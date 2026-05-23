import SwiftUI
import HazakuraLLMManagerCore

struct EndpointView: View {
    @ObservedObject var controller: ServerController
    @State private var isAdvancedExpanded = false

    var body: some View {
        GroupBox("Endpoint") {
            if let endpoint = controller.runtimeEndpoint {
                let healthCurlCommand = endpoint.endpointHealthCurlCommand

                VStack(alignment: .leading, spacing: DesignTokens.Spacing.lg) {
                    HStack(spacing: DesignTokens.Spacing.md) {
                        Text(endpoint.apiBaseURLString)
                            .codeBlockStyle()
                            .frame(maxWidth: .infinity, alignment: .leading)

                        EndpointCopyButton(
                            title: "Copy Endpoint",
                            systemImage: "doc.on.doc",
                            value: endpoint.apiBaseURLString
                        )
                    }

                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                        endpointDetailRow(
                            title: "Model ID",
                            value: endpoint.modelID,
                            copyTitle: "Copy Model ID"
                        )

                        endpointDetailRow(
                            title: "Model Name",
                            value: endpoint.modelName
                        )

                        Label("API key is not required unless llama-server is started with --api-key.", systemImage: "lock.open")
                            .font(DesignTokens.Font.caption)
                            .foregroundStyle(.secondary)
                    }

                    HStack(alignment: .top, spacing: DesignTokens.Spacing.xl) {
                        Label {
                            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                                Text(controller.endpointHealthStatus.title)
                                if let detail = controller.endpointHealthStatus.detail {
                                    Text(detail)
                                        .font(DesignTokens.Font.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        } icon: {
                            Image(systemName: controller.endpointHealthStatus.systemImageName)
                                .foregroundStyle(healthColor)
                        }
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel(Text("Endpoint Health"))
                        .accessibilityValue(Text(healthAccessibilityValue))

                        Spacer()

                        Button {
                            controller.checkEndpointHealth()
                        } label: {
                            Label("Check Health", systemImage: "waveform.path.ecg")
                        }
                        .buttonStyle(SecondaryButtonStyle())
                        .disabled(!controller.canCheckEndpointHealth)
                    }

                    Divider()

                    DisclosureSectionHeader(
                        title: "Advanced Connection Details",
                        isExpanded: $isAdvancedExpanded
                    )

                    if isAdvancedExpanded {
                        advancedDetails(endpoint, healthCurlCommand: healthCurlCommand)
                            .padding(.top, DesignTokens.Spacing.sm)
                    }
                }
            } else {
                Label(
                    controller.runtimeEndpointErrorMessage ?? "Endpoint is not available for the current configuration.",
                    systemImage: "exclamationmark.triangle"
                )
                .font(DesignTokens.Font.caption)
                .foregroundStyle(.secondary)
            }
        }
    }

    private func advancedDetails(_ endpoint: RuntimeEndpoint, healthCurlCommand: String?) -> some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.lg) {
            codeSnippetBlock(
                label: "Environment Variables",
                value: endpoint.environmentSnippet,
                copyTitle: "Copy Environment",
                copyIcon: "terminal"
            )

            codeSnippetBlock(
                label: "Health Check curl",
                value: healthCurlCommand ?? "Health check is not available for this adapter.",
                copyTitle: "Copy Health Check",
                copyIcon: "cross.case",
                disabled: healthCurlCommand == nil
            )

            codeSnippetBlock(
                label: "Client Connection curl",
                value: endpoint.aiMobileSmokeCurlCommand,
                copyTitle: "Copy AI Mobile Test",
                copyIcon: "checkmark.circle"
            )
        }
    }

    private func codeSnippetBlock(
        label: String,
        value: String,
        copyTitle: LocalizedStringKey,
        copyIcon: String,
        disabled: Bool = false
    ) -> some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            Text(label)
                .font(DesignTokens.Font.caption)
                .foregroundStyle(.secondary)

            HStack(spacing: DesignTokens.Spacing.md) {
                Text(value)
                    .codeBlockStyle()
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                EndpointCopyButton(
                    title: copyTitle,
                    systemImage: copyIcon,
                    value: value.isEmpty ? nil : value
                )
            }
        }
    }

    private func endpointDetailRow(
        title: LocalizedStringKey,
        value: String,
        copyTitle: LocalizedStringKey? = nil
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

            if let copyTitle {
                EndpointCopyButton(
                    title: copyTitle,
                    systemImage: "doc.on.doc",
                    value: value
                )
            }
        }
    }

    private var healthColor: Color {
        switch controller.endpointHealthStatus.tone {
        case .neutral: .secondary
        case .inProgress: .orange
        case .success: .green
        case .failure: .red
        }
    }

    private var healthAccessibilityValue: String {
        if let detail = controller.endpointHealthStatus.detail {
            "\(controller.endpointHealthStatus.title). \(detail)"
        } else {
            controller.endpointHealthStatus.title
        }
    }
}

private struct EndpointCopyButton: View {
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
