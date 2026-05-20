import AppKit
import SwiftUI
import HazakuraLLMManagerCore

struct ContentView: View {
    @ObservedObject var controller: ServerController

    private enum ContentSection: Hashable {
        case commandPreview
    }

    var body: some View {
        ScrollViewReader { scrollProxy in
            ZStack {
                AuroraBackgroundView(status: controller.status)

                VStack(spacing: 0) {
                    StatusHeaderView(controller: controller)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 16)
                        .background(.ultraThinMaterial.opacity(0.4))
                        .overlay(
                            VStack {
                                Spacer()
                                Rectangle()
                                    .fill(Color.white.opacity(0.08))
                                    .frame(height: 1)
                            }
                        )

                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            ProfileView(controller: controller)
                            ConfigurationView(controller: controller)
                            EndpointView(controller: controller)
                            CommandPreviewView(controller: controller)
                                .id(ContentSection.commandPreview)
                            LogsView(controller: controller)
                        }
                        .padding(24)
                    }
                }
            }
            .toolbar {
                ToolbarItemGroup {
                    Button {
                        controller.start()
                    } label: {
                        Label("Start", systemImage: "play.fill")
                    }
                    .disabled(!controller.canStart)

                    Button {
                        controller.stop()
                    } label: {
                        Label("Stop", systemImage: "stop.fill")
                    }
                    .disabled(!controller.canStop)

                    Button {
                        controller.restart()
                    } label: {
                        Label("Restart", systemImage: "arrow.clockwise")
                    }
                    .disabled(!controller.canRestart)
                }

                ToolbarItem {
                    Button {
                        controller.checkEndpointHealth()
                    } label: {
                        Label("Check Health", systemImage: "waveform.path.ecg")
                    }
                    .disabled(controller.endpointHealthStatus == .checking)
                }

                ToolbarItem {
                    Button {
                        withAnimation {
                            scrollProxy.scrollTo(ContentSection.commandPreview, anchor: .center)
                        }
                    } label: {
                        Label("Show Command", systemImage: "terminal")
                    }
                    .help("Show the existing launch command preview")
                }

                ToolbarItem {
                    Button {
                        controller.clearLogs()
                    } label: {
                        Label("Clear Logs", systemImage: "trash")
                    }
                    .disabled(controller.logEntries.isEmpty)
                    .help("Clear the in-memory runtime logs")
                }

                ToolbarItem {
                    Menu {
                        Button {
                            exportRuntimeProfile()
                        } label: {
                            Label("Export Active Profile", systemImage: "square.and.arrow.up")
                        }

                        Button {
                            importRuntimeProfile()
                        } label: {
                            Label("Import Profile", systemImage: "square.and.arrow.down")
                        }
                    } label: {
                        Label("Profile", systemImage: "doc.text")
                    }
                    .help("Import or export the active runtime profile")
                }

                ToolbarItem {
                    Menu {
                        Button {
                            copy(controller.launchCommandPreview)
                        } label: {
                            Label("Copy Launch Command", systemImage: "terminal")
                        }

                        if let endpoint = controller.runtimeEndpoint {
                            Divider()

                            Button {
                                copy(endpoint.apiBaseURLString)
                            } label: {
                                Label("Copy Endpoint", systemImage: "link")
                            }

                            Button {
                                copy(endpoint.environmentSnippet)
                            } label: {
                                Label("Copy Environment", systemImage: "terminal")
                            }

                            Button {
                                if let healthCurlCommand = endpoint.endpointHealthCurlCommand {
                                    copy(healthCurlCommand)
                                }
                            } label: {
                                Label("Copy Health Check", systemImage: "cross.case")
                            }
                            .disabled(endpoint.endpointHealthCurlCommand == nil)

                            Button {
                                copy(endpoint.aiMobileSmokeCurlCommand)
                            } label: {
                                Label("Copy AI Mobile Test", systemImage: "checkmark.circle")
                            }
                        }
                    } label: {
                        Label("Copy", systemImage: "doc.on.doc")
                    }
                    .help("Copy existing command, endpoint, and client snippets")
                }
            }
        }
        .groupBoxStyle(GlassGroupBoxStyle())
        .frame(minWidth: 640, minHeight: 700)
    }

    private func copy(_ value: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(value, forType: .string)
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
