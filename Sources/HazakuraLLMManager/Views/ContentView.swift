import SwiftUI
import HazakuraLLMManagerCore

struct ContentView: View {
    @ObservedObject var controller: ServerController

    var body: some View {
        ZStack {
            AuroraBackgroundView()

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
                        LogsView(controller: controller)
                    }
                    .padding(24)
                }
            }
        }
        .groupBoxStyle(GlassGroupBoxStyle())
        .frame(minWidth: 640, minHeight: 700)
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
        }
    }
}
