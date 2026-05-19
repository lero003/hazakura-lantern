import AppKit
import SwiftUI

struct EndpointView: View {
    @ObservedObject var controller: ServerController

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
                            copy(endpoint.apiBaseURLString)
                        } label: {
                            Label("Copy Endpoint", systemImage: "doc.on.doc")
                        }
                        .buttonStyle(SecondaryButtonStyle())
                    }

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
                            copy(endpoint.environmentSnippet)
                        } label: {
                            Label("Copy Env", systemImage: "terminal")
                        }
                        .buttonStyle(SecondaryButtonStyle())
                    }

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
                                copy(healthCurlCommand)
                            }
                        } label: {
                            Label("Copy Health Check", systemImage: "cross.case")
                        }
                        .buttonStyle(SecondaryButtonStyle())
                        .disabled(healthCurlCommand == nil)
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
                            copy(endpoint.aiMobileSmokeCurlCommand)
                        } label: {
                            Label("Copy AI Mobile Test", systemImage: "checkmark.circle")
                        }
                        .buttonStyle(SecondaryButtonStyle())
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

    private func copy(_ value: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(value, forType: .string)
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
}
