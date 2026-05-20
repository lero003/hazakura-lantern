import AppKit
import SwiftUI
import HazakuraLLMManagerCore

struct MenuBarControlView: View {
    @ObservedObject var controller: ServerController
    @Environment(\.openWindow) private var openWindow

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

        Button("Copy Endpoint") {
            if let endpoint = controller.runtimeEndpoint {
                PasteboardWriter.copy(endpoint.apiBaseURLString)
            }
        }
        .disabled(controller.runtimeEndpoint == nil)

        Button("Copy Launch Command") {
            PasteboardWriter.copy(controller.launchCommandPreview)
        }

        if let endpoint = controller.runtimeEndpoint {
            Button("Copy Environment") {
                PasteboardWriter.copy(endpoint.environmentSnippet)
            }

            Button("Copy Health Check") {
                if let healthCurlCommand = endpoint.endpointHealthCurlCommand {
                    PasteboardWriter.copy(healthCurlCommand)
                }
            }
            .disabled(endpoint.endpointHealthCurlCommand == nil)

            Button("Copy AI Mobile Test") {
                PasteboardWriter.copy(endpoint.aiMobileSmokeCurlCommand)
            }
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
}
