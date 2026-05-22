import SwiftUI

struct EndpointView: View {
    @ObservedObject var controller: ServerController
    @State private var isAdvancedExpanded = false

    var body: some View {
        GroupBox("Endpoint") {
            if let endpoint = controller.runtimeEndpoint {
                let healthCurlCommand = endpoint.endpointHealthCurlCommand

                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 8) {
                        Text(endpoint.apiBaseURLString)
                            .font(.system(.body, design: .monospaced))
                            .textSelection(.enabled)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(.black.opacity(0.22), in: RoundedRectangle(cornerRadius: 6))
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color.white.opacity(0.06), lineWidth: 1)
                            )

                        EndpointCopyButton(
                            title: "Copy Endpoint",
                            systemImage: "doc.on.doc",
                            value: endpoint.apiBaseURLString
                        )
                    }

                    VStack(alignment: .leading, spacing: 6) {
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
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    HStack(alignment: .top, spacing: 12) {
                        Label {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(controller.endpointHealthStatus.title)
                                if let detail = controller.endpointHealthStatus.detail {
                                    Text(detail)
                                        .font(.caption)
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

                    VStack(alignment: .leading, spacing: 0) {
                        DisclosureSectionHeader(
                            title: "Advanced Connection Details",
                            isExpanded: $isAdvancedExpanded
                        )

                        if isAdvancedExpanded {
                            VStack(alignment: .leading, spacing: 10) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Environment Variables")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    HStack(spacing: 8) {
                                        Text(endpoint.environmentSnippet)
                                            .font(.system(.caption, design: .monospaced))
                                            .foregroundStyle(.secondary)
                                            .textSelection(.enabled)
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 6)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .background(.black.opacity(0.22), in: RoundedRectangle(cornerRadius: 6))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 6)
                                                    .stroke(Color.white.opacity(0.06), lineWidth: 1)
                                            )

                                        EndpointCopyButton(
                                            title: "Copy Environment",
                                            systemImage: "terminal",
                                            value: endpoint.environmentSnippet
                                        )
                                    }
                                }

                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Health Check curl")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    HStack(spacing: 8) {
                                        Text(healthCurlCommand ?? "Health check is not available for this adapter.")
                                            .font(.system(.caption, design: .monospaced))
                                            .foregroundStyle(.secondary)
                                            .textSelection(.enabled)
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 6)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .background(.black.opacity(0.22), in: RoundedRectangle(cornerRadius: 6))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 6)
                                                    .stroke(Color.white.opacity(0.06), lineWidth: 1)
                                            )

                                        EndpointCopyButton(
                                            title: "Copy Health Check",
                                            systemImage: "cross.case",
                                            value: healthCurlCommand
                                        )
                                    }
                                }

                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Client Connection curl")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    HStack(spacing: 8) {
                                        Text(endpoint.aiMobileSmokeCurlCommand)
                                            .font(.system(.caption, design: .monospaced))
                                            .foregroundStyle(.secondary)
                                            .textSelection(.enabled)
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 6)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .background(.black.opacity(0.22), in: RoundedRectangle(cornerRadius: 6))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 6)
                                                    .stroke(Color.white.opacity(0.06), lineWidth: 1)
                                            )

                                        EndpointCopyButton(
                                            title: "Copy AI Mobile Test",
                                            systemImage: "checkmark.circle",
                                            value: endpoint.aiMobileSmokeCurlCommand
                                        )
                                    }
                                }
                            }
                            .padding(.top, 8)
                        }
                    }
                }
            } else {
                Label(
                    controller.runtimeEndpointErrorMessage ?? "Endpoint is not available for the current configuration.",
                    systemImage: "exclamationmark.triangle"
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
    }

    private func endpointDetailRow(
        title: LocalizedStringKey,
        value: String,
        copyTitle: LocalizedStringKey? = nil
    ) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .frame(width: 78, alignment: .leading)

            Text(value)
                .font(.system(.caption, design: .monospaced))
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
        case .neutral:
            .secondary
        case .inProgress:
            .orange
        case .success:
            .green
        case .failure:
            .red
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
        VStack(alignment: .trailing, spacing: 3) {
            Button {
                copyValue()
            } label: {
                Label(title, systemImage: systemImage)
            }
            .buttonStyle(SecondaryButtonStyle())
            .disabled(value == nil)

            Text("Copied!")
                .font(.caption2)
                .foregroundStyle(.green)
                .opacity(didCopy ? 1 : 0)
                .accessibilityHidden(!didCopy)
                .frame(height: 12, alignment: .trailing)
        }
    }

    private func copyValue() {
        guard let value else {
            return
        }

        PasteboardWriter.copy(value)
        copyGeneration += 1
        let generation = copyGeneration

        withAnimation(.easeInOut(duration: 0.15)) {
            didCopy = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
            guard copyGeneration == generation else {
                return
            }

            withAnimation(.easeInOut(duration: 0.2)) {
                didCopy = false
            }
        }
    }
}
