import AppKit
import SwiftUI
import HazakuraLLMManagerCore

struct MenuBarControlView: View {
    @ObservedObject var controller: ServerController
    @State private var didCopyFromMenuBar = false
    @State private var menuBarCopyGeneration = 0

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            statusPillBar

            Divider()

            primaryActions

            Divider()

            copyActions

            Divider()

            profileActions

            Divider()

            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
        }
        .padding(.vertical, DesignTokens.Spacing.sm)
    }

    // MARK: - Status Pill Bar

    @ViewBuilder
    private var statusPillBar: some View {
        HStack(spacing: DesignTokens.Spacing.md) {
            Image(systemName: statusSystemImage)
                .font(.body)
                .foregroundStyle(statusColor)

            Text(LocalizedStringKey(controller.status.title))
                .font(DesignTokens.Font.subheading)

            if let pid = controller.processIdentifier {
                Text("pid \(pid)")
                    .font(DesignTokens.Font.codeDigit)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Circle()
                .fill(statusColor)
                .frame(width: 6, height: 6)
                .shadow(color: statusColor.opacity(0.5), radius: 2)
        }
        .padding(.horizontal, DesignTokens.Spacing.xxl)
        .padding(.vertical, DesignTokens.Spacing.md)
        .background(
            statusColor.opacity(DesignTokens.Opacity.fillLight),
            in: Capsule()
        )
        .overlay(
            Capsule()
                .stroke(
                    statusColor.opacity(DesignTokens.Opacity.borderMedium),
                    lineWidth: 1
                )
        )
    }

    private var statusColor: Color {
        DesignTokens.StatusColor.forStatus(controller.status)
    }

    // MARK: - Primary Actions

    @ViewBuilder
    private var primaryActions: some View {
        VStack(spacing: DesignTokens.Spacing.xxs) {
            Button("Open Window") { openMainWindow() }

            Menu {
                Button("Start Server") { controller.start() }
                    .disabled(!controller.canStart)

                Button("Stop Server") { controller.stop() }
                    .disabled(!controller.canStop)

                Button("Restart Server") { controller.restart() }
                    .disabled(!controller.canRestart)

                Button("Check Health") { controller.checkEndpointHealth() }
                    .disabled(!controller.canCheckEndpointHealth)
            } label: {
                Label("Server Controls", systemImage: statusSystemImage)
            }
        }
    }

    // MARK: - Copy Actions

    @ViewBuilder
    private var copyActions: some View {
        VStack(spacing: DesignTokens.Spacing.xxs) {
            if didCopyFromMenuBar {
                Label("Copied!", systemImage: "checkmark.circle")
                    .foregroundStyle(.green)
            }

            Button("Copy Endpoint") {
                if let endpoint = controller.runtimeEndpoint {
                    copyFromMenuBar(endpoint.apiBaseURLString)
                }
            }
            .disabled(controller.runtimeEndpoint == nil)
            .accessibilityHint(Text("Copy the client connection URL to the clipboard."))

            Button("Copy Launch Command") {
                copyFromMenuBar(controller.launchCommandPreview)
            }
            .accessibilityHint(Text("Copy the generated launch command to the clipboard."))

            if let endpoint = controller.runtimeEndpoint {
                Button("Copy Environment") {
                    copyFromMenuBar(endpoint.environmentSnippet)
                }
                .accessibilityHint(Text("Copy OpenAI-compatible environment variables to the clipboard."))

                Button("Copy Health Check") {
                    if let cmd = endpoint.endpointHealthCurlCommand {
                        copyFromMenuBar(cmd)
                    }
                }
                .disabled(endpoint.endpointHealthCurlCommand == nil)
                .accessibilityHint(Text("Copy the timeout-bounded health-check curl command to the clipboard."))

                Button("Copy AI Mobile Test") {
                    copyFromMenuBar(endpoint.aiMobileSmokeCurlCommand)
                }
                .accessibilityHint(Text("Copy the timeout-bounded AI Mobile smoke curl command to the clipboard."))
            }
        }
    }

    // MARK: - Profile Actions

    @ViewBuilder
    private var profileActions: some View {
        VStack(spacing: DesignTokens.Spacing.xxs) {
            Button("Export Profile") { exportRuntimeProfile() }
            Button("Import Profile") { importRuntimeProfile() }

            if let msg = controller.profileFileMessage {
                Label(msg, systemImage: "info.circle")
                    .font(DesignTokens.Font.caption)
                    .foregroundStyle(.secondary)
            }

            Button("Clear Logs") { controller.clearLogs() }
                .disabled(controller.logEntries.isEmpty)
        }
    }

    // MARK: - Helpers

    private var statusSystemImage: String {
        switch controller.status {
        case .running: "checkmark.circle.fill"
        case .starting, .loading: "arrow.triangle.2.circlepath"
        case .stopping: "pause.circle.fill"
        case .restarting: "arrow.clockwise"
        case .error: "exclamationmark.triangle.fill"
        case .stopped: "stop.circle.fill"
        }
    }

    private func openMainWindow() {
        NotificationCenter.default.post(name: .hazakuraShowMainWindow, object: nil)
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func exportRuntimeProfile() {
        if let url = FilePanel.chooseProfileExportFile(
            suggestedFileName: controller.runtimeProfileDocument.suggestedExportFileName
        ) {
            controller.exportRuntimeProfile(to: url)
        }
    }

    private func importRuntimeProfile() {
        if let url = FilePanel.chooseProfileImportFile() {
            controller.importRuntimeProfile(from: url)
        }
    }

    private func copyFromMenuBar(_ value: String) {
        PasteboardWriter.copy(value)
        menuBarCopyGeneration += 1
        let generation = menuBarCopyGeneration

        didCopyFromMenuBar = true

        DispatchQueue.main.asyncAfter(deadline: .now() + DesignTokens.Animation.copyFeedback) {
            guard menuBarCopyGeneration == generation else { return }
            didCopyFromMenuBar = false
        }
    }
}
