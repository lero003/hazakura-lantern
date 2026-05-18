import AppKit
import SwiftUI

struct EndpointView: View {
    @ObservedObject var controller: ServerController

    var body: some View {
        GroupBox("Endpoint") {
            if let endpoint = controller.runtimeEndpoint {
                let healthCurlCommand = endpoint.endpointHealthCurlCommand

                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text(endpoint.apiBaseURLString)
                            .font(.system(.body, design: .monospaced))
                            .textSelection(.enabled)

                        Spacer()

                        Button {
                            copy(endpoint.apiBaseURLString)
                        } label: {
                            Label("Copy Endpoint", systemImage: "doc.on.doc")
                        }
                    }

                    HStack(alignment: .top, spacing: 12) {
                        Text(endpoint.environmentSnippet)
                            .font(.system(.caption, design: .monospaced))
                            .foregroundStyle(.secondary)
                            .textSelection(.enabled)

                        Spacer()

                        Button {
                            copy(endpoint.environmentSnippet)
                        } label: {
                            Label("Copy Env", systemImage: "terminal")
                        }
                    }

                    HStack(alignment: .top, spacing: 12) {
                        Text(healthCurlCommand ?? "Health check is not available for this adapter.")
                            .font(.system(.caption, design: .monospaced))
                            .foregroundStyle(.secondary)
                            .textSelection(.enabled)

                        Spacer()

                        Button {
                            if let healthCurlCommand {
                                copy(healthCurlCommand)
                            }
                        } label: {
                            Label("Copy Health Check", systemImage: "cross.case")
                        }
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
                        .disabled(controller.endpointHealthStatus == .checking)
                    }

                    Divider()

                    HStack(alignment: .top, spacing: 12) {
                        Text(endpoint.aiMobileSmokeCurlCommand)
                            .font(.system(.caption, design: .monospaced))
                            .foregroundStyle(.secondary)
                            .textSelection(.enabled)

                        Spacer()

                        Button {
                            copy(endpoint.aiMobileSmokeCurlCommand)
                        } label: {
                            Label("Copy AI Mobile Test", systemImage: "checkmark.circle")
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
