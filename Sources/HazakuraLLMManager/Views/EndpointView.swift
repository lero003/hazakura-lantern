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

                        Button {
                            PasteboardWriter.copy(endpoint.apiBaseURLString)
                        } label: {
                            Label("Copy Endpoint", systemImage: "doc.on.doc")
                        }
                        .buttonStyle(SecondaryButtonStyle())
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
                        .disabled(controller.endpointHealthStatus == .checking)
                    }

                    Divider()

                    VStack(alignment: .leading, spacing: 0) {
                        DisclosureSectionHeader(
                            title: "詳細な接続情報 / Advanced Connection Details",
                            isExpanded: $isAdvancedExpanded
                        )

                        if isAdvancedExpanded {
                            VStack(alignment: .leading, spacing: 10) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("環境変数 / Environment Variables")
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

                                        Button {
                                            PasteboardWriter.copy(endpoint.environmentSnippet)
                                        } label: {
                                            Label("Copy Env", systemImage: "terminal")
                                        }
                                        .buttonStyle(SecondaryButtonStyle())
                                    }
                                }

                                VStack(alignment: .leading, spacing: 4) {
                                    Text("ヘルスチェック / Health Check curl")
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

                                        Button {
                                            if let healthCurlCommand {
                                                PasteboardWriter.copy(healthCurlCommand)
                                            }
                                        } label: {
                                            Label("Copy Health Check", systemImage: "cross.case")
                                        }
                                        .buttonStyle(SecondaryButtonStyle())
                                        .disabled(healthCurlCommand == nil)
                                    }
                                }

                                VStack(alignment: .leading, spacing: 4) {
                                    Text("外部クライアント接続テスト / Client Connection curl")
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

                                        Button {
                                            PasteboardWriter.copy(endpoint.aiMobileSmokeCurlCommand)
                                        } label: {
                                            Label("Copy AI Mobile Test", systemImage: "checkmark.circle")
                                        }
                                        .buttonStyle(SecondaryButtonStyle())
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
