import AppKit
import SwiftUI
import HazakuraLLMManagerCore

struct MenuBarControlView: View {
    @ObservedObject var controller: ServerController
    @Environment(\.openWindow) private var openWindow
    @State private var didCopyFromMenuBar = false
    @State private var menuBarCopyGeneration = 0

    var body: some View {
        Label {
            Text(LocalizedStringKey(controller.status.title))
        } icon: {
            Image(systemName: statusSystemImage)
        }

        if let processIdentifier = controller.processIdentifier {
            Text("pid \(processIdentifier)")
        }

        Divider()

        Button("Open Window") {
            openMainWindow()
        }

        Divider()

        Button("Start Server") {
            controller.start()
        }
        .disabled(!controller.canStart)

        Button("Stop Server") {
            controller.stop()
        }
        .disabled(!controller.canStop)

        Button("Restart Server") {
            controller.restart()
        }
        .disabled(!controller.canRestart)

        Button("Check Health") {
            controller.checkEndpointHealth()
        }
        .disabled(controller.endpointHealthStatus == .checking)

        Divider()

        if didCopyFromMenuBar {
            Label("Copied!", systemImage: "checkmark.circle")
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
                if let healthCurlCommand = endpoint.endpointHealthCurlCommand {
                    copyFromMenuBar(healthCurlCommand)
                }
            }
            .disabled(endpoint.endpointHealthCurlCommand == nil)
            .accessibilityHint(Text("Copy the timeout-bounded health-check curl command to the clipboard."))

            Button("Copy AI Mobile Test") {
                copyFromMenuBar(endpoint.aiMobileSmokeCurlCommand)
            }
            .accessibilityHint(Text("Copy the timeout-bounded AI Mobile smoke curl command to the clipboard."))
        }

        Divider()

        Button("Export Profile") {
            exportRuntimeProfile()
        }

        Button("Import Profile") {
            importRuntimeProfile()
        }

        Button("Clear Logs") {
            controller.clearLogs()
        }
        .disabled(controller.logEntries.isEmpty)

        Divider()

        Button("Quit") {
            NSApplication.shared.terminate(nil)
        }
    }

    private var statusSystemImage: String {
        switch controller.status {
        case .running:
            "checkmark.circle"
        case .starting:
            "clock"
        case .stopping:
            "pause.circle"
        case .restarting:
            "arrow.clockwise.circle"
        case .error:
            "exclamationmark.triangle"
        case .stopped:
            "stop.circle"
        }
    }

    private func openMainWindow() {
        if let window = NSApplication.shared.windows.first(where: { $0.canBecomeMain }) {
            window.makeKeyAndOrderFront(nil)
        } else {
            openWindow(id: "main")
        }

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

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
            guard menuBarCopyGeneration == generation else {
                return
            }

            didCopyFromMenuBar = false
        }
    }
}
