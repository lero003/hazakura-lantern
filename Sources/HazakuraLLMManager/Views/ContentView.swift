import SwiftUI
import HazakuraLLMManagerCore

struct ContentView: View {
    @ObservedObject var controller: ServerController
    @State private var selectedItem: SidebarItem? = .dashboard
    @State private var showSetupGuide = false
    @State private var didCopyFromToolbar = false
    @State private var toolbarCopyGeneration = 0

    private enum SidebarItem: String, CaseIterable, Identifiable {
        case dashboard = "Dashboard"
        case configuration = "Configuration"
        case smokeConsole = "Smoke Console"
        case logs = "Logs"
        case settings = "Settings"

        var id: String { self.rawValue }

        var systemImage: String {
            switch self {
            case .dashboard: return "square.grid.2x2"
            case .configuration: return "slider.horizontal.3"
            case .smokeConsole: return "checkmark.circle"
            case .logs: return "doc.text"
            case .settings: return "gearshape"
            }
        }
    }

    var body: some View {
        NavigationSplitView {
            List(SidebarItem.allCases, selection: $selectedItem) { item in
                NavigationLink(value: item) {
                    Label(LocalizedStringKey(item.rawValue), systemImage: item.systemImage)
                }
            }
            .frame(minWidth: 160)
        } detail: {
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

                    if let selectedItem {
                        switch selectedItem {
                        case .dashboard:
                            DashboardView(controller: controller, onOpenSetupGuide: {
                                showSetupGuide = true
                            })
                        case .configuration:
                            ScrollView {
                                VStack(alignment: .leading, spacing: 20) {
                                    ProfileView(controller: controller)
                                    ConfigurationView(controller: controller)
                                }
                                .padding(24)
                            }
                        case .smokeConsole:
                            ScrollView {
                                SmokeConsoleView(controller: controller)
                                    .padding(24)
                                    .frame(maxWidth: .infinity, alignment: .topLeading)
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                        case .logs:
                            LogsView(controller: controller)
                                .padding(24)
                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                        case .settings:
                            SettingsView()
                                .padding(24)
                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                        }
                    } else {
                        ContentUnavailableView("Select an item", systemImage: "sidebar.left")
                    }
                }
            }
            .toolbar {
                ToolbarItem {
                    Toggle(isOn: $showSetupGuide) {
                        Label("Setup Guide", systemImage: "laurel.leading")
                    }
                    .toggleStyle(.button)
                    .labelStyle(.titleAndIcon)
                    .accessibilityLabel(Text("Setup Guide"))
                    .accessibilityHint(Text("Show or hide the setup guide inspector."))
                    .help("Show Setup Guide")
                }

                ToolbarItemGroup {
                    Button {
                        exportRuntimeProfile()
                    } label: {
                        Label("Export Profile", systemImage: "square.and.arrow.up")
                    }
                    .labelStyle(.titleAndIcon)
                    .accessibilityLabel(Text("Export Active Profile"))
                    .accessibilityHint(Text("Export the active runtime profile as a .lantern-profile.json file."))
                    .help("Export Active Profile")

                    Button {
                        importRuntimeProfile()
                    } label: {
                        Label("Import Profile", systemImage: "square.and.arrow.down")
                    }
                    .labelStyle(.titleAndIcon)
                    .accessibilityLabel(Text("Import Profile"))
                    .accessibilityHint(Text("Import a .lantern-profile.json file into the active configuration."))
                    .help("Import Profile")
                }

                ToolbarItem {
                    Menu {
                        Button {
                            copyFromToolbar(controller.launchCommandPreview)
                        } label: {
                            Label("Copy Launch Command", systemImage: "terminal")
                        }

                        if let endpoint = controller.runtimeEndpoint {
                            Divider()

                            Button {
                                copyFromToolbar(endpoint.apiBaseURLString)
                            } label: {
                                Label("Copy Endpoint", systemImage: "link")
                            }

                            Button {
                                copyFromToolbar(endpoint.environmentSnippet)
                            } label: {
                                Label("Copy Environment", systemImage: "terminal")
                            }

                            Button {
                                if let healthCurlCommand = endpoint.endpointHealthCurlCommand {
                                    copyFromToolbar(healthCurlCommand)
                                }
                            } label: {
                                Label("Copy Health Check", systemImage: "cross.case")
                            }
                            .disabled(endpoint.endpointHealthCurlCommand == nil)

                            Button {
                                copyFromToolbar(endpoint.aiMobileSmokeCurlCommand)
                            } label: {
                                Label("Copy AI Mobile Test", systemImage: "checkmark.circle")
                            }
                        }
                    } label: {
                        Label {
                            Text(LocalizedStringKey(didCopyFromToolbar ? "Copied!" : "Copy"))
                        } icon: {
                            Image(systemName: didCopyFromToolbar ? "checkmark.circle" : "doc.on.doc")
                        }
                    }
                    .labelStyle(.titleAndIcon)
                    .accessibilityLabel(Text("Copy"))
                    .accessibilityHint(Text("Open copy options for the launch command, endpoint, environment, and smoke commands."))
                    .help("Copy existing command, endpoint, and client snippets")
                }
            }
        }
        .groupBoxStyle(GlassGroupBoxStyle())
        .inspector(isPresented: $showSetupGuide) {
            SetupGuideView(controller: controller)
                .inspectorColumnWidth(min: 300, ideal: 320, max: 340)
        }
        .onAppear {
            if controller.configuration.runtimeExecutablePath.isEmpty ||
               controller.configuration.modelPath.isEmpty {
                showSetupGuide = true
            }
        }
        .frame(minWidth: 980, minHeight: 640)
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

    private func copyFromToolbar(_ value: String) {
        PasteboardWriter.copy(value)
        toolbarCopyGeneration += 1
        let generation = toolbarCopyGeneration

        withAnimation(.easeInOut(duration: 0.15)) {
            didCopyFromToolbar = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
            guard toolbarCopyGeneration == generation else {
                return
            }

            withAnimation(.easeInOut(duration: 0.2)) {
                didCopyFromToolbar = false
            }
        }
    }
}
