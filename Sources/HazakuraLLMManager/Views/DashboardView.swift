import SwiftUI
import HazakuraLLMManagerCore

struct DashboardView: View {
    @ObservedObject var controller: ServerController

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                GroupBox("Server Controls") {
                    VStack(alignment: .leading, spacing: 16) {
                        if let launchSetupHint = controller.launchSetupHint {
                            Label(launchSetupHint, systemImage: "info.circle")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        HStack(spacing: 12) {
                            Button {
                                controller.start()
                            } label: {
                                Label("Start", systemImage: "play.fill")
                            }
                            .buttonStyle(PrimaryButtonStyle())
                            .disabled(!controller.canStart)

                            Button {
                                controller.stop()
                            } label: {
                                Label("Stop", systemImage: "stop.fill")
                            }
                            .buttonStyle(SecondaryButtonStyle())
                            .disabled(!controller.canStop)

                            Button {
                                controller.restart()
                            } label: {
                                Label("Restart", systemImage: "arrow.clockwise")
                            }
                            .buttonStyle(SecondaryButtonStyle())
                            .disabled(!controller.canRestart)

                            Spacer()

                            if let message = controller.lastErrorMessage {
                                Label(message, systemImage: "exclamationmark.triangle")
                                    .foregroundStyle(.red)
                                    .font(.caption)
                                    .lineLimit(2)
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }

                EndpointView(controller: controller)
                CommandPreviewView(controller: controller)
            }
            .padding(24)
        }
    }
}
